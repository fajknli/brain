# Brain System

Core: 47 lines (`core.awk`) | Total: ~240 lines  
Shebang: `#!/bin/sh` | Pure POSIX, no Bash extensions.

> Awk = Database, Pipeline = Bus, Plaintext = Truth

## Overview

Brain is a personal knowledge management system built exclusively with POSIX shell and Awk. It operates without databases, compilation steps, or external runtime dependencies. The architecture is designed for long-term stability, ensuring compatibility across any POSIX-compliant environment for decades.

## Directory Structure

```text
brain/
├── bin/               # Executable scripts and core logic
├── atoms/             # Source of truth (Markdown notes)
├── inbox/             # Incoming queue for unprocessed items
├── cache/             # Auto-generated, ephemeral indexes
│   ├── meta.tsv       # Note metadata (UID, title, date, type, status, path)
│   ├── links.tsv      # Directed graph of note relationships
│   └── tags.tsv       # Inverted index for tags
└── conflicts.report   # Log of malformed or conflicting records
```

## Installation

```sh
git clone <repository-url> ~/brain
cd ~/brain
chmod +x bin/*
echo 'export PATH="$HOME/brain/bin:$PATH"' >> ~/.profile
source ~/.profile
```

## Command Reference

| Command | Description |
| :--- | :--- |
| `brain` | Launches the FZF-based interactive TUI. |
| `brain-add` | Creates a new note using the current FZF query string. |
| `brain-new` | Generates a blank note template and opens it in `$EDITOR`. |
| `brain-clip` | Reads the system clipboard and saves it as a new note in `inbox/`. |
| `brain-archive` | Updates a note's status to `archived`, hiding it from default queries. |
| `brain-promote` | Safely moves a note from `inbox/` to `atoms/` with UID collision checks. |
| `brain-promote-latest` | Automatically promotes the most recently modified note in `inbox/`. |
| `brain-context <uid>` | Displays inbound and outbound links for a specific note, including target status. |
| `brain-search <kw>` | Performs a full-text search across `atoms/` using AND logic. |
| `brain-tag <tag>` | Retrieves all notes associated with a specific tag. |
| `brain-list` | Outputs a plain-text list of all active notes (UID and title). |
| `brain-index` | Rebuilds all cache indexes atomically from the `atoms/` directory. |
| `brain-copy-link` | Copies a standardized link template (e.g., `+link: <UID> updates`) to the clipboard. |

## Note Specification

Notes must adhere to the following Frontmatter structure:

```markdown
---
uid: U-20260615T012230042
title: Your title
date: 2026-06-15 01:22:30
type: note
status: live
+tag: inbox
+link: U-xxxxxxxxxxx updates
---

Content goes here.
```

**Constraints:**
- `uid`: Must exactly match the filename (excluding the `.md` extension).
- `status`: Must be either `live` or `archived`.
- Malformed files are bypassed by the indexer and logged in `conflicts.report`.

## Design Decisions

### Why POSIX `sh`
Bash-specific features introduce portability risks. The system strictly adheres to POSIX standards to ensure compatibility with `dash`, `busybox`, and legacy Unix environments.
- No `$RANDOM`: Process ID (`$$`) is used as a seed for pseudo-random generation.
- No `$'\t'`: Tab characters are generated via `printf '\t'`.
- No `pipefail`: Error handling relies on `set -e`.
- No unquoted `echo`: All variable output uses `printf '%s\n'` to prevent backslash interpretation.

### Security Posture
The architecture mitigates common shell scripting vulnerabilities by design:
- Command injection is prevented by avoiding dynamic evaluation of user input.
- Here-document injection is avoided in favor of `printf`.
- Quote and escape traps are neutralized through strict variable handling.
- UID overwrites are blocked by explicit collision checks during promotion.
- Index deadlocks are prevented by using atomic `mv` operations on temporary files.

## Non-Negotiable Constraints

The following behaviors are intentional design choices and will not be altered:
1. **Search Logic**: `brain-search` uses AND logic, not OR.
2. **Data Sanitization**: Tabs in titles are automatically converted to spaces.
3. **Interface**: The system is strictly CLI/TUI based. No GUI or mobile applications are planned or supported.
4. **File Mutability**: The indexer reads source files but never modifies them. State changes (like archiving) are handled by dedicated, auditable scripts.

## Execution

```sh
brain
```

Awk. Shell. Filesystem.  
That is all that is required.
