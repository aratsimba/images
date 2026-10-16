# Environment Setup Guide

Reproducible steps to recreate this development environment on a macOS
(Apple Silicon) machine: Python 3.12 via `uv`, a project virtual environment with
document/media packages, LibreOffice, and ffmpeg/ffprobe.

Assumes `uv` is already installed (`curl -LsSf https://astral.sh/uv/install.sh | sh`,
which puts `uv`/`uvx` in `~/.local/bin`). Adjust `<you>` / paths as needed.

---

## 1. Python 3.12 (via uv)

Install a standalone CPython 3.12 managed by `uv`. This does not touch the system
`python3` (3.9.6) and requires no admin rights.

```bash
uv python install 3.12
```

Verify:

```bash
uv run --python 3.12 python --version   # Python 3.12.x
```

## 2. Project virtual environment

Create a 3.12 venv at the project root so that both `python` and `python3`
resolve to 3.12 inside it.

```bash
cd /path/to/project
uv venv --python 3.12 .venv
```

Activate (per terminal session):

```bash
source .venv/bin/activate
python --version    # 3.12.x
python3 --version   # 3.12.x
deactivate          # return to system shell
```

Keep the venv out of git:

```bash
echo ".venv/" >> .gitignore
```

## 3. Python packages (document / media processing)

Install into the venv. Package name → import name differs for several of these.

```bash
uv pip install --python .venv/bin/python \
  python-pptx \
  python-docx \
  openpyxl \
  pymupdf \
  pillow
```

| Package     | Import as  | Purpose                     |
|-------------|------------|-----------------------------|
| python-pptx | `pptx`     | PowerPoint (.pptx)          |
| python-docx | `docx`     | Word (.docx)                |
| openpyxl    | `openpyxl` | Excel (.xlsx)               |
| pymupdf     | `pymupdf`  | PDF (import `pymupdf`, not the deprecated `fitz`) |
| pillow      | `PIL`      | Images                      |

Verify:

```bash
.venv/bin/python -c "import pptx, docx, openpyxl, pymupdf, PIL; print('ok')"
```

## 4. LibreOffice (official DMG, Apple Silicon)

Native arm64 build from The Document Foundation. Check the current stable version
at https://www.libreoffice.org/download/download-libreoffice/ and substitute it for
`<version>` below (these steps used 26.8.1).

```bash
VERSION=26.8.1
cd /tmp
curl -L -o "LibreOffice_${VERSION}_MacOS_aarch64.dmg" \
  "https://download.documentfoundation.org/libreoffice/stable/${VERSION}/mac/aarch64/LibreOffice_${VERSION}_MacOS_aarch64.dmg"

# Mount, install to /Applications, unmount
hdiutil attach "LibreOffice_${VERSION}_MacOS_aarch64.dmg" -nobrowse -mountpoint /Volumes/LibreOffice_LO
rm -rf /Applications/LibreOffice.app
cp -R "/Volumes/LibreOffice_LO/LibreOffice.app" /Applications/
hdiutil detach /Volumes/LibreOffice_LO

# Clean up installer
rm -f "/tmp/LibreOffice_${VERSION}_MacOS_aarch64.dmg"
```

Verify (should report "accepted / Notarized Developer ID" and the version):

```bash
spctl -a -t exec -vv /Applications/LibreOffice.app
/Applications/LibreOffice.app/Contents/MacOS/soffice --version
```

Headless conversion example (pairs with the Python document packages):

```bash
/Applications/LibreOffice.app/Contents/MacOS/soffice --headless --convert-to pdf --outdir . file.docx
```

## 5. Homebrew + ffmpeg / ffprobe

ffmpeg has no single canonical signed macOS binary; Homebrew is the safest,
self-maintaining arm64 source. Homebrew install needs an admin password and is
interactive, so run it yourself first.

**Install Homebrew (interactive — prompts for your macOS password):**

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Add brew to PATH (Apple Silicon):**

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

**Install ffmpeg (brings ffprobe and the codec dependency tree):**

```bash
brew install ffmpeg
```

Verify (expect native arm64 and matching versions):

```bash
file "$(command -v ffmpeg)"   # ... arm64
ffmpeg -version | head -1
ffprobe -version | head -1
```

Update later with:

```bash
brew upgrade ffmpeg
```

---

## Notes

- `uv`-managed Python and venvs stay isolated from the system `python3`; nothing
  global changes unless you opt in (e.g. `uv python install 3.12 --default`).
- `~/.local/bin` is on PATH, so tools installed there are callable directly.
- On an Amazon-managed Mac, check the internal self-service software catalog first
  for LibreOffice/ffmpeg — it's the policy-compliant path when the app is offered.
- Prefer the native **arm64** build of anything on Apple Silicon (M-series) to
  avoid running under Rosetta.
