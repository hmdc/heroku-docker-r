#!/usr/bin/env bash
for var in `env|cut -f1 -d=`; do
  echo "PassEnv $var" >> /app/apache/etc/apache2/httpd.conf;
done

PORTS=$(bash /usr/bin/run_r_workers.sh)

for port in $PORTS; do
    echo "--> Waiting for R process listening on ${port} to start."
    timeout 120 sh -c 'until nc -z $0 $1; do sleep 1; done' 127.0.0.1 $port
    echo "--> R ${port} started."
done

echo "--> Starting Apache"
exec /usr/sbin/apache2 -DFOREGROUND -DNO_DETACH -f /app/apache/etc/apache2/httpd.conf