---
name: "flutter-setting-up-mcp"
description: "Sets up the Dart and Flutter MCP server to enable AI assistants to interact with Dart and Flutter tools. Use when configuring an MCP client (like Antigravity, Claude Code, or Cursor) to use the Dart and Flutter MCP server."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 18 Mar 2026 21:47:27 GMT"

---
# Configuring the Dart and Flutter MCP Server

## Contents
- [Prerequisites & Environment Check](#prerequisites--environment-check)
- [Client Configuration Workflows](#client-configuration-workflows)
- [Usage Workflows](#usage-workflows)
- [Examples](#examples)

## Prerequisites & Environment Check

Before initiating any setup procedures, verify the current environment state to prevent redundant configurations. The Dart and Flutter MCP server exposes specific tools to the agent environment.

**Conditional Setup Logic:**
1. Check available tools in your current environment for `analyze_code`, `hot_reload`, or `get_runtime_errors`.
2. **If** these tools are present, the MCP server is already active. **Do not** proceed with setup instructions unless explicitly instructed to configure a new environment.
3. **If** these tools are unavailable, proceed to the [Client Configuration Workflows](#client-configuration-workflows).

*Note: The base command to start the server is `dart mcp-server`. Append the `--force-roots-fallback` flag if the target client does not correctly set project roots.*

## Client Configuration Workflows

Execute the appropriate configuration workflow based on the active client environment.

### Antigravity Configuration
1. Open the Agent side panel (Cmd/Ctrl + L).
2. Click the Additional options (`...`) menu and select **MCP Servers**.
3. Click **Manage MCP Servers**.
4. **If** using the UI: Search for "Dart" and click **Install**.
5. **If** using raw configuration: Click **View raw config** and append the following JSON:
   ```json
   "dart-mcp-server": {
     "command": "dart",
     "args": ["mcp-server"],
     "env": {}
   }
   ```

### Claude Code Configuration
Run the following command in the terminal to attach the server via stdio:
```bash
claude mcp add --transport stdio dart -- dart mcp-server
```

### Codex CLI Configuration
Run the following command in the terminal (includes the roots fallback flag):
```bash
codex mcp add dart -- dart mcp-server --force-roots-fallback
```

### Cursor / VS Code / Generic Clients
Configure the MCP server manually in the client's respective `mcp.json` or settings UI. Ensure the Dart SDK is in the system `PATH`.
```json
"dart": {
  "command": "dart",
  "args": ["mcp-server"]
}
```

## Usage Workflows

Utilize the following sequential workflows to interact with the Dart and Flutter MCP server effectively. Copy the checklists to track progress during complex tasks.

### Workflow: Resolving Runtime Layout Errors
Use this feedback loop when encountering UI overflow or RenderFlex errors.

- [ ] **Step 1: Retrieve Errors.** Execute the tool to fetch current runtime errors from the active application.
- [ ] **Step 2: Inspect Widget Tree.** Access the Flutter widget tree to isolate the node causing the layout constraint violation.
- [ ] **Step 3: Apply Fix.** Modify the Dart code to correct the constraint (e.g., wrapping in `Expanded`, `Flexible`, or adjusting `SizedBox` dimensions).
- [ ] **Step 4: Verify.** Trigger a hot reload and re-run the runtime error check.
- [ ] **Step 5: Feedback Loop.** If errors persist, return to Step 2. Otherwise, conclude the task.

### Workflow: Implementing New Package Functionality
Use this workflow when a feature requires an external dependency.

- [ ] **Step 1: Search.** Execute the `pub_dev_search` tool with specific keywords (e.g., "line chart").
- [ ] **Step 2: Evaluate.** Review the search results for high popularity and compatibility.
- [ ] **Step 3: Install.** Use the dependency management tool to add the selected package to `pubspec.yaml`.
- [ ] **Step 4: Implement.** Generate the required boilerplate and integrate the package into the target widget.
- [ ] **Step 5: Validate.** Run static analysis to ensure no syntax errors were introduced.

## Examples

### Example: Prompting for Layout Fixes
When acting on user requests to fix UI issues, translate vague requests into targeted tool executions.

**User Input:**
> "The app has yellow and black stripes on the settings screen."

**Agent Action Sequence:**
1. Execute `get_runtime_errors` to capture the exact RenderFlex exception.
2. Execute code analysis on `settings_screen.dart`.
3. Apply the fix and trigger `hot_reload`.

### Example: Prompting for Package Integration
**User Input:**
> "Find a suitable package to add a line chart that maps the number of button presses over time."

**Agent Action Sequence:**
1. Execute `pub_dev_search` with query `"chart"`.
2. Identify `fl_chart` as the optimal candidate.
3. Add `fl_chart` to dependencies.
4. Write the implementation code using `LineChart` from the package.
