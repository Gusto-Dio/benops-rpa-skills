# Changelog

All notable changes to this plugin are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning: PATCH for bug fixes, MINOR for new skills, MAJOR for breaking changes.

## [1.1.0] — 2026-05-21

### Added
- `plugin.json` with MCP dependencies declared per skill (`required` flag)
- `allowed-tools` declarations in all skill frontmatter — restricts each skill to its intended tool surface
- `requires_mcp` declarations in all skills that use external MCPs
- `sdlc_phases` tags for lifecycle categorization (`test`, `operate`)
- `references/` directory for `benops-ticket-investigation` with extracted procedure docs:
  - `references/orchestrator-log-queries.md` — REST API query sequence, tenant IDs, error pattern table
  - `references/investigation-rules.md` — red flags and common mistakes
- `Config` section in `morning` and `followup` skills — all user-specific IDs now clearly documented and overridable
- Plugin-level `README.md` and `CHANGELOG.md`

### Changed
- `benops-ticket-investigation/SKILL.md` condensed from ~200 to ~80 lines — detailed procedures moved to `references/`
- `followup/SKILL.md` — "Key identifiers" section replaced with structured `Config` table
- Repo restructured: all skills moved from flat root into `plugins/benops-rpa/skills/`

## [1.0.0] — 2026-05-21

### Added
- Initial release with 8 skills: `analyze`, `benops-rpa-setup`, `benops-sync`, `benops-ticket-investigation`, `benops-triage-agent`, `followup`, `morning`, `uipath-test-cases-from-ticket`
