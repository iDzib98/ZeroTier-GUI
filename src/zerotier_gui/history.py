"""Persistent local history of networks joined through the GUI."""

import json
import os


class NetworkHistory:
    def __init__(self, file_path=None):
        self.file_path = file_path or os.path.expanduser(
            "~/.local/share/zerotier-gui/network_history.json"
        )
        self.entries = self._load()

    def _load(self):
        try:
            with open(self.file_path, "r", encoding="utf-8") as stream:
                data = json.load(stream)
                return data if isinstance(data, dict) else {}
        except (OSError, json.JSONDecodeError):
            return {}

    def list(self):
        return [
            {
                "id": network_id,
                "name": entry.get("name") or "Unknown network",
                "joinedAt": entry.get("join_date", "-"),
            }
            for network_id, entry in reversed(list(self.entries.items()))
        ]

    def add(self, network_id, name):
        self.entries[network_id] = {
            "name": name or "Unknown network",
            "join_date": __import__("datetime").datetime.now().strftime(
                "%Y/%m/%d %H:%M"
            ),
        }
        self.save()

    def remove(self, network_id):
        self.entries.pop(network_id, None)
        self.save()

    def save(self):
        os.makedirs(os.path.dirname(self.file_path), exist_ok=True)
        temporary_path = self.file_path + ".tmp"
        with open(temporary_path, "w", encoding="utf-8") as stream:
            json.dump(self.entries, stream, indent=2)
        os.replace(temporary_path, self.file_path)
