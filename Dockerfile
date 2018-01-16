FROM trion/ng-cli-karma:1.6.4

MAINTAINER DDCTeamWookie <DLDDCTeamWookie@auspost.com.au>

USER root
### Installation as in https://github.com/docker-library/openjdk/blob/master/8-jdk/Dockerfile due to missing mixins in docker ###

ARG LABEL_SCHEMA_VERSION=unknown
ARG LABEL_BUILD_DATE=unknown
ARG LABEL_DESCRIPTION=unknown
ARG LABEL_VERSION=unknown
ARG LABEL_VCS_URL=unknown
ARG LABEL_VCS_REF=unknown

LABEL org.label-schema.schema-version=$LABEL_SCHEMA_VERSION \
      org.label-schema.build-date=$LABEL_BUILD_DATE \
      org.label-schema.description=$LABEL_DESCRIPTION \
      org.label-schema.version=$LABEL_VERSION \
      org.label-schema.vcs-url=$LABEL_VCS_URL \
      org.label-schema.vcs-ref=$LABEL_VCS_REF

RUN apt-get update && apt-get install -y --no-install-recommends \
    bzip2 \
    unzip \
    xz-utils \
    libgconf-2-4 \
    xvfb firefox-esr \
        && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN echo 'deb http://deb.debian.org/debian jessie-backports main' > /etc/apt/sources.list.d/jessie-backports.list

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

# script to auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
RUN { \
    echo '#!/bin/sh'; \
    echo 'set -e'; \
    echo; \
    echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
  } > /usr/local/bin/docker-java-home \
  && chmod +x /usr/local/bin/docker-java-home

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

ENV JAVA_VERSION 8u131
ENV JAVA_DEBIAN_VERSION 8u131-b11-1~bpo8+1

# see https://bugs.debian.org/775775
# and https://github.com/docker-library/java/issues/19#issuecomment-70546872
ENV CA_CERTIFICATES_JAVA_VERSION 20161107~bpo8+1

RUN set -x \
  && apt-get update \
  && apt-get install -y \
    openjdk-8-jdk="$JAVA_DEBIAN_VERSION" \
    ca-certificates-java="$CA_CERTIFICATES_JAVA_VERSION" \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && [ "$JAVA_HOME" = "$(docker-java-home)" ]

# see CA_CERTIFICATES_JAVA_VERSION notes above
RUN /var/lib/dpkg/info/ca-certificates-java.postinst configure

USER $USER_ID
