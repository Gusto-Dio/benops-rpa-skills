#!/usr/bin/env bash
# UserPromptSubmit hook — BT ticket field gate.
#
# Fires when a prompt mentions a BizTech support ticket (BT-xxxxx) and injects a reminder that
# the eight reportable fields must be set before other work on that ticket. Points the agent at
# the `ticket-fields` skill, which reads current values first and is cheap if they are filled.
#
# Deliberately NON-BLOCKING — always exits 0. A blocking hook here would wedge every prompt that
# merely quotes a ticket key, including "what did we decide on BT-75245?".
#
# Pure bash + sed + grep on purpose: no jq, no node, no python. jq is not present on a fresh
# BenOps VDI, and a hook that dies on a missing dependency is worse than no hook.
#
# Wired up by hooks/hooks.json. Nothing here is machine-specific.

set -uo pipefail

main() {
  local payload scrubbed keys msg

  payload=$(cat 2>/dev/null || true)
  [ -n "$payload" ] || return 0

  # Drop the fields that legitimately carry filesystem paths before matching. Without this, a
  # repo or transcript path containing "BT-12345" would fire the hook on an unrelated prompt.
  scrubbed=$(
    printf '%s' "$payload" |
      sed -E 's/"(transcript_path|cwd|session_id|permission_mode|hook_event_name)"[[:space:]]*:[[:space:]]*"[^"]*"//g'
  )

  # BT-1234 to BT-1234567. The boundaries stop ABT-12345 and BT-12345678 from matching.
  keys=$(
    printf '%s' "$scrubbed" |
      grep -oE '(^|[^A-Za-z0-9])BT-[0-9]{4,7}([^0-9]|$)' |
      grep -oE 'BT-[0-9]{4,7}' |
      sort -u |
      tr '\n' ' ' |
      sed 's/ $//'
  ) || true
  [ -n "$keys" ] || return 0

  read -r -d '' msg <<EOF || true
BT ticket detected in this prompt: ${keys}

Before pulling Orchestrator logs, reading XAML, proposing a fix, opening a PR, or transitioning
status on this ticket, the eight reportable fields must be set: Priority, Complexity, Process,
Category of Break, Workaround Solutions, Story Points, Sprint, Ticket Type?.

Invoke the 'ticket-fields' skill now. It reads the current values first, so it is cheap and
idempotent if they are already filled. Do not fill these fields from memory of the option lists
- Complexity and Ticket Type? both had their options replaced, and a stale value fails
validation.

If the user explicitly says to skip the fields, say plainly that they are being skipped and
continue.
EOF

  # UserPromptSubmit: stdout is appended to the model's context. Plain text, no JSON envelope,
  # so there is nothing to escape.
  printf '%s\n' "$msg"
}

main || true
exit 0
