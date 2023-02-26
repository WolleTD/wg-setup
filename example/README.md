Run `./up.sh` for the example. The WireGuard keys are freshly generated, so it requires some
steps to connect client and server. The advantage is that the script showcases more stuff.

If successful, it will have done a HTTP download on the WireGuard server from a HTTP server
provided "through" the WireGuard client.

See `docker-compose.yml` for some more words about the three different containers and their
configuration.

**NOTE:** `docker-compose` prior v2.x is apparently unable to do anything when the container
defined in `network_mode:` doesn't already exist. In that case, you have to comment out that
line, run `docker-compose up -d wg-client`, remove the comment and continue. This is currently
incompatible with using the `up.sh` script.

Furthermore, recreating the `wg-client` container _requires_ also recreating the dependent
`nginx` container, as the network stack is bound to a particular container, not an abstract
name. Unfortunately, you can't define this kind of dependency in `docker-compose`, so it must
be done manually.
