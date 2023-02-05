Run `./up.sh` for the example. The WireGuard keys are freshly generated, so it requires some
steps to connect client and server. The advantage is that the script showcases more stuff.

If successful, it will have done a HTTP download on the WireGuard server from a HTTP server
provided "through" the WireGuard client.

See `docker-compose.yml` for some more words about the three different containers and their
configuration.
