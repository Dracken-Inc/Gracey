from __future__ import annotations

from pathlib import Path
from typing import Any

import yaml


def _repo_root() -> Path:
    # interfaces/api/app/config_loader.py -> repo root is three levels up.
    return Path(__file__).resolve().parents[3]


def _read_yaml(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        data = yaml.safe_load(f) or {}
    if not isinstance(data, dict):
        return {}
    return data


def load_stack_config() -> dict[str, Any]:
    return _read_yaml(_repo_root() / "configs" / "gracey_stack.yaml")


def load_routing_policy() -> dict[str, Any]:
    return _read_yaml(_repo_root() / "platform" / "router" / "routing_policy.yaml")


def load_role_registry() -> dict[str, Any]:
    return _read_yaml(_repo_root() / "platform" / "inference" / "role_registry.yaml")
