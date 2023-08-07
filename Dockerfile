FROM swift:5.8

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y -q && apt-get upgrade -y -q
RUN apt-get install -y -q \
    libllvm15 \
    llvm-15 \
    llvm-15-dev \
    llvm-15-runtime \
    zstd

RUN ln -s /usr/bin/llvm-config-15 /usr/bin/llvm-config

COPY build /root

WORKDIR /root
