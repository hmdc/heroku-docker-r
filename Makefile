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
IMAGE_TAG:=$(IMAGE_NAME):$(R_VERSION)-$(GIT_SHA)
GIT_DATE:="$(shell TZ=UTC git show --quiet --date='format-local:%Y-%m-%d %H:%M:%S +0000' --format='%cd')"
BUILD_DATE:="$(shell date -u '+%Y-%m-%d %H:%M:%S %z')"

build:

	# "base" image
	docker build \
		--pull \
		--build-arg R_VERSION=$(R_VERSION) \
		--build-arg APT_VERSION=$(APT_VERSION) \
		--build-arg MAINTAINER=$(MAINTAINER) \
		--build-arg MAINTAINER_URL=$(MAINTAINER_URL) \
		--build-arg GIT_SHA="$(GIT_SHA)" \
		--build-arg GIT_DATE=$(GIT_DATE) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--tag $(IMAGE_TAG) \
		--tag $(IMAGE_NAME):latest \
		--file Dockerfile .

	# "build" image
	docker build \
		--tag $(IMAGE_TAG)-build \
		--tag $(IMAGE_NAME):build \
		--file Dockerfile.build .

	# "shiny" image
	docker build \
		--tag $(IMAGE_TAG)-shiny \
		--tag $(IMAGE_NAME):shiny \
		--file Dockerfile.shiny .

push:

	docker push $(IMAGE_NAME):latest
	docker push $(IMAGE_TAG)

	docker push $(IMAGE_NAME):build
	docker push $(IMAGE_TAG)-build

	docker push $(IMAGE_NAME):shiny
	docker push $(IMAGE_TAG)-shiny

test:

	# TODO
	@echo ""
