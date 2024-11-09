#
# MonaServer2 Dockerfile

FROM alpine:latest AS builder

LABEL maintainer="itwhs<itwhs@foxmail.com>"

# install prerequisites
RUN apk add --no-cache libgcc \
		libstdc++ \
		openssl-dev

RUN apk add --no-cache --virtual .build-deps \
		curl \
		make \
		g++ \
		git

# Build & install luajit
WORKDIR /usr/src
RUN curl -fSL -o luajit.tar.gz https://github.com/LuaJIT/LuaJIT/archive/refs/tags/v2.1.ROLLING.tar.gz \
	&& tar -xzf luajit.tar.gz \
	&& cd LuaJIT-2.1.ROLLING \
	&& sed -i 's/#XCFLAGS+= -DLUAJIT_ENABLE_LUA52COMPAT/XCFLAGS+= -DLUAJIT_ENABLE_LUA52COMPAT/g' src/Makefile \
	&& make \
	&& make install

# Build
RUN git clone https://github.com/MonaSolutions/MonaServer2.git
WORKDIR /usr/src/MonaServer2/MonaBase
RUN make 
WORKDIR /usr/src/MonaServer2/MonaCore
RUN make
WORKDIR /usr/src/MonaServer2/MonaServer
RUN make

# install MonaServer
RUN cp ../MonaBase/lib/libMonaBase.so ../MonaCore/lib/libMonaCore.so /usr/local/lib \
	&& cp MonaServer ../MonaTiny/cert.pem ../MonaTiny/key.pem /usr/local/bin

# No need to delete build tools with the multi-stage build

##################################################
# Create a new Docker image with just the binaries
FROM alpine:latest

RUN apk add --no-cache libgcc libstdc++

COPY --from=builder /usr/local/lib /usr/local/lib
COPY --from=builder /usr/local/bin /usr/local/bin

#
# Expose ports for MonaCore protocols
#

# HTTP(S)/WS(S)
EXPOSE 80/tcp
EXPOSE 443/tcp
# RTM(F)P
EXPOSE 1935/tcp
EXPOSE 1935/udp
# STUN
EXPOSE 3478/udp

WORKDIR /usr/local/bin

# Set MonaServer as default executable
CMD ["./MonaServer", "--log=7"]
