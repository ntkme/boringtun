FROM docker.io/library/alpine:3.16.0

RUN apk add --no-cache catatonit libgcc wireguard-tools \
 && apk add --no-cache --virtual .build-deps cargo libcap \
 && RUSTFLAGS="-Ccodegen-units=1" cargo install --root /usr --git https://github.com/cloudflare/boringtun.git boringtun-cli \
 && rm -rf ~/.cargo \
 && setcap cap_net_admin+ep /usr/bin/boringtun-cli \
 && apk del --purge .build-deps \
 && printf '%s\n' \
           '#!/bin/sh' \
           'mkdir -p /var/run/wireguard && chown "$LOGNAME:" /var/run/wireguard && exec su -s /usr/bin/boringtun-cli -- "$LOGNAME" "$@"' \
  | tee /usr/local/bin/boringtun-cli \
 && printf '%s\n' \
           '#!/bin/bash' \
           'if [[ $# -eq 2 && $1 == up ]]; then' \
           '	eval "$(sed -e "/^# ~~ function override insertion point ~~$/q" /usr/bin/wg-quick)"' \
           '	add_if() { kill -18 $$ && until wg show "$INTERFACE" >/dev/null 2>&1; do sleep 1 && kill -0 $$ || return; done; }' \
           '	die() { echo "$PROGRAM: $*" >&2; kill -9 $$; exit 1; }' \
           '	auto_su' \
           '	parse_options "$2"' \
           '	( cmd_up & )' \
           '	kill -19 $$' \
           '	cmd exec "${WG_QUICK_USERSPACE_IMPLEMENTATION:-wireguard-go}" --foreground "$INTERFACE"' \
           'else' \
           '	exec /usr/bin/wg-quick "$@"' \
           'fi' \
  | tee /usr/local/bin/wg-quick \
 && chmod a+x /usr/local/bin/boringtun-cli /usr/local/bin/wg-quick

VOLUME ["/etc/wireguard"]

ENV WG_QUICK_USERSPACE_IMPLEMENTATION=boringtun-cli LOGNAME=nobody

ENTRYPOINT ["/usr/bin/catatonit", "--", "/bin/sh", "-c", "test -c /dev/net/tun || { mkdir -p /dev/net && mknod -m 666 /dev/net/tun c 10 200; } && exec wg-quick up \"$@\"", "--"]
