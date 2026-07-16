# me-claude-ide: Emacs Bridge for Claude Code `/ide`

**Date:** 2026-07-16
**Status:** Approved (design)
**Scope:** One Emacs package, read-only selection sensing

## Goal

Run terminal Emacs in one terminal, `claude` CLI in another. `claude` → `/ide`
auto-discovers the Emacs session and auto-injects the current editor selection
into every prompt — same UX as the official VS Code extension.

Non-goal: bidirectional control (open diffs, jump-to-line, save). Claude's edits
are read by the user in Emacs via auto-revert (already enabled in `me-ai.el`).

## Background

`/ide` only ships for VS Code / JetBrains. The protocol is reverse-engineered
(no official spec). Reference impls: Zed (Rust), claudecode.nvim, Magia.
Emacs has no existing implementation.

## Protocol (confirmed against Zed / claudecode.nvim / Magia)

### Lock file
- Path: `~/.claude/ide/<port>.lock` (or `$CLAUDE_CONFIG_DIR/ide/`).
- Dir `0700`, file `0600`.
- JSON:
  ```json
  { "pid": <emacs-pid>, "workspaceFolders": ["<root>"],
    "ideName": "Emacs", "transport": "ws",
    "authToken": "<32-hex>" }
  ```
- `ideName` is free text (Zed uses "Zed", Magia "Magia") — not an enum.
- Deleted on shutdown.

### WebSocket
- `ws://127.0.0.1:<random 10000-65535>`, no TLS.
- Auth header `x-claude-code-ide-authorization` sent on the HTTP upgrade.
- **Decision: skip header verification.** Loopback only, lock file is 0600
  owner-only, so only the user can read the token. Adding a constant-time
  compare buys nothing on a single-user box. (`ponytail:` local trust
  boundary; add header check if this ever runs on a shared host.)

### JSON-RPC 2.0 over WS
- `initialize` / `initialized` — standard MCP handshake; respond with
  `protocolVersion: "2025-03-26"`, `capabilities.tools: {}`, serverInfo.
- `tools/list` — return tool schemas (see below).
- `tools/call` — dispatch on `params.name`.
- Notifications (no `id`): **`selection_changed`** pushed by Emacs on region
  change (debounced 200ms):
  ```json
  { "jsonrpc":"2.0", "method":"selection_changed",
    "params": { "text":"...", "filePath":"/abs/path",
      "fileUrl":"file:///abs/path",
      "selection": { "start":{"line":L,"character":C},
                     "end":{"line":L,"character":C},
                     "isEmpty": false } } }
  ```
- Lines are **0-based** in the protocol; Emacs is 1-based — convert.

## Architecture (single file `modules/extras/me-claude-ide.el`)

1. **Lock file manager** — pick free port, gen token, write JSON, delete on
   shutdown (`kill-emacs-hook`).
2. **WS server** — `websocket.el`; on connect, store conn in a defvar.
3. **JSON-RPC dispatch** — parse, route by method.
4. **Selection tracker** — `post-command-hook` + 200ms debounce; when
   `(region-active-p)` and region changed, send `selection_changed`. Also
   cache "latest selection" for pull.
5. **Read-only tools** (what `tools/list` advertises):
   - `getCurrentSelection` — current region (or empty)
   - `getLatestSelection` — last recorded selection
   - `getOpenEditors` — file-backed buffers as tabs (`uri`,`isActive`,
     `label`,`languageId`,`isDirty`)
   - `getWorkspaceFolders` — `(vc-root-dir)` / project root
   - `getDiagnostics` — flymake diagnostics for the active buffer
6. **Minor mode** `claude-ide-bridge-mode`, wired into `me-ai`, on by default.

## Data flow

```
select in Emacs → post-command-hook (debounced) → selection_changed ──WS──> CLI caches
prompt ─────────────────────────────────────────────────────────────> CLI injects cached selection
CLI may tools/call getCurrentSelection ──WS──> Emacs returns current selection (pull fallback)
```

Push + pull both implemented — the protocol docs don't pin down which the CLI
uses for auto-injection, so cover both.

## Risk / honesty

- **Push-vs-pull unknown:** both implemented; "auto-inject" must be verified by
  an end-to-end test, not assumed.
- **Single vs dual WS connection:** a third-party bridge mentions two; official
  vscode uses one. Start with one; if `/ide` won't connect, this is the first
  thing to check.
- Lock JSON shape, 0-based offset, JSON-RPC framing — these have concrete specs;
  copy them.
- Connection drop: clear conn ref; CLI reconnects and re-initializes.

## Testing

One `ert` self-check (non-trivial logic: offset conversion, lock JSON shape,
JSON-RPC round-trip): start bridge → spawn a WS client from a temp Emacs → send
`tools/list` + `tools/call getCurrentSelection` with a region active → assert
shape. Goes red if the logic breaks.

## Wiring

- `me-ai.el`: replace the `claude-code-ide` (manzaltu) package with
  `me-claude-ide`. Old keybindings under `SPC a` are for a different package —
  either drop them or leave (decide in plan).
- New straight dep: `websocket` (`emacs-websocket/websocket`).
