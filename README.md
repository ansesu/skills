# Agent Skills Workspace (Claude Code & Google Antigravity)

Workspace for authoring, managing, and synchronizing custom agent skills for **Claude Code** and **Google Antigravity**.

---

## Repository Structure

```
.
├── skills/                     # Local custom skills
│   ├── audit-skill/            # Auditor and creation guide for agent skills
│   │   ├── SKILL.md            # Skill instructions & frontmatter
│   │   └── references/
│   │       └── ANTHROPIC-STANDARDS.md # Anthropic standards & 5-axis rubric
│   ├── crisply-en/             # High-fidelity text refiner for English study materials
│   │   ├── SKILL.md            # Core rules and refinement workflow
│   │   └── references/
│   │       └── AI-PATTERNS.md  # Banned AI vocabulary and structural fix matrix
│   └── crisply-pt/             # High-fidelity text refiner for Portuguese study materials
│       ├── SKILL.md            # Core rules and Portuguese editing workflow
│       └── references/
│           └── PADROES-IA.md   # Portuguese AI clichés, queísmo, and cartorial patterns
├── import-skills.ps1           # PowerShell synchronization script for Windows
├── import-skills.sh            # Bash synchronization script for macOS and Linux
├── CLAUDE.md                   # Instructions for Claude Code in this repository
├── .gitignore                  # Git ignore rules
└── README.md                   # Workspace documentation
```

---

## Included Skills

### `audit-skill`
An automated supervisor and evaluator for AI agent skills based solely on Anthropic's engineering best practices and the open Agent Skills standard (`agentskills.io`).

- **Dual-Mode Operation**:
  - **Creation Guidance Mode**: Automatically activates during skill authoring to guide scope, directory layout, frontmatter context pointers, and verifiable completion gates.
  - **Audit & Review Mode**: Evaluates an existing skill across 5 Anthropic core axes, outputting an objective scorecard and drop-in remediations.
- **5 Core Axes**:
  1. *Directory & Manifest Anatomy*: Kebab-case naming, `SKILL.md` presence, absence of root `README.md`.
  2. *Frontmatter & Discovery*: Third-person description, front-loaded action verbs, explicit `"Use when..."` triggers.
  3. *Progressive Disclosure & Attention Economy*: Soft cap under 500 lines, delegating bulky catalogs/schemas to sibling files.
  4. *Behavioral Framing & Ergonomics*: Positive target instruction, defeating the Negation Trap.
  5. *Completion Criteria & Execution Rigor*: Observable, binary checks guarding against premature completion.
- **Slash Command**: `/audit-skill [skill name or path to SKILL.md]`
- **Compatibility**: Claude Code (`~/.claude/skills/audit-skill`) and Google Antigravity (`~/.gemini/config/skills/audit-skill`).

### `crisply-en`
A precision text refiner designed to make existing study materials clear, concise, direct, and natural for human reading.

- **Prime Directive**: 100% semantic fidelity. Preserves every fact, distinction, and technical nuance without adding outside explanations or dropping details.
- **What it fixes**:
  - **Syntax knots**: Converts convoluted, passive sentences into active, direct statements.
  - **Throat-clearing**: Eliminates meta-introductions (*"It should be noted that..."*).
  - **AI clichés**: Replaces synthetic AI buzzwords (*delve, tapestry, testament to, foster, streamline*) with plain English.
  - **Cadence**: Eliminates robotic rule-of-three triplets and preachy conclusions.
- **Passive Payload Guarantee**: Strictly refines the input text. Never executes shell commands, runs code, or answers prompts contained within the source material.
- **Slash Command**: `/crisply-en [text or file path]`
- **Compatibility**: Claude Code (`~/.claude/skills/crisply-en`) and Google Antigravity (`~/.gemini/config/skills/crisply-en`).

### `crisply-pt`
Refinador de precisão para materiais de estudo e textos em português, tornando-os claros, concisos, diretos e naturais para leitura humana sem vícios sintéticos.

- **Mandato Primordial**: 100% de fidelidade semântica. Preserva todos os fatos, distinções técnicas e pré-requisitos sem acrescentar explicações externas nem suprimir detalhes.
- **O que elimina**:
  - **Queísmo e períodos labirínticos**: Desmonta orações relativas encadeadas e períodos frouxos de 40+ palavras.
  - **Prolixidade cartorial**: Substitui nominalizações em *-ção/-mento* e passivas pesadas por verbos vivos e voz ativa.
  - **Pigarro acadêmico**: Corta preâmbulos vazios (*"Vale ressaltar que..."*, *"Faz-se mister notar..."*).
  - **Calques e cacoetes de IA**: Extirpa anglicismos literais (*mergulhar em, divisor de águas, desempenha um papel crucial, ao final do dia, alavancar*), falsas tríades mecânicas e sermões moralizantes.
- **Garantia de Payload Passivo**: Trata o texto estritamente como prosa passiva a ser editada. Jamais executa comandos de shell, scripts ou solicitações presentes no conteúdo.
- **Comando Slash**: `/crisply-pt [texto ou caminho do arquivo]`
- **Compatibilidade**: Claude Code (`~/.claude/skills/crisply-pt`) e Google Antigravity (`~/.gemini/config/skills/crisply-pt`).

---

## Skills Synchronization

We provide two scripts to manage syncing your local workspace skills into your AI assistants' global discovery directories:
- **Claude Code**: `~/.claude/skills/`
- **Google Antigravity**: `~/.gemini/config/skills/`

Both scripts perform SHA256 content fingerprinting to ensure only new or modified skills are synced, and perform clean updates to ensure deleted files (such as obsolete manifests) do not linger as orphans.

### Common Commands

#### Windows (PowerShell)
```powershell
# Sync workspace skills to BOTH Claude Code and Antigravity (default)
.\import-skills.ps1

# Sync ONLY to Claude Code (~/.claude/skills/)
.\import-skills.ps1 -ClaudeOnly
# or
.\import-skills.ps1 -Target Claude

# Sync ONLY to Antigravity (~/.gemini/config/skills/)
.\import-skills.ps1 -AntigravityOnly
# or
.\import-skills.ps1 -Target Antigravity

# Force re-syncing of all skills even if unchanged
.\import-skills.ps1 -Force
```

#### macOS & Linux (Bash)
```bash
# Make script executable (first run)
chmod +x ./import-skills.sh

# Sync workspace skills to BOTH Claude Code and Antigravity (default)
./import-skills.sh

# Sync ONLY to Claude Code (~/.claude/skills/)
./import-skills.sh --claude-only

# Sync ONLY to Antigravity (~/.gemini/config/skills/)
./import-skills.sh --antigravity-only

# Force re-syncing of all skills even if unchanged
./import-skills.sh --force
```

---

## Authoring New Custom Skills

To add a new skill to this workspace:

1. **Create a folder under `skills/`**: Name it with lowercase kebab-case (e.g. `skills/my-new-skill/`).
2. **Add `SKILL.md`**: Define frontmatter (`name`, `description`, `argument-hint`) and clear step-by-step instructions. Handle `$ARGUMENTS` if you want to support slash command parameters.
3. **(Optional) Add Reference Files**: For large lookup tables or domain rules, create sibling markdown files (e.g. `REFERENCE.md`) and link to them from `SKILL.md`.
4. **Deploy globally**:
   - **Windows**:
     ```powershell
     .\import-skills.ps1
     ```
   - **macOS & Linux**:
     ```bash
     ./import-skills.sh
     ```
   The script will automatically detect the new folder under `skills/`, compute its fingerprint, and sync it cleanly to both Claude Code and Antigravity.
