DOCKER = docker
DOCKERHUB_USER = boecklic
PWD := $(shell pwd)
LOCAL_UID := $(shell id -u $$USER)
CMD ?= 
# use $$ to escape $: $$0 is reduces to $0 in shell
TAG := $(shell cat requirements.txt | grep -E ^jupyterlab | awk '{split($$0,a,"=="); print a[2]}')

.PHONY: build
build:
	@echo $(TAG)
	$(DOCKER) build -t $(DOCKERHUB_USER)/jupylab\:$(TAG) .

.PHONY: push
push: build
	$(DOCKER) tag $(DOCKERHUB_USER)/jupylab\:$(TAG) $(DOCKERHUB_USER)/jupylab\:$(TAG)
	$(DOCKER) push $(DOCKERHUB_USER)/jupylab\:$(TAG)


.PHONY: run
run:
	#@echo ${LOCAL_UID}
	# - Bind container port 8888 (the notebooks port)
	#   to host port 80
	# - set the env variable LOCAL_UID to the host users
	#   uid running the container
	# - mount the local directory as /home/user inside
	#   the container
	$(DOCKER) run -it --init -p 8888:8888 \
		-e LOCAL_UID=$(LOCAL_UID) \
		-v $(PWD):/home/user $(DOCKERHUB_USER)/jupylab\:$(TAG) $(CMD)

.PHONY: login
login:
	$(DOCKER) exec -it $(DOCKERHUB_USER)/jupylab\:$(TAG) /bin/bash
