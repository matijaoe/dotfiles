# Testing the gum integration branch

This guide walks through verifying the `gum` integration on an already-set-up Mac.
Delete this file before merging.

## Prerequisites

You should be on the feature branch:

```sh
git checkout claude/explore-setup-improvements-XbSoU
```

## 1. Verify gum binary download (standalone, safe)

This confirms the tarball downloads, extracts, and the binary is locatable.
Run in your terminal — nothing is installed permanently.

```sh
GUM_TMP="$(mktemp -d)"
curl -fsSL "https://github.com/charmbracelet/gum/releases/download/v0.17.0/gum_0.17.0_Darwin_$(uname -m).tar.gz" \
  | tar xz -C "$GUM_TMP"
echo "--- Contents ---"
ls -R "$GUM_TMP"
echo "--- Binary ---"
find "$GUM_TMP" -name gum -type f
echo "--- Version ---"
"$(find "$GUM_TMP" -name gum -type f | head -1)" --version
rm -rf "$GUM_TMP"
```

**Expected:** The binary is found, runs, and prints a version string.

## 2. Run full setup (idempotent, safe)

Everything is already installed on your machine, so every step will show
"Already installed" or "up to date". This tests the gum-enhanced output.

```sh
./setup.sh --work
```

**What to look for:**
- [ ] Step 0: gum bootstrap is skipped (gum already installed via brew)
- [ ] Section headers use styled gum output (bold cyan)
- [ ] Step 4: profile shows "Using saved profile: work" (no interactive prompt)
- [ ] Step 5: brew packages cycle through with a spinner, ending with "N packages up to date"
- [ ] Steps 7-9: Node/npm/pnpm show green checkmarks for installed packages
- [ ] Step 12: macOS defaults show a spinner then "Applied"
- [ ] Final banner: styled green "Setup complete!"
- [ ] Manual steps section renders with gum-styled headers

## 3. Test standalone scripts

These test gum outside of `setup.sh` (no bootstrap, uses brew-installed gum):

```sh
# Brew install (tests the spinner)
dots run brew

# Save (tests gum confirm — decline with N)
dots save

# Claude setup (tests gum confirm for override prompts)
dots run claude
```

**What to look for:**
- [ ] `dots run brew`: spinner cycles package names, summary line at end
- [ ] `dots save`: changes listed, gum confirm dialog appears (press N to skip)
- [ ] `dots run claude`: all configs show as already linked, summary line

## 4. Test gum bootstrap (simulate fresh machine)

This temporarily hides brew's gum so `setup.sh` triggers the temp binary download.

```sh
# Save current PATH
PATH_BACKUP="$PATH"

# Remove Homebrew dirs from PATH so gum isn't found
export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v homebrew | tr '\n' ':')

# Verify gum is hidden
which gum 2>/dev/null && echo "FAIL: gum still visible" || echo "OK: gum not found"

# Run setup — should download gum to temp, then proceed normally
./setup.sh --work

# Restore PATH
export PATH="$PATH_BACKUP"
```

**What to look for:**
- [ ] "gum not found" confirmed before setup
- [ ] Step 0 downloads gum (brief curl activity)
- [ ] All subsequent steps work identically to test 2
- [ ] No leftover temp files after setup exits

## 5. Test curl-pipe behavior (stdin/tty redirect)

This simulates `curl -fsSL .../install.sh | bash`:

```sh
cat install.sh | bash --work
```

**What to look for:**
- [ ] Script detects existing clone, says "already cloned"
- [ ] Hands off to `setup.sh` successfully
- [ ] Interactive prompts work (stdin redirected from /dev/tty)
- [ ] No "read: not a terminal" errors

## 6. Test gum confirm behavior

Quick standalone check that `confirm` works in both accept/reject paths:

```sh
source scripts/lib/common.sh

# Test accept (press Y)
confirm "Test prompt — press Y" && echo "Accepted" || echo "Declined"

# Test reject (press N)
confirm "Test prompt — press N" && echo "Accepted" || echo "Declined"
```

**Expected:** First shows "Accepted", second shows "Declined". Both use gum's
native confirm dialog (arrow keys + enter, or y/n keys).

## What if something fails

- **gum binary download fails:** Check the URL manually in a browser.
  The tarball URL is `https://github.com/charmbracelet/gum/releases/download/v0.17.0/gum_0.17.0_Darwin_arm64.tar.gz`
- **"gum: command not found" in standalone scripts:** Run `brew install gum`
  (it should already be in your Brewfile after running setup)
- **Spinner doesn't animate:** The brew spinner uses ANSI escape codes.
  Verify your terminal supports `\r` (carriage return) and `\033[K` (clear line).
  Ghostty, iTerm2, and Terminal.app all support this.
- **stdin issues with cat | bash:** Ensure `/dev/tty` exists (`ls -la /dev/tty`).
  This is standard on macOS but could be missing in containers.
