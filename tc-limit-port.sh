#!/bin/bash
# Interactive tc bandwidth limit for Remnawave/Xray ports (no reverse proxy).
# Shared pool: all clients on that port together.
#
# Usage:
#   ./tc-limit-port.sh              # interactive
#   ./tc-limit-port.sh install 8443 10mbit
#   ./tc-limit-port.sh remove 8443
#   ./tc-limit-port.sh status [8443]
#   ./tc-limit-port.sh list

set -euo pipefail

IFACE="${IFACE:-}"
if [[ -z "$IFACE" ]]; then
  IFACE="$(ip -4 route show default 2>/dev/null | awk '{print $5; exit}')"
fi
if [[ -z "$IFACE" ]]; then
  echo "ERROR: cannot detect network interface. Set IFACE=ens1"
  ip -br a
  exit 1
fi

STATE_DIR="/var/lib/tc-limit-ports"
mkdir -p "$STATE_DIR"

ifb_name() {
  local p="$1"
  echo "ifb-p${p}"
}

remove_port() {
  local PORT="$1"
  local IFB
  IFB="$(ifb_name "$PORT")"

  # We use one HTB root per iface shared by all limited ports — rebuild without this port.
  # Simpler approach: remove ALL qdisc and re-apply remaining ports from state.
  rm -f "$STATE_DIR/${PORT}.rate"
  rebuild_all
  echo "OK: removed limit on port $PORT"
}

rebuild_all() {
  # wipe iface qdisc / all our ifbs
  tc qdisc del dev "$IFACE" root 2>/dev/null || true
  tc qdisc del dev "$IFACE" ingress 2>/dev/null || true

  local f port rate IFB
  for f in "$STATE_DIR"/*.rate; do
    [[ -e "$f" ]] || continue
    port="$(basename "$f" .rate)"
    IFB="$(ifb_name "$port")"
    tc qdisc del dev "$IFB" root 2>/dev/null || true
    ip link set dev "$IFB" down 2>/dev/null || true
    ip link delete "$IFB" type ifb 2>/dev/null || true
  done

  # also clean orphan ifb-p*
  for IFB in $(ip -o link show type ifb 2>/dev/null | awk -F': ' '{print $2}' | awk '{print $1}'); do
    case "$IFB" in
      ifb-p*) ip link delete "$IFB" type ifb 2>/dev/null || true ;;
    esac
  done

  local ports=()
  for f in "$STATE_DIR"/*.rate; do
    [[ -e "$f" ]] || continue
    ports+=("$(basename "$f" .rate)")
  done

  if [[ ${#ports[@]} -eq 0 ]]; then
    echo "No active port limits."
    return 0
  fi

  modprobe ifb 2>/dev/null || true

  # root HTB on main iface (egress)
  tc qdisc add dev "$IFACE" root handle 1: htb default 999
  tc class add dev "$IFACE" parent 1: classid 1:1 htb rate 10gbit ceil 10gbit
  tc class add dev "$IFACE" parent 1:1 classid 1:999 htb rate 10gbit ceil 10gbit

  # ingress redirect hub — one ingress qdisc, filters per port to own IFB
  tc qdisc add dev "$IFACE" handle ffff: ingress

  local idx=0
  local class_id ifb_handle
  for port in "${ports[@]}"; do
    rate="$(cat "$STATE_DIR/${port}.rate")"
    IFB="$(ifb_name "$port")"
    idx=$((idx + 1))
    class_id=$((10 + idx))
    ifb_handle=$((20 + idx))

    # egress class + filter (sport = server replies / client download)
    tc class add dev "$IFACE" parent 1:1 classid "1:${class_id}" \
      htb rate "$rate" ceil "$rate" burst 32k cburst 32k 2>/dev/null \
      || tc class add dev "$IFACE" parent 1:1 classid "1:${class_id}" \
           htb rate "$rate" ceil "$rate"
    tc qdisc add dev "$IFACE" parent "1:${class_id}" handle "${class_id}:" fq_codel
    tc filter add dev "$IFACE" protocol ip parent 1:0 prio "$idx" u32 \
      match ip sport "$port" 0xffff flowid "1:${class_id}"
    tc filter add dev "$IFACE" protocol ipv6 parent 1:0 prio $((100 + idx)) u32 \
      match ip6 sport "$port" 0xffff flowid "1:${class_id}"

    # ingress via IFB (dport = client upload)
    ip link add "$IFB" type ifb 2>/dev/null || true
    ip link set dev "$IFB" up
    tc filter add dev "$IFACE" parent ffff: protocol ip prio "$idx" u32 \
      match ip dport "$port" 0xffff \
      action mirred egress redirect dev "$IFB"
    tc filter add dev "$IFACE" parent ffff: protocol ipv6 prio $((100 + idx)) u32 \
      match ip6 dport "$port" 0xffff \
      action mirred egress redirect dev "$IFB"

    tc qdisc add dev "$IFB" root handle "${ifb_handle}:" htb default 30
    tc class add dev "$IFB" parent "${ifb_handle}:" classid "${ifb_handle}:1" htb rate 10gbit ceil 10gbit
    tc class add dev "$IFB" parent "${ifb_handle}:1" classid "${ifb_handle}:30" htb rate 10gbit ceil 10gbit
    tc class add dev "$IFB" parent "${ifb_handle}:1" classid "${ifb_handle}:10" \
      htb rate "$rate" ceil "$rate" burst 32k cburst 32k 2>/dev/null \
      || tc class add dev "$IFB" parent "${ifb_handle}:1" classid "${ifb_handle}:10" \
           htb rate "$rate" ceil "$rate"
    tc qdisc add dev "$IFB" parent "${ifb_handle}:10" handle "$((200 + idx)):" fq_codel
    tc filter add dev "$IFB" protocol ip parent "${ifb_handle}:0" prio 1 u32 \
      match ip dport "$port" 0xffff flowid "${ifb_handle}:10"
    tc filter add dev "$IFB" protocol ipv6 parent "${ifb_handle}:0" prio 2 u32 \
      match ip6 dport "$port" 0xffff flowid "${ifb_handle}:10"

    echo "  + port $port -> $rate (up+down shared) on $IFACE"
  done
}

install_port() {
  local PORT="$1"
  local RATE="$2"
  if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [[ "$PORT" -lt 1 || "$PORT" -gt 65535 ]]; then
    echo "ERROR: bad port: $PORT"
    exit 1
  fi
  if [[ -z "$RATE" ]]; then
    echo "ERROR: rate required (e.g. 10mbit, 5mbit, 1mbit)"
    exit 1
  fi
  # normalize: allow bare number as mbit
  if [[ "$RATE" =~ ^[0-9]+$ ]]; then
    RATE="${RATE}mbit"
  fi
  echo "$RATE" > "$STATE_DIR/${PORT}.rate"
  echo "Applying limits on $IFACE ..."
  rebuild_all
  echo "OK: port $PORT limited to $RATE"
}

list_limits() {
  echo "IFACE=$IFACE"
  local f port rate
  local any=0
  for f in "$STATE_DIR"/*.rate; do
    [[ -e "$f" ]] || continue
    any=1
    port="$(basename "$f" .rate)"
    rate="$(cat "$f")"
    echo "  port $port -> $rate"
  done
  if [[ "$any" -eq 0 ]]; then
    echo "  (no limits)"
  fi
}

status_port() {
  local PORT="${1:-}"
  list_limits
  echo
  echo "--- tc classes $IFACE ---"
  tc -s class show dev "$IFACE" 2>/dev/null || echo "(none)"
  if [[ -n "$PORT" ]]; then
    local IFB
    IFB="$(ifb_name "$PORT")"
    if ip link show "$IFB" &>/dev/null; then
      echo "--- tc classes $IFB ---"
      tc -s class show dev "$IFB"
    fi
  else
    local f port IFB
    for f in "$STATE_DIR"/*.rate; do
      [[ -e "$f" ]] || continue
      port="$(basename "$f" .rate)"
      IFB="$(ifb_name "$port")"
      if ip link show "$IFB" &>/dev/null; then
        echo "--- tc classes $IFB (port $port) ---"
        tc -s class show dev "$IFB"
      fi
    done
  fi
}

interactive() {
  echo "========================================"
  echo "  TC port limit  (iface: $IFACE)"
  echo "========================================"
  list_limits
  echo
  echo "1) Enable / change limit"
  echo "2) Disable limit"
  echo "3) Status"
  echo "4) List"
  echo "5) Exit"
  echo
  read -r -p "Choice [1-5]: " choice
  case "$choice" in
    1)
      read -r -p "Port (e.g. 8443): " port
      read -r -p "Limit (e.g. 10mbit or just 10): " rate
      install_port "$port" "$rate"
      ;;
    2)
      read -r -p "Port to disable: " port
      if [[ ! -f "$STATE_DIR/${port}.rate" ]]; then
        echo "No limit on port $port"
        exit 0
      fi
      remove_port "$port"
      ;;
    3)
      read -r -p "Port for details (Enter = all): " port
      status_port "$port"
      ;;
    4)
      list_limits
      ;;
    5|*)
      exit 0
      ;;
  esac
}

cmd="${1:-}"
case "$cmd" in
  "")
    interactive
    ;;
  install|add|on)
    install_port "${2:?port}" "${3:?rate}"
    ;;
  remove|off|disable)
    remove_port "${2:?port}"
    ;;
  status)
    status_port "${2:-}"
    ;;
  list)
    list_limits
    ;;
  rebuild)
    rebuild_all
    ;;
  *)
    echo "Usage:"
    echo "  $0                          # interactive"
    echo "  $0 install <port> <rate>    # e.g. install 8443 10mbit"
    echo "  $0 remove <port>"
    echo "  $0 status [port]"
    echo "  $0 list"
    exit 1
    ;;
esac
