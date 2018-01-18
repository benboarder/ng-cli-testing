#simple angular-cli docker installation
#docker build -t ng-cli .
#or specify angular-cli version
#docker build --build-arg NG_CLI_VERSION=1.6.4

FROM node:8

MAINTAINER DDCTeamWookie <DLDDCTeamWookie@auspost.com.au>

USER root

ARG NG_CLI_VERSION=1.6.4
ARG USER_HOME_DIR="/tmp"
ARG APP_DIR="/app"
ARG USER_ID=1000

ENV NPM_CONFIG_LOGLEVEL warn
#angular-cli rc0 crashes with .angular-cli.json in user home
ENV HOME "$USER_HOME_DIR"

# npm 5 uses different userid when installing packages, as workaround su to node when installing
# see https://github.com/npm/npm/issues/16766
RUN set -xe \
  && curl -sL https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 > /usr/bin/dumb-init \
  && chmod +x /usr/bin/dumb-init \
  && mkdir -p $USER_HOME_DIR \
  && chown $USER_ID $USER_HOME_DIR \
  && chmod a+rw $USER_HOME_DIR \
  && chown -R node /usr/local/lib /usr/local/include /usr/local/share /usr/local/bin \
  && (cd "$USER_HOME_DIR"; su node -c "npm install -g @angular/cli@$NG_CLI_VERSION; npm install -g yarn; npm cache clean --force")

ADD display-chromium /usr/bin/display-chromium
ADD xvfb-chromium /usr/bin/xvfb-chromium
ADD xvfb-chromium-webgl /usr/bin/xvfb-chromium-webgl

RUN rm -rf /var/lib/apt/lists/* \
  echo 'deb http://deb.debian.org/debian jessie-backports main' > /etc/apt/sources.list.d/jessie-backports.list

RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    bzip2 \
    unzip \
    xz-utils \
    xvfb \
    firefox-esr \
    libosmesa6 \
    libgconf-2-4 \
    dumb-init \
    gnupg \
    wget \
    ca-certificates \
    apt-transport-https \
    ttf-wqy-zenhei \
  && apt-get clean \
  && wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
  && (dpkg -i google-chrome-stable_current_amd64.deb; apt-get -fy install; rm google-chrome-stable_current_amd64.deb; apt-get clean; rm -rf /var/lib/apt/lists/* ) \
  && mv /usr/bin/google-chrome /usr/bin/google-chrome.real  \
  && mv /opt/google/chrome/google-chrome /opt/google/chrome/google-chrome.real  \
  && rm /etc/alternatives/google-chrome \
  && ln -s /opt/google/chrome/google-chrome.real /etc/alternatives/google-chrome \
  && ln -s /usr/bin/xvfb-chromium /usr/bin/google-chrome \
  && ln -s /usr/bin/xvfb-chromium /usr/bin/chromium-browser \
  && ln -s /usr/lib/x86_64-linux-gnu/libOSMesa.so.6 /opt/google/chrome/libosmesa.so

ENV LANG C.UTF-8

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
ENV CA_CERTIFICATES_JAVA_VERSION 20161107~bpo8+1

RUN set -x \
  && apt-get update \
  && apt-get install -y \
    openjdk-8-jdk="$JAVA_DEBIAN_VERSION" \
    ca-certificates-java="$CA_CERTIFICATES_JAVA_VERSION" \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && [ "$JAVA_HOME" = "$(docker-java-home)" ]

RUN /var/lib/dpkg/info/ca-certificates-java.postinst configure

#VOLUME "$USER_HOME_DIR/.cache/yarn"
#VOLUME "$APP_DIR/"
WORKDIR $APP_DIR
EXPOSE 4200

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

USER $USER_ID