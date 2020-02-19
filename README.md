# WireGuard Scripts

### `(add|remove)-wg-peer`

Scripts to interactively manage peers via systemd-`.netdev` files (and cli for the running
interface). Change file lookup and `[WireGuardPeer]` to `[Peer]` to use with `wg-quick`
configuration files.

`remove-wg-peer` requires gawk >= 4.1.0 (it's seven years old, you probably have it).

### `setup-*`

Small templates to quickly setup WireGuard on clients. Replace all the placeholders in the
template with your actual server configuration, run the scripts like
`setup-wg-quick $IP_ADDRESS` and add the new client to the server configuration. VPN done.

You could even add the installation itself to the scripts. While WireGuard will be in kernel
5.6, some of us will probably want VPN connections to older devices for quite some time.

### Windows/MacOS

Take your wg-quick template minus the first two lines. Paste into connection editor in the
WireGuard UI and customize the IP address for the client. Click Save, click Activate. Add
PublicKey and IP address to the server. VPN done.

Alternatively, generate configurations locally with a modified `setup-wg-quick` (no root,
different output files, no service stuff) and distribute them. The UI clients allow importing.
On the other hand, please don't send private keys over insecure connections, like the internet
in general.

## License

CC-BY-SA, I guess... These are hacky scripts. Read and understand them before you use them,
that's all I'm asking for. Also, recommend them if you like them.
