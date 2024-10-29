# syntax=docker/dockerfile:1
FROM ubuntu:24.04 AS builder
ARG TARGETPLATFORM
ARG MONGODB_VERSION="8.0.3"
ARG MONGOSH_VERSION="2.3.2"

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl \
  && case "$TARGETPLATFORM" in \
    "linux/amd64") MONGODB_ARCH="x86_64" && MONGOSH_ARCH="x64" ;; \
    "linux/arm64") MONGODB_ARCH="aarch64" && MONGOSH_ARCH="arm64" ;; \
    *) echo "unsupported platform: $TARGETPLATFORM" && exit 1 ;; \
  esac \
  && curl -sSL https://fastdl.mongodb.org/linux/mongodb-linux-$MONGODB_ARCH-ubuntu2404-$MONGODB_VERSION.tgz -o mongodb.tgz \
  && curl -sSL https://downloads.mongodb.com/compass/mongosh-$MONGOSH_VERSION-linux-$MONGOSH_ARCH.tgz -o mongosh.tgz \
  && tar -xzf mongodb.tgz \
  && tar -xzf mongosh.tgz \
  && rm -rf mongodb.tgz mongosh.tgz \
  && mv mongodb-*/bin/mongod mongosh-*/bin/mongosh /usr/local/bin/ \
  && rm -rf mongodb-* mongosh-* \
  && apt-get purge -y --auto-remove ca-certificates curl \
  && rm -rf /var/lib/apt/lists/*

FROM ubuntu:24.04

COPY --from=builder /usr/local/bin/mongod /usr/local/bin/mongosh /usr/local/bin/
COPY entrypoint.sh /usr/local/bin/

RUN apt-get update \
  && apt-get install -y --no-install-recommends curl wait-for-it \
  && rm -rf /var/lib/apt/lists/* \
  && groupadd -r mongo && useradd -r -g mongo -d /home/mongo -m mongo \
  && chmod +x /usr/local/bin/entrypoint.sh \
  && mkdir -p /var/lib/mongo1 /var/log/mongo1 /var/lib/mongo2 /var/log/mongo2 /var/lib/mongo3 /var/log/mongo3 \
  && chown -R mongo:mongo /var/lib/mongo1 /var/log/mongo1 /var/lib/mongo2 /var/log/mongo2 /var/lib/mongo3 /var/log/mongo3

EXPOSE 27017
EXPOSE 27018
EXPOSE 27019

USER mongo
ENTRYPOINT [ "bash", "/usr/local/bin/entrypoint.sh" ]
