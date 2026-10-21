"""ZeroTier CLI and host service integration."""

import grp
import json
import os
import pwd
import shlex
import shutil
import subprocess
import sys


ZERO_TIER_GROUP = "zerotier-one"

CLI_CANDIDATES = (
    "/usr/sbin/zerotier-cli",
    "/sbin/zerotier-cli",
    "/usr/bin/zerotier-cli",
    "/bin/zerotier-cli",
)

ONE_CANDIDATES = (
    "/usr/sbin/zerotier-one",
    "/usr/bin/zerotier-one",
)

INSTALL_URL = "https://install.zerotier.com"
DOWNLOAD_URL = "https://www.zerotier.com/download/"


class ZeroTierError(RuntimeError):
    """An operation against zerotier-one or the host failed."""

    def __init__(self, message, returncode=None):
        super().__init__(message)
        self.returncode = returncode


def _command_environment():
    env = os.environ.copy()
    if getattr(sys, "frozen", False):
        original = env.pop("LD_LIBRARY_PATH_ORIG", None)
        if original:
            env["LD_LIBRARY_PATH"] = original
        else:
            env.pop("LD_LIBRARY_PATH", None)
    return env


class ZeroTierService:
    def __init__(self):
        self.cli_path = self._find_cli()

    @staticmethod
    def _find_cli():
        for candidate in CLI_CANDIDATES:
            if os.path.isfile(candidate):
                return candidate
        return shutil.which("zerotier-cli") or "zerotier-cli"

    def is_installed(self):
        if any(os.path.isfile(path) for path in CLI_CANDIDATES):
            return True
        if any(os.path.isfile(path) for path in ONE_CANDIDATES):
            return True
        if shutil.which("zerotier-cli") or shutil.which("zerotier-one"):
            return True
        return os.path.isdir("/var/lib/zerotier-one")

    @staticmethod
    def install_command():
        # The official installer configures the package repository and enables
        # the zerotier-one service. Run it as root through polkit; the Flatpak
        # and AppImage launchers forward pkexec to the host system.
        script = (
            "set -e\n"
            "if command -v curl >/dev/null 2>&1; then\n"
            f"  curl -fsSL {INSTALL_URL} | bash\n"
            "elif command -v wget >/dev/null 2>&1; then\n"
            f"  wget -qO- {INSTALL_URL} | bash\n"
            "else\n"
            '  echo "curl or wget is required to install ZeroTier." >&2\n'
            "  exit 1\n"
            "fi\n"
        )
        return ["pkexec", "/bin/sh", "-c", script]

    @staticmethod
    def _is_member_of_group():
        try:
            entry = grp.getgrnam(ZERO_TIER_GROUP)
            username = pwd.getpwuid(os.getuid()).pw_name
        except (KeyError, OSError):
            return False
        return username in entry.gr_mem

    @staticmethod
    def _has_group_in_session():
        try:
            gid = grp.getgrnam(ZERO_TIER_GROUP).gr_gid
        except KeyError:
            return False
        return gid == os.getgid() or gid in os.getgroups()

    def _cli_command(self, arguments):
        # Packaged launchers provide a host-aware zerotier-cli wrapper. Native
        # installs use sg if the user is a group member but this login session
        # predates that membership.
        if getattr(sys, "frozen", False) or os.environ.get("FLATPAK_ID"):
            return ["zerotier-cli", *arguments]
        if (
            os.getuid() != 0
            and self._is_member_of_group()
            and not self._has_group_in_session()
        ):
            command = shlex.join([self.cli_path, *arguments])
            return ["sg", ZERO_TIER_GROUP, "-c", f"exec {command}"]
        return [self.cli_path, *arguments]

    @staticmethod
    def _run(command, check=True):
        try:
            completed = subprocess.run(
                command,
                check=False,
                capture_output=True,
                text=True,
                env=_command_environment(),
            )
        except OSError as error:
            raise ZeroTierError(str(error)) from error
        if check and completed.returncode != 0:
            message = (completed.stderr or completed.stdout or "Command failed").strip()
            raise ZeroTierError(message, completed.returncode)
        return completed

    def _run_cli(self, *arguments):
        return self._run(self._cli_command(list(arguments)))

    def networks(self):
        try:
            data = json.loads(self._run_cli("-j", "listnetworks").stdout)
        except json.JSONDecodeError as error:
            raise ZeroTierError(f"Invalid ZeroTier network response: {error}") from error

        result = []
        for network in data:
            interface = network.get("portDeviceName", "")
            interface_state = self.interface_state(interface) if interface else "UNKNOWN"
            status = network.get("status", "UNKNOWN")
            if interface_state.lower() == "down":
                status_label = "Interface down"
            elif status == "OK":
                status_label = "Okay"
            else:
                status_label = status.replace("_", " ").title()
            result.append(
                {
                    "id": network.get("nwid", network.get("id", "")),
                    "name": network.get("name") or "Unknown network",
                    "status": status,
                    "statusLabel": status_label,
                    "interface": interface,
                    "interfaceState": interface_state,
                    "addresses": network.get("assignedAddresses", []),
                    "type": network.get("type", "-"),
                    "mac": network.get("mac", "-"),
                    "mtu": network.get("mtu", "-"),
                    "dhcp": network.get("dhcp", False),
                    "bridge": network.get("bridge", False),
                    "allowDefault": network.get("allowDefault", False),
                    "allowGlobal": network.get("allowGlobal", False),
                    "allowManaged": network.get("allowManaged", False),
                    "allowDNS": network.get("allowDNS", False),
                }
            )
        return result

    def peers(self):
        try:
            data = json.loads(self._run_cli("-j", "peers").stdout)
        except json.JSONDecodeError as error:
            raise ZeroTierError(f"Invalid ZeroTier peer response: {error}") from error
        return [
            {
                "address": peer.get("address", "-"),
                "version": "-" if peer.get("version") == "-1.-1.-1" else peer.get("version", "-"),
                "role": peer.get("role", "-"),
                "latency": peer.get("latency", "-"),
                "paths": peer.get("paths", []),
            }
            for peer in data
        ]

    def status(self):
        fields = self._run_cli("status").stdout.split()
        if len(fields) < 5:
            raise ZeroTierError("Unexpected response from zerotier-cli status")
        return {
            "address": fields[2],
            "version": fields[3],
            "status": fields[4],
        }

    def service_status(self):
        output = self._run(
            ["systemctl", "show", "--property=ActiveState", "--value", "zerotier-one"]
        ).stdout.strip()
        return output or "unknown"

    def set_service_running(self, running):
        action = "start" if running else "stop"
        self._run(["systemctl", action, "zerotier-one"])

    def join_network(self, network_id):
        self._run_cli("join", network_id)

    def leave_network(self, network_id):
        self._run_cli("leave", network_id)

    def set_network_option(self, network_id, option, value):
        self._run_cli("set", network_id, f"{option}={int(bool(value))}")

    def interface_state(self, interface):
        output = self._run(["ip", "--json", "address"]).stdout
        try:
            for item in json.loads(output):
                if item.get("ifname") == interface:
                    return item.get("operstate", "UNKNOWN")
        except json.JSONDecodeError:
            pass
        return "UNKNOWN"

    def toggle_interface(self, interface, currently_up):
        target_state = "down" if currently_up else "up"
        self._run(["pkexec", "ip", "link", "set", interface, target_state])

    def ensure_user_access(self):
        if not self.token_exists():
            try:
                self.set_service_running(True)
            except ZeroTierError:
                pass
        if not self.token_exists():
            raise ZeroTierError(
                "No se encontró authtoken.secret. Inicia zerotier-one y vuelve a intentarlo."
            )
        username = pwd.getpwuid(os.getuid()).pw_name
        commands = [
            ["usermod", "-aG", ZERO_TIER_GROUP, username],
            ["chmod", "660", "/var/lib/zerotier-one/authtoken.secret"],
            ["chmod", "660", "/var/lib/zerotier-one/identity.secret"],
        ]
        shell_command = " && ".join(shlex.join(command) for command in commands)
        self._run(["pkexec", "/bin/sh", "-c", shell_command])

    def token_exists(self):
        return os.path.isfile("/var/lib/zerotier-one/authtoken.secret")
