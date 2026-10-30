#!/bin/bash
# Dave's deploy script - DO NOT RUN WITHOUT TELLING DAVE
# usage: ./deploy.sh
scp target/contoso-orders-1.0-SNAPSHOT.jar dave@prod-orders-01:/opt/orders/
ssh dave@prod-orders-01 "pkill -9 -f contoso-orders; cd /opt/orders; nohup java -jar contoso-orders-1.0-SNAPSHOT.jar > out.log 2>&1 &"
echo "done (probably)"
