ARG SRS_VERSION=2.0-r6
ARG SRS_BUILD_PATH=/usr/local/srs
ARG SRS_CONFIGURE_ARGS=--full

FROM gcc:5.5 AS build

ARG SRS_VERSION
ARG SRS_BUILD_PATH
ARG SRS_CONFIGURE_ARGS

RUN set -ex;

RUN apt-get update && apt-get install -y --no-install-recommends wget ca-certificates sudo python net-tools libspeex-dev bzip2 autoconf;

# install nasm for ffmpeg
RUN cd /tmp; \
    wget https://www.nasm.us/pub/nasm/releasebuilds/2.14.02/nasm-2.14.02.tar.bz2; \
    tar xjvf nasm-2.14.02.tar.bz2; \
    cd nasm-2.14.02; \
    ./autogen.sh; \
    ./configure  --bindir="/usr/local/bin"; \
    make; \
    make install;

# build srs
RUN cd /tmp; \
    wget https://github.com/ossrs/srs/archive/v${SRS_VERSION}.tar.gz; \
    tar zxf v${SRS_VERSION}.tar.gz; \
    cd srs-${SRS_VERSION}/trunk; \
    ./configure --prefix=${SRS_BUILD_PATH} ${SRS_CONFIGURE_ARGS}; \
    make; \
    make install;

COPY ./srs.conf /srs/conf/docker.conf

FROM debian:stretch-slim

ARG SRS_VERSION
ARG SRS_BUILD_PATH
ARG SRS_CONFIGURE_ARGS

ENV SRS_VERSION=${SRS_VERSION}
ENV SRS_CONFIGURE_ARGS=${SRS_CONFIGURE_ARGS}
ENV SRS_BUILD_PATH=${SRS_BUILD_PATH}

EXPOSE 1935 1985 8080

COPY --from=build ${SRS_BUILD_PATH} ${SRS_BUILD_PATH}

WORKDIR ${SRS_BUILD_PATH}

CMD ["./objs/srs", "-c", "./conf/docker.conf"]