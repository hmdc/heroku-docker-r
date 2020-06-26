#!/bin/bash

if [ -f "/app/packrat/packrat.lock" ]; then
    cat /app/packrat/packrat.lock |grep -Poi "(?<=Package: )([a-zA-Z0-9]+)"|xargs -P 4 -IPKG curl -w '\n' https://sysreqs.r-hub.io/pkg/PKG 2>/dev/null | while read line; do
    PACKAGES=$(echo "${line}" | jq -r '..[]|.platforms|.DEB?|select (. != null)' 2>/dev/null)
    echo $PACKAGES
    done | sed '/^$/d' | tr ' ' '\n' | sort | uniq | tr '\n' ' ' >>/tmp/r-sysreq-dependencies.txt
else
    R --no-save --quiet --slave -e 'library(jsonlite); toJSON(packrat:::appDependencies(fields=c("Imports", "Depends")))' | jq -r '.[]' | xargs -P 4 -IPKG curl -w '\n' https://sysreqs.r-hub.io/pkg/PKG 2>/dev/null | while read line; do
        PACKAGES=$(echo "${line}" | jq -r '..[]|.platforms|.DEB?|select (. != null)' 2>/dev/null)
        echo $PACKAGES
    done | sed '/^$/d' | tr ' ' '\n' | sort | uniq | tr '\n' ' ' >>/tmp/r-sysreq-dependencies.txt
fi

echo "-> Installing system level dependencies: $(cat /tmp/r-sysreq-dependencies.txt)"
apt-get -y install $(cat /tmp/r-sysreq-dependencies.txt)
