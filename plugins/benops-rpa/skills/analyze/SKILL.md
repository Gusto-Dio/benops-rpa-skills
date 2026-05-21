---
name: analyze
description: Review current branch changes for XAML issues, naming conventions, selector quality, and uncommitted modifications. Run before any PR.
sdlc_phases: [test]
allowed-tools: [Bash(git *), PowerShell, Read, Grep, Glob]
---

# /analyze — Review Current Branch Changes

No arguments needed. Analyzes everything changed on the current branch vs develop. Respond in Portuguese.

---

## Execution Plan

### STEP 1 — Read branch state

```powershell
# Current branch
git -C "C:\Users\diogenesribei_gsto\Documents\Projects\biztech-uipath-rpa" branch --show-current

# Files changed vs develop
git -C "C:\Users\diogenesribei_gsto\Documents\Projects\biztech-uipath-rpa" diff develop..HEAD --name-only

# Full diff of changed files
git -C "C:\Users\diogenesribei_gsto\Documents\Projects\biztech-uipath-rpa" diff develop..HEAD
```

### STEP 2 — For each changed XAML file, run these checks

#### Check A — Activity types (CRITICAL)
For every `ui:SomeActivity` tag found in the diff additions (`+` lines), verify that activity type already exists in the project:

```powershell
Select-String -Path "C:\Users\diogenesribei_gsto\Documents\Projects\biztech-uipath-rpa\**\*.xaml" -Pattern "ui:ActivityName" -Recurse
```

If an activity type appears in the diff but NOT elsewhere in the project → **flag as HIGH risk**.

#### Check B — Library files (CRITICAL)
If any changed file path contains `Libraries/` → **flag as CRITICAL**: changes to shared libraries affect all processes.

#### Check C — Selector quality
In changed XAML files, look for selectors (strings inside `selectorValue=` or similar). Flag selectors that:
- Use `idx=` attributes (fragile, position-based)
- Use `parentid=` with long generated IDs
- Have no `aria-role`, `name`, or semantic attributes

Prefer: `aria-role`, `aaname`, `name`, `automationid`.

#### Check D — Naming conventions
Check arguments and variables in changed XAML:
- Arguments must follow: `in_Name`, `out_Name`, `io_Name` (PascalCase with prefix)
- Variables must be camelCase
- Flag anything that deviates

#### Check E — Uncommitted changes
```powershell
git -C "C:\Users\diogenesribei_gsto\Documents\Projects\biztech-uipath-rpa" status --short
```
Flag any modified files that are NOT staged (might be forgotten).

---

## Output Format

```
## Análise do branch [branch-name]

**Arquivos alterados:** [N] | **Commits:** [N]

### 🔴 Crítico
[Issues that could break the build or affect other processes — must fix before PR]

### 🟡 Atenção
[Issues that should be reviewed — selectors frágeis, naming, etc.]

### 🟢 OK
[What looks good — activity types verified, no Library edits, etc.]

### 📋 Checklist antes do PR
- [ ] Todas as atividades novas verificadas no projeto
- [ ] Nenhum arquivo de Library alterado
- [ ] Transações testadas no Orchestrator
- [ ] IDs de transação prontos para o PR body
```

If no issues are found in a category, say "Nenhum problema encontrado" in one line — do not omit the category.
