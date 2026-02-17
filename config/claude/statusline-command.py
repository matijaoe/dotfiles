#!/usr/bin/env python3
"""Claude Code status line script."""

import json
import os
import subprocess
import sys
from datetime import datetime

# ============================================================================
# CONFIGURATION
# ============================================================================

CONFIG = {
    "show_cost": False,
    "show_session_id": False,  # Debug: show session ID prefix
    "show_model_id": False,  # Debug: show raw model ID instead of parsed name
    "debug_log": True,  # Write to ~/.claude/statusline-debug.log
}

# ============================================================================
# COLORS
# ============================================================================

COLORS = {
    # Models
    "model_sonnet_1m": "#F5A80B",  # Amber
    "model_sonnet": "#EB875F",  # Anthropic Orange
    "model_opus": "#FF6B80",  # Coral Pink
    "model_haiku": "#D4A8E8",  # Lavender
    "model_unknown": "#ABB1BF",  # Gray

    # Context usage
    "context_low": "#60BA9C",  # Sea Green
    "context_medium": "#F0DC8E",  # Amber
    "context_high": "#E8A862",  # Orange
    "context_critical": "#E05561",  # Red
    "context_zero": "#999999",  # Gray
    "context_overflow_fg": "#FFFFFF",
    "context_overflow_bg": "#C43D4B",  # Dark Red

    # Effort level (matches Anthropic's official selector)
    "effort_active": "#D77757",  # Anthropic Orange
    "effort_inactive": "#505050",  # Dark Gray

    # Git
    "repo": "#DA9BB8",  # Pink
    "branch": "#89CFF0",  # Sky Blue

    # UI
    "separator": "#999999",
    "cost": "#F0DC8E",
}

# Order matters: more specific patterns must come first (e.g. sonnet+1m before sonnet)
MODEL_COLOR_MAP = [
    (["sonnet", "1m"], COLORS["model_sonnet_1m"]),
    (["opus"], COLORS["model_opus"]),
    (["sonnet"], COLORS["model_sonnet"]),
    (["haiku"], COLORS["model_haiku"]),
]

CONTEXT_THRESHOLDS = {
    "standard": (50, 70, 85, 95),
    "extended": (65, 80, 90, 95),
}

CONTEXT_COLORS = [
    COLORS["context_low"],
    COLORS["context_medium"],
    COLORS["context_high"],
    COLORS["context_critical"],
]


# ============================================================================
# TERMINAL FORMATTING
# ============================================================================


def hex_to_rgb(h):
    h = h.lstrip("#")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def colored(text, fg=None, bg=None):
    codes = []
    if fg:
        r, g, b = hex_to_rgb(fg)
        codes.append(f"\033[38;2;{r};{g};{b}m")
    if bg:
        r, g, b = hex_to_rgb(bg)
        codes.append(f"\033[48;2;{r};{g};{b}m")
    return f"{''.join(codes)}{text}\033[0m" if codes else text


def dim(text):
    return f"\033[2m{text}\033[0m"


def hyperlink(text, url):
    """Make text clickable using OSC 8 terminal hyperlink sequences."""
    return f"\033]8;;{url}\033\\{text}\033]8;;\033\\"


# ============================================================================
# MODEL
# ============================================================================


def parse_model_name(model_id):
    """
    Parse a model ID into a display name.

    claude-opus-4-6            → Opus 4.6
    claude-sonnet-4-5-20250929 → Sonnet 4.5
    claude-sonnet-4-5-20250929[1m] → Sonnet 4.5 [1M]
    claude-haiku-4-5-20251001  → Haiku 4.5
    """
    if not model_id or model_id == "unknown":
        return "unknown"

    suffix = ""
    base = model_id
    if "[" in base:
        base, suffix_raw = base.split("[", 1)
        suffix = f" [{suffix_raw.rstrip(']').upper()}]"

    parts = base.split("-")
    start = 1 if parts[0] == "claude" else 0

    if len(parts) <= start:
        return model_id

    family = parts[start].capitalize()

    version_parts = []
    for part in parts[start + 1 :]:
        if part.isdigit() and len(part) >= 8:  # date segment, stop
            break
        version_parts.append(part)

    if version_parts:
        return f"{family} {'.'.join(version_parts)}{suffix}"
    return f"{family}{suffix}"


def get_model_color(name):
    lower = name.lower()
    for keywords, color in MODEL_COLOR_MAP:
        if all(kw in lower for kw in keywords):
            return color
    return COLORS["model_unknown"]


def style_model(name):
    if not name or name == "unknown":
        return dim("unknown")
    return colored(name, fg=get_model_color(name))


# ============================================================================
# EFFORT LEVEL
# ============================================================================

EFFORT_BAR = "▌"
EFFORT_LEVELS = {"low": 1, "medium": 2, "high": 3}


def get_effort_level(cwd):
    """
    Read effort level from settings files.

    Priority: env var > project settings > user settings > None.
    Note: This reads the *configured* setting, not a session-specific value.
    When changed via /model, the settings file updates and this picks it up.
    See: github.com/anthropics/claude-code/issues/9488
    """
    env = os.environ.get("CLAUDE_CODE_EFFORT_LEVEL")
    if env:
        return env.lower()

    paths = []
    if cwd:
        paths.append(os.path.join(cwd, ".claude", "settings.json"))
    paths.append(os.path.expanduser("~/.claude/settings.json"))

    for path in paths:
        try:
            with open(path) as f:
                level = json.load(f).get("effortLevel")
                if level:
                    return level.lower()
        except (OSError, json.JSONDecodeError, AttributeError):
            continue

    return "high"


def supports_effort_level(model_id):
    """Check if model supports effort levels (currently only Opus 4.6+)."""
    if not model_id:
        return False
    lower = model_id.lower()
    # Check for opus-4-6 or higher
    return "opus" in lower and ("4-6" in lower or "4-7" in lower or "4-8" in lower or "4-9" in lower or "5-" in lower)


def style_effort(level, model_id):
    """Build effort bar: ▮▮▮ with orange active / dark gray inactive."""
    if not supports_effort_level(model_id) or level is None:
        return None

    active = EFFORT_LEVELS.get(level, 3)
    inactive = 3 - active

    bar = colored(EFFORT_BAR * active, fg=COLORS["effort_active"])
    if inactive:
        bar += colored(EFFORT_BAR * inactive, fg=COLORS["effort_inactive"])
    return bar


# ============================================================================
# CONTEXT
# ============================================================================


def style_context(pct, is_extended=False):
    if pct is None or pct == 0:
        return colored("0%", fg=COLORS["context_zero"])

    label = f"{int(pct)}%"
    thresholds = CONTEXT_THRESHOLDS["extended" if is_extended else "standard"]

    for threshold, color in zip(thresholds, CONTEXT_COLORS):
        if pct < threshold:
            return colored(label, fg=color)

    return colored(label, fg=COLORS["context_overflow_fg"], bg=COLORS["context_overflow_bg"])


# ============================================================================
# GIT
# ============================================================================


def _git(project_dir, *args):
    """Run a git command and return stdout, or None on failure."""
    if not project_dir:
        return None
    try:
        result = subprocess.run(
            ["git", "-C", project_dir, "--no-optional-locks", *args],
            capture_output=True,
            text=True,
            timeout=1,
        )
        return result.stdout.strip() if result.returncode == 0 else None
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return None


def get_git_branch(project_dir):
    return _git(project_dir, "rev-parse", "--abbrev-ref", "HEAD")


def get_remote_url(project_dir):
    """Get remote origin as an HTTPS browser URL."""
    url = _git(project_dir, "remote", "get-url", "origin")
    if not url:
        return None
    if url.startswith("git@"):
        url = url.replace(":", "/", 1).replace("git@", "https://", 1)
    return url.removesuffix(".git")


def branch_exists_on_remote(project_dir, branch):
    if not branch:
        return False
    return _git(project_dir, "rev-parse", "--verify", f"refs/remotes/origin/{branch}") is not None


def get_repo_name(project_dir):
    return os.path.basename(project_dir) if project_dir else None


# ============================================================================
# DEBUG
# ============================================================================

DEBUG_LOG_PATH = os.path.expanduser("~/.claude/statusline-debug.log")


def write_debug_log(session_id, model_id, model_name):
    if not CONFIG["debug_log"]:
        return
    try:
        with open(DEBUG_LOG_PATH, "a") as f:
            ts = datetime.now().isoformat()
            sid = session_id[:8] if session_id else "?"
            f.write(f"{ts} | Session: {sid} | Model ID: {model_id} | Parsed: {model_name}\n")
    except OSError:
        pass


# ============================================================================
# MAIN
# ============================================================================


def build_status_line(data):
    sep = colored(" · ", fg=COLORS["separator"])

    # -- Model --
    model_id = data.get("model", {}).get("id", "unknown")
    model_name = parse_model_name(model_id)
    session_id = data.get("session_id", "unknown")
    write_debug_log(session_id, model_id, model_name)

    display_model = model_id if CONFIG["show_model_id"] else model_name

    # -- Effort level (read from settings files, not stdin JSON) --
    cwd = data.get("workspace", {}).get("current_dir")
    effort = get_effort_level(cwd)
    effort_bar = style_effort(effort, model_id)

    # -- Context --
    ctx = data.get("context_window", {})
    used_pct = ctx.get("used_percentage")
    is_extended = ctx.get("total", 0) > 500_000

    # -- Git --
    project_dir = data.get("workspace", {}).get("project_dir")
    branch = get_git_branch(project_dir)
    repo_name = get_repo_name(project_dir)
    remote_url = get_remote_url(project_dir)

    # -- First line: model [effort] · context · [session] · [repo] · [cost] --
    model_part = style_model(display_model)
    if effort_bar:
        model_part += " " + effort_bar
    parts = [model_part, style_context(used_pct, is_extended)]

    if CONFIG["show_session_id"]:
        parts.append(dim(session_id[:8]))
    if repo_name:
        parts.append(colored(repo_name, fg=COLORS["repo"]))
    if CONFIG["show_cost"]:
        total = data.get("cost", {}).get("total_cost_usd", 0)
        if total > 0:
            parts.append(colored(f"${total:.2f}", fg=COLORS["cost"]))

    output = sep.join(parts)

    # -- Second line: branch (clickable if pushed to remote) --
    if branch:
        branch_text = colored(branch, fg=COLORS["branch"])
        if remote_url and branch_exists_on_remote(project_dir, branch):
            branch_text = hyperlink(branch_text, f"{remote_url}/compare/{branch}")
        output += "\n" + branch_text

    return output


def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        print("error")
        sys.exit(0)

    print(build_status_line(data))


if __name__ == "__main__":
    main()
