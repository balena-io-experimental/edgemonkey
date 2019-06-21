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
| `BANDWIDTH_MAX` | maximum bandwidth for wondershaper resets (in Kbps) | 9999999 |
| `CLEANUP_FREQ` | how often to generally remove limits/throttles/filters (in 1/x refreshes) | 4 |
| `DOWNLOAD_LIMIT` | global download bandwidth limit (in Kbps) | 500 |
| `FORCED_UPDATE_FREQ` | how often to force the supervisor to update the application (in 1/x refreshes) | 25 |
| `GLOBAL_REFRESH` | global refresh rate (in s) | 2 |
| `GLOBAL_TIMEOUT` | after N seconds (refresh rate * loop count), edgemonkey will clean up & sleep infinity (for debugging) (in s) | 0 |
| `LOCKFILE_FREQ` | how often to take the application lockfile (in 1/x refreshes) | 25 |
| `PACKET_DROP_FREQ` | how often to drop packets (in 1/x refreshes) | 25 |
| `PERC_DROP` | global percentage of traffic to drop (in %) | 5 |
| `RANDOM_SERVICE_RESTART_FREQ` | how often to restart one of the hostOS processes (in 1/x refreshes) | 25 |
| `RANDOM_SUBNET_FREQ` | how often to randomly block a subnet (in 1/x refreshes) | 25 |
| `THROTTLE_FREQ` | how often to throttle traffic (in 1/x refreshes) | 25 |
| `THROTTLE_VALUE` | global throttle value (in ms) | 250 |
| `UPLOAD_LIMIT` | global upload bandwidth limit (in Kbps) | 500 |

### Currently implemented tests
#### `global_throttle_traffic`
Throttle all traffic to $THROTTLE_VALUE

#### `global_drop_packets`
Drop $PERC_DROP packets indiscriminantly

#### `global_bandwidth_limit`
Limit either upload, download, or all bandwidth

#### `drop_random_subnet`
Drop all traffic to a randomly-generated subnet

#### `force_update`
Force an update from the supervisor (disregarding application locks)

#### `take_application_lock`
Take the application lock exclusively

#### `drop_dns`
Drop all UDP port 53 (DNS) traffic

#### `restart_supervisor`
Restart the `resin-supervisor` service in the hostOS via DBus

#### `restart_network`
Restart the `NetworkManager` service in the hostOS via DBus

#### `restart_dns`
Restart the `dnsmasq` service in the hostOS via DBus

#### `restart_timesync`
Restart the `chronyd` service in the hostOS via DBus

#### `restart_vpn`
Restart the `openvpn` service in the hostOS via DBus

#### `restart_engine`
Restart the `balena` service in the hostOS via DBus

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
* Time corruption (MiTM)
* Limit CPU frequency
* Log spamming
* Packet duplication (https://wiki.linuxfoundation.org/networking/netem)
* Packet corruption
* Packet reordering
