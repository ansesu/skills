---
name: audit-skill
description: Audit, guide, and review agent skills against Anthropic's official best practices and the open Agent Skills standard. Disambiguation: audits skill manifests and directories, not general application code. Use when creating, authoring, drafting, refactoring, or reviewing any skill or SKILL.md file.
argument-hint: "[skill name or path to SKILL.md]"
---

# audit-skill

Audit, guide, and evaluate AI agent skills using Anthropic's official engineering best practices and the open Agent Skills standard (`agentskills.io`) as the sole reference.

This skill operates in two distinct modes:
1. **Creation Guidance Mode**: Automatically guides the design and authoring of new skills to guarantee compliance from step one.
2. **Audit & Review Mode**: Reviews existing or draft skills, identifies structural or behavioral flaws, scores them across 5 core axes, and delivers drop-in remediations.

---

## Input & Mode Detection

Evaluate `$ARGUMENTS` and the conversation context to determine the active mode:

- **Audit & Review Mode**:
  - Triggered when `$ARGUMENTS` provides a skill name (e.g. `audit-skill crisply-en`) or a file path (e.g. `skills/crisply-en/SKILL.md`), OR when the user asks to review, evaluate, check, or audit an existing skill.
  - Read the specified `SKILL.md` and inspect the skill directory structure, then proceed to [Audit & Review Mode Workflow](#mode-2-audit--review-mode-workflow).
- **Creation Guidance Mode**:
  - Triggered when creating, authoring, drafting, or proposing a new skill (e.g. "let's create a skill named...", "write a skill that...").
  - Proceed to [Creation Guidance Mode Workflow](#mode-1-creation-guidance-mode-workflow).
- **No Input / Ambiguous**:
  - If `$ARGUMENTS` is empty and no skill is actively being created, list available workspace skills in `skills/` and ask the user which skill they want to audit or create.

---

## Anthropic's 5 Core Audit Axes

Every skill is evaluated against these 5 foundational principles derived from Anthropic engineering research (*Building Effective Agents*, Claude Code documentation, and the Agent Skills standard):

| # | Axis | Core Rule | Failure Mode Prevented |
|---|---|---|---|
| **1** | **Directory & Manifest Anatomy** | Lowercase `kebab-case` directory, single `SKILL.md` manifest, omit `README.md`. | Manifest confusion; orphan docs; discovery collision. |
| **2** | **Frontmatter & Discovery** | Third-person `description`, front-loaded action verbs, explicit `"Use when..."` triggers. | Weak context pointers; false activations; discovery failure. |
| **3** | **Progressive Disclosure & Sizing** | `SKILL.md` under 500 lines soft cap. Bulky tables/schemas offloaded to sibling files or `references/`. | Context window saturation; "lost in the middle" attention decay. |
| **4** | **Behavioral Framing & Ergonomics** | Positive instruction framing. State what the agent **must do** rather than what it must not do. | The **Negation Trap** (semantic priming of forbidden actions). |
| **5** | **Completion Criteria & Execution** | Observable, checkable completion bounds. Step-by-step ordered execution with verification. | **Premature completion**; rushing past unverified steps. |

Consult [ANTHROPIC-STANDARDS.md](./references/ANTHROPIC-STANDARDS.md) for the exhaustive evaluation rubric, scoring criteria, and Anthropic rationale.

---

## Mode 1: Creation Guidance Mode Workflow

When creating or drafting a new skill, follow this step-by-step protocol to build a compliant skill:

### Step 1: Establish Single-Purpose Scope
- Ensure the skill addresses exactly one cohesive domain or workflow.
- If the proposed skill attempts to solve multiple disparate tasks, decompose it into focused sibling skills.

### Step 2: Establish Directory Layout
- Target path: `skills/<skill-name>/` using lowercase `kebab-case`.
- Mandatory manifest: `skills/<skill-name>/SKILL.md`.
- Supporting subdirectories (create only if needed):
  - `references/` or sibling `.md` files for domain catalogs, rule matrices, and schemas.
  - `scripts/` for deterministic helper scripts or CLIs.
  - `assets/` for templates and boilerplate documents.
- **Strict Constraint**: Maintain `SKILL.md` as the exclusive root manifest and documentation source; omit `README.md` to prevent discovery collisions.

### Step 3: Craft Frontmatter Context Pointers
- Set `name` to match the directory name exactly.
- Write the `description` following Anthropic discovery standards:
  - Use third-person phrasing: *"Audit, guide, and review..."* (not *"I audit..."* or *"You should audit..."*).
  - Front-load primary verbs and keywords within the first 10 words.
  - Include an explicit `"Use when..."` trigger clause specifying user intent and operational moments.
  - Add `argument-hint` if the skill accepts arguments during slash command invocation.

### Step 4: Author the Instruction Body
- **Length Constraint**: Keep `SKILL.md` under 500 lines. Move large reference tables, banned lists, or schemas to sibling files.
- **Positive Framing**: Express every rule as a positive target behavior. If a negative constraint is necessary, pair it immediately with the required positive replacement.
- **Progressive Disclosure**: Inline only what every run requires; link to sibling files for branch-specific details.
- **Poka-Yoke Tool Design**: Specify atomic operations, absolute paths, and unambiguous parameters.

### Step 5: Define Verifiable Completion Criteria
- End workflows with explicit, observable verification conditions (e.g. files created at specific paths, linters passing, tests succeeding).
- Define deterministic, objective completion checks; replace ambiguous subjective phrases (e.g. *"ensure it looks good"*).

### Step 6: Verify Compliance
- Run the 5-axis self-audit against the drafted skill before saving or deploying.

---

## Mode 2: Audit & Review Mode Workflow

When evaluating an existing skill or reviewing a draft, execute the following audit loop:

### Step 1: Ingest & Inspect
1. Locate and read the target `SKILL.md`.
2. Inspect the enclosing directory for layout compliance (check for disallowed files like `README.md` or proprietary manifests).
3. Measure line count and token weight of `SKILL.md`.

### Step 2: Evaluate Across the 5 Axes
Evaluate the skill against each axis using [ANTHROPIC-STANDARDS.md](./references/ANTHROPIC-STANDARDS.md):
- **Axis 1 (Anatomy)**: Is the folder kebab-case? Is `SKILL.md` present? Is `README.md` absent?
- **Axis 2 (Frontmatter)**: Does `name` match the directory? Is `description` third-person? Are triggers front-loaded? Is `"Use when..."` present and specific?
- **Axis 3 (Progressive Disclosure)**: Is line count < 500? Are deep references properly delegated to sibling files?
- **Axis 4 (Framing & Ergonomics)**: Is the instruction positively framed? Does it avoid the negation trap? Are steps ordered and actionable?
- **Axis 5 (Completion Criteria)**: Are completion criteria clear and observable? Does it guard against premature completion?

### Step 3: Produce the Audit Report
Generate a structured report formatted exactly as follows:

```markdown
# Skill Audit Report: <skill-name>

## Executive Summary
- **Overall Rating**: [PASS | NEEDS IMPROVEMENT | CRITICAL FIX REQUIRED]
- **Target File**: `<path-to-skill>/SKILL.md`
- **Line Count**: `<count>` lines (Threshold: < 500 lines)

## Scorecard by Axis
| # | Axis | Status | Key Observation |
|---|---|---|---|
| 1 | Directory & Manifest Anatomy | [PASS / FAIL] | ... |
| 2 | Frontmatter & Discovery | [PASS / FAIL] | ... |
| 3 | Progressive Disclosure & Sizing | [PASS / FAIL] | ... |
| 4 | Behavioral Framing & Ergonomics | [PASS / FAIL] | ... |
| 5 | Completion Criteria & Execution | [PASS / FAIL] | ... |

## Detailed Findings
### [Axis Name]
- **Issue**: Precise description of the deficiency.
- **Anthropic Rationale**: Why this causes degradation or failure.
- **Recommendation**: Concrete fix.

## Remediation Diff
```yaml / markdown
# Provide the exact drop-in diff or replacement code
```
```

---

## Completion Criteria

The audit or guidance task is complete when:
1. For **Creation Mode**: A fully compliant skill directory and `SKILL.md` are drafted or written, satisfying all 5 Anthropic axes.
2. For **Audit Mode**: A complete 5-axis scorecard, detailed findings citing Anthropic principles, and actionable remediation diffs are presented to the user.
