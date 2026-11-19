# Create multi-platform docker image. If you have native systems around, using
# them will be much more efficient at build time. See e.g.
# https://netfuture.ch/2020/05/multi-arch-docker-image-easy/
# Use Docker Desktop's local Linux VM by default. Override DOCKER_CONTEXT to
# use another Docker host. A dedicated builder name avoids reusing builders
# attached to a different context.
DOCKER_CONTEXT	= desktop-linux
DOCKER		= docker --context ${DOCKER_CONTEXT}
BUILDER		= https-portal-multiarch

# Override this, if you want to use your own registry
REGISTRY	= steveltn
# For version x.y.z, output "-t …:x.yz -t …:x.y -t …:x";
# for anything else, output nothing
BASETAG		= ${REGISTRY}/https-portal
VERSIONTAGS	= $(shell git describe --tags --exact-match | \
                  sed -n -e 's,^\(\(\([0-9]*\).[0-9]*\).[0-9]*\)\(.*\),-t ${BASETAG}:\1\4 -t ${BASETAG}:\2\4 -t ${BASETAG}:\3\4 -t ${BASETAG}:latest\4,p')

# For platform compatibility/naming matrix, see `./fs_overlay/bin/archname`
#
# Not building for linux/arm/v5, as building the docker image fails with:
# Error while loading /usr/sbin/dpkg-split: No such file or directory
# Error while loading /usr/sbin/dpkg-deb: No such file or directory

PLATFORMS	= linux/386,linux/amd64,linux/arm/v7,linux/arm64/v8

docker-multiarch:	qemu buildx docker-multiarch-builder
	${DOCKER} login
	${DOCKER} buildx build --builder ${BUILDER} --pull \
		--platform ${PLATFORMS} \
		${VERSIONTAGS} .

docker-multiarch-push: qemu buildx docker-multiarch-builder
	${DOCKER} login
	${DOCKER} buildx build --builder ${BUILDER} --pull --push \
		--platform ${PLATFORMS} \
		${VERSIONTAGS} .

qemu:
	${DOCKER} run --privileged --rm tonistiigi/binfmt --install all

buildx:
	@${DOCKER} buildx version > /dev/null 2>&1 || ( \
		echo '*** `docker buildx` is missing.'; \
		echo '*** Install Docker Desktop or the Docker Buildx plugin.'; \
		exit 1; \
	)

docker-multiarch-builder:	qemu buildx
	@if ! ${DOCKER} buildx inspect --builder ${BUILDER} > /dev/null 2>&1; then \
		${DOCKER} buildx create --name ${BUILDER} --driver docker-container; \
	fi
	${DOCKER} buildx inspect --builder ${BUILDER} --bootstrap

.PHONY:		qemu buildx docker-multiarch docker-multiarch-push docker-multiarch-builder
