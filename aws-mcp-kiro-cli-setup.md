# Enabling the aws-mcp Server in Kiro CLI

How we got the `aws-mcp` server working in **both** the Kiro CLI and the Kiro IDE,
the approaches that failed along the way, and what to try if you want to re-enable
the CLI agent sandbox later.

## TL;DR — the final solution

The `aws-mcp` server (the `mcp-proxy-for-aws` proxy) authenticates to AWS using the
standard credential chain. The Kiro IDE is not sandboxed and reads `~/.aws`
directly; the Kiro CLI, with agent sandboxing on, blocks that path — which is what
broke the CLI.

The fix that made both work from a single shared config:

1. **Disable the CLI agent sandbox.** Edit `~/.kiro/settings/amazon-internal.json`:
   ```json
   {"sandbox": false}
   ```
2. **Keep `mcp.json` clean** — the `aws-mcp` env block needs only the profile and
   region (no credential-file overrides):
   ```json
   "aws-mcp": {
     "command": "/Users/<you>/.local/bin/uvx",
     "args": ["mcp-proxy-for-aws@latest", "https://aws-mcp.us-east-1.api.aws/mcp"],
     "env": {
       "AWS_PROFILE": "default",
       "AWS_REGION": "us-east-1"
     },
     "disabled": false,
     "autoApprove": []
   }
   ```

With the sandbox off, the CLI-launched proxy reads the `default` profile from
`~/.aws` via its isengardcli `credential_process`, exactly like the IDE. No
per-session vending, no re-vending, no config divergence.

**Trade-off:** disabling the sandbox removes its isolation — `~/.aws` and IMDS are
no longer walled off from agents in the CLI. The internal guidance is to keep the
sandbox on unless automatic/seamless credentials matter more to you than that
protection. For a single-user dev machine this is a common, reasonable choice.

Reference: [AWS Credentials for Kiro Agents](https://w.amazon.com/bin/view/EnterpriseEngineeringSystemsDevelopment/AgenticDevelopment/AWSCredentials/).

## Background: why the CLI behaved differently from the IDE

- **Kiro IDE** is not sandboxed. Its `aws-mcp` proxy reads `~/.aws`, resolves the
  `default` profile through isengardcli, and works out of the box.
- **Kiro CLI** had agent sandboxing on (`{"sandbox": true}` in
  `~/.kiro/settings/amazon-internal.json`). Sandbox-on blocks the agent and every
  process it spawns — including the `aws-mcp` proxy — from reading `~/.aws`, and the
  isengardcli `credential_process` is never run. Instead the sandbox points the
  proxy's `AWS_CONFIG_FILE` / `AWS_SHARED_CREDENTIALS_FILE` at a per-session
  directory (`~/.sbox-session/<session-id>/`) that is empty until credentials are
  vended. Result:
  ```
  JSON-RPC error: -32603: No AWS credentials available.
  Configure credentials or use --skip-auth to send unsigned requests
  ```
  (`--skip-auth` is not a real fix — the AWS MCP endpoint requires SigV4-signed
  requests, so unsigned requests just fail differently.)

## Options we tried and why they failed

### Option A — Vend credentials with `get_aws_creds` (keep sandbox on)
- **What:** In the CLI, ask the agent to vend creds via the `creds-agent` MCP server
  (`get_aws_creds`) into the `default` profile. This populates the sandbox's
  per-session credential directory.
- **Result:** Worked in the CLI for that session.
- **Why we moved on:** Vended credentials are short-lived and per-session. A new CLI
  session starts with an empty/expired session directory, so the same error returns
  until you re-vend. Ongoing manual re-vending every session was more friction than
  we wanted.

### Option B — Add `AWS_SHARED_CREDENTIALS_FILE` / `AWS_CONFIG_FILE` to `mcp.json`
- **What:** The vending flow added these to the `aws-mcp` env block:
  ```json
  "AWS_SHARED_CREDENTIALS_FILE": "${AWS_SHARED_CREDENTIALS_FILE}",
  "AWS_CONFIG_FILE": "${AWS_CONFIG_FILE}"
  ```
- **Result:** Worked in the CLI (the sandbox sets those variables to the per-session
  directory, so they expanded correctly), **but broke the IDE.**
- **Why it broke the IDE:** The IDE is not sandboxed, so those environment variables
  are unset. `${AWS_SHARED_CREDENTIALS_FILE}` expanded to empty, pointing the proxy
  at a non-existent credentials file instead of `~/.aws` — so the IDE could no longer
  find the `default` profile and failed to connect.
- **Root cause:** `mcp.json` is shared between the CLI and the IDE, but these two
  variables are only valid inside the CLI sandbox. One shared env block cannot serve
  both a sandboxed and an unsandboxed context.
- **Also note:** even in the CLI, Option B still depends on vended creds existing, so
  it inherited Option A's per-session expiry problem on a new session.

### Option C — Revert `mcp.json` to profile + region only
- **What:** Remove the two credential-file variables, leaving `AWS_PROFILE` +
  `AWS_REGION`.
- **Result:** Restores the IDE, but the CLI (still sandboxed) goes back to failing,
  because it needs the per-session credential-file path.
- **Why we moved on:** This is a straight IDE-vs-CLI trade-off from one shared file —
  it fixes one by breaking the other.

### Final choice — Disable the sandbox
Disabling the CLI sandbox removed the condition that caused all of the above: with
`~/.aws` readable again, the clean `mcp.json` (Option C's shape) works for both the
IDE and the CLI simultaneously. See TL;DR.

## Verifying it works

```bash
# Credentials resolve from ~/.aws (should print your assumed-role identity)
aws sts get-caller-identity --profile default

# CLI sandbox is off
cat ~/.kiro/settings/amazon-internal.json        # {"sandbox": false}
```

Then start a new kiro-cli session; `aws-mcp` should connect. In the IDE, a
lightweight read-only tool such as `aws___list_regions` confirms the tools are live.

## If you want to re-enable the sandbox later

Set `~/.kiro/settings/amazon-internal.json` back to `{"sandbox": true}` and use one
of these so `aws-mcp` still gets credentials under the sandbox:

1. **Vend per session (simplest, matches Option A).**
   Keep the `creds-agent` MCP server installed (AIM manages it; it provides
   `get_aws_creds`). At the start of each CLI session, ask the agent to vend creds
   into the `default` profile, e.g.:
   > vend creds for account <account-id>, role <role>, into the default profile, then retry

   Re-vend when they expire. Vending authenticates with Midway, so run `mwinit`
   outside the sandbox if it fails. The downside is the per-session manual step.

2. **Try the `${VAR:-default}` fallback form in one shared `mcp.json`.**
   The reason Option B broke the IDE is that `${AWS_SHARED_CREDENTIALS_FILE}` expands
   to empty when the variable is unset (the unsandboxed IDE). A shell-style default
   can make the same line work in both contexts — use the sandbox-provided path when
   it's set, otherwise fall back to `~/.aws`:
   ```json
   "env": {
     "AWS_PROFILE": "default",
     "AWS_REGION": "us-east-1",
     "AWS_SHARED_CREDENTIALS_FILE": "${AWS_SHARED_CREDENTIALS_FILE:-/Users/<you>/.aws/credentials}",
     "AWS_CONFIG_FILE": "${AWS_CONFIG_FILE:-/Users/<you>/.aws/config}"
   }
   ```
   - **CLI (sandboxed):** the variables are set, so they resolve to the per-session
     directory → uses vended creds.
   - **IDE (unsandboxed):** the variables are unset, so they fall back to `~/.aws` →
     reads the `default` profile as normal.

   **Caveat (untested):** this only works if Kiro's MCP env-var expansion supports the
   `${VAR:-default}` syntax. Some MCP clients do plain `${VAR}` substitution only,
   in which case the `:-default` part is ignored or treated literally and this won't
   help. Treat it as an experiment: after saving, verify **both** the IDE and the CLI
   connect. If the IDE breaks, the `:-` default isn't honored — fall back to option 3
   (split config). You still need vended creds to exist in the CLI for the sandbox
   path to resolve to anything.

3. **Split the config so IDE and CLI stop sharing one env block (removes the Option B
   conflict).**
   Keep the global `~/.kiro/settings/mcp.json` clean (profile + region) for the IDE,
   and put the sandbox-specific `aws-mcp` variant — the one with
   `AWS_SHARED_CREDENTIALS_FILE` / `AWS_CONFIG_FILE` — in a **workspace-scoped**
   config that only the CLI uses:
   ```bash
   aim mcp install --scope workspace <...>
   ```
   or a workspace `.kiro/settings/mcp.json`. The IDE reads the clean version; the CLI
   reads the sandbox version. You still need vended creds to exist (option 1), but the
   two tools no longer fight over one file.

4. **Confirm `isengardcli` is reachable to the sandboxed proxy.**
   If you rely on the isengardcli `credential_process` under the sandbox and hit a
   "command not found" / credential_process failure, use the absolute path in
   `~/.aws/credentials`:
   ```ini
   credential_process = /Users/<you>/.toolbox/bin/isengardcli credentials <account-alias> --role <RoleName> --awscli
   ```
   (`~/.aws/credentials` is editable; the `~/.kiro/settings/` files are not, so those
   you edit by hand.)

## Notes / gotchas learned

- `mcp.json` and `amazon-internal.json` under `~/.kiro/settings/` are protected from
  agent writes — edit them by hand. `~/.aws/*` files are editable normally.
- `creds-agent` is a legitimate AIM-managed server providing `get_aws_creds`; AIM may
  re-add it automatically on CLI sign-in. It's harmless to leave installed even with
  the sandbox off (it may just show "failed to connect" in the IDE).
- Credentials themselves live in `~/.aws` and were never modified by vending — vended
  creds land in `~/.sbox-session/<session-id>/`, isolated from `~/.aws`.
- Back up before editing: we kept copies like
  `~/amazon-internal.json.backup.<timestamp>` and `~/.aws.backup.<timestamp>`.
