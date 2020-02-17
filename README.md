# WireGuard Scripts

Scripts to interactively add or remove peers to/from systemd-`.netdev` files. Change file lookup and `[WireGuardPeer]` to `[Peer]` to use with `wg-quick` configuration files.

`remove-wg-peer` requires gawk >= 4.1.0 (it's seven years old, you probably have it).
