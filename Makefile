# Create multi-platform docker image. If you have native systems around, using
# them will be much more efficient at build time. See e.g.
# https://netfuture.ch/2020/05/multi-arch-docker-image-easy/
BUILDXDETECT	= ${HOME}/.docker/cli-plugins/docker-buildx

# Just one of the many files created
QEMUDETECT	= /proc/sys/fs/binfmt_misc/qemu-m68k

# Override this, if you want to use your own registry
REGISTRY	= steveltn
# For version x.y.z, output "-t …:x.yz -t …:x.y -t …:x";
# for anything else, output nothing
BASETAG		= ${REGISTRY}/https-portal
VERSIONTAGS	= $(shell git describe --tags | \
                  sed -n -e 's,^\(\(\([0-9]*\).[0-9]*\).[0-9]*\)\(.*\),-t ${BASETAG}:\1\4 -t ${BASETAG}:\2\4 -t ${BASETAG}:\3\4,p')

# For platform compatibility/naming matrix, see `./fs_overlay/bin/archname`
#
# Not building for linux/arm/v5, as building the docker image fails with:
# Error while loading /usr/sbin/dpkg-split: No such file or directory
# Error while loading /usr/sbin/dpkg-deb: No such file or directory

PLATFORMS	= linux/386,linux/amd64,linux/arm/v7,linux/arm64/v8

docker-multiarch:	qemu buildx docker-multiarch-builder
	docker login
	docker buildx build --builder docker-multiarch --pull \
		--platform ${PLATFORMS} \
		${VERSIONTAGS} -t ${BASETAG}:latest .

docker-multiarch-push: qemu buildx docker-multiarch-builder
	docker login
	docker buildx build --builder docker-multiarch --pull --push \
		--platform ${PLATFORMS} \
		${VERSIONTAGS} -t ${BASETAG}:latest .

qemu:		${QEMUDETECT}
${QEMUDETECT}:
	docker pull multiarch/qemu-user-static
	docker run --privileged multiarch/qemu-user-static --reset -p yes
	docker ps -a | sed -n 's, *multiarch/qemu-user-static.*,,p' \
	  | (xargs docker rm 2>&1 || \
	    echo "Cannot remove docker container on ZFS; retry after next reboot") \
	  | grep -v 'dataset is busy'

buildx:		${BUILDXDETECT}
${BUILDXDETECT}:
	@echo
# Output of `uname -m` is too different
	@echo '*** `docker buildx` missing. Install binary for this machine architecture'
	@echo '*** from `https://github.com/docker/buildx/releases/latest`'
	@echo '*** to `~/.docker/cli-plugins/docker-buildx` and `chmod +x` it.'
	@echo
	@exit 1

docker-multiarch-builder:	qemu buildx
	if ! docker buildx ls | grep -w docker-multiarch > /dev/null; then \
		docker buildx create --name docker-multiarch && \
		docker buildx inspect --builder docker-multiarch --bootstrap; \
	fi

.PHONY:		qemu buildx docker-multiarch docker-multiarch-builder
