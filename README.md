# edgemonkey
## On-device chaos for edge resilience

### Use
To apply this to your container, simply drop the (`docker-compose.yml`)[./docker-compose.yml] snippet application's
`docker-compose.yml` file and [`edgemonkey`](./edgemonkey) directory into your app's root and push to a LOCAL TEST
DEVICE.

While the tests are running, observe your application and device to confirm things are functioning as expected!

Stopping the edgemonkey (or sending `KILL`/`HUP`/`STOP` signals) will clean up and reset all settings, though it is
still recommended that one has **PHYSICAL ACCESS** to the device in case things go awry.

### Configuration options (via environment variables)

| Variable | Description | Default value |
| ------- | ------ | ----- |
| `CHAOS` | if set, prevent the chaos engine from starting up (for debugging) | unset |
| `GLOBAL_TIMEOUT` | after N seconds (refresh rate * loop count), edgemonkey will clean up & sleep infinity (for debugging) (in s) | 0 |
| `GLOBAL_REFRESH` | global refresh rate (in s) | 2 |
| `THROTTLE_VALUE` | global throttle value (in ms) | 250 |
| `PERC_DROP` | global percentage of traffic to drop (in %) | 5 |
| `DOWNLOAD_LIMIT` | global download bandwidth limit (in Kbps) | 500 |
| `UPLOAD_LIMIT` | global upload bandwidth limit (in Kbps) | 500 |
| `THROTTLE_FREQ` | how often to throttle traffic (in 1/x refreshes) | 25 |
| `PACKET_DROP_FREQ` | how often to drop packets (in 1/x refreshes) | 25 |
| `DNS_DROP_FREQ` | how often to block DNS traffic (in 1/x refreshes) | 25 |
| `SUPERVISOR_RESTART_FREQ` | how often to restart the supervisor (in 1/x refreshes) | 25 |
| `BANDWIDTH_MAX` | maximum bandwidth for wondershaper resets (in Kbps) | 9999999 |

### Currently implemented tests
#### `global_throttle_traffic`
Throttle all traffic to $THROTTLE_VALUE

#### `global_drop_packets`
Drop $PERC_DROP packets indiscriminantly

#### `global_bandwidth_limit`
Limit either upload, download, or all bandwidth

#### `drop_dns`
Drop all UDP port 53 (DNS) traffic

#### `restart_supervisor`
Not yet implemented

#### `restart_app`
Not yet implemented

#### `stop_app`
Not yet implemented

#### `restart_all_apps`
Not yet implemented

### Planned expansion tests
* Network partitions with iptables
* Memory exhaustion
* Disk space exhaustion
* Service-specific bandwidth throttling (DNS, NTP, HTTP, VPN, etc)
* Disk I/O throttling
* Time corruption (MITM)
* Limit CPU frequency
* Drop LAN traffic
* Drop WAN traffic
* Log spamming
* Packet duplication https://wiki.linuxfoundation.org/networking/netem
* Packet corruption https://wiki.linuxfoundation.org/networking/netem
* Packet reordering https://wiki.linuxfoundation.org/networking/netem
