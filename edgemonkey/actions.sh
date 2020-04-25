#!/bin/bash

function log() {
    if [ "${DEBUG}" -eq 1 ]; then
        echo "$@"
    fi
}

function log() {
    if [ "${DEBUG}" -eq 1 ]; then
        echo "$@"
    fi
}

INTERFACE="$(ip addr | awk '/'"$(curl -sq -X GET --header "Content-Type:application/json" \
"${BALENA_SUPERVISOR_ADDRESS}/v1/device?apikey=${BALENA_SUPERVISOR_API_KEY}" | jq -r .ip_address)"'/{print $NF}')"
DATA_DIR="/data"
FILL_FILE="edgemonkey.fill"

THROTTLE=${THROTTLE_VALUE:-250} # ms
UPLOAD_LIMIT=${UPLOAD_LIMIT:-500} # Kbps
DOWNLOAD_LIMIT=${DOWNLOAD_LIMIT:-500} # Kbps
PERC_DROP=${PERC_DROP:-5} # %
TC_CORRELATION=${TC_CORRELATION:-25} # %
BANDWIDTH_MAX=${BANDWIDTH_MAX:-9999999} # Kbps

function global_throttle_traffic() {
    log "throttling traffic globally to ${THROTTLE}.."
    tc qdisc replace dev "${INTERFACE}" root netem delay "${THROTTLE}ms" "$(( THROTTLE / 10 ))ms" "${TC_CORRELATION}%"
    log "Throttle applied"
}

function global_drop_packets() {
    log "dropping ${PERC_DROP}% of packets routed to ${INTERFACE}.."
    tc qdisc replace dev "${INTERFACE}" root netem loss "${PERC_DROP}%" "${TC_CORRELATION}%"
    log "Packet drop applied"
}

function global_restore_packet_drop() {
    log "removing global packet loss to ${INTERFACE}.."
    tc qdisc replace dev "${INTERFACE}" root netem loss 0%
    log "Packet loss removed"
}

function global_restore_throttle() {
    log "undoing global throttle.."
    tc qdisc replace dev "${INTERFACE}" root netem delay 0ms
    log "Throttle undone"
}

function restart_unit(){
    log "restarting $1.."
    DBUS_SYSTEM_BUS_ADDRESS=unix:path=/host/run/dbus/system_bus_socket dbus-send --system --print-reply \
    --dest=org.freedesktop.systemd1 /org/freedesktop/systemd1 org.freedesktop.systemd1.Manager.RestartUnit string:"$1" \
    string:"replace"
    log "$1 restarted.."
}

function restart_supervisor() {
    restart_unit "resin-supervisor.service"
}

function restart_vpn() {
    restart_unit "openvpn.service"
}

function restart_network() {
    restart_unit "NetworkManager.service"
}

function restart_dns() {
    restart_unit "dnsmasq.service"
}

function restart_timesync() {
    restart_unit "chronyd.service"
}

function restart_engine() {
    restart_unit "balena.service"
}

function force_update(){
    log "forcing an app update from the supervisor..."
    curl -X POST --header "Content-Type:application/json" \
    --data '{"force": true}' \
    "$BALENA_SUPERVISOR_ADDRESS/v1/update?apikey=$BALENA_SUPERVISOR_API_KEY"
}

function restart_app() {
    curl -X POST --header "Content-Type:application/json" \
    --data "{\"appId\": $1}" \
    "${BALENA_SUPERVISOR_ADDRESS}/v1/restart?apikey=${BALENA_SUPERVISOR_API_KEY}"
}

function stop_app() {
    curl -X POST --header "Content-Type:application/json" \
    "${BALENA_SUPERVISOR_ADDRESS}/v1/apps/$1/stop?apikey=${BALENA_SUPERVISOR_API_KEY}"
}

function restart_all_apps() {
    curl -X POST --header "Content-Type:application/json" \
    --data "{\"appId\": $1}" \
    "${BALENA_SUPERVISOR_ADDRESS}/v1/restart?apikey=${BALENA_SUPERVISOR_API_KEY}"
}

function drop_vpn() {
    log "dropping all VPN traffic.."
    iptables -A OUTPUT -p tcp --dport 443 -j DROP -m comment --comment "VPN_DROP_OUT"
    iptables -A INPUT -p tcp --dport 443 -j DROP -m comment --comment "VPN_DROP_IN"
    log "VPN filters applied"
}

function drop_dns() {
    log "dropping all DNS traffic.."
    iptables -A OUTPUT -p udp -m udp --dport 53 -j DROP -m comment --comment "DNS_DROP_OUT"
    iptables -A INPUT -p udp -m udp --dport 53 -j DROP -m comment --comment "DNS_DROP_IN"
    log "DNS filters applied"
}

function drop_random_subnet() {
    random_subnet="$(( RANDOM % 256 )).$(( RANDOM % 256 )).$(( RANDOM % 256 )).$(( RANDOM % 256 ))/$(( (RANDOM % 24)+8))"
    log "dropping all traffic to $random_subnet.."
    iptables -A OUTPUT -j DROP -s "$random_subnet" -m comment --comment "RANDOM_SUBNET_OUT"
    iptables -A INPUT -j DROP -s "$random_subnet" -m comment --comment "RANDOM_SUBNET_IN"
    log "Traffic to $random_subnet dropped"
}

function restore_random_subnets() {
    log "restoring random subnet traffic.."
    comment="RANDOM_SUBNET"
    RAND="${1:-$RANDOM}"
    case "$(( RAND % 3 ))" in
        "0")
            log "restoring ALL random subnet traffic.."
            iptables-save | grep -v "${comment}" | iptables-restore
            ;;
        "1")
            log "restoring INBOUND random subnet traffic.."
            iptables-save | grep -v "${comment}_IN" | iptables-restore
            ;;
        "2")
            log "restoring OUTBOUND random subnet traffic.."
            iptables-save | grep -v "${comment}_OUT" | iptables-restore
            ;;
    esac
    log "random subnet filters removed"
}

function global_restore_bandwidth(){
    log "removing all bandwidth limits.."
    wondershaper "${INTERFACE}" clear
}

function fill_random_data_dir(){
    victim_dir=$(find "${DATA_DIR}" -mindepth 1 -maxdepth 1 | shuf -n1)
    size=$(df -lBM --output=avail "${victim_dir}" | awk '/^[0-9]./')
    log "creating ${size} edgemonkey fill file in ${victim_dir}.."
    fallocate -l "${size}" "${victim_dir}/${FILL_FILE}"
    log "created fill file"
}

function remove_fill_files(){
    log "removing all fill files from ${DATA_DIR}.."
    rm -f "${DATA_DIR}/*/${FILL_FILE}"
    log "removed fill files"
}

function global_limit_bandwidth(){
    RAND="${RANDOM}"
    case "$(( RAND % 3 ))" in
        "0")
            log "limiting upload and download bandwidth.."
            wondershaper "${INTERFACE}" "${UPLOAD_LIMIT}" "${DOWNLOAD_LIMIT}"
            ;;
        "1")
            log "limiting ONLY download bandwidth.."
            wondershaper "${INTERFACE}" "${BANDWIDTH_MAX}" "${DOWNLOAD_LIMIT}"
            ;;
        "2")
            log "limiting ONLY upload bandwidth.."
            wondershaper "${INTERFACE}" "${UPLOAD_LIMIT}" "${BANDWIDTH_MAX}"
            ;;
    esac
}

function restore_vpn() {
    log "restoring VPN traffic.."
    comment="VPN_DROP"
    RAND="${1:-$RANDOM}"
    case "$(( RAND % 3 ))" in
        "0")
            log "restoring ALL VPN traffic.."
            iptables-save | grep -v "${comment}" | iptables-restore
            ;;
        "1")
            log "restoring INBOUND VPN traffic.."
            iptables-save | grep -v "${comment}_IN" | iptables-restore
            ;;
        "2")
            log "restoring OUTBOUND VPN traffic.."
            iptables-save | grep -v "${comment}_OUT" | iptables-restore
            ;;
    esac
    log "VPN filters removed"
}

function restore_dns() {
    log "restoring DNS traffic.."
    comment="DNS_DROP"
    RAND="${1:-$RANDOM}"
    case "$(( RAND % 3 ))" in
        "0")
            log "restoring ALL DNS traffic.."
            iptables-save | grep -v "${comment}" | iptables-restore
            ;;
        "1")
            log "restoring INBOUND DNS traffic.."
            iptables-save | grep -v "${comment}_IN" | iptables-restore
            ;;
        "2")
            log "restoring OUTBOUND DNS traffic.."
            iptables-save | grep -v "${comment}_OUT" | iptables-restore
            ;;
    esac
    log "DNS filters removed"
}

function take_application_lock() {
    log "taking lock at $BALENA_APP_LOCK_PATH"
    lockfile-create --lock-name "$BALENA_APP_LOCK_PATH"
    log "took lock at $BALENA_APP_LOCK_PATH"
}

function remove_application_lock() {
    log "removing lock at $BALENA_APP_LOCK_PATH"
    if lockfile-remove --lock-name "$BALENA_APP_LOCK_PATH"; then
        log "removed lock at $BALENA_APP_LOCK_PATH"
    else
        log "could not remove lock at $BALENA_APP_LOCK_PATH, owned by pid $(cat "$BALENA_APP_LOCK_PATH")"
    fi
}

function cleanup() {
    # passing a 0 restores all DNS traffic
    remove_fill_files
    restore_dns 0
    restore_vpn 0
    restore_random_subnets 0
    global_restore_packet_drop
    global_restore_bandwidth
    global_restore_throttle
    remove_application_lock
}
