<div align="center">

<img src="assets/tonic.svg" alt="tonic logo" width="128"/>

# tonic

Answer yes/no questions by playing your instrument. Major scale means yes, minor means no.

[![CI](https://github.com/pgagnidze/tonic/actions/workflows/ci.yml/badge.svg)](https://github.com/pgagnidze/tonic/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-000080)](LICENSE)

</div>

## How It Works

tonic records a few seconds of audio, tracks one fundamental frequency per frame (YIN with FFT autocorrelation), and tallies which notes you played. Minor and major scales built on the same root share notes, so the key is fixed up front and only the notes that separate the two scales are scored. In A blues, D, D# and G vote no. B, C# and F# vote yes. The root, the flat third and the fifth are neutral.

Everything lives in a single Lua file with a hand-rolled FFT, no libraries required. It runs on LuaJIT or Lua 5.4, and any monophonic instrument works, humming included.

Silence, ambient hum, or a take with fewer than three distinct notes returns UNCLEAR instead of a verdict, so a misfire never approves anything.

## Installation

### Standalone binary (recommended)

Downloads a self-contained binary with no Lua dependency (Linux and macOS):

```bash
curl -fsSL https://raw.githubusercontent.com/pgagnidze/tonic/main/install.sh | bash
```

### From source

Requires `luajit` (or Lua 5.4):

```bash
git clone https://github.com/pgagnidze/tonic
ln -s "$(pwd)/tonic/tonic" ~/.local/bin/tonic
```

### Runtime requirements

One audio capture tool. tonic tries them in order:

| Tool | Platform | Usually from |
|------|----------|--------------|
| `parec` | Linux (PulseAudio/PipeWire) | preinstalled |
| `pw-record` | Linux (PipeWire) | preinstalled |
| `arecord` | Linux (ALSA) | alsa-utils |
| `rec` | macOS or Linux | `brew install sox` / sox package |

Optional: `pactl` (Linux) for `mic-check`. macOS uses the built-in `system_profiler`.

## Usage

```bash
# Find your input source, then agree on a key and play
tonic mic-check
tonic decide --countdown 3 --duration 8 --source <name>

# Gate any command
tonic confirm --countdown 3 --duration 8 && terraform apply
```

```
tonic decide [options]       print the verdict
tonic confirm [options]      exit 0 = YES, 1 = NO, 2 = UNCLEAR
tonic hook [options]         Claude Code PermissionRequest hook
tonic mic-check              find the input source for your instrument
```

| Option | Description | Default |
|--------|-------------|---------|
| `--key NOTE` | Root of the agreed key | `A` |
| `--scale NAME` | `blues` or `pentatonic` | `blues` |
| `--duration SECONDS` | Listening window | `4` |
| `--countdown SECONDS` | Get-ready countdown before listening | `0` |
| `--source NAME` | PipeWire/Pulse source | `$TONIC_SOURCE` |
| `--min-confidence X` | Below this the verdict is UNCLEAR | `0` |
| `--input FILE` | Analyze raw s16le samples instead of recording | - |

## Claude Code Hook

Add to `.claude/settings.local.json` in a project, or to `~/.claude/settings.json` for every session. The hook fires only when a permission dialog would appear, and it needs default permission mode, since auto mode answers prompts before hooks see them. Use `"Bash"` to gate shell commands, or `"Bash|Edit|Write"` to gate file changes too:

```json
{
  "hooks": {
    "PermissionRequest": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "tonic hook --countdown 5 --duration 10 --min-confidence 0.6 --source <name>",
            "timeout": 60
          }
        ]
      }
    ]
  }
}
```

Major approves, minor denies with the verdict as the reason, UNCLEAR shows the normal dialog.

## Git Pre-Push Gate

```bash
printf '%s\n' '#!/usr/bin/env bash' 'exec tonic confirm --countdown 4 --duration 10' > .git/hooks/pre-push
chmod +x .git/hooks/pre-push
```

Every push now requires a major lick.

## Development

```bash
luacheck tonic      # Lint
stylua tonic        # Format
```

## License

[MIT](LICENSE)

> [!NOTE]
> This tool was written with assistance from LLMs. Human review, guidance, and all guitar playing provided where needed.
