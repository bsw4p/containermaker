# Containermaker
# Year: 2015
# Author: Benedikt Schmotzle - code@schmotzle.info
# -----------------------------------------------------------------------------------
# Containermaker is a script to help with the creation and maintenance of 
# docker container images.

makelink = $(shell find -maxdepth 1 -type l | grep Makefile)

# -----------------------------------------------------------------------------------
# Include global config if availabe 
ifneq ($(makelink),)
  global_path=$(shell ls -l Makefile | cut -d ">" -f 2 | sed -s 's/\/Makefile$$//')
  include $(global_path)/global.mk
endif

# -----------------------------------------------------------------------------------
# Include local config if availabe
config_path= $(shell find -maxdepth 1 -type f | grep "config.mk$$")
ifneq ($(config_path),)
  include $(shell pwd)/config.mk
else
  ifneq ($(global_path),)
    # setup template files
    $(warning Running for the first time \o/)
    $(warning Trying to copy template files.)
    $(shell cp -n $(global_path)/config.mk .)    
    $(shell cp -n $(global_path)/Dockerfile .)    
    include $(shell pwd)/config.mk
  else
    $(error No config file or config file template found. Makefile should be a symlink \
to a directory containing the main Makefile and template files)
  endif
endif 

# -----------------------------------------------------------------------------------
# Build Docker name from namespace and container name
ifneq ($(container_namespace),)
  ifneq ($(container_name),)
    name = $(container_namespace)/$(container_name) 
    path = $(container_namespace)_$(container_name)
  else
    $(error 'container_name' name not set in config.mk)
  endif
else
  $(warning No 'container_namespace' set in config.mk although it is good practice)

  ifneq ($(container_name),)
    name = $(container_name)
    path = $(name)
  else
    $(error 'container_name' name not set in config.mk)
  endif
endif

# -----------------------------------------------------------------------------------
# use sudo if configured in config.mk or global.mk
ifeq ($(use_sudo),YES)
  docker_cmd = sudo docker
else
  docker_cmd = docker
endif

# -----------------------------------------------------------------------------------
# build network port mapping strings from options in config.mk or global.mk

ifneq ($(port_intern),)
  ifneq ($(address),)
    bind_address=$(address)
  else
    $(warning No 'address' set. Using 127.0.0.1)
    bind_address=127.0.0.1
  endif

  ifneq ($(port_extern),)
    ports = -p $(bind_address):$(port_extern):$(port_intern)
  else
    $(warning No 'port_extern' set. Using internal port $(port_intern) as extern port)
    ports = -p $(bind_address):$(port_intern):$(port_intern)
  endif
endif


# -----------------------------------------------------------------------------------
# build mounts into the container from options in config.mk or global.mk
ifneq ($(in_mount_from),)
  ifneq ($(in_mount_to),)
    in_mount = -v $(shell pwd)/$(in_mount_from):$(in_mount_to):ro
  else
    $(error 'in_mount_to' is not set.)
  endif
endif

# -----------------------------------------------------------------------------------
# build mounts ouf of the container from options in config.mk or global.mk
ifneq ($(out_mount_from),)
  ifneq ($(out_mount_to),)
    out_mount = -v $(shell pwd)/$(out_mount_from):$(out_mount_to)
  else
    $(error 'out_mount_to' is not set.)
  endif
endif

ifneq ($(link_from),)
  ifneq ($(link_to),)
    link = --link $(link_from):$(link_to) 
  else
    $(error 'link_to' is not set.)
  endif
endif

# -----------------------------------------------------------------------------------
# set terminal options if configured 
ifneq ($(terminal),)
  term=-it -e TERM
endif

# -----------------------------------------------------------------------------------
# configure user 
user=$(shell grep -E "USER" Dockerfile | sed -e 's/^[[:space:]]*//' | grep -E "^USER" | cut -d " " -f 2)

ifneq ($(user),)
  ifeq ($(user),root)
    home = "/root/"
  else
    home = "/home/$(user)"
  endif
else
  home = "/"
endif

ifneq ($(local_user),)
  user_id = -u $(shell id -u):$(shell id -g)
endif

prebuild_exists=$(shell ls | grep prebuild)
postbuild_exists=$(shell ls | grep postbuild)
prerun_exists=$(shell ls | grep prerun)
postrun_exists=$(shell ls | grep postrun)

ifneq ($(prebuild_exists),)
  prebuild=./prebuild
endif

ifneq ($(postbuild_exists),)
  postbuild=./postbuild
endif

ifneq ($(prerun_exists),)
  prerun=./prerun
endif

ifneq ($(postrun_exists),)
  postrun=./postrun
endif



run = $(docker_cmd) run $(user_id) $(in_mount) $(out_mount) $(ports) $(term) $(link)

all: help

build:
	$(prebuild)
	$(docker_cmd) build -t $(name) .
	$(postbuild)

save:
	$(docker_cmd) save $(name) > $(path).tar

load:
	$(docker_cmd) load $(name) < $(path).tar

clean:
	rm $(path).tar

interactive:
	$(prerun)
	$(run) --privileged -e HOME=$(home) -e TERM -it -i $(name) bash -i
	$(postrun)

run:
	$(prerun)
	$(run) -e HOME=$(home) --rm --name $(container_name) $(name) 
	$(postrun)

background:
	$(prerun)
	$(run) --name $(container_name) -d $(name)
	$(postrun)

stop:
	$(docker_cmd) stop $(container_name)
	$(docker_cmd) rm $(container_name)	

attach:
	$(docker_cmd) attach --sig-proxy=false $(container_name)

logs:
	$(docker_cmd) logs `$(docker_cmd) ps | grep $(name) | cut -d " " -f 1`

inspect:
	$(docker_cmd) inspect $(shell docker ps | grep $(name)| cut -d " " -f 1)

help:
	@echo "_________                __         .__                                    __                  "
	@echo "\_   ___ \  ____   _____/  |______  |__| ____   ___________  _____ ___ _  |  | __  ___________  "
	@echo "/    \  \/ /  _ \ /    \   __\__  \ |  |/    \_/ __ \_  __ \/     \ __  \ |  |/ / /__ \_   __ \ "
	@echo "\     \___(  <_> )   |  \  |  / __ \|  |   |  \  ___/|  | \/  Y Y  \/ __ \|    < \  ___/|  | \/ "
	@echo " \______  /\____/|___|  /__| (____  /__|___|  /\___  >__|  |__|_|  (____  /__|_ \ \___  >__|    "
	@echo "        \/            \/          \/        \/     \/            \/     \/     \/    \/        "
	@echo "---------------------------------------------------------------------------------------------"
	@echo "Run make with one of the following options\n" \ 
	@echo "make build\t\t\t- create a container image from Dockerfile"
	@echo "make save\t\t\t- save the container image into a tar file for deployment"
	@echo "make load\t\t\t- load a container image from a tar file"
	@echo "make clean\t\t\t- remove a saves container image tar file"
	@echo "make interactive\t\t- run a shell inside the container for debugging"
	@echo "make run\t\t\t- run the container image"
	@echo "make background\t\t\t- run the container image in background"
	@echo "make stop\t\t\t- stops the container image"
	@echo "make attach\t\t\t- attach to a container running in background mode"
	@echo "make logs\t\t\t- show logs from container running in background mode"
