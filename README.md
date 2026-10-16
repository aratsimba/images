# Environment & Kiro Setup Notes

Reference docs for setting up this machine's development environment and the
Kiro `aws-mcp` integration. Each guide is self-contained; start with whichever
matches your task.

## Guides

| Document | What it covers |
|----------|----------------|
| [environment-setup.md](./environment-setup.md) | Reproducible setup of the dev toolchain: Python 3.12 via `uv`, a 3.12 project virtualenv, the document/media Python packages (python-pptx, python-docx, openpyxl, pymupdf, pillow), LibreOffice (Apple Silicon DMG), and ffmpeg/ffprobe via Homebrew. |
| [aws-mcp-setup.md](./aws-mcp-setup.md) | Adding the `aws-mcp` MCP server to Kiro: installing `uvx`, setting up `isengardcli` AWS credentials, the `mcp.json` entry, and reconnect/verify steps. The baseline (IDE) setup. |
| [aws-mcp-kiro-cli-setup.md](./aws-mcp-kiro-cli-setup.md) | Getting `aws-mcp` working in the Kiro **CLI** as well as the IDE: the agent-sandbox issue, the options tried and why they failed, the final fix (disable the CLI sandbox), and what to try if you re-enable the sandbox later. |

## Quick orientation

- **Setting up a fresh machine?** Start with `environment-setup.md`, then
  `aws-mcp-setup.md`.
- **`aws-mcp` works in the IDE but fails in the CLI (or vice versa)?** See
  `aws-mcp-kiro-cli-setup.md` — that tension and its fix are the whole point of
  that doc.

## Conventions used across these docs

- Target platform is **macOS on Apple Silicon** (M-series); prefer native `arm64`
  builds over Rosetta.
- Paths use `/Users/<you>/...` or `<you>` as a placeholder for the current user.
- Files under `~/.kiro/settings/` (`mcp.json`, `amazon-internal.json`) are
  protected from agent writes and are edited by hand; `~/.aws/*` files are editable
  normally.
- Back up config/credentials before editing (e.g.
  `~/.aws.backup.<timestamp>`, `~/amazon-internal.json.backup.<timestamp>`).

## Not tracked in git

- `.venv/` — the project virtualenv (see `.gitignore`).
