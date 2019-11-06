ARG R_VERSION
FROM hmdc/heroku-docker-r:$R_VERSION-shiny
ENV PORT=8080
CMD /usr/bin/R --no-save -f /app/run.R