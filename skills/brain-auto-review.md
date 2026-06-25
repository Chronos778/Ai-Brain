---
name: brain-auto-review
description: Autonomous loop for filling in auto-generated skill stubs
---

# Brain Auto-Review

This is an automated workflow skill. Use it when the user asks you to "run auto review" or "fill in pending skill reviews".

## Workflow Instructions

When invoked, execute the following steps strictly in order:

### 1. Identify Pending Stubs
1. Run `Get-ChildItem -Path C:\Users\Maithil\AI-Brain\skills\review\ -Filter *.md`
2. If there are no files, inform the user that there are no pending reviews and stop.
3. If there are files, pick the first one and proceed. Do this one file at a time.

### 2. Research Context
1. Read the stub file to identify the technology (e.g., `Svelte`, `Django`).
2. The stub will say `> Detected in: [ProjectName]`.
3. Read the `package.json` or equivalent configuration file of that project to see how the technology is being used (e.g., which specific dependencies are installed alongside it).
4. Run a web search or use your internal knowledge to gather expert-level patterns and common anti-patterns for this specific technology stack.

### 3. Draft the Skill
Draft a complete replacement for the stub using the standard AI-Brain skill format. 
You MUST include YAML frontmatter at the top (`name` and `description`).
The markdown must have 3 main sections:
- `## How I Build`: 4-6 bullet points of architecture and library choices.
- `## Expert Decisions`: 3-4 bullet points of non-obvious engineering decisions.
- `## Mistakes That Cost Hours`: 3-4 bullet points of common pitfalls or debugging nightmares specific to this stack.

*CRITICAL*: Write in a confident, builder-centric voice. No fluffy explanations. Focus on hard facts and strict rules.

### 4. Apply the Skill
1. Create a new file in `C:\Users\Maithil\AI-Brain\skills\` using the exact name from the stub (e.g., `svelte.md`).
2. Write the drafted content into this new file using `write_to_file`.
3. Delete the original stub from `skills\review\`.

### 5. Loop or Conclude
If there are more files in `skills\review\`, go back to Step 1.
If the directory is empty, inform the user that all auto-reviews are complete and the AI-Brain has learned the new skills.
