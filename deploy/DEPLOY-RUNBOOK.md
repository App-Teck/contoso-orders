# Contoso Orders – Deployment Runbook

## Deploying to **test** (anyone on the team, any time)

```bash
mvn verify                                   # build and run the tests (no more -DskipTests)
deploy/deploy.sh test target/contoso-orders-1.0-SNAPSHOT.jar
deploy/status.sh test                         # what is live, is it healthy
```

The script copies the jar into a new release folder, stops the old process, starts the new one,
waits for `/orders/health` to report `UP`, and **rolls back automatically** to the previous release
if it doesn't. Nothing is edited by hand on the box. To roll back deliberately:

```bash
deploy/rollback.sh test
```

Environment-specific values (port, memory, profile, health URL) live in
`deploy/environments/<env>.env`. The same script and the same jar are used for every environment,
which is what makes test a meaningful rehearsal for prod.

## Deploying to **prod** (interim process until the pipeline takes over)

Still done by a person during the release window, but now it is the same two commands against
`prod.env` on the prod box, using the **jar that CI built and that was already deployed to test**.
Download it from the CI run's artifacts rather than building it on a laptop.

```bash
deploy/deploy.sh prod contoso-orders-1.0-SNAPSHOT.jar
```

Database changes in `sql/` are still run by hand before deploying. Automating them is on the
roadmap (Flyway, roadmap step 3).

## What changed from the old process

| Before | Now |
|---|---|
| Build on a laptop in IntelliJ, tests skipped | Built and tested by CI on every pull request |
| `kill -9` and `nohup` typed by hand | One script, same every time, in Git |
| Rollback = find a backup jar, if any | Previous release kept; automatic rollback on failed health check |
| Prod config edited by hand on the box | Per-environment config files in Git (secrets move out in step 5) |
| Only Dave can deploy | Anyone can deploy to test; prod is the same command |
