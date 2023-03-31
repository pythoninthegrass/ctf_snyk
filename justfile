# See https://just.systems/man/en

# load .env
set dotenv-load

# positional params
set positional-arguments

# set env var
export APP      := `echo ${APP_NAME:-"ctf_snyk"}`
export CWD      := `echo $(pwd)`
export IMAGE    := `echo "python:slim-bullseye:latest"`
export POETRY   := `echo ${POETRY:-"1.4.1"}`
export PY_VER   := `echo ${PY_VER:-"3.11.2"}`
export SCRIPT   := `echo ${SCRIPT:-"startup.sh"}`
export SHELL    := `echo ${SHELL:-"/bin/bash"}`
export TAG      := `echo ${TAG:-"latest"}`
export VERSION  := `echo ${VERSION:-"latest"}`

# x86_64/arm64
arch := `uname -m`

# hostname
host := `uname -n`

# operating system
os := `uname -s`

# home directory
home_dir := env_var('HOME')

# docker-compose / docker compose
# * https://docs.docker.com/compose/install/linux/#install-using-the-repository
docker-compose := if `command -v docker-compose; echo $?` == "0" {
	"docker-compose"
} else {
	"docker compose"
}

# [halp]     list available commands
default:
	just --list

# [deps]     update dependencies
update-deps args=CWD:
	#!/usr/bin/env bash
	# set -euxo pipefail
	args=$(realpath {{args}})
	find "${args}" -maxdepth 3 -name "pyproject.toml" -exec \
		echo "[{}]" \; -exec \
		echo "Clearing pypi cache..." \; -exec \
		poetry --directory "${args}" cache clear --all pypi --no-ansi \; -exec \
		poetry --directory "${args}" update --lock --no-ansi \;

# [deps]     export requirements.txt
export-reqs args=CWD: update-deps
	#!/usr/bin/env bash
	# set -euxo pipefail
	args=$(realpath {{args}})
	find "${args}" -maxdepth 3 -name "pyproject.toml" -exec \
		echo "[{}]" \; -exec \
		echo "Exporting requirements.txt..." \; -exec \
		poetry --directory "${args}" export --no-ansi --without-hashes --output requirements.txt \;

# [git]      update pre-commit hooks
pre-commit:
	@echo "To install pre-commit hooks:"
	@echo "pre-commit install -f"
	@echo "Updating pre-commit hooks..."
	pre-commit autoupdate

# [check]    lint sh script
checkbash:
	#!/usr/bin/env bash
	checkbashisms {{SCRIPT}}
	if [[ $? -eq 1 ]]; then
		echo "bashisms found. Exiting..."
		exit 1
	else
		echo "No bashisms found"
	fi

# TODO: see below @buildx
# [docker]   build locally
build: checkbash
	#!/usr/bin/env bash
	set -euxo pipefail
	# https://stackoverflow.com/a/74277737
	BUILD_ARGS=$(for i in $(cat .env); do
		if [[ $i = "APP_NAME="* ]]; then
			continue
		fi
		out+="--build-arg $i "
		done
		echo $out; out=""
	)

	if [[ {{arch}} == "arm64" ]]; then
		docker build -f Dockerfile -t {{APP}} --build-arg CHIPSET_ARCH=aarch64-linux-gnu ${BUILD_ARGS} .
	else
		docker build -f Dockerfile --progress=plain -t {{APP}} ${BUILD_ARGS} .
	fi

# [scripts]  run script in working directory
sh args=SCRIPT:
	sh {{args}}

# TODO: QA and possibly exclude ${TAG} in conditional
# ! may have undesirable behavior for non-build env vars; possibly create new one called build.env
# [docker]   intel build
buildx: checkbash
	#!/usr/bin/env bash
	set -euxo pipefail
	# https://stackoverflow.com/a/74277737
	BUILD_ARGS=$(for i in $(cat .env); do
		if [[ $i = "APP_NAME="* ]]; then
			continue
		fi
		out+="--build-arg $i "
		done
		echo $out; out=""
	)

	docker buildx build -f Dockerfile --progress=plain -t {{TAG}} --build-arg CHIPSET_ARCH=x86_64-linux-gnu ${BUILD_ARGS} --load .

# [docker]   arm build w/docker-compose defaults
build-clean: checkbash
	#!/usr/bin/env bash
	set -euxo pipefail
	if [[ {{arch}} == "arm64" ]]; then
		{{docker-compose}} build --pull --no-cache --build-arg CHIPSET_ARCH=aarch64-linux-gnu --parallel
	else
		{{docker-compose}} build --pull --no-cache --parallel
	fi

# [docker]   login to registry (exit code 127 == 0)
login:
	#!/usr/bin/env bash
	# set -euxo pipefail
	echo "Log into ${REGISTRY_URL} as ${USER_NAME}. Please enter your password: "
	cmd=$(docker login --username ${USER_NAME} ${REGISTRY_URL})
	if [[ $("$cmd" >/dev/null 2>&1; echo $?) -ne 127 ]]; then
		echo 'Not logged into Docker. Exiting...'
		exit 1
	fi

# [docker]   tag image as latest
tag-latest:
	docker tag {{APP}}:latest {{IMAGE}}/{{APP}}:latest

# [docker]   tag latest image from VERSION file
tag-version:
	@echo "create tag {{APP}}:{{VERSION}} {{IMAGE}}/{{APP}}:{{VERSION}}"
	docker tag {{APP}} {{IMAGE}}/{{APP}}:{{VERSION}}

# [docker]   push latest image
push: login
	docker push {{IMAGE}}/{{APP}}:{{TAG}}

# [docker]   pull latest image
pull: login
	docker pull {{IMAGE}}/{{APP}}

# [docker]   run container
run: build
	#!/usr/bin/env bash
	# set -euxo pipefail
	docker run --rm -it \
		--name {{APP}} \
		--env-file .env \
		--entrypoint={{SHELL}} \
		-h ${HOST:-localhost} \
		-v $(pwd)/app:/app \
		{{APP}}

# [docker]   start docker-compose container
up: build
	{{docker-compose}} up -d

# [docker]   get running container logs
logs:
	{{docker-compose}} logs -tf --tail="50" {{APP}}

# [docker]   ssh into container
exec:
	docker exec -it {{APP}} {{SHELL}}

# [docker]   stop docker-compose container
stop:
	{{docker-compose}} stop

# [docker]   remove docker-compose container(s) and networks
down: stop
	{{docker-compose}} down --remove-orphans
