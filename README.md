# edgemonkey
## On-device chaos for edge resilience

### Use
To apply this to your container, simply drop the [`docker-compose.yml`](./docker-compose.yml) snippet application's
`docker-compose.yml` file and [`edgemonkey`](./edgemonkey) directory into your app's root and push to a LOCAL TEST
DEVICE.

You can then trigger any test or fix individually by POSTing to the API:

```shell
curl -XPOST http://316d17c.local/v1/drop_dns
```

Alternatively, you can trigger chaos mode by POSTing:

```shell
curl -XPOST http://316d17c.local/v1/chaos
```

This mode will create chaos according to a thresholded Poisson distribution. The distribution and filter parameters can
be controlled with the following environment variables:

| Variable | Description | Default value |
| ------- | ------ | ----- |
| `LOOP_TIME_MS` | total time to create chaos (in ms) | 60000 |
| `LAMBDA_VALUE` | lambda used in Poisson distribution | 4 |
| `FILTER_VALUE` | values from Poisson above which to cause chaos | 5 |
| `TIME_SLICES` | how many times to test within the `LOOP_TIME_MS` | 20 |

### Configuration options (via environment variables)

| Variable | Description | Default value |
| ------- | ------ | ----- |
| `EDGEMONKEY_PORT` | port to listen on | 9000 |
| `BANDWIDTH_MAX` | maximum bandwidth for wondershaper resets (in Kbps) | 9999999 |
| `DOWNLOAD_LIMIT` | global download bandwidth limit (in Kbps) | 500 |
| `GLOBAL_REFRESH` | global refresh rate (in s) | 2 |
| `GLOBAL_TIMEOUT` | after N seconds (refresh rate * loop count), edgemonkey will clean up & sleep infinity (for debugging) (in s) | 0 |
| `PERC_DROP` | global percentage of traffic to drop (in %) | 5 |
| `THROTTLE_VALUE` | global throttle value (in ms) | 250 |
| `UPLOAD_LIMIT` | global upload bandwidth limit (in Kbps) | 500 |

### Currently implemented tests
#### `global_throttle_traffic`
Throttle all traffic to ${THROTTLE_VALUE}

#### `global_drop_packets`
Drop ${PERC_DROP} packets indiscriminately

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

#### `fill_random_data_dir`
Fill a random volume provided with nothing (to test disk fill events)

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
