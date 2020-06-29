FROM alpine:latest

RUN apk add --no-cache alpine-sdk rustup \
 && rustup-init -y --target x86_64-unknown-linux-musl \
 && source ~/.cargo/env \
 && cargo install --target x86_64-unknown-linux-musl boringtun

FROM alpine:latest

COPY --from=0 /root/.cargo/bin/boringtun /usr/bin

RUN apk add --no-cache wireguard-tools \
 && apk add --no-cache --virtual .build-deps libcap \
 && setcap cap_net_admin+ep /usr/bin/boringtun \
 && apk del --purge .build-deps \
 && printf '%s\n' '#!/bin/sh' 'mkdir -p /var/run/wireguard && chown "$LOGNAME:" /var/run/wireguard && exec su -s /usr/bin/boringtun -- "$LOGNAME" "$@"' \
  | tee /usr/local/bin/boringtun \
 && chmod a+x /usr/local/bin/boringtun

VOLUME ["/etc/wireguard"]

ENV WG_QUICK_USERSPACE_IMPLEMENTATION=/usr/local/bin/boringtun LOGNAME=nobody INTERFACE=wg0

ENTRYPOINT ["/bin/sh", "-c", "test -f \"/etc/wireguard/$INTERFACE.conf\" || ( umask 077 && printf '%s\\n' '[Interface]' 'Address = 10.8.0.1/24' 'PostUp = iptables --table nat --append POSTROUTING --jump MASQUERADE' 'PostDown = iptables --table nat --delete POSTROUTING --jump MASQUERADE' 'ListenPort = 51820' \"PrivateKey = $(wg genkey)\" | tee \"/etc/wireguard/$INTERFACE.conf\" ) && test -c /dev/net/tun || { mkdir -p /dev/net && mknod -m 666 /dev/net/tun c 10 200; } && trap 'wg-quick down \"$INTERFACE\"; exit' TERM && wg-quick up \"$INTERFACE\" && while :; do wait && { sleep infinity & }; done", "--"]
