# CLAUDE.md – working notes for Claude Code sessions on this repo

Read this first. It is the handover between machines (laptop and desktop) and between sessions.

## What this repo is

A training lab built by the owner (not an interview deliverable). The scenario is a mock
DevOps question: *"A client deploys manually once a month and releases often break. How would
you modernise them?"* The repo starts as the client's app and each roadmap step is one or more
pull requests, so the whole modernisation is visible in the Git history.

The owner wants to **learn by doing**: for every step, explain each file and each line in plain
language *while writing it*, do the work so it is visible in IntelliJ, then let the owner read
and say "merge" before anything lands on `main`. Keep explanations simple. Interview prep
docs with the 7-step roadmap live in Google Drive under `Interview/` (Accenture Final Screening
docx, section 3.1), but the owner has said this scenario is their own training, not the interview.

## Ground rules

- `main` is protected by the GitHub ruleset `protect-main`: PR required, the **Build and test**
  check must be green on the latest commit, review threads resolved, no force-push, no delete.
  A direct push fails with `GH013`. So: branch → commit → push → `gh pr create` → wait for CI
  → owner says merge → `gh pr merge <n> --merge --delete-branch`.
- One PR per roadmap sub-step. Commit messages say which step they are.
- Repo is public on purpose (free branch protection). Keep it free of anything real.
- The owner's GitHub account is `App-Teck`. Java 21 and Maven 3.9 are installed on both machines.

## Roadmap and where we are

| Step | Content | State |
|---|---|---|
| 1 Clarify and assess | README baseline, DORA day-one numbers | done (first commit) |
| 2.1 Tests | `src/test/java` – 7 tests, `mvn verify` runs them | done, PR #1 |
| 2.2 CI | `.github/workflows/ci.yml` – build + test on every PR and push to main | done, PR #1 |
| 2.3 Scripted deploy | `deploy/deploy.sh`, `rollback.sh`, `status.sh`, `environments/*.env` | done, PR #2 |
| 2.4 Protected main | ruleset `protect-main` | done, documented in PR #4 |
| **3 Build the pipeline** | containerise; stages dev → test → prod; build once, promote the same artefact; gated prod | **next** |
| 4 Infrastructure as Code | Terraform so test matches prod | todo |
| 5 Security and quality | quality gate, dependency + image scanning, secrets out of code (Key Vault), managed identity | todo |
| 6 People | docs and runbooks the client team can own | todo |
| 7 Measure | before/after DORA | todo |

PR #3 was a duplicate of #1 made from the laptop before noticing #1 existed; closed, ignore it.

## Step 3 plan (not started)

Suggested sub-steps, each its own PR, each explained line by line as it is written:

1. **3.1 Dockerfile** – multi-stage build (Maven build stage → slim JRE 21 runtime), non-root
   user, `HEALTHCHECK` on `/orders/health`. Add `.dockerignore`. Build and run locally, curl it.
2. **3.2 CI builds and pushes the image** – extend `ci.yml`: on push to `main`, build the image,
   tag with the Git SHA, push to GitHub Container Registry (`ghcr.io/app-teck/contoso-orders`).
   This is the "build once" artefact.
3. **3.3 Deploy stages** – a `deploy.yml` workflow with GitHub Environments `dev`, `test`, `prod`:
   same image tag promoted through each; `prod` environment has a required reviewer (gated).
   Deploy target for now is a container run on the host via the existing `deploy.sh` idea, or
   `docker compose` per environment; keep it simple and local until step 4 adds real infra.
4. **3.4 Database migrations in the pipeline** – Flyway with the two scripts moved to
   `src/main/resources/db/migration/`, so the April incident class of failure disappears.
5. Update README roadmap and the diagram when done.

## Useful commands

```bash
mvn verify                                   # build + 7 tests
deploy/deploy.sh test target/contoso-orders-1.0-SNAPSHOT.jar
deploy/status.sh test ; deploy/rollback.sh test
gh pr list ; gh pr checks <n> ; gh run list --branch main --limit 3
gh api repos/App-Teck/contoso-orders/rulesets   # see protect-main
```

## Artifacts

- Step 2 before/after diagram (private artifact of the owner): https://claude.ai/artifact/BH1p8huepypJ1xJDddWn7P
