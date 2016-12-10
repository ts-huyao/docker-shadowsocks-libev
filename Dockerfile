#
# Dockerfile for shadowsocks-libev
#

FROM alpine
MAINTAINER EasyPi Software Foundation

ENV SS_VER 2.5.6
ENV SS_URL https://github.com/shadowsocks/shadowsocks-libev/archive/v$SS_VER.tar.gz
ENV SS_DIR shadowsocks-libev-$SS_VER

ENV KCP_VER 20161207
ENV KCP_URL https://github.com/xtaci/kcptun/releases/download/v$KCP_VER/kcptun-linux-amd64-$KCP_VER.tar.gz

RUN set -ex \
    && apk add --no-cache pcre \
    && apk add --no-cache \
               --virtual TMP autoconf \
                             build-base \
                             curl \
                             libtool \
                             linux-headers \
                             openssl-dev \
                             pcre-dev \
    && curl -sSL $SS_URL | tar xz \
    && cd $SS_DIR \
        && ./configure --disable-documentation \
        && make install \
        && cd .. \
        && rm -rf $SS_DIR \
        && curl -sSL $KCP_URL |tar xz -C /usr/local/bin \
        && mv /usr/local/bin/server_linux_amd64 /usr/local/bin/kcp-server \
        && rm /usr/local/bin/client_linux_amd64 \
    && apk del --virtual TMP \
    && echo "#!/bin/sh" >> /usr/local/bin/init.sh \
    && echo "" >> /usr/local/bin/init.sh \
    && echo "nohup kcp-server -l :\$KCP_PORT -t 127.0.0.1:\$SERVER_PORT --crypt \$KCP_CRYPT --mtu \$KCP_MTU --mode \$KCP_MODE --dscp \$KCP_DSCP \$KCP_OPTIONS &" >> /usr/local/bin/init.sh \
    && echo "ss-server -s "\$SERVER_ADDR" -p "\$SERVER_PORT" -m "\$METHOD" -k "\$PASSWORD" -t "\$TIMEOUT" -d "\$DNS_ADDR" -u -A --fast-open \$OPTIONS" >> /usr/local/bin/init.sh \
    && chmod a+x /usr/local/bin/init.sh

ENV SERVER_ADDR 0.0.0.0
ENV SERVER_PORT 23493
ENV METHOD      aes-256-cfb
ENV PASSWORD=
ENV TIMEOUT     60
ENV DNS_ADDR    8.8.8.8

ENV KCP_PORT 33493
ENV KCP_CRYPT aes-128
ENV KCP_MTU 1350
ENV KCP_MODE fast
ENV KCP_DSCP 0
ENV KCP_OPTIONS=

EXPOSE $SERVER_PORT/tcp
EXPOSE $SERVER_PORT/udp
EXPOSE $KCP_PORT/tcp
EXPOSE $KCP_PORT/udp

CMD /usr/local/bin/init.sh
