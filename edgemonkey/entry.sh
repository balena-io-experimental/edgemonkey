#!/bin/bash

trap cleanup EXIT INT HUP

INTERFACE="$(ip addr | awk '/'"$(curl -sq -X GET --header "Content-Type:application/json" \
"${BALENA_SUPERVISOR_ADDRESS}/v1/device?apikey=${BALENA_SUPERVISOR_API_KEY}" | jq -r .ip_address)"'/{print $NF}')"

# come from ENV
# values
CHAOS=${CHAOS:-true} # bool
GLOBAL_TIMEOUT=${GLOBAL_TIMEOUT:-0} # s
GLOBAL_REFRESH=${GLOBAL_REFRESH:-2} # s
THROTTLE=${THROTTLE_VALUE:-250} # ms
UPLOAD_LIMIT=${UPLOAD_LIMIT:-500} # Kbps
DOWNLOAD_LIMIT=${DOWNLOAD_LIMIT:-500} # Kbps
PERC_DROP=${PERC_DROP:-5} # %
TC_CORRELATION=${TC_CORRELATION:-25} # %
BANDWIDTH_MAX=${BANDWIDTH_MAX:-9999999} # Kbps

# frequencies
THROTTLE_FREQ=${THROTTLE_FREQ:-25}
PACKET_DROP_FREQ=${PACKET_DROP_FREQ:-25}
DNS_DROP_FREQ=${DNS_DROP_FREQ:-25}
SUPERVISOR_RESTART_FREQ=${SUPERVISOR_RESTART_FREQ:-25}
BANDWIDTH_LIMIT_FREQ=${BANDWIDTH_LIMIT_FREQ:-25}

function global_throttle_traffic() {
    echo "throttling traffic globally to ${THROTTLE}.."
    tc qdisc replace dev "${INTERFACE}" root netem delay "${THROTTLE}ms" "$(( THROTTLE / 10 ))ms" "${TC_CORRELATION}%"
    echo "Throttle applied"
}

function global_drop_packets() {
    echo "dropping ${PERC_DROP}% of packets routed to ${INTERFACE}.."
    tc qdisc replace dev "${INTERFACE}" root netem loss "${PERC_DROP}%" "${TC_CORRELATION}%"
    echo "Packet drop applied"
}

function global_restore_packet_drop() {
    echo "removing global packet loss to ${INTERFACE}.."
    tc qdisc replace dev "${INTERFACE}" root netem loss 0%
    echo "Packet loss removed"
}

function global_restore_throttle() {
    echo "undoing global throttle.."
    tc qdisc replace dev "${INTERFACE}" root netem delay 0ms
    echo "Throttle undone"
}

function restart_supervisor() {
    echo "restarting supervisor.."
    # some dbus commands to restart stuff
    echo "Supervisor restarted"
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

function drop_dns() {
    echo "dropping all DNS traffic.."
    iptables -A OUTPUT -p udp -m udp --dport 53 -j DROP -m comment --comment "DNS_DROP_OUT"
    iptables -A INPUT -p udp -m udp --dport 53 -j DROP -m comment --comment "DNS_DROP_IN"
    echo "DNS filters applied"
}

function global_restore_bandwidth(){
    echo "removing all bandwidth limits.."
    wondershaper "${INTERFACE}" clear
}

function global_limit_bandwidth(){
    RAND="${RANDOM}"
    if [ $(( RAND % 3 )) -eq 0 ]; then
        echo "limiting upload and download bandwidth.."
        wondershaper "${INTERFACE}" "${UPLOAD_LIMIT}" "${DOWNLOAD_LIMIT}"
    elif [ $(( RAND % 3 )) -eq 1 ]; then
        echo "limiting ONLY download bandwidth.."
        wondershaper "${INTERFACE}" "${BANDWIDTH_MAX}" "${DOWNLOAD_LIMIT}"
    elif [ $(( RAND % 3 )) -eq 2 ]; then
        echo "limiting ONLY upload bandwidth.."
        wondershaper "${INTERFACE}" "${UPLOAD_LIMIT}" "${BANDWIDTH_MAX}"
    fi
}

function restore_dns() {
    echo "restoring DNS traffic.."
    comment="DNS_DROP"
    RAND="${1:-$RANDOM}"
    if [ $(( RAND % 3 )) -eq 0 ]; then
        echo "restoring ALL DNS traffic.."
        iptables-save | grep -v "${comment}" | iptables-restore
    elif [ $(( RAND % 3 )) -eq 1 ]; then
        echo "restoring INBOUND DNS traffic.."
        iptables-save | grep -v "${comment}_IN" | iptables-restore
    elif [ $(( RAND % 3 )) -eq 2 ]; then
        echo "restoring OUTBOUND DNS traffic.."
        iptables-save | grep -v "${comment}_OUT" | iptables-restore
    fi
    echo "DNS filters removed"
}

function cleanup() {
    # passing a 0 restores all DNS traffic
    restore_dns 0
    global_restore_packet_drop
    global_restore_bandwidth
    global_restore_throttle
}

echo "INTERFACE set to ${INTERFACE}"

# initialize some states
dns_drop_applied=false
global_traffic_throttled=false
global_bandwidth_limited=false
global_packet_drop=false
global_iter_count=0

while "${CHAOS}" ; do
    RAND="${RANDOM}"
    if [ $(( RAND % DNS_DROP_FREQ )) -eq 0 ]; then
        if $dns_drop_applied; then
            dns_drop_applied=false
            restore_dns
        else
            dns_drop_applied=true
            drop_dns
        fi
    elif [ $(( RAND % PACKET_DROP_FREQ )) -eq 1 ]; then
        if $global_packet_drop; then
            global_packet_drop=false
            global_restore_packet_drop
        else
            global_packet_drop=true
            global_drop_packets
        fi
    elif [ $(( RAND % BANDWIDTH_LIMIT_FREQ )) -eq 2 ]; then
        if $global_bandwidth_limited; then
            global_bandwidth_limited=false
            global_restore_bandwidth
        else
            global_bandwidth_limited=true
            global_limit_bandwidth
        fi
    elif [ $(( RAND % THROTTLE_FREQ )) -eq 3 ]; then
        if $global_traffic_throttled; then
            global_traffic_throttled=false
            global_restore_throttle
        else
            global_traffic_throttled=true
            global_throttle_traffic
        fi
    elif [ $(( RAND % SUPERVISOR_RESTART_FREQ )) -eq 4 ]; then
        restart_supervisor
    fi
    global_iter_count=$(( global_iter_count + 1 ))
    if [[ $GLOBAL_TIMEOUT -gt 0 ]]; then
        if [[ $(( global_iter_count * GLOBAL_REFRESH )) -ge $GLOBAL_TIMEOUT ]]; then
            echo "global limit reached, suspending actions after cleanup"
            cleanup
            echo "sleeping indefinitely"
            sleep infinity
        else
            sleep "${GLOBAL_REFRESH}"
        fi
    else
        sleep "${GLOBAL_REFRESH}"
    fi
done
