# CLAUDE.md

Guidelines and reference for Claude Code working in this repository.

## Repository Overview

This repository is a workspace for authoring, maintaining, and synchronizing custom agent skills for **Claude Code** and **Google Antigravity**.

```
.
├── skills/                     # Local custom skills
│   ├── audit-skill/            # Auditor and creation guide for agent skills
│   │   ├── SKILL.md            # Skill instructions & frontmatter
│   │   └── references/
│   │       └── ANTHROPIC-STANDARDS.md # Anthropic standards & 5-axis rubric
│   ├── crisply-en/             # High-fidelity text refiner for English study materials
│   │   ├── SKILL.md            # Skill instructions & frontmatter
│   │   └── references/
│   │       └── AI-PATTERNS.md  # Banned AI vocabulary and replacement matrix
│   └── crisply-pt/             # High-fidelity text refiner for Portuguese study materials
│       ├── SKILL.md            # Skill instructions & frontmatter
│       └── references/
│           └── PADROES-IA.md   # Portuguese AI clichés, queísmo, and cartorial patterns
├── import-skills.ps1           # PowerShell synchronization script (Windows)
│                               # Targets: ~/.claude/skills and ~/.gemini/config/skills
├── import-skills.sh            # Bash synchronization script (macOS/Linux)
├── CLAUDE.md                   # Agent reference
└── README.md                   # Human workspace documentation
```

---

## Synchronization Commands

The sync scripts deploy all workspace skills (`./skills/*`) to the user's global discovery directories using SHA256 content fingerprinting and clean folder replacement.

### PowerShell (Windows)

```powershell
# Sync to both Claude Code and Antigravity (default)
.\import-skills.ps1

# Sync only to Claude Code (~/.claude/skills)
.\import-skills.ps1 -ClaudeOnly
# or
.\import-skills.ps1 -Target Claude

# Sync only to Antigravity (~/.gemini/config/skills)
.\import-skills.ps1 -AntigravityOnly
# or
.\import-skills.ps1 -Target Antigravity

# Force re-copying of all skills even if unchanged
.\import-skills.ps1 -Force
```

### Bash (macOS & Linux)

```bash
# Sync to both Claude Code and Antigravity (default)
./import-skills.sh

# Sync only to Claude Code
./import-skills.sh --claude-only

# Sync only to Antigravity
./import-skills.sh --antigravity-only

# Force re-copying
./import-skills.sh --force
```

---

## Global Discovery Paths

- **Claude Code**: `~/.claude/skills/<skill-name>/`
- **Google Antigravity**: `~/.gemini/config/skills/<skill-name>/`

---

## Skill Authoring Guidelines

When creating or modifying skills in this repository:

1. **Location**: Place each skill in `skills/<skill-name>/` with a lowercase kebab-case folder name.
2. **YAML Frontmatter (`SKILL.md`)**:
   - `name`: Matches folder name exactly.
   - `description`: Front-load key triggers. Include a clear *"Use when..."* clause so Claude Code's progressive disclosure dynamically triggers the skill at the right moment.
   - `argument-hint`: Optional hint displayed during slash command autocompletion (e.g. `"[file path or text]"`).
3. **Arguments Handling**:
   - Support slash command invocations (`/skill-name [arg]`) by handling `$ARGUMENTS` in the instructions:
     - Check if `$ARGUMENTS` is a file path, raw text, or empty.
4. **Progressive Disclosure**:
   - Keep `SKILL.md` lean: core steps, constraints, and completion criteria (< 500 lines soft cap).
   - Offload large tables, banned phrase matrices, or domain references to the `references/` subfolder (e.g. `references/AI-PATTERNS.md`, `references/PADROES-IA.md`, `references/ANTHROPIC-STANDARDS.md`) and point to them from `SKILL.md`.
5. **Portability**:
   - Write standard Markdown and YAML frontmatter compatible with both Claude Code and Antigravity. Do not include agent-specific proprietary manifests (e.g., `openai.yml`).
