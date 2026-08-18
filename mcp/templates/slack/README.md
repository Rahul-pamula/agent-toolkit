# Slack MCP Template

Official Server: [`@modelcontextprotocol/server-slack`](https://github.com/modelcontextprotocol/servers/tree/main/src/slack)

Provides tools to interact with Slack workspaces, allowing agents to read channels, post messages, and reply to threads.

## Required environment variables

- `SLACK_BOT_TOKEN` (starts with `xoxb-`)
- `SLACK_APP_TOKEN` (starts with `xapp-`)
- `SLACK_TEAM_ID` (optional, for workspace scoping)

### Getting Tokens
1. Go to [Slack API Apps](https://api.slack.com/apps) and Create a New App.
2. Under **OAuth & Permissions**, add required Bot Token Scopes (e.g., `channels:history`, `channels:read`, `chat:write`).
3. Install the app to your workspace and copy the **Bot User OAuth Token** (`SLACK_BOT_TOKEN`).
4. Under **Basic Information > App-Level Tokens**, generate a token with `connections:write` scope to get your `SLACK_APP_TOKEN`.

## Usage

1. Copy `config.template.json` into your MCP client config.
2. Export `SLACK_BOT_TOKEN`.
3. Optionally run `./wrapper.sh` as a local launcher example.
