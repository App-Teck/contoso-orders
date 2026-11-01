# Contoso Orders – DevOps modernisation lab

A hands-on replica of the interview scenario:

> *"A client deploys manually once a month and releases often break. How would you modernise them?"*

This repository starts in the state the **client** is in. Each later step is a
separate commit / pull request so the whole journey is visible in the history.

## Starting point (the "client" today)

| Area | State |
|---|---|
| Source control | Code lived on a shared drive; this repo is the first time it's in Git |
| Build | Developer clicks *Build* in IntelliJ, then `mvn package -DskipTests` |
| Tests | None. "Broken since 2023, just skip them" |
| Deployment | Manual, last Friday of the month, by one person (`deploy/DEPLOY-RUNBOOK.md`) |
| Environments | Test VM under someone's desk; doesn't match prod |
| Config/secrets | Hard-coded in `application.properties`; prod values edited by hand on the box |
| DB changes | SQL scripts run by hand in SSMS, in the right order, hopefully |
| Rollback | Copy the old jar back, if a backup was taken |
| Monitoring | Open the health URL in a browser |
| Change failure rate | 4 of the last 6 releases needed a rollback or hotfix |

The app itself is a small Spring Boot 3 / Java 21 REST service:

```
GET  /orders            list orders
GET  /orders/{id}       get one order
POST /orders            create an order
POST /orders/{id}/ship  mark an order shipped
GET  /orders/health     health check
```

Run locally: `mvn spring-boot:run` then `curl localhost:8080/orders`.

Run as a container (step 3.1):

```bash
docker build -t contoso-orders:dev .
docker run --rm -p 8080:8080 contoso-orders:dev
curl localhost:8080/orders/health
docker inspect -f '{{.State.Health.Status}}' <container>   # Docker's own health check
```

The image is built in two stages (Maven build, then a JRE-only Alpine runtime), runs as a
non-root user and carries a `HEALTHCHECK` on `/orders/health`. See the comments in `Dockerfile`.

Every push to `main` also builds the image in CI and publishes it (step 3.2):

```bash
docker pull ghcr.io/app-teck/contoso-orders:latest      # newest main
docker pull ghcr.io/app-teck/contoso-orders:<short-sha> # one exact commit
```

Pull requests build the image too, but do not push it, so a broken `Dockerfile` fails the PR.
The image job only runs after the tests pass, and the tag is the Git SHA: this is the single
artefact that later gets promoted through the environments.

## Modernisation roadmap (mirrors the interview answer)

1. **Clarify and assess** – map the path to production, baseline DORA metrics. ✅ *(this README)*
2. **Quick wins** ✅ – Git with pull requests to `main`, automated build + unit tests on every PR ([#1](../../pull/1)), one scripted deployment to a test environment with automatic rollback ([#2](../../pull/2)). `main` is protected by the `protect-main` ruleset: pull request required, **Build and test** check must be green, no direct or force pushes.
3. **Build the pipeline** – 3.1 containerise ✅ · 3.2 CI builds and publishes the image ✅ · 3.3 dev → test → prod stages, same image promoted, gated prod · 3.4 Flyway for the SQL scripts.
4. **Infrastructure as Code** – Terraform so test matches prod.
5. **Security and quality** – quality gate, dependency and image scanning, secrets out of code, managed identity.
6. **People** – docs and runbooks the client's team can own.
7. **Measure** – before/after DORA metrics.

## DORA baseline (day one)

| Metric | Client today |
|---|---|
| Deployment frequency | Monthly |
| Lead time for changes | 2–6 weeks (waits for the release window) |
| Change failure rate | ~67% (4 of last 6) |
| Time to restore service | Hours to days (manual rollback by one person) |

## Step 2 status (quick wins)

| Quick win | Where | State |
|---|---|---|
| Unit and API tests, run by `mvn verify` | `src/test/java` | done ([#1](../../pull/1)) |
| CI build + tests on every pull request and push to `main` | `.github/workflows/ci.yml` | done ([#1](../../pull/1)) |
| Repeatable scripted deployment with health check and automatic rollback | `deploy/` | done ([#2](../../pull/2)) |
| Protected `main` | GitHub ruleset `protect-main` | done |

The `protect-main` ruleset means nobody, including the repo owner, can push straight to `main`,
force-push it, or delete it. Every change goes through a pull request, the **Build and test**
check has to be green on the latest commit, and review threads have to be resolved. The CI
workflow and the deploy script are what get promoted in step 3; the ruleset is what makes
them mandatory rather than optional.
