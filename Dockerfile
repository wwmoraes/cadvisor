FROM golang:1.17-alpine3.15 AS source

RUN apk update && apk add --quiet --no-cache \
  git \
  && rm -rf /var/cache/apk

ARG VERSION
RUN git clone \
  --single-branch \
  --depth 1 \
  --branch v${VERSION} \
  https://github.com/google/cadvisor.git \
  /go/src/github.com/google/cadvisor

WORKDIR /go/src/github.com/google/cadvisor
RUN go mod download

FROM golang:1.17-alpine3.15 AS build

COPY --from=source /go/pkg/mod /go/pkg/mod

RUN apk update && apk add --quiet --no-cache \
  make \
  bash \
  gcc \
  musl-dev \
  && rm -rf /var/cache/apk

WORKDIR /go/src/github.com/google/cadvisor
COPY --from=source /go/src/github.com/google/cadvisor .
RUN make build


FROM --platform=${TARGETPLATFORM} alpine:3.15
	MAINTAINER dengnan@google.com vmarmol@google.com vishnuk@google.com jimmidyson@gmail.com stclair@google.com

	RUN apk --quiet --no-cache add libc6-compat device-mapper findutils ndctl && \
	    apk --quiet --no-cache add thin-provisioning-tools zfs --repository http://dl-3.alpinelinux.org/alpine/edge/main/ && \
	    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf && \
	    rm -rf /var/cache/apk/*

	# Grab cadvisor,libpfm4 and libipmctl from "build" container.
	COPY --from=build /usr/local/lib/libpfm.so* /usr/local/lib/
	COPY --from=build /usr/local/lib/libipmctl.so* /usr/local/lib/
	COPY --from=build /go/src/github.com/google/cadvisor/cadvisor /usr/bin/cadvisor

	EXPOSE 8080

	ENV CADVISOR_HEALTHCHECK_URL=http://localhost:8080/healthz

	HEALTHCHECK --interval=30s --timeout=3s \
	  CMD wget --quiet --tries=1 --spider $CADVISOR_HEALTHCHECK_URL || exit 1

	ENTRYPOINT ["/usr/bin/cadvisor", "-logtostderr"]
