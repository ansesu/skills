# Anthropic Agent Skills Standards & Evaluation Rubric

This reference document defines the complete evaluation rubric, architectural rationales, and grading standards for AI agent skills based solely on Anthropic's engineering literature (*Building Effective Agents*, Claude Code documentation, and the open Agent Skills standard at `agentskills.io`).

---

## 1. Axis 1: Directory & Manifest Anatomy

### Core Standards
- **Folder Naming**: Must be lowercase `kebab-case` (e.g., `audit-skill`, `code-review`, `database-migrate`). No spaces, underscores, or uppercase characters.
- **Manifest File**: Must contain a single required manifest named `SKILL.md` directly at the skill root.
- **No `README.md` Policy**: Skill folders must **never** contain a `README.md`. 
  - *Rationale*: Human documentation must be integrated directly into `SKILL.md` or secondary reference files. Multiple markdown files at the root level cause discovery confusion and dilute agent attention when exploring directory trees.
- **Modular Subdirectories**:
  - `references/`: For large domain models, syntax catalogs, standards, or API references (keeps the root clean with `SKILL.md` as the single manifest entry point).
  - `scripts/`: For executable tools or automation scripts.
  - `assets/`: For static templates, boilerplate files, or schemas.
  - `evals/`: For test scenarios, sample inputs, and evaluation benchmarks.

### Rubric & Grading
- **PASS**: Directory is strictly lowercase `kebab-case`, contains `SKILL.md`, has no `README.md`, and organizes supporting materials into proper subdirectories (such as `references/`).
- **FAIL**: Directory contains `README.md`, uses non-kebab-case naming (e.g. `AuditSkill` or `audit_skill`), or places unstructured helper files at the skill root.

---

## 2. Axis 2: Frontmatter & Discovery Engineering

### Core Standards
- **YAML Frontmatter Delimiters**: Must begin with `---` on line 1 and close with `---`.
- **`name` Field**:
  - Must match the enclosing directory name exactly.
  - Must be lowercase `kebab-case`.
- **`description` Field (The Top-Level Context Pointer)**:
  - *Context Economics*: Only the frontmatter (`name` and `description`) is pre-loaded into the agent's context during discovery (~50–100 tokens). The body is loaded only upon activation.
  - *Third-Person Phrasing*: Write descriptions in the third person (e.g., *"Audit, guide, and review agent skills..."*). Never use first-person (*"I audit..."*) or second-person (*"Use this to audit..."*).
  - *Front-Loaded Action Verbs*: Place decisive capability triggers in the first 10 words.
  - *Explicit Trigger Clause*: Must include a clear `"Use when..."` clause defining user intents, scenarios, and triggers.
  - *Scoping & Negative Boundaries*: When overlapping skills exist, explicitly disambiguate when the skill should *not* fire.
- **`argument-hint` Field**:
  - Optional but strongly recommended for skills that accept arguments via slash commands (e.g., `"[skill-name or path]"`).

### Good vs. Bad Descriptions

```yaml
# ❌ BAD: Vague, first-person, missing trigger clause
---
name: my-auditor
description: I help you check your skills and make sure they look good and follow all the rules.
---

# ✅ GOOD: Third-person, front-loaded, explicit trigger clause, matches folder
---
name: audit-skill
description: Audit, guide, and review agent skills against Anthropic's official best practices and the open Agent Skills standard. Use when creating, authoring, drafting, refactoring, or reviewing any skill or SKILL.md file.
argument-hint: "[skill name or path to SKILL.md]"
---
```

### Rubric & Grading
- **PASS**: `name` matches folder; `description` is third-person, front-loads triggers, contains an unambiguous `"Use when..."` clause, and stays within 150 words.
- **FAIL**: `name` mismatches folder; `description` is first-person, lacks `"Use when..."`, is overly verbose (>200 words), or lacks clear semantic boundaries.

---

## 3. Axis 3: Progressive Disclosure & Attention Sizing

### Core Standards
- **The 500-Line Soft Cap**: The `SKILL.md` manifest should strictly remain under 500 lines.
  - *Rationale*: Large instruction files induce the "lost in the middle" attention failure mode, where LLMs miss nuanced instructions placed midway through extensive documents.
- **3-Tier Information Hierarchy**:
  1. *Tier 1 (In-file Step)*: High-level sequence of actions executed on every run.
  2. *Tier 2 (In-file Reference)*: Core definitions, guardrails, and completion criteria essential to all runs.
  3. *Tier 3 (Disclosed Reference)*: Bulky catalogs, edge-case tables, and deep domain specs pushed to `references/` (e.g. `references/ANTHROPIC-STANDARDS.md`, `references/AI-PATTERNS.md`) and loaded only when relevant branches are reached.
- **Elimination of Duplication & Environmental Truth**:
  - Never cache information the agent can easily look up in the environment (e.g., repeating `package.json` dependencies or CLI `--help` text).
  - Cache only unwritten rules, domain gotchas, and procedural checklists.

### Rubric & Grading
- **PASS**: `SKILL.md` is under 500 lines; complex tables, extensive examples, or schemas are cleanly offloaded to `references/` or secondary docs; progressive disclosure links are unambiguous.
- **FAIL**: `SKILL.md` exceeds 500 lines, inlines massive reference tables that only fire under niche circumstances, or dumps raw environment configs into the prompt.

---

## 4. Axis 4: Behavioral Framing & Ergonomics

### Core Standards
- **Overcoming the Negation Trap**:
  - *Mechanism*: Negative constraints (*"Do NOT use bash"*, *"Never edit file X"*) prime the forbidden concept in the model's active attention window, paradoxically increasing the probability of the prohibited action.
  - *Rule*: State instructions in terms of positive, concrete target behaviors.
  - *Example*: Instead of *"Do not use shell commands to create directories"*, instruct *"Create directories exclusively using native filesystem tools."*
  - *Hard Guardrail Exception*: When a hard prohibition is mandatory (e.g. security boundaries), pair it immediately with the required positive action.
- **Imperative & Actionable Steps**:
  - Numbered, ordered workflows.
  - Concrete actions rather than open-ended advice.
- **Poka-Yoke (Mistake-Proofing) Tool Usage**:
  - Direct the agent to use atomic edits rather than complex diff patching.
  - Require absolute paths or deterministic relative paths to avoid working-directory confusion.
  - Provide clear handling for errors, empty inputs, or missing files.

### Rubric & Grading
- **PASS**: Rules are positively framed; procedural steps are ordered and clear; tool usage minimizes error potential; negations are paired with explicit positive targets.
- **FAIL**: Document is dominated by unguided negative rules (*"Don't do X, never do Y"*); steps are vague or unordered; encourages fragile tool interactions (e.g. blind string replacements or ambiguous git diffs).

---

## 5. Axis 5: Completion Criteria & Execution Rigor

### Core Standards
- **Observable Completion Bounds**:
  - Every workflow must terminate on an objective, verifiable completion criterion (e.g., specific file exists, validation report rendered, tests passing, linter exits cleanly).
  - Subjective criteria (*"Make sure the code is high quality"*) invite **Premature Completion**, where the model declares victory after doing shallow or incomplete work.
- **Defense Against Post-Completion Rush**:
  - In multi-step workflows, subsequent visible steps create a gravitational pull that tempts the model to rush through intermediate verification.
  - Define explicit verification gates at the conclusion of each phase before proceeding to the next.

### Rubric & Grading
- **PASS**: Explicit, observable completion criteria are defined; self-verification or checklist validation is required before declaring completion; avoids fuzzy subjective exit states.
- **FAIL**: Workflow ends without completion criteria or relies entirely on subjective declarations (*"Check that everything looks right and finish"*).
