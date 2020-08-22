# wg-setup WireGuard Management

wg-setup was designed to simplify the setup of WireGuard when handling larger amounts of
clients. The server-side tools only support `systemd-networkd`-backed WireGuard interfaces.

## Quick example

Set up a VPN connection with eight commands (of which three are signature checking)!

Server:
```
$ git clone https://github.com/WolleTD/wg-setup.git && cd wg-setup

# To install only wg-setup scripts and services
$ sudo ./install.sh

# To also configure a WireGuard server interface
$ sudo ./install.sh wireguard
```

Client:
```
$ gpg --recv-keys FB9DA662
$ curl -O https://raw.githubusercontent.com/WolleTD/wg-setup/$ref/wg-setup-client
$ curl -O https://raw.githubusercontent.com/WolleTD/wg-setup/$ref/wg-setup-client.sig
$ gpg --verify wg-setup-client.sig && chmod +x setup-wg-quick

$ sudo ./setup-wg-quick -e vpn.example.com:12345 -p Vq12...3a4= 172.16.1.10/16
...
```

## Manage peers manually

A WireGuard interface and thus a WireGuard server is usually configured in a
root-private file, also the running interface has to restarted or configured separately to the
file for the change to take effect.

This is tedious and error-prone, so `wg-setup` provides `add-peer` and `remove-peer` commands.

### add-peer

 - input validation
 - force a valid hostname as comment on every peer
 - use a default CIDR of `/32` for AllowedIPs
 - keep configuration file and interface in sync
 - print added configuration to stdout
 - ask for confirmation, except -y is passed
 - interactive input with no arguments

Example:
```
$ wg-setup add-peer my-peer iCJSinvalidCG2/WP9D1/viGlv+WrNpWtd1XkRzyrFs= 172.16.0.10
[WireGuardPeer]
# my-peer
# Added by wolle at 2020-05-20
PublicKey = iCJSinvalidCG2/WP9D1/viGlv+WrNpWtd1XkRzyrFs=
AllowedIPs = 172.16.0.10/32

Add this configuration to /etc/systemd/network/90-wireguard.netdev? [Y/n]
```

### remove-peer

 - input validation
 - keep configuration file and interface in sync
 - print removed configuration to stdout
 - ask for confirmation, except -y is passed

Example:
```
$ wg-setup remove-peer iCJSinvalidCG2/WP9D1/viGlv+WrNpWtd1XkRzyrFs=
[WireGuardPeer]
# my-peer
# Added by wolle at 2020-05-20
PublicKey = iCJSinvalidCG2/WP9D1/viGlv+WrNpWtd1XkRzyrFs=
AllowedIPs = 172.16.0.10/32

Remove this configuration from /etc/systemd/network/90-wireguard.netdev? [y/N]
```

### list-peers

_(work in progress)_

## wg-setup-client: Setup clients

This is kind of a companion script. Where `wg-setup` shall help managing larger WireGuard
networks, a large amount of clients has to be setup as well.

Basic usage:
```bash
sudo ./wg-setup-client -e <server-endpoint> -p <server-pubkey> <ip-address>
```

- If `<ip-address>` is specified without prefix-length, `/24` is used
- If `-e` or `-p` is missing, the values are queried interactively
- See `--help` for more options

##### Security

To easily setup "bare" clients, `wg-setup-client` can basically be executed from GitHub directly.
You may also serve your own copy, in any case you should _always_ incorporate some kind of
signature validation in such automatic setup environments and don't trust HTTP(S):

```bash
gpg --recv-keys FB9DA662
curl -O https://raw.githubusercontent.com/WolleTD/wg-setup/$ref/wg-setup-client
curl -O https://raw.githubusercontent.com/WolleTD/wg-setup/$ref/wg-setup-client.sig
gpg --verify wg-setup-client.sig && chmod +x setup-wg-quick
```

---

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
