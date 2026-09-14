# Claude Account Switcher

A macOS menu bar app that lets you switch quickly between two
[Claude Code](https://claude.com/claude-code) accounts (e.g. personal and work)
without repeating the full login flow — including the email verification code —
every time.

## How it works

1. For each account, you run `claude setup-token` once (going through the normal
   login flow, including the email code if your organization requires it). This
   generates a long-lived OAuth token — the official Claude Code mechanism for
   authenticating without an interactive login (originally intended for CI/CD).
2. You paste that token into the app, which stores it in the macOS Keychain using
   `Security.framework` directly (never as a plaintext file or a process argument).
3. When you pick an account from the menu, the app opens a new Terminal window with
   `CLAUDE_CODE_OAUTH_TOKEN` set for that account and launches `claude` — no browser,
   no verification code.

The token travels from the Keychain to Terminal through a FIFO (named pipe): it is
never written to disk. A non-blocking write `open()` on the FIFO only succeeds once a
reader is already waiting (Terminal, via `cat`), so the bytes flow straight through a
kernel pipe between the two processes.

This mechanism never touches or interferes with the normal `claude login` flow — it's
a parallel, non-destructive path.

## Requirements

- macOS 13+
- Swift 5.9+ (Xcode Command Line Tools)
- A Claude subscription (Pro/Max/Team) for each account you want to link

## Build

```bash
./build.sh
open ".build/Claude Account Switcher.app"
```

## Stack

SwiftUI (`MenuBarExtra`), Security.framework, AppleScript (to open Terminal.app).
No external dependencies.
