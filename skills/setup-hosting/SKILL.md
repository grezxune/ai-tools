---
name: setup-hosting
description: Create the GitHub repo, the Vercel project, and its environment variables, then deploy to production.
disable-model-invocation: true
---

# Setup Hosting

Automate the full hosting pipeline: Git init, GitHub repo creation, Vercel project setup, environment variable configuration, and production deployment.

## Prerequisites

Before starting, verify all required CLI tools are authenticated:

```bash
# Check GitHub CLI
gh auth status

# Check Vercel CLI
vercel whoami

# Check git config
git config user.name && git config user.email
```

If any tool is missing or not authenticated:
- **gh not found:** Ask user to install (`brew install gh`) and authenticate (`gh auth login`)
- **vercel not found:** Install with `bun add -g vercel`, then `vercel login`
- **git not configured:** Ask user for name/email

## Workflow

Execute these steps in order. **Ask the user to confirm before each major phase** (Git, GitHub, Vercel, Deploy).

---

### Phase 1: Gather Information

Ask the user for:

1. **Repository name** — suggest based on current directory name (kebab-case)
2. **Visibility** — public or private (default: private)
3. **Vercel team/scope** — if they have multiple Vercel teams (check with `vercel teams ls`)
4. **Custom domain** — optional, if they want to add one after deployment

Check for existing state:
```bash
# Is this already a git repo?
git rev-parse --is-inside-work-tree 2>/dev/null

# Does it already have a remote?
git remote -v

# Is it already linked to Vercel?
ls .vercel/project.json 2>/dev/null
```

Skip any steps that are already complete. Tell the user what you're skipping and why.

---

### Phase 2: Git Setup

```bash
# Only if not already a git repo
git init

# Check for a .gitignore — CRITICAL: never commit node_modules, .env files, etc.
# If missing, warn the user and offer to create one
```

**Commit strategy:**
- If there are no commits yet, create an initial commit with all files
- If there are existing commits, only commit uncommitted changes
- Use descriptive commit messages, not "initial commit" for projects with real code
- Stage specific files — avoid `git add -A` to prevent accidentally committing secrets

**Secret file check — CRITICAL:**
Before any commit, verify these are in `.gitignore`:
```
.env
.env.local
.env.prod
.env.production
.env*.local
```

If `.env` files exist but `.gitignore` is missing entries, **stop and warn the user** before committing.

---

### Phase 3: GitHub Repo Creation

```bash
# Create the repo (--private is default, --public if requested)
gh repo create <repo-name> --private --source=. --remote=origin --push
```

**Key flags:**
- `--source=.` — use the current directory
- `--remote=origin` — sets the remote name
- `--push` — pushes after creating

**If the repo already exists** on GitHub, just add the remote and push:
```bash
git remote add origin git@github.com:<owner>/<repo>.git
git push -u origin main
```

**If the branch is `master` not `main`:**
```bash
git branch -M main
```

---

### Phase 4: Vercel Project Setup

```bash
# Link to Vercel (interactive — will ask to confirm settings)
vercel link
```

**During `vercel link`:**
- It will ask to link to an existing project or create new — choose **Create New**
- Project name should match the repo name
- It auto-detects the framework (Next.js, etc.)

**If already linked** (`.vercel/project.json` exists), skip this step.

---

### Phase 5: Environment Variables

This is the most error-prone step. Follow carefully.

**Discovery — find all env vars the project needs:**

```bash
# Check for .env example files
ls .env.example .env.local.example .env.sample 2>/dev/null

# Check for .env.prod or .env.production (production values)
ls .env.prod .env.production 2>/dev/null

# Scan code for env var references
grep -r "process.env\." --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" -oh | sort -u
```

**Ask the user which env file contains production values.** If `.env.prod` exists, confirm they want to use those values.

**Pushing env vars to Vercel — correct syntax:**

```bash
# IMPORTANT: vercel env add only accepts ONE environment target per call
# Valid targets: production, preview, development

# For each variable:
echo "<value>" | vercel env add <VAR_NAME> production

# Do NOT try to pass multiple environments in one call — this will error:
# WRONG: vercel env add VAR_NAME production preview development
# RIGHT: one call per environment target
```

**Common env var categories and handling:**

| Category | Example | Notes |
|----------|---------|-------|
| Public build vars | `NEXT_PUBLIC_*` | Needed at build time, safe to expose |
| Server secrets | `AUTH_SECRET`, API keys | Production only, never expose |
| Service URLs | `NEXT_PUBLIC_CONVEX_URL` | Usually same across environments |
| Payment keys | `STRIPE_*` | Use test keys for preview, live for production |

**Batch approach — push all vars efficiently:**

Read the env file, extract key-value pairs, and push each one. Run the calls in parallel where possible (they're independent).

```bash
# Example for each var (run these in parallel):
echo "value1" | vercel env add VAR_NAME_1 production
echo "value2" | vercel env add VAR_NAME_2 production
# ... etc
```

**Verify after pushing:**
```bash
vercel env ls
```

---

### Phase 6: Deploy

```bash
# Production deployment
vercel --prod
```

**If the build fails:**

1. **Check the build logs** — the URL is in the output (the "Inspect" URL)
2. **Common failures and fixes:**

| Failure | Cause | Fix |
|---------|-------|-----|
| `NEXT_PUBLIC_*` undefined at build | Env var missing or not `NEXT_PUBLIC_` prefixed | Push the var to Vercel |
| Module-level env access crashes build | Code reads `process.env.X` at import time | Use lazy initialization pattern (see below) |
| TypeScript errors | Stricter config on Vercel | Fix locally with `bun run build` first |
| Missing dependencies | `devDependencies` not installed in prod | Move to `dependencies` or set `INSTALL_DEV_DEPS=1` |

**Lazy initialization pattern for server-side clients:**

If code instantiates clients at module level using env vars, the build will fail because env vars aren't available at build time on Vercel. Fix with lazy initialization:

```typescript
// BAD - crashes during Vercel build
const client = new SomeClient(process.env.SOME_URL!);

// GOOD - defers to runtime
let client: SomeClient | null = null;
export function getClient(): SomeClient {
  if (!client) {
    const url = process.env.SOME_URL;
    if (!url) throw new Error("SOME_URL is not set");
    client = new SomeClient(url);
  }
  return client;
}
```

This applies to `ConvexHttpClient`, database clients, Stripe clients, etc. — anything that reads env vars at import time.

3. **After fixing, commit, push to GitHub, then redeploy:**
```bash
git add <files> && git commit -m "fix: resolve Vercel build failure"
git push origin main
vercel --prod
```

---

### Phase 7: Post-Deploy Verification

After successful deployment:

1. **Report the URLs to the user:**
   - Production URL (e.g., `https://project-name.vercel.app`)
   - Inspect URL for build logs
   - Dashboard URL: `https://vercel.com/<team>/<project>`

2. **Custom domain setup (if requested):**
   ```bash
   vercel domains add <domain>
   ```
   Then instruct user to update DNS:
   - For apex domain: A record → `76.76.21.21`
   - For subdomain: CNAME → `cname.vercel-dns.com`

3. **Remind user about:**
   - Auth callback URLs — Google OAuth, Auth.js etc. need the production URL added as an authorized redirect
   - Webhook URLs — Stripe, payment providers need the production URL
   - CORS settings — if using external APIs that whitelist origins
   - `AUTH_URL` or `NEXTAUTH_URL` env var may need to be set to the production URL

---

## Gotchas and Lessons Learned

### Vercel CLI quirks
- `vercel env add` accepts only ONE environment per call — passing multiple errors with "Invalid number of arguments"
- Valid built-in environments: `production`, `preview`, `development`
- **Custom environments** (e.g., `staging`, `QA`) are supported on Pro/Enterprise plans. The CLI accepts custom environment names directly — `vercel env add VAR_NAME staging` will auto-create the custom environment if it doesn't exist
- To deploy to a custom environment: `vercel deploy --target=staging`
- To remove a var from a custom environment: `vercel env rm VAR_NAME staging --yes`
- `vercel --prod` deploys from local files, not from Git — for Git-triggered deploys, push to GitHub and let Vercel's GitHub integration handle it
- `vercel link` must be run from the project root directory
- `NEXT_PUBLIC_` vars are flagged with a warning — this is expected, not an error
- **Do NOT use `preview` as a staging environment** — `preview` is Vercel's built-in PR preview system. Use a custom environment named `staging` instead

### Git pitfalls
- Always check `.gitignore` before the first commit — secrets pushed to Git history are very hard to remove
- Use `git add <specific-files>` not `git add -A` to avoid committing `.env`, `.DS_Store`, etc.
- If the repo was created with a README via GitHub web UI, you'll need `git pull --rebase origin main` before pushing

### Build-time vs runtime env vars
- `NEXT_PUBLIC_*` vars are inlined at **build time** — they must be set in Vercel before deploying
- Server-only vars are available at **runtime** — they work even if added after the build
- If a `NEXT_PUBLIC_` var changes, you must **redeploy** for the change to take effect

### Auth.js on Vercel
- `AUTH_SECRET` must be set — Auth.js won't work without it in production
- `AUTH_URL` / `NEXTAUTH_URL` is auto-detected on Vercel from `VERCEL_URL`, but it's safer to set it explicitly to your custom domain
- Google OAuth requires the production URL in the authorized redirect URIs in Google Cloud Console

### Framework detection
- Vercel auto-detects Next.js, Vite, Remix, etc. from `package.json`
- If detection fails, set the framework in Vercel dashboard or via `vercel.json`:
  ```json
  { "framework": "nextjs" }
  ```

## Checklist

Before reporting completion to the user, verify:

- [ ] Code is committed and pushed to GitHub
- [ ] GitHub repo visibility matches user preference
- [ ] Vercel project is linked and deployed
- [ ] All environment variables are pushed to Vercel production
- [ ] Build succeeded (no errors in build logs)
- [ ] Production URL is accessible
- [ ] User has been given: production URL, GitHub repo URL, Vercel dashboard URL
- [ ] User has been reminded about auth callback URLs and webhook URLs
