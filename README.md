# benops-rpa-skills

Claude Code skills for the BenOps RPA team at Gusto.

## Structure

Each skill lives in its own subfolder. The folder name is the skill name.

```
benops-rpa-skills/
├── benops-rpa-setup/
│   └── SKILL.md          # VDI setup for new team members
└── <future-skill>/
    └── SKILL.md
```

## Installing a skill

Run the two commands below in the VDI terminal, replacing `<skill-name>` with the folder name:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\skills\<skill-name>"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Gusto-Dio/benops-rpa-skills/main/<skill-name>/SKILL.md" -OutFile "$env:USERPROFILE\.claude\skills\<skill-name>\SKILL.md"
```

Then open Claude Code and type `/<skill-name>` to invoke it.

## Available skills

| Skill | Description | Invoke |
|---|---|---|
| `benops-rpa-setup` | Interactive VDI setup for new BenOps RPA team members — installs tools, plugins, and configures MCPs | `/benops-rpa-setup` |

## Adding a new skill

1. Create a subfolder with the skill name: `my-new-skill/`
2. Add a `SKILL.md` file following the [agentskills.io spec](https://agentskills.io/specification)
3. Add a row to the table above
