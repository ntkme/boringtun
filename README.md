# boringtun

``` sh
docker run -d \
  --cap-add MKNOD \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  --publish 51820:51820/udp \
  --volume /etc/wireguard/wg0.conf:/etc/wireguard/wg0.conf \
  ghcr.io/ntkme/boringtun:edge wg0
```
