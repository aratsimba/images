# Adding the AWS MCP Server to Kiro

A reference for wiring up the `aws-mcp` server (the AWS MCP Server, via the
`mcp-proxy-for-aws` proxy) in Kiro, including the AWS credential setup it needs.

## Overview

The AWS MCP Server is a remote service. Locally, Kiro runs the `mcp-proxy-for-aws`
proxy as a stdio subprocess; the proxy handles the HTTPS leg to the remote endpoint
and signs requests (SigV4) with your AWS credentials:

```
Kiro  <-- stdio -->  mcp-proxy-for-aws  <-- HTTPS (SigV4) -->  https://aws-mcp.us-east-1.api.aws/mcp
```

So you configure it as a local `command` server, and it reaches AWS on your behalf
using whichever AWS profile you point it at.

## Prerequisites

- The install command from the registry page:
  https://ai-registry.amazon.dev/mcp-registry/server/aws-mcp
  → `uvx mcp-proxy-for-aws@latest https://aws-mcp.us-east-1.api.aws/mcp`
- `uvx` (ships with `uv`)
- Working AWS credentials (this guide uses `isengardcli` profiles)

## Step 1 — Install uv / uvx

The proxy is launched with `uvx`. Install `uv` (which provides `uvx`) with the
official standalone installer:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

This installs `uv` and `uvx` to `~/.local/bin`. Confirm the path (used in the config):

```bash
command -v uvx    # e.g. /Users/<you>/.local/bin/uvx
```

Tip: use the absolute path to `uvx` in the config so Kiro finds it regardless of
the PATH it spawns processes with.

## Step 2 — Set up AWS credentials (isengardcli)

The proxy uses the standard AWS credential chain, resolved from the profile named
in the config's `env` block. These profiles pull temporary credentials through
`isengardcli`, so install it via Builder Toolbox:

```bash
toolbox registry add s3://buildertoolbox-registry-isengard-cli-us-west-2/tools.json
toolbox install brazilcli        # dependency
toolbox install isengard-cli     # runnable command is: isengardcli
```

Example `~/.aws/config` profile:

```ini
[default]
region = us-east-1
output = json
```

Example `~/.aws/credentials` profile (credentials fetched on demand by isengardcli):

```ini
[default]
credential_process = isengardcli credentials <account-alias> --role <RoleName> --awscli
```

isengardcli authenticates through Midway. If credential resolution starts failing,
refresh your session:

```bash
mwinit
```

Verify a profile resolves (prints identity, not secrets):

```bash
aws sts get-caller-identity --profile <profile>
```

Least-privilege note: the `aws-mcp` tools can call real AWS APIs with whatever role
the configured profile assumes. Prefer a read-only / least-privilege role over an
Administrator role for an agent.

## Step 3 — Add aws-mcp to the Kiro MCP config

Edit `~/.kiro/settings/mcp.json` (user level) or
`<workspace>/.kiro/settings/mcp.json` (workspace level) and add the `aws-mcp` entry
alongside any existing servers:

```json
{
  "mcpServers": {
    "aws-mcp": {
      "command": "/Users/<you>/.local/bin/uvx",
      "args": [
        "mcp-proxy-for-aws@latest",
        "https://aws-mcp.us-east-1.api.aws/mcp"
      ],
      "env": {
        "AWS_PROFILE": "default",
        "AWS_REGION": "us-east-1"
      },
      "disabled": false,
      "autoApprove": []
    }
  }
}
```

Notes:
- `AWS_PROFILE` selects which `~/.aws` profile the proxy uses.
- Keep `AWS_REGION` as `us-east-1` to match the endpoint's signing region,
  regardless of the profile's own default region.
- Leave `autoApprove` empty so each AWS tool call prompts you first.
- `"transport": "stdio"` is optional here — with a `command` present, Kiro defaults
  to stdio anyway.

## Step 4 — Reconnect and verify

1. Save `mcp.json`. Kiro reloads on the change, or reconnect `aws-mcp` from the
   MCP Server view in the Kiro feature panel.
2. First launch takes a few seconds while `uvx` fetches `mcp-proxy-for-aws`.
3. Confirm the tools are live by running a lightweight, read-only tool such as
   `aws___list_regions`. A successful region list confirms the proxy launched,
   authenticated, and reached AWS.

## Ongoing

- Refresh Midway with `mwinit` when the proxy starts failing auth.
- `mcp-proxy-for-aws@latest` picks up proxy updates on each launch.
