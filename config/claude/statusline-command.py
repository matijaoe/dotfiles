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
    "show_model_id": False,  # Debug: show raw model ID instead of parsed name
    "debug_log": False,  # Write to ~/.claude/statusline-debug.log
}

# ============================================================================
# COLORS
# ============================================================================

COLORS = {
    # Models
    "model_opus_1m_fg": "#000000",  # Black text
    "model_opus_1m_bg": "#A34455",  # Muted Coral Pink
    "model_sonnet_1m": "#F5A80B",  # Amber
    "model_sonnet": "#EB875F",  # Anthropic Orange
    "model_opus": "#FF6A82",  # Coral Pink
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

# Order matters: more specific patterns must come first (e.g. Opus+1m before Opus).
# Keywords match substrings of display_name (e.g. "Claude Sonnet 4.6"), case-insensitive.
# Entries are (keywords, fg_color, bg_color_or_None)
MODEL_COLOR_MAP = [
    (["opus", "1m"], COLORS["model_opus_1m_fg"], COLORS["model_opus_1m_bg"]),
    (["sonnet", "1m"], COLORS["model_sonnet_1m"], None),
    (["opus"], COLORS["model_opus"], None),
    (["sonnet"], COLORS["model_sonnet"], None),
    (["haiku"], COLORS["model_haiku"], None),
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


def get_model_colors(name):
    """Return (fg, bg) tuple for the given model name."""
    lower = name.lower()
    for keywords, fg, bg in MODEL_COLOR_MAP:
        if all(kw in lower for kw in keywords):
            return fg, bg
    return COLORS["model_unknown"], None


def style_model(name):
    if not name or name == "unknown":
        return dim("unknown")
    fg, bg = get_model_colors(name)
    text = f" {name} " if bg else name
    result = colored(text, fg=fg, bg=bg)
    if bg:
        result = f"\033[1m{result}"
    return result


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
    model_name = data.get("model", {}).get("display_name") or ""
    session_id = data.get("session_id", "unknown")
    write_debug_log(session_id, model_id, model_name)

    if CONFIG["show_model_id"]:
        display_model = model_id
    else:
        # Strip any parenthetical context size suffix from display name, e.g. " (1M context)"
        import re
        display_model = re.sub(r"\s*\([^)]*context[^)]*\)", "", model_name).strip()
        # Append [1M] badge if the context window is 1M or larger
        ctx_size = data.get("context_window", {}).get("context_window_size", 0)
        if ctx_size >= 1_000_000:
            display_model += " [1M]"

    # -- Effort level (read from settings files, not stdin JSON) --
    cwd = data.get("workspace", {}).get("current_dir")
    effort = get_effort_level(cwd)
    effort_bar = style_effort(effort, model_id)

    # -- Context --
    ctx = data.get("context_window", {})
    used_pct = ctx.get("used_percentage")
    is_extended = ctx.get("context_window_size", 0) > 500_000

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

    if repo_name:
        repo_text = colored(repo_name, fg=COLORS["repo"])
        if remote_url:
            repo_text = hyperlink(repo_text, remote_url)
        parts.append(repo_text)

    if CONFIG["show_cost"]:
        total = data.get("cost", {}).get("total_cost_usd", 0)
        if total > 0:
            parts.append(colored(f"${total:.2f}", fg=COLORS["cost"]))

    output = sep.join(parts)

    # -- Second line: branch (clickable if pushed to remote) · open in Cursor --
    if branch:
        branch_text = colored(branch, fg=COLORS["branch"])
        if remote_url and branch_exists_on_remote(project_dir, branch):
            branch_text = hyperlink(branch_text, f"{remote_url}/compare/{branch}")
        open_dir = project_dir or cwd
        open_text = hyperlink(colored("cursor ↗", fg=COLORS["separator"]), f"cursor://file/{open_dir}")
        output += "\n" + branch_text + sep + open_text

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
