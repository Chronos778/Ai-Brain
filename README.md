# AI Brain

Your personal, global AI knowledge base. Every project you open in VS Code automatically loads your coding style, preferences, and current context — no setup needed per project.

## How It Works

```
You open any project in VS Code
        ↓
VS Code global settings point to brain files
        ↓
Copilot reads your identity, style, preferences, and active context
        ↓
Every response already knows how you code. Zero effort.
```

The wiring lives in your VS Code **user settings** (`%APPDATA%\Code\User\settings.json`):
```json
"github.copilot.chat.codeGeneration.instructions": [
    { "file": "C:/Users/Maithil/AI-Brain/identity/profile.md" },
    { "file": "C:/Users/Maithil/AI-Brain/identity/style.md" },
    { "file": "C:/Users/Maithil/AI-Brain/identity/preferences.md" },
    { "file": "C:/Users/Maithil/AI-Brain/memory/active-context.md" }
]
```

These are **live file pointers** — update the brain, and every project sees the changes on the next prompt.

---

## Folder Structure

```
AI-Brain/
├── identity/          ← WHO YOU ARE (edit these to refine your AI experience)
│   ├── profile.md         Your name, OS, editors, general work approach
│   ├── preferences.md     Editor prefs, workflow habits, pet peeves
│   └── style.md           Naming conventions, formatting, commit style, patterns
│
├── skills/            ← WHAT YOU KNOW (grows over time)
│   ├── _index.md          Auto-updated registry of all detected tech
│   └── <tech>.md          One file per tech (react.md, python.md, etc.)
│
├── memory/            ← WHAT YOU'RE DOING (auto-updated by brain-sync)
│   ├── active-projects.json   Machine-readable project data
│   ├── active-context.md      AI-readable summary (auto-generated)
│   ├── decisions.md           Your architectural decisions log
│   └── learnings.md           Cross-project insights
│
├── scripts/
│   └── brain-sync.ps1    The sync script
│
├── logs/              ← Sync logs (git-ignored)
└── .gitignore
```

---

## Commands

### `brain-sync`
Scans your projects folder, updates memory, commits, and pushes to GitHub.

```powershell
brain-sync              # Full sync + git push
brain-sync -NoPush      # Sync without pushing
```

**What it does:**
1. Recursively finds every git repo inside `C:\Users\Maithil\Projects`
2. Detects tech stack (package.json, requirements.txt, Cargo.toml, etc.)
3. Identifies active projects (committed to in last 14 days)
4. Reports any folders with no git repo found
5. Rebuilds `memory/active-projects.json` and `memory/active-context.md`
6. Updates `skills/_index.md` with newly detected tech
7. Commits and pushes to GitHub

The `brain-sync` command works from any directory — it's aliased in your PowerShell profile.

---

## How to Use Each Part

### Identity (edit manually)
These files define how AI interacts with you. Edit them anytime:
- **profile.md** — Update if your setup or workflow changes
- **preferences.md** — Add pet peeves, tool preferences, things AI should/shouldn't do
- **style.md** — Refine your naming conventions, patterns, project structure rules

### Skills (add as needed)
When brain-sync detects new tech in your projects, it flags it in `skills/_index.md`. To document your patterns for a tech:

1. Create `skills/<tech>.md` (e.g., `skills/react.md`)
2. Write your preferred patterns, anti-patterns, libraries, conventions
3. Run `brain-sync` to update the index

Skill files are not auto-loaded by Copilot (that would be too much context). They're a reference for you and can be manually added to specific projects if needed.

### Memory (mostly automatic)
- **active-context.md** — Auto-generated every sync. Don't edit manually.
- **decisions.md** — Append your decisions here. Format:
  ```markdown
  ### 2026-03-08 | project-name | What you decided
  **Context**: Why this came up.
  **Decision**: What you chose and why.
  ```
- **learnings.md** — Append insights. Format:
  ```markdown
  ### 2026-03-08 | Topic
  What you learned and why it matters.
  ```

You can also tell Copilot: *"add this decision to my brain"* or *"save this as a learning"* and it'll know what you mean.

---

## GitHub Setup

This brain is designed to live in a private GitHub repo so it's backed up and accessible:

```powershell
cd C:\Users\Maithil\AI-Brain
git remote add origin https://github.com/YOUR_USERNAME/ai-brain.git
git branch -M main
git push -u origin main
```

After this, `brain-sync` auto-pushes on every run.

---

## Customization

### Change projects folder
Edit `$ProjectsRoot` in `scripts/brain-sync.ps1`

### Change active window
Default is 14 days. Override with:
```powershell
brain-sync -ActiveDays 30
```

### Add more tech detection
Edit the `$markers` and `$jsFrameworks` hashtables in `brain-sync.ps1`

---

## Tips
- Run `brain-sync` after a productive day to capture what you worked on
- Update `identity/style.md` when you notice AI making style choices you don't like
- Keep `decisions.md` updated — future-you will thank past-you
- Skill files are optional but powerful for tech you use daily
