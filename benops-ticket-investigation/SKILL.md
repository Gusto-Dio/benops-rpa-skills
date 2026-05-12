---
name: benops-ticket-investigation
description: Use when a BenOps RPA process is failing in Production and a bug ticket needs investigation — before reading any XAML code or proposing a fix
---

# BenOps Ticket Investigation

## Overview

Structured investigation workflow for BenOps RPA production failures. The core principle: **Orchestrator logs are ground truth — code analysis without logs first produces wrong root causes.** The baseline failure mode is jumping straight to XAML and guessing.

## The Iron Rule

**Pull Orchestrator production logs BEFORE reading any process code.**

Code analysis without logs = guessing. The baseline proof: an agent that skipped logs identified a wrong root cause (SSN selector) when the actual failures were a missing XAML file and an unhandled SSO popup — two things only visible in the runtime logs.

## Investigation Order (Non-Negotiable)

### Phase 1 — Orchestrator Production Logs

Switch to Production tenant, then:

```powershell
# 1. Get auth token
cat ~/.uipath/.auth

# 2. List recent failed jobs for the process
# GET .../odata/Jobs?$filter=ReleaseName eq '<ProcessName>' and State eq 'Faulted'&$orderby=CreationTime desc&$top=5

# 3. Get the job GUID (NOT just the integer ID)
# GET .../odata/Jobs(<id>)  →  extract field "Key" (GUID format)

# 4. Query robot logs using the GUID
# GET .../odata/RobotLogs?$filter=JobKey eq guid'<GUID>'&$orderby=TimeStamp asc
```

**Pull these yourself using the REST API — do NOT ask the user to provide logs.** Auth token is at `~/.uipath/.auth`. If expired, run `uip login` first.

**Extract verbatim error messages.** These drive everything else.

Common error patterns and what they mean:

| Error pattern | Root cause area |
|---|---|
| `Could not find file '...\SomeWorkflow.xaml'` | InvokeWorkflowFile referencing non-existent file |
| `Element not found` / timeout | Selector issue, popup blocking UI, page not loaded |
| `Object reference not set` | Variable not initialized, workflow returned without setting output |
| `An ExceptionActivity was thrown` | Explicit Business Rule Exception in workflow |

### Phase 2 — Jira Ticket

Pull the ticket with `/ticket BT-XXXXX` or via Jira MCP:
- Confirm the **exact failure mode** described (matches logs?)
- Check **linked tickets** — related issues often cover part of the same process
- Note **when failures started** — correlates with recent deploys

### Phase 3 — Git History for the Process

```powershell
git log --oneline -- "Processes/.../ProcessName/" | head -20
```

Look for: recent commits, dependency bumps, selector changes. Cross-reference commit dates with when failures started.

### Phase 4 — Recent PRs

Check GitHub PRs merged to `develop` in the last 30–60 days touching the process folder. A dependency bump or selector change is often the regression source.

### Phase 5 — Targeted Code Analysis

**Read ONLY what the logs point to.** If the error says `KillAllProcesses.xaml not found`, read `CloseAllApplications.xaml` — not the entire process. If the error says `Element not found` in `EnterDependentsInformation`, read that file AND `ProcessTransaction.xaml` for popup handling context.

Do NOT read all XAML files. The logs tell you where to look.

### Phase 6 — Fix Proposal

Structure every proposal as:

```markdown
## Root Cause
[Verbatim error from Orchestrator logs]
[File and line where the issue originates]

## Fix
[Specific change — file, activity, selector or missing file to create]

## Risk
[What breaks if fix is wrong; what other workflows touch this code]

## Test Plan
- [ ] Minimum 3 transactions in Staging Orchestrator
- [ ] Transaction IDs documented
- [ ] No Library files modified (process-level fix only)
```

## Red Flags — STOP if you think this

| Thought | Reality |
|---|---|
| "Let me look at the code first to get context" | No. Logs first. Always. |
| "I'll ask the user to paste the Orchestrator logs" | No. Pull them yourself with the REST API. |
| "The code looks fine, must be environmental" | Check logs before concluding anything. |
| "I found one suspicious selector, that must be it" | Verify against actual log error messages. |

## Common Mistakes

| Mistake | Result |
|---|---|
| Read XAML before pulling logs | Wrong root cause — code analysis without runtime context is guessing |
| Use integer job ID instead of GUID for log query | OData filter fails with type mismatch error |
| Fix the first error visible in logs | Often masks a second failure downstream — read full log sequence |
| Conclude from one faulted job | One job may be an outlier — check 3+ recent failures for pattern |
| Skip recent PRs check | Misses dependency bumps that changed selector behavior |

## Orchestrator Tenants — BenOps

| Env | Folder | ID |
|---|---|---|
| Production | Benefits | 46023 |
| Production | CarrierAutomation | 944168 |
| Staging | Benefits | 48382 |
| Staging | CarrierAutomation | 946022 |

Auth token stored at `~/.uipath/.auth` after `uip login`.
