# WireGuard Scripts

### `wg-(add|remove)-peer`

Scripts to interactively manage peers via systemd-`.netdev` files (and cli for the running
interface). Change file lookup and `[WireGuardPeer]` to `[Peer]` to use with `wg-quick`
configuration files.

`wg-remove-peer` requires gawk >= 4.1.0 (it's seven years old, you probably have it).

### `setup-*`

Small templates to quickly setup WireGuard on clients. At least `WG_PUBKEY` and `WG_ENDPOINT`
have to be set to get a working result. The default network is `172.16.0.0/24` and can be
adjusted by setting `WG_NET` and `WG_CIDR` accordingly. You need to run `sudo` with the `-E`
flag to preserve the set environment variables. Example:

```bash
export WG_PUBKEY="<pubkey>" WG_ENDPOINT="vpn.example.com:12345" WG_NET=172.16.25.0
sudo -E ./setup-wg-quick $IP_ADDRESS
```

The `$IP_ADDRESS` is expected without CIDR suffix. The required server peer entry is display
at the end. VPN done.

##### Security

Be careful executing software from GitHub as root. Read all the code you are going to execute
and please verify signatures if you download the script just-in-time.

```bash
gpg --recv-keys FB9DA662
curl -O https://raw.githubusercontent.com/WolleTD/WireGuard-scripts/$ref/setup-wg-quick
curl -O https://raw.githubusercontent.com/WolleTD/WireGuard-scripts/$ref/setup-wg-quick.sig
gpg --verify setup-wg-quick.sig && chmod +x setup-wg-quick
```

---

Other variables rarely need customization, these are their defaults:

  - `WG_NAME = wg0`

wg-quick:
  - `WG_CONF = /etc/wireguard/${WG_NAME}.conf`

wireguard-netdev:
  - `WG_BASENAME = 90-wireguard`
  - `WG_NETDEV = /etc/systemd/network/${WG_BASENAME}.netdev`
  - `WG_NETWORK = /etc/systemd/network/${WG_BASENAME}.network`
  - `WG_DESC = WireGuard VPN` (Description for netdev)

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
