"""Swarm config — precedence CLI > project > workspace > user > defaults."""

from __future__ import annotations

import os
from pathlib import Path
from typing import Any

MODEL_PROFILE_NAMES = ("economy", "balanced", "quality", "private")
TASK_CLASSES = ("planning", "coding", "review", "architecture", "hardening", "qa")


# Aliases for prompt autodetect (short names -> OWNER/REPO)
_PROMPT_ALIASES: dict[str, str] = {
    "create-node-app": "Create-Node-App/create-node-app",
    "cna-templates": "Create-Node-App/cna-templates",
    "create-awesome-node-app": "Create-Node-App/create-node-app",
}

def _candidate_repo_paths(owner_repo: str) -> list[Path]:
    owner, repo = owner_repo.split("/", 1)
    candidates: list[Path] = []
    ws = Path.home() / ".ai-workspace"
    candidates.append(ws / "repos" / "github.com" / owner / repo)
    candidates.append(ws / "repos" / owner / repo)
    try:
        cwd_ws = Path.cwd().resolve()
        for parent in [cwd_ws] + list(cwd_ws.parents):
            if (parent / "repos").is_dir() and parent.name == ".ai-workspace":
                candidates.append(parent / "repos" / "github.com" / owner / repo)
                candidates.append(parent / "repos" / owner / repo)
                break
    except Exception:
        pass
    candidates.append(Path.home() / ".ai-workspace" / "repos" / "github.com" / owner / repo)
    candidates.append(Path.cwd() / repo)
    return candidates

def _resolve_owner_repo_from_prompt(prompt: str | None) -> str | None:
    if not prompt:
        return None
    import re
    m = re.search(r"https?://github\.com/([A-Za-z0-9_.-]+)/([A-Za-z0-9_.-]+)", prompt)
    if m:
        return f"{m.group(1)}/{m.group(2)}"
    m = re.search(r"\b([A-Za-z0-9_.-]+)/([A-Za-z0-9_.-]+)(?:#\d+)?\b", prompt)
    if m:
        candidate = f"{m.group(1)}/{m.group(2)}"
        if "/" in candidate and not candidate.lower().startswith("error"):
            for cand in _candidate_repo_paths(candidate):
                if (cand / ".git").exists():
                    return candidate
            if candidate.startswith("Create-Node-App/"):
                return candidate
            pass
    low = prompt.lower()
    for alias, owner_repo in _PROMPT_ALIASES.items():
        if alias in low:
            return owner_repo
    return None

def autodetect_repo_from_prompt(prompt: str | None) -> Path | None:
    owner_repo = _resolve_owner_repo_from_prompt(prompt)
    if not owner_repo:
        return None
    for cand in _candidate_repo_paths(owner_repo):
        if (cand / ".git").exists():
            return cand.resolve()
    return None

def find_repo_root(start: Path | None = None, prompt_text: str | None = None, workspace: str | None = None) -> Path:
    if workspace:
        ws = Path(workspace).expanduser().resolve()
        if (ws / ".git").exists():
            return ws
        if "/" in workspace and not workspace.startswith("/"):
            for cand in _candidate_repo_paths(workspace):
                if (cand / ".git").exists():
                    return cand.resolve()
        return ws
    if prompt_text:
        auto = autodetect_repo_from_prompt(prompt_text)
        if auto is not None:
            return auto
    cur = (start or Path.cwd()).resolve()
    for p in [cur] + list(cur.parents):
        if (p / ".git").exists():
            return p
    return cur

def find_run_dir_by_id(run_id: str, workspace: str | None = None) -> Path | None:
    from .store import run_dir_for
    if workspace:
        repo = find_repo_root(workspace=workspace)
        cand = run_dir_for(repo, run_id)
        if cand.is_dir():
            return cand
        for cand2 in _candidate_repo_paths(workspace):
            if (cand2 / ".git").exists():
                cand = run_dir_for(cand2.resolve(), run_id)
                if cand.is_dir():
                    return cand
    try:
        repo = find_repo_root()
        cand = run_dir_for(repo, run_id)
        if cand.is_dir():
            return cand
    except Exception:
        pass
    search_roots = [
        Path.home() / ".ai-workspace" / "repos" / "github.com",
        Path.home() / ".ai-workspace" / "repos",
    ]
    try:
        cwd = Path.cwd().resolve()
        for parent in [cwd] + list(cwd.parents):
            if (parent / "repos").is_dir() and parent.name == ".ai-workspace":
                search_roots.append(parent / "repos" / "github.com")
                search_roots.append(parent / "repos")
                break
    except Exception:
        pass
    for root in search_roots:
        if not root.is_dir():
            continue
        try:
            for owner in root.iterdir():
                if not owner.is_dir():
                    continue
                if (owner / ".git").exists():
                    cand = run_dir_for(owner, run_id)
                    if cand.is_dir():
                        return cand
                else:
                    for repo in owner.iterdir():
                        if not repo.is_dir() or not (repo / ".git").exists():
                            continue
                        cand = run_dir_for(repo, run_id)
                        if cand.is_dir():
                            return cand
        except Exception:
            continue
    home_cand = Path.home() / ".agent-toolkit" / "swarm" / "runs" / run_id
    if home_cand.is_dir():
        return home_cand
    return None

def list_all_runs(workspace: str | None = None) -> list[Path]:
    from .store import list_runs
    if workspace:
        repo = find_repo_root(workspace=workspace)
        return list_runs(repo)
    try:
        repo = find_repo_root()
        runs = list_runs(repo)
        if runs:
            return runs
        if repo.name == ".ai-workspace" or (repo / "repos").is_dir():
            all_runs: list[Path] = []
            search_roots = [
                Path.home() / ".ai-workspace" / "repos" / "github.com",
                Path.home() / ".ai-workspace" / "repos",
            ]
            for parent in [repo] + list(repo.parents):
                if (parent / "repos").is_dir() and parent.name == ".ai-workspace":
                    search_roots.append(parent / "repos" / "github.com")
                    break
            for root in search_roots:
                if not root.is_dir():
                    continue
                for owner in root.iterdir():
                    if not owner.is_dir():
                        continue
                    for maybe_repo in [owner] if (owner / ".git").exists() else (list(owner.iterdir()) if owner.is_dir() else []):
                        if not maybe_repo.is_dir() or not (maybe_repo / ".git").exists():
                            continue
                        all_runs.extend(list_runs(maybe_repo))
            home_root = Path.home() / ".agent-toolkit" / "swarm" / "runs"
            if home_root.is_dir():
                all_runs.extend([p for p in home_root.iterdir() if p.is_dir()])
            return sorted(all_runs, key=lambda p: p.stat().st_mtime if p.exists() else 0, reverse=True)
    except Exception:
        pass
    return []


def load_yaml_file(path: Path) -> dict[str, Any]:
    if not path.is_file():
        return {}
    text = path.read_text(encoding="utf-8")
    try:
        import yaml  # type: ignore

        data = yaml.safe_load(text)
        return data if isinstance(data, dict) else {}
    except ImportError:
        import json

        try:
            return json.loads(text)
        except Exception:
            return {}
    except Exception:
        return {}


def resolve_config(repo_root: Path, cli_overrides: dict[str, Any] | None = None) -> dict[str, Any]:
    # Precedence: CLI > project-local > workspace > user > defaults
    defaults = {
        "recipe": "pair",
        "ui": "auto",
        "runner": "opencode",
        "model_profile": "balanced",
        "budget": {},
        "model_profiles": {},
    }
    # User config
    user_cfg_path = Path.home() / ".config" / "agent-toolkit" / "swarm.yaml"
    user_cfg = load_yaml_file(user_cfg_path)
    # Workspace: repo/.agent-toolkit/swarm.yaml OR swarm.yaml
    ws_cfg = {}
    for p in [
        repo_root / ".agent-toolkit" / "swarm.yaml",
        repo_root / "swarm.yaml",
        repo_root / ".agent-toolkit" / "swarm" / "config.yaml",
    ]:
        if p.is_file():
            ws_cfg = load_yaml_file(p)
            break
    # Project-local is same as workspace for now (repo root)
    merged = dict(defaults)
    for src in (user_cfg, ws_cfg):
        if src:
            for k, v in src.items():
                if v is not None:
                    if isinstance(v, dict) and isinstance(merged.get(k), dict):
                        merged[k] = {**merged[k], **v}
                    else:
                        merged[k] = v
    if cli_overrides:
        for k, v in cli_overrides.items():
            if v is not None:
                merged[k] = v
    # Env overrides for runtime paths (not primary config)
    if os.environ.get("AGENT_TOOLKIT_SWARM_RUNS_DIR"):
        merged["runs_dir"] = os.environ["AGENT_TOOLKIT_SWARM_RUNS_DIR"]
    return merged
