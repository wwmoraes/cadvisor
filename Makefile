PLATFORMS = linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6
VERSION = 0.39.3

release: Dockerfile
	@docker buildx build --push --platform ${PLATFORMS} \
		--build-arg VERSION=${VERSION} \
		-t wwmoraes/cadvisor:${VERSION} -f $< .

build: Dockerfile
	@docker buildx build --load \
		--build-arg VERSION=${VERSION} \
		-t wwmoraes/cadvisor:${VERSION} -f $< .
