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

## Modernisation roadmap (mirrors the interview answer)

1. **Clarify and assess** – map the path to production, baseline DORA metrics. ✅ *(this README)*
2. **Quick wins** ✅ – Git with pull requests to `main`, automated build + unit tests on every PR ([#1](../../pull/1)), one scripted deployment to a test environment with automatic rollback ([#2](../../pull/2)). Branch protection on `main` needs the repo to be public or GitHub Pro.
3. **Build the pipeline** – containerise; dev → test → prod stages; build once, promote the same artefact; gated prod.
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
