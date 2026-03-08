# AI Brain

A global knowledge base that makes every AI interaction aware of how I think, what I know, and what I'm building. Opens in any VS Code project — zero per-project setup.

## Architecture

```
AI-Brain/
├── identity/              ← Who I am as a builder
│   ├── profile.md             Background, stack, environment
│   ├── preferences.md         How AI should work with me
│   └── style.md               Code decisions, not formatting rules
│
├── skills/                ← Expert-level patterns per technology
│   ├── _index.md              Quick reference across all skills
│   ├── react.md               ┐
│   ├── typescript.md          │
│   ├── next-js.md             │  Each file: How I Build,
│   ├── tailwind-css.md        │  Expert Decisions,
│   ├── three-js.md            │  Mistakes That Cost Hours
│   ├── node-js.md             │
│   ├── express.md             │
│   ├── python.md              │
│   ├── firebase.md            │
│   ├── vite.md                │
│   ├── bun.md                 │
│   └── frontend-design.md    ┘
│
├── memory/                ← Current context + accumulated knowledge
│   ├── active-context.md      What changed since last sync (auto-generated)
│   ├── active-projects.json   Machine-readable project state
│   ├── decisions.md           Architecture choices with reasoning
│   └── learnings.md           Hard-won insights worth remembering
│
├── scripts/
│   ├── brain-sync.ps1         Scan projects, update memory, push
│   └── brain-learn.ps1        Record learnings and decisions
│
└── logs/                  ← Sync history (git-ignored)
```

## How It Works

VS Code global settings point to brain files as live pointers:

```json
"github.copilot.chat.codeGeneration.instructions": [
    { "file": "C:/Users/Maithil/AI-Brain/identity/profile.md" },
    { "file": "C:/Users/Maithil/AI-Brain/identity/style.md" },
    { "file": "C:/Users/Maithil/AI-Brain/identity/preferences.md" },
    { "file": "C:/Users/Maithil/AI-Brain/memory/active-context.md" }
]
```

Update the brain → every project sees the changes on next prompt.

## Commands

### `brain-sync`

Scans `C:\Users\Maithil\Projects`, detects tech stacks, updates memory, commits and pushes.

```powershell
brain-sync              # Full sync + push
brain-sync -NoPush      # Sync without pushing
```

What happens:
1. Finds every git repo in Projects folder
2. Detects tech from package.json, requirements.txt, Cargo.toml, etc.
3. Builds `active-context.md` with meaningful change summary — not git log dumps
4. Creates minimal skill stubs for newly detected tech
5. Syncs VS Code settings to point at brain files
6. Commits with descriptive message and pushes

### `brain-learn`

Records learnings and decisions, connected to relevant skills.

```powershell
brain-learn react "useFrame allocates every frame — pre-allocate with useMemo"
brain-learn --decide myproject "Switched from REST to tRPC for type safety"
brain-learn --list              # View all learnings
brain-learn --recent            # Last 10 entries
```

Learnings are auto-categorized by scanning for skill keywords and tagged accordingly.

## Design Principles

**Every file earns its place.** No filler, no textbook content, no auto-generated walls of text.

- Identity files are personality, not rulebooks
- Skill files capture expert decisions, not documentation
- Memory captures real context and reasoning, not timestamps
- Scripts produce signal, not noise

## Customization

| Setting | Location |
|---------|----------|
| Projects folder | `$ProjectsRoot` in brain-sync.ps1 |
| Active window | `brain-sync -ActiveDays 30` |
| Tech detection | `$markers` / `$jsFrameworks` in brain-sync.ps1 |
| Skill keywords | `$SkillKeywords` in brain-learn.ps1 |
