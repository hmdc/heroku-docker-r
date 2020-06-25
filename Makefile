# default build target
all::

all:: build
.PHONY: all push test

R_VERSION:=3.5.2
APT_VERSION:=$(R_VERSION)-1bionic

MAINTAINER:="Evan Sarmiento <esarmien@g.harvard.edu>"
MAINTAINER_URL:="https://github.com/hmdc/heroku-docker-r"
IMAGE_NAME:=hmdc/heroku-docker-r
GIT_SHA:=$(shell git rev-parse HEAD)
OS:=$(shell uname | tr '[:upper:]' '[:lower:]')
GIT_BRANCH:=$(shell git rev-parse --abbrev-ref HEAD)
CONTAINER_TEST_VERSION:=1.8.0

ifeq ($(shell ./bin/semver get major $(R_VERSION)), 4)
	CRAN_PATH:="cran40"
	APT_VERSION:=$(R_VERSION)-1.1804.0
endif

ifeq ($(shell ./bin/semver get major $(R_VERSION)), 3)
        CRAN_PATH:="cran35"
endif

ifeq ($(GIT_BRANCH), master)
	IMAGE_TAG:=$(IMAGE_NAME):$(R_VERSION)-$(GIT_SHA)
	PREFIX:=$(R_VERSION)
else
	IMAGE_TAG:=$(IMAGE_NAME):$(R_VERSION)-$(GIT_BRANCH)-$(GIT_SHA)
	PREFIX:=$(R_VERSION)-$(GIT_BRANCH)
endif

GIT_DATE:="$(shell TZ=UTC git show --quiet --date='format-local:%Y-%m-%d %H:%M:%S +0000' --format='%cd')"
BUILD_DATE:="$(shell date -u '+%Y-%m-%d %H:%M:%S %z')"

build:

	# "base" image
	docker build \
		--no-cache \
		--pull \
		--build-arg R_VERSION=$(R_VERSION) \
		--build-arg CRAN_PATH=$(CRAN_PATH) \
		--build-arg APT_VERSION=$(APT_VERSION) \
		--build-arg MAINTAINER=$(MAINTAINER) \
		--build-arg MAINTAINER_URL=$(MAINTAINER_URL) \
		--build-arg GIT_SHA="$(GIT_SHA)" \
		--build-arg GIT_DATE=$(GIT_DATE) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--tag $(IMAGE_TAG) \
		--tag $(IMAGE_NAME):$(PREFIX) \
		--file Dockerfile .

	# "shiny" image
	docker build \
		--no-cache \
		--build-arg R_VERSION=$(PREFIX) \
		--tag $(IMAGE_TAG)-shiny \
		--tag $(IMAGE_NAME):$(PREFIX)-shiny \
		--file Dockerfile.shiny .

output:
	docker save -o hmdc-heroku-docker-r-$(PREFIX).tar $(IMAGE_NAME):$(PREFIX)
	docker save -o hmdc-heroku-docker-r-$(PREFIX)-shiny.tar $(IMAGE_NAME):$(PREFIX)-shiny

push:
	docker push $(IMAGE_NAME):$(PREFIX)
	docker push $(IMAGE_NAME):$(PREFIX)-shiny
	docker tag $(IMAGE_NAME):$(PREFIX) $(IMAGE_TAG)
	docker tag $(IMAGE_NAME):$(PREFIX)-shiny $(IMAGE_TAG)-shiny
	docker push $(IMAGE_TAG)
	docker push $(IMAGE_TAG)-shiny


test:	
	# No reporting available yet.
	# https://github.com/GoogleContainerTools/container-structure-test/issues/207
	# Downloading container-structure-test
	mkdir -p ./bin
	if [ ! -f "./bin/container-structure-test-$(CONTAINER_TEST_VERSION)" ]; then curl -L https://storage.googleapis.com/container-structure-test/v$(CONTAINER_TEST_VERSION)/container-structure-test-$(OS)-amd64 -o ./bin/container-structure-test-$(CONTAINER_TEST_VERSION); fi
	chmod a+x ./bin/container-structure-test-$(CONTAINER_TEST_VERSION)
	# Running basic tests on parent image
	for image in "$(IMAGE_NAME):$(PREFIX)" "$(IMAGE_NAME):$(PREFIX)-shiny"; do \
		./bin/container-structure-test-$(CONTAINER_TEST_VERSION) test -c ./test/check-container-metadata.yaml --image $$image; \
		./bin/container-structure-test-$(CONTAINER_TEST_VERSION) test -c ./test/check-r-version-is-$(R_VERSION).yaml --image $$image; \
	done
	# Running tests on child image
	docker build --build-arg R_VERSION=$(PREFIX) -f ./test/app/Dockerfile -t shiny-app-hello-$(R_VERSION) ./test/app
	./bin/container-structure-test-$(CONTAINER_TEST_VERSION) test -c ./test/check-app-saved-to-image.yaml --image shiny-app-hello-$(R_VERSION)
	./bin/container-structure-test-$(CONTAINER_TEST_VERSION) test -c ./test/check-multiprocessing-support.yaml --image shiny-app-hello-$(R_VERSION)
	# Simple curl test
	docker run -d -p 8080:8080 shiny-app-hello-$(R_VERSION)|while read CONTAINER_ID; do \
		sleep 10s; \
		docker exec $$CONTAINER_ID curl --connect-timeout 20 --retry 20 --retry-delay 5 --retry-max-time 120 http://localhost:8080 -f; \
		docker kill $$CONTAINER_ID; \
	done
