FROM heroku/heroku:18-build

ARG R_VERSION
ARG CRAN_PATH
ARG APT_VERSION
ARG GIT_SHA
ARG GIT_DATE
ARG BUILD_DATE
ARG MAINTAINER
ARG MAINTAINER_URL
ARG APT_GPG_KEY_ID=51716619E084DAB9

LABEL "r.version"="$R_VERSION" \
      "r.version.apt"="$APT_VERSION" \
      "git.sha"="$GIT_SHA" \
      "git.date"="$GIT_DATE" \
      "build.date"="$BUILD_DATE" \
      "maintainer"="$MAINTAINER" \
      "maintainer.url"="$MAINTAINER_URL"

## Configure default locale
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
  && locale-gen en_US.utf8 \
  && /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

# copy over helpers script
COPY helpers.R /etc/R/helpers.R
COPY findSystemDependencies.sh /usr/bin
# install R & set default CRAN repo
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $APT_GPG_KEY_ID \
  && chmod a+x /usr/bin/findSystemDependencies.sh \
  && echo "deb https://cloud.r-project.org/bin/linux/ubuntu bionic-$CRAN_PATH/" > /etc/apt/sources.list.d/cran.list \
  && apt-get update -q \
  && apt-get install -qy --no-install-recommends \
    jq \
    libgsl0-dev \
    r-base-core=$APT_VERSION \
    r-base-dev=$APT_VERSION \
  && apt-get autoclean \
  && rm -rf /var/lib/apt/lists/* \
  && echo 'options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version$platform, R.version$arch, R.version$os)))' > /etc/R/Rprofile.site \
  && echo 'options(repos = c(CRAN = "https://packagemanager.rstudio.com/all/__linux__/bionic/latest", CRAN_SRC = "https://cloud.r-project.org/"), download.file.method = "libcurl")' >> /etc/R/Rprofile.site \
  && echo '.libPaths(c("/app/R/site-library", .libPaths()))' >> /etc/R/Rprofile.site \
  && echo 'source("/etc/R/helpers.R")' >> /etc/R/Rprofile.site \
  && mkdir -p /app/R/site-library

# set /app as working directory
WORKDIR /app

# run R console
CMD ["/usr/bin/R", "--no-save"]
