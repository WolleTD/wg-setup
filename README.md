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

# Generate a new token
$ wg-setup new-token test-peer 172.16.1.10
ABCDEFGH            test-peer           172.16.1.10
```

Client:
```
$ gpg --recv-keys FB9DA662
$ curl -O https://raw.githubusercontent.com/WolleTD/wg-setup/$ref/wg-setup-client
$ curl -O https://raw.githubusercontent.com/WolleTD/wg-setup/$ref/wg-setup-client.sig
$ gpg --verify wg-setup-client.sig && chmod +x setup-wg-quick

$ sudo ./setup-wg-quick -e vpn.example.com:12345 -p Vq12...3a4= 172.16.1.10/16 ABCDEFGH
...
Connecting to tcp://vpn.example.com:12345
Success! Using ping target: 172.16.0.1
Ping successful! WireGuard VPN setup complete!
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

## wg-setup token: Add peers automatically

`wg-setup` can also add peers via pregenerated, random tokens linked to single AllowedIPs.
Besides some `wg-setup` commands, the scripts `wg-setup-use-token` and `wg-setup-service`
are used to securely expose this feature to the network.

Tokens are eight character long Base32 strings to keep them human read- and writeable.
The list of active tokens is located in `/var/lib/wg-setup/tokenlist`

### new-token

Takes a hostname and an IP address as input, generates and saves a random token linked to this
specific IP address. The hostname is internal and defined by the administrator on token creation.

```
$ wg-setup new-token peer-043 172.16.0.43
EOD3U2RG                172.16.0.43/32          peer-043
```

### revoke-token

Takes a token and removes it from the wg-setup tokenlist.

```
$ wg-setup revoke-token EOD3U2RG
EOD3U2RG                172.16.0.43/32          peer-043
```

### list-tokens

List all tokens. Basically `cat /var/lib/wg-setup/tokenlist`.

### use-token

Takes a token, a PublicKey and a single IP address as input. If the given combination
of token and IP address matches a line in the wg-setup tokenlist, a new peer will be
added to WireGuard, using the provided PublicKey and IP address as well as the hostname
from the tokenlist. On success, the token will be removed from the list.

```
$ wg-setup use-token EOD3U2RG iCJSinvalidCG2/WP9D1/viGlv+WrNpWtd1XkRzyrFs= 172.16.0.43
[WireGuardPeer]
# peer-043
# Added by wolle at 2020-05-20
PublicKey = iCJSinvalidCG2/WP9D1/viGlv+WrNpWtd1XkRzyrFs=
AllowedIPs = 172.16.0.43/32

Add this configuration to test.netdev? [Y/n]
```

### wg-setup-use-token

Small, self-sudoing wrapper around `wg-setup use-token`. The wg-setup sudoers file
allows the `wg-setup` user to run this wrapper without password.

### wg-setup-service

Meant to run as a TCP service through socat. This script reads the same input as `use_token`,
but exclusively from stdin. After RegExp validation, the input is passed to `wg-setup`
through `wg-setup-use-token` and evaluated. On success, "OK" is printed, nothing otherwise.
`wg-setup.service` provides a systemd unit for this.

### Setup the service

The default operation of `./install.sh` is to install the scripts to `/usr/local/bin` and also
add the required system configuration (sudoers, systemd-unit, wg-setup user). It expects a running
WireGuard interface to get the `ListenPort` from. To also setup the WireGuard interface (using `wg-setup-client`), run `./install.sh wireguard`.

Everything can be removed by running `./install.sh uninstall`.

```
$ sudo ./install.sh
$ systemctl enable --now wg-setup.service
```

A netcat to the TCP port identical to the UDP port of the WireGuard server should now prompt
for a token.

## wg-setup-client: Setup clients (with tokens)

This is kind of a companion script. Where `wg-setup` shall help managing larger WireGuard
networks, a large amount of clients has to be setup as well, naturally. `wg-setup-client`
works fine without tokens, but with tokens it will do everything, including a ping test.

Basic usage:
```bash
sudo ./wg-setup-client -e <server-endpoint> -p <server-pubkey> <ip-address> <token>
```

- If `<ip-address>` is specified without prefix-length, `/24` is used
- If `-e` or `-p` is missing, the values are queried interactively
- If `<token>` is omitted and `-t` is specified, the token is queried interactively, otherwise, token authentication is skipped
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
