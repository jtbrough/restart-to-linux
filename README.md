# restart-to-linux

Simple CLI and launcher app for macOS users who want a one-time restart into Asahi Linux.

## Contents

- [Disclaimer](#disclaimer)
- [Install](#install)
- [Use](#use)
- [Development](#development)

## Disclaimer

One could, of course, just do this via simple CLI:

```bash
sudo bless --mount "/Volumes/Your Linux Volume" --setBoot --nextonly && sudo shutdown -r now
```

I built this small app because:

1. it was fun.
2. I wanted a clean Finder and Spotlight path in addition to the CLI.
3. I like the way it works.

If you decide to use it, I hope you enjoy it. Please feel free to report any issues.

On the tested Apple Silicon Asahi dual-boot machine, the observed behavior is effectively "restart to Linux once": ordinary macOS restarts still return to macOS, while `restart-to-linux` sends the next boot into Linux.

## Install

### Dependencies

This project is macOS-only and relies on system tools already present on macOS, primarily:

- `bless`
- `diskutil`
- `osascript`
- `codesign`

Check your environment with:

```bash
restart-to-linux --check
```

### Brew

Install:

```bash
brew tap jtbrough/tap
brew install jtbrough/tap/restart-to-linux
restart-to-linux --install-app
```

Uninstall:

```bash
restart-to-linux --uninstall-app
brew uninstall restart-to-linux
```

`--install-app` installs `Restart to Linux.app` into `~/Applications` so it can be launched from Finder, Spotlight, or the Dock.

After installation, Spotlight indexing may take a few minutes before the app appears in search results.

### Manual

Install:

```bash
git clone https://github.com/jtbrough/restart-to-linux.git
cd restart-to-linux
./install.sh
restart-to-linux --install-app
```

Uninstall:

```bash
restart-to-linux --uninstall-app
./uninstall.sh
```

## Use

### Via CLI

```bash
restart-to-linux --check
restart-to-linux --version
restart-to-linux --list
restart-to-linux --dry-run
sudo restart-to-linux --bless-only
sudo restart-to-linux
```

If multiple mounted APFS `System` volumes match:

- the CLI shows a numbered chooser when run interactively
- the CLI refuses to guess in non-interactive mode and requires `--target`

Explicit selection:

```bash
sudo restart-to-linux --target "/Volumes/Your Linux Volume"
```

### Via GUI

Install the launcher app:

```bash
restart-to-linux --install-app
```

Then launch `Restart to Linux.app` from Finder, Spotlight, or the Dock.

If multiple valid Linux targets are available, the app presents a chooser dialog before requesting administrator privileges.

## Development

Project layout:

- `src/`: installable payload
- `packaging/`: Brew and macOS packaging
- `tests/`: test suite
- `tools/`: validation helpers

```bash
just lint
just validate
just test
just ci
just build-app
```
