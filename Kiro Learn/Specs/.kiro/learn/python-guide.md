# Python Rules

## Virtual Environment
- Always use a venv.
- Invoke the venv interpreter directly (`./.venv/bin/python script.py`).
- Do not use `source .venv/bin/activate` — each command runs in its own shell.

## Execution Rules
Multi-line `python -c` can hang the terminal with a `dquote>` prompt that
does not recover. Avoid it entirely — when in doubt, write to a `.py` file.

- Do not use `python -c` with physical newlines or heredocs (`<<EOF`).
- Do not use `python -c` with nested quotes or shell-escaped special
  characters (`$`, backticks, `"..."` inside `"..."`).
- Semicolon-chained one-liners are fine, e.g.
  `python -c "import json; print(json.dumps({'a': 1}))"`.
- For anything else, write a `.py` file under a `tmp/` directory and run
  it with `./.venv/bin/python tmp/script.py`. Delete the file after
  successful execution; keep it if the script fails so you can debug.
