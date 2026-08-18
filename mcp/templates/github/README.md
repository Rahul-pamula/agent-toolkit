# GitHub MCP Template

Official server: [`github/github-mcp-server`](https://github.com/github/github-mcp-server)
(`ghcr.io/github/github-mcp-server`). The npm package
`@modelcontextprotocol/server-github` is **deprecated** as of April 2025.

Provides comprehensive tools to interact with GitHub repositories, pull requests, issues, and file content.

## Required environment variables

- `GITHUB_PERSONAL_ACCESS_TOKEN` — fine-grained or classic PAT

### Getting a Token
1. Go to [GitHub Developer Settings](https://github.com/settings/tokens).
2. Generate a new Fine-grained Personal Access Token (recommended).
3. Grant `Repository permissions` for the repos you want the agent to access (e.g., `Contents: Read & write`, `Pull Requests: Read & write`, `Issues: Read & write`).

## Usage

1. Ensure Docker is available.
2. Copy `config.template.json` into your MCP client config.
3. Export `GITHUB_PERSONAL_ACCESS_TOKEN`.
4. Optionally run `./wrapper.sh` as a local launcher example.
