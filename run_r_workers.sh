#!/bin/bash
set -e
DYNO_CORES=$(grep -c processor /proc/cpuinfo 2>/dev/null)
# Divide by 2 because Shiny takes up a lot of memory.
CORES=${R_NUM_PROCS:-$((${DYNO_CORES} / 2))}
PORT_START=12000
# Index starts at 0
PORT_END=$(($PORT_START + $(($CORES - 1))))

function BalanceMembers() {
    local PROTOCOL="${1}"
    for port in $(seq $PORT_START $PORT_END)
    do
        # Use port as the route number for simplicity.
        echo "BalancerMember ${PROTOCOL}://127.0.0.1:${port} route=r${port}"
    done
}

cat <<EOF > /app/apache/etc/apache2/instances.conf
<Proxy balancer://webapp>
$(BalanceMembers "http")
ProxySet stickysession=route
</Proxy>

<Proxy balancer://websocket>
$(BalanceMembers "ws")
ProxySet stickysession=route
</Proxy>
EOF

for port in $(seq $PORT_START $PORT_END)
do
        echo "Starting worker on $port..." 1>&2
        R -f /app/run.R --gui-none --no-save --args $port 1>&2 &
done

echo $(seq $PORT_START $PORT_END)
