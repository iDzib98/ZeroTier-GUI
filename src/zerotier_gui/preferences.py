"""Persistent user preferences for the GUI."""

import json
import os


class Preferences:
    def __init__(self, file_path=None):
        self.file_path = file_path or os.path.expanduser(
            "~/.local/share/zerotier-gui/preferences.json"
        )
        self.data = self._load()

    def _load(self):
        try:
            with open(self.file_path, "r", encoding="utf-8") as stream:
                data = json.load(stream)
                return data if isinstance(data, dict) else {}
        except (OSError, json.JSONDecodeError):
            return {}

    def get(self, key, default=None):
        return self.data.get(key, default)

    def set(self, key, value):
        self.data[key] = value
        self.save()

    def save(self):
        os.makedirs(os.path.dirname(self.file_path), exist_ok=True)
        temporary_path = self.file_path + ".tmp"
        with open(temporary_path, "w", encoding="utf-8") as stream:
            json.dump(self.data, stream, indent=2)
        os.replace(temporary_path, self.file_path)
