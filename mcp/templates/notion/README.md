# Notion MCP Template

Official Server: [`@modelcontextprotocol/server-notion`](https://github.com/modelcontextprotocol/servers/tree/main/src/notion)

Provides tools to interact with Notion workspaces, allowing agents to search, read, and write pages and databases.

## Required environment variables

- `NOTION_API_TOKEN` — An internal integration token.

### Getting a Token
1. Go to [Notion My Integrations](https://www.notion.so/my-integrations)
2. Create a new integration
3. Copy the "Internal Integration Secret"
4. **Important**: You must share specific Notion pages/databases with your integration via the "Share" menu in the top right of the Notion UI before the MCP server can access them.

## Usage

1. Copy `config.template.json` into your MCP client config (e.g., `claude_desktop_config.json`).
2. Export `NOTION_API_TOKEN` or add it to the client config.
3. Optionally run `./wrapper.sh` as a local launcher example.
