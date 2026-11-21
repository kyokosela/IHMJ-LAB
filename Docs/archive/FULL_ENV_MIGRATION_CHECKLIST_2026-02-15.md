# Full Environment Migration Checklist (IMHJ + AI Workflow)

Use this to resume on a stronger PC with the same project + assistant workflow context.

## 1) Project Snapshot To New GitHub Repo

1. Create a new **private empty repository** on GitHub.
2. From `C:\Dev\Projects\IMHJ`, run:

```bash
git checkout -b ai-effects-migration-2026-02-15
git remote add personal <YOUR_NEW_REPO_URL>
git add -A
git commit -m "snapshot: IMHJ effects/mail/insomnia migration"
git push -u personal ai-effects-migration-2026-02-15
```

3. On new PC:

```bash
git clone <YOUR_NEW_REPO_URL>
cd IMHJ
git checkout ai-effects-migration-2026-02-15
```

## 2) AI Assistant Workflow Files To Copy

Copy this folder exactly (contains instructions, skills, workflow docs):

- `C:\Users\Ramirex\.config\opencode`

Important items inside:

- `C:\Users\Ramirex\.config\opencode\instructions\`
- `C:\Users\Ramirex\.config\opencode\skills\`
- `C:\Users\Ramirex\.config\opencode\CODEX_OPUS_WORKFLOW.md`

## 3) Session Context Files In Project

Keep these in the repo root for quick resume:

- `AI_MIGRATION_CONTEXT_2026-02-15.md`
- `FULL_ENV_MIGRATION_CHECKLIST_2026-02-15.md`

## 4) Godot/Tooling Resume

On new PC:

1. Install same Godot version used here.
2. Open project and allow reimport/cache rebuild.
3. Verify autoloads and plugins are enabled as expected.

## 5) Quick Sanity Verification After Moving

1. Open project in Godot and load playground/integration scene.
2. Verify Mail app opens with larger window and list inbox behavior.
3. Verify effects show icons in player UI.
4. Verify insomnia resource loads and levels are visible.

## 6) Optional Local Backup (Before Push)

Create a full zip backup of current working tree before migration:

```powershell
Compress-Archive -Path "C:\Dev\Projects\IMHJ\*" -DestinationPath "C:\Dev\Projects\IMHJ_migration_backup_2026-02-15.zip" -Force
```
