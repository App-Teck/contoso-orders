# Contoso Orders – Production Deployment Runbook

**Release window:** last Friday of the month, 6pm–10pm. Tell Finance beforehand.
**Who:** Dave (or Priya if Dave is on leave). Nobody else has the prod password.

## Steps

1. Make sure everyone has emailed you their latest changes and you've copied them
   into the `orders-final-v3` folder on the shared drive. Check nothing is missing.
2. On your laptop, open the project in IntelliJ and click *Build*. If it fails,
   ask whoever changed it last.
3. Run `mvn package -DskipTests` (tests have been broken since 2023, just skip them).
4. Copy `target/contoso-orders-1.0-SNAPSHOT.jar` to the prod box:
   `scp target/*.jar dave@prod-orders-01:/opt/orders/`
5. If there are new files in `sql/`, open SQL Server Management Studio, connect to
   prod with the sa password (in the Excel sheet), and run them **in order**.
   Do NOT forget this step (see April incident).
6. SSH to `prod-orders-01` and:
   ```
   ps -ef | grep java        # find the old process
   kill -9 <pid>
   cd /opt/orders
   nohup java -jar contoso-orders-1.0-SNAPSHOT.jar > out.log 2>&1 &
   ```
7. Open http://prod-orders-01:8080/orders/health in a browser. If it says UP, you're done.
8. If it doesn't come up, copy the old jar back from `/opt/orders/backup/` (if
   someone remembered to make a backup) and repeat step 6.
9. Email the team that the release is done.

## Known issues

- The test environment is a VM under Priya's desk and doesn't match prod (different
  Java version, different DB). Things that work in test sometimes break in prod.
- Config in `application.properties` is for local dev. Dave edits it by hand on the
  prod box after each deployment. If you overwrite it, the app points at the wrong DB.
- Last 6 releases: 4 needed a rollback or a hotfix the following Monday.
