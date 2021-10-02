FROM ubuntu:20.04

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        bzip2 \
        ca-certificates \
        curl \
        file \
        g++ \
        g++-multilib \
        libc6-dev \
        make \
    && rm -rf /var/lib/apt/lists/*

ENV SDE_VERSION=8.35.0-2019-03-11
RUN curl --retry 3 -LsSf https://github.com/gnzlbg/intel_sde/raw/master/sde-external-$SDE_VERSION-lin.tar.bz2 | tar -xjf -
ENV PATH=/sde-external-$SDE_VERSION-lin:$PATH

ENV CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_RUNNER="sde64 -rtm_mode full --"
