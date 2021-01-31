# container-boringtun

``` sh
docker run -d \
  --cap-add MKNOD \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  --publish 51820:51820/udp \
  --volume /etc/wireguard:/etc/wireguard \
  ntkme/boringtun
```
