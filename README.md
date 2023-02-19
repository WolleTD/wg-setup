# wg-setup WireGuard Management

Trivial CLI tool to simplify WireGuard interface management.

Highlights:
* add and remove peers while keeping files and running interface configuration in sync
* list peers in condensed formats
* purely implemented in bash (which already is a dependency of `wg-quick`)
* works seamlessly with both `wg-quick` and `systemd-networkd` as interface backend
* adds a concept of "hostnames" to WireGuard peers that can also be used to remove peers
* uses existing configuration files, no additional services (hostnames are stored as simple comments)
* basic hook support for e.g. automatically updating a DNS zone

The `wg-setup-client` tool is used to setup WireGuard client (and server) interfaces.
It will use `systemd-networkd` if enabled, otherwise fallback to `wg-quick`.

## Examples

```
# Add a peer
$ wg-setup add-peer my-peer DX/sYzuD9AYsKegfLpklFboYAWLyxKoe7CU00g9iSzc= 172.16.10.2
[Peer]
# my-peer
# Added by root at 2020-05-20
PublicKey = DX/sYzuD9AYsKegfLpklFboYAWLyxKoe7CU00g9iSzc=
AllowedIPs = 172.16.10.2/32

Add this configuration to /etc/wireguard/wg0.conf? [Y/n]
$

# Remove a peer (using hostname, IP address or public key)
$ wg-setup remove-peer 172.16.10.2
[Peer]
# my-peer
# Added by root at 2020-05-20
PublicKey = DX/sYzuD9AYsKegfLpklFboYAWLyxKoe7CU00g9iSzc=
AllowedIPs = 172.16.10.2/32

Remove this configuration from /etc/wireguard/wg0.conf? [y/N]
$

# List registered peers
$ wg-setup list-peers pubkeys
172.16.10.2     my-peer         DX/sYzuD9AYsKegfLpklFboYAWLyxKoe7CU00g9iSzc=
$
```

## Installation

### Docker
See the [example](example) directory for how to use docker-compose to set up server and client.

### Server
```
$ git clone https://github.com/WolleTD/wg-setup.git && cd wg-setup

# To install wg-setup scripts and services
$ sudo ./install.sh

# To also configure a WireGuard server interface
$ sudo ./wg-setup-client --server [SERVER_IP] [LISTENING_PORT]
```

### Client
```
$ gpg --recv-keys FB9DA662
$ curl -O https://raw.githubusercontent.com/WolleTD/wg-setup/$ref/wg-setup-client
$ curl -O https://raw.githubusercontent.com/WolleTD/wg-setup/$ref/wg-setup-client.sig
$ gpg --verify wg-setup-client.sig && chmod +x wg-setup-client
...
gpg: Good signature ...
$ sudo ./wg-setup-client -e vpn.example.com:12345 -p Vq12...3a4= 172.16.1.10/16
...
============================================================
WireGuard setup successful! Server side add-peer command:
wg-setup add-peer my_hostname my_publickey 172.16.1.10
```

Paste the last line printed by `wg-setup-client` in a terminal on the server and you're done.

## Motivation

A WireGuard interface and thus a WireGuard server is usually configured in a file only editable
by root, also the running interface has to be restarted or configured separately to the file for
the change to take effect.
Doing this manually is tedious and error-prone, so `wg-setup` provides `add-peer` and `remove-peer`
commands to make this easier and safer.
`wg-setup` always updates both the interface and the backing configuration files and provides
an input validation layer for the file content.

While `wg-quick` supports an additional `SaveConfig` parameter, this only exports the running
interface configuration upon wg-quick shutdown, carrying the risk of losing new peer configuration
if the service or machine terminates abnormally.
Also, it simply doesn't work with `systemd-networkd` and that's what I wanted to use for my
WireGuard interfaces.

The next pain point of plain WireGuard is that there are no human-readable names assigned to peers.
So from the beginning, my tools added a comment line with a supplied hostname for each peer.
It's not tagged, it's just the first comment line in a `[Peer]` section.


`list-peers` provides a convenient way to export the client list into some other format.
Currently, three formats are supported:

* `hosts`: an `/etc/hosts`-like list of names and IP addresses
* `pubkeys`: like `hosts` but with the pubkeys in a third column
* `dns`: BIND zonefile format (only host lines, no header)

### Hooks

`wg-setup` provides a simple hook mechanism, which will call all executables in
`WG_SETUP_HOOK_DIR` (which defaults to `/etc/wg-setup`) with these arguments:
`added|removed <name> <public key> <allowed ips>`. This can be used to e.g. update
a condensed list of hosts or a DNS zone. The example hooks don't even use the
provided arguments, but simply call `list-peers` to get a full list each time.

## Setup clients with `wg-setup-client`

This is kind of a companion script. Where `wg-setup` shall help managing larger WireGuard
networks, a large amount of clients has to be setup as well.

Basic usage:
```bash
sudo ./wg-setup-client -e <server-endpoint> -p <server-pubkey> <ip-address>
```

- If `<ip-address>` is specified without prefix-length, `/24` is used
- If any of the three required parameters is missing, the values are queried interactively
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
