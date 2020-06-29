# docker-boringtun

``` sh
docker run -d \
  --cap-add NET_ADMIN \
  --publish 51820:51820/udp \
  --volume /etc/wireguard:/etc/wireguard \
  ntkme/boringtun
```