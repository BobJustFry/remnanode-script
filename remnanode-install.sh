#!/bin/bash
 
# Скрипт установщика для Ubuntu
# Настройки интерфейса, установка Docker и дополнительного софта

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

set -e  # Остановить скрипт при ошибке

# Определение команды для sudo
case "$EUID" in
0)
   SUDO_CMD=""
;;
*)
   SUDO_CMD="sudo"
;;
esac

echo "Choose language / Выберите язык:"
echo "1. English"
echo "2. Русский"
read -r lang

# Инициализация переменных
skip_update=false
skip_docker=false
skip_mtu=false
additional_ports_input=""
install_mode="1"
clean_install=false
reconfigure_only=false

case "$lang" in
1)
    MSG_NODE_PORT="Enter NODE_PORT (default 2222):"
    MSG_SECRET="Enter SECRET_KEY for RemnaNode:"
    MSG_SECRET_EMPTY="SECRET_KEY not entered or empty. Enter again? (y/n)"
    MSG_CANCEL="Installation canceled."
    MSG_UPDATE="Updating system..."
    MSG_GUI_COMMENT="# Interface settings (example: install and configure Xfce for GUI, if needed)"
    MSG_GUI_UNCOMMENT="# If you need GUI, uncomment the following lines:"
    MSG_GUI_COMPLETE="# Interface setup completed."
    MSG_DOCKER_CHECK="Docker is already installed. Perform a clean reinstall? (y/n)"
    MSG_DOCKER_CLEAN="Removing Docker for clean reinstall..."
    MSG_SKIP_DOCKER="Skipping Docker installation."
    MSG_INSTALL_DOCKER="Installing Docker..."
    MSG_REMOVE_OLD="Removing old Docker versions, if any"
    MSG_START_DOCKER="Starting Docker..."
    MSG_DOCKER_UNCHANGED="Docker left unchanged."
    MSG_DOCKER_CONTAINERS_FOUND="The following Docker containers were found and may conflict with the new installation:"
    MSG_DOCKER_CONTAINERS_REMOVE="It is recommended to remove them before continuing. Remove all containers and their data (volumes, images)? (y/n)"
    MSG_DOCKER_CONTAINERS_REMOVED="All Docker containers, volumes and images removed."
    MSG_DOCKER_CONTAINERS_UNCHANGED="Docker containers left unchanged."
    MSG_DOCKER_NO_CONTAINERS="No Docker containers found."
    MSG_NGINX_FOUND="Nginx is already installed. Remove it for a clean install? (y/n)"
    MSG_NGINX_REMOVED="Nginx removed."
    MSG_NGINX_UNCHANGED="Nginx left unchanged."
    MSG_CADDY_FOUND="Caddy is already installed. Remove it for a clean install? (y/n)"
    MSG_CADDY_REMOVED="Caddy removed."
    MSG_CADDY_UNCHANGED="Caddy left unchanged."
    MSG_IPV6="Disabling IPv6..."
    MSG_BBR="Configuring BBR for network optimization..."
    MSG_PORTS="Checking required ports..."
    MSG_PORT_ALREADY_OPEN="Port already open"
    MSG_PORT_OPENED="Port opened"
    MSG_FIREWALL_NOT_FOUND="No supported firewall tool found. Skipping port configuration."
    MSG_FIREWALL_INACTIVE="Firewall is not active. Skipping port configuration."
    MSG_PORTS_DONE="Port check completed."
    MSG_MODE_SELECT="Select mode:"
    MSG_MODE_0="0) Exit"
    MSG_MODE_1="1) Full install"
    MSG_MODE_2="2) Open ports only (no reinstall)"
    MSG_MODE_3="3) Clean reinstall (remove old data)"
    MSG_MODE_4="4) Update parameters only"
    MSG_MODE_INVALID="Invalid mode selected. Full install will be used."
    MSG_ADDITIONAL_PORTS="Enter additional node ports (comma-separated), or leave empty:"
    MSG_PORTS_ONLY_START="Running in ports-only mode."
    MSG_SAVED_NODE_PORT_FOUND="Found NODE_PORT from existing installation"
    MSG_SAVED_NODE_PORT_NOT_FOUND="NODE_PORT from existing installation was not found. Using default 2222."
    MSG_NO_VALID_PORTS="No valid ports provided. Skipping port changes."
    MSG_PORT_22_UNCHANGED="SSH port 22 is already open. Leaving it unchanged"
    MSG_CLEAN_REINSTALL="Running clean reinstall: removing old RemnaNode data..."
    MSG_RECONFIGURE_ONLY="Running parameter update mode (without clean reinstall)."
    MSG_REMNANODE="Installing RemnaNode..."
    MSG_COMPLETE="Installation completed!"
    MSG_UPDATE_CONFIRM="Update and upgrade system packages? (y/n)"
    MSG_SKIP_UPDATE="Skipping system update."
    MSG_REBOOT="If the system was updated, a reboot may be required (check with sudo reboot if needed)."
    MSG_MTU_CONFIRM="Set MTU to 1450 for hosts using DDoS protection? (y/n)"
    MSG_SKIP_MTU="Skipping MTU configuration."
;;
*)
    MSG_NODE_PORT="Введите NODE_PORT (по умолчанию 2222):"
    MSG_SECRET="Введите SECRET_KEY для RemnaNode:"
    MSG_SECRET_EMPTY="SECRET_KEY не введен или пустой. Ввести еще раз? (y/n)"
    MSG_CANCEL="Установка отменена."
    MSG_UPDATE="Обновление системы..."
    MSG_GUI_COMMENT="# Настройки интерфейса (пример: установка и настройка Xfce для GUI, если нужно)"
    MSG_GUI_UNCOMMENT="# Если вам нужен GUI, раскомментируйте следующие строки:"
    MSG_GUI_COMPLETE="# Настройка интерфейса завершена."
    MSG_DOCKER_CHECK="Docker уже установлен. Выполнить чистую переустановку? (y/n)"
    MSG_DOCKER_CLEAN="Удаление Docker для чистой переустановки..."
    MSG_SKIP_DOCKER="Пропускаем установку Docker."
    MSG_INSTALL_DOCKER="Установка Docker..."
    MSG_REMOVE_OLD="Удаление старых версий Docker, если есть"
    MSG_START_DOCKER="Запуск Docker..."
    MSG_DOCKER_UNCHANGED="Docker оставлен без изменений."
    MSG_DOCKER_CONTAINERS_FOUND="Обнаружены следующие Docker-контейнеры, которые могут помешать новой установке:"
    MSG_DOCKER_CONTAINERS_REMOVE="Рекомендуется удалить их перед продолжением. Удалить все контейнеры и их данные (тома, образы)? (y/n)"
    MSG_DOCKER_CONTAINERS_REMOVED="Все Docker-контейнеры, тома и образы удалены."
    MSG_DOCKER_CONTAINERS_UNCHANGED="Docker-контейнеры оставлены без изменений."
    MSG_DOCKER_NO_CONTAINERS="Docker-контейнеры не найдены."
    MSG_NGINX_FOUND="Nginx уже установлен. Удалить для чистой установки? (y/n)"
    MSG_NGINX_REMOVED="Nginx удалён."
    MSG_NGINX_UNCHANGED="Nginx оставлен без изменений."
    MSG_CADDY_FOUND="Caddy уже установлен. Удалить для чистой установки? (y/n)"
    MSG_CADDY_REMOVED="Caddy удалён."
    MSG_CADDY_UNCHANGED="Caddy оставлен без изменений."
    MSG_IPV6="Отключение IPv6..."
    MSG_BBR="Настройка BBR для оптимизации сети..."
    MSG_PORTS="Проверка необходимых портов..."
    MSG_PORT_ALREADY_OPEN="Порт уже открыт"
    MSG_PORT_OPENED="Порт открыт"
    MSG_FIREWALL_NOT_FOUND="Поддерживаемый фаервол не найден. Пропускаем настройку портов."
    MSG_FIREWALL_INACTIVE="Фаервол не активен. Пропускаем настройку портов."
    MSG_PORTS_DONE="Проверка портов завершена."
    MSG_MODE_SELECT="Выберите режим:"
    MSG_MODE_0="0) Выход"
    MSG_MODE_1="1) Полная установка"
    MSG_MODE_2="2) Только открыть порты (без переустановки)"
    MSG_MODE_3="3) Чистая переустановка (удалить старые данные)"
    MSG_MODE_4="4) Только изменение параметров"
    MSG_MODE_INVALID="Выбран неверный режим. Будет использована полная установка."
    MSG_ADDITIONAL_PORTS="Введите дополнительные порты ноды (через запятую) или оставьте пустым:"
    MSG_PORTS_ONLY_START="Запуск в режиме только открытия портов."
    MSG_SAVED_NODE_PORT_FOUND="Найден NODE_PORT из существующей установки"
    MSG_SAVED_NODE_PORT_NOT_FOUND="NODE_PORT из существующей установки не найден. Используется 2222 по умолчанию."
    MSG_NO_VALID_PORTS="Валидные порты не указаны. Пропускаем изменение портов."
    MSG_PORT_22_UNCHANGED="SSH порт 22 уже открыт. Оставляем без изменений"
    MSG_CLEAN_REINSTALL="Запуск чистой переустановки: удаляем старые данные RemnaNode..."
    MSG_RECONFIGURE_ONLY="Запуск режима изменения параметров (без чистой переустановки)."
    MSG_REMNANODE="Установка RemnaNode..."
    MSG_COMPLETE="Установка завершена!"
    MSG_UPDATE_CONFIRM="Обновить и апгрейдить пакеты системы? (y/n)"
    MSG_SKIP_UPDATE="Пропускаем обновление системы."
    MSG_REBOOT="Если система была обновлена, возможно, потребуется перезагрузка (проверьте с sudo reboot если нужно)."
    MSG_MTU_CONFIRM="Установить MTU в 1450 для хостов, использующих защиту от DDoS-атак? (y/n)"
    MSG_SKIP_MTU="Пропускаем настройку MTU."
;;
esac

normalize_port_list() {
    local input="$1"
    local out=""
    local token

    input=${input//,/ }

    for token in $input; do
        token=$(printf '%s\n' "$token" | tr -d '[:space:]')
        if [[ -z "$token" ]]; then
            continue
        fi

        if [[ "$token" =~ ^[0-9]+$ ]] && [ "$token" -ge 1 ] && [ "$token" -le 65535 ]; then
            case " $out " in
            *" $token "*)
                ;;
            *)
                out="$out $token"
                ;;
            esac
        fi
    done

    printf '%s\n' "$out"
}

get_installed_node_port() {
    local compose_file="/opt/remnanode/docker-compose.yml"

    if [ ! -f "$compose_file" ]; then
        return
    fi

    awk -F= '/NODE_PORT=/{
        port=$2
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", port)
        if (port != "") {
            print port
            exit
        }
    }' "$compose_file"
}

ensure_port_open() {
    local port="$1"
    local proto
    local ufw_status

    if command -v ufw >/dev/null 2>&1; then
        ufw_status=$($SUDO_CMD ufw status 2>/dev/null || true)
        if printf '%s\n' "$ufw_status" | grep -qi "Status: active"; then
            for proto in tcp udp; do
                if printf '%s\n' "$ufw_status" | grep -Eq "^[[:space:]]*${port}/${proto}[[:space:]]+ALLOW"; then
                    if [ "$port" = "22" ]; then
                        echo "$MSG_PORT_22_UNCHANGED: ${port}/${proto}"
                    else
                        echo "$MSG_PORT_ALREADY_OPEN: ${port}/${proto}"
                    fi
                else
                    $SUDO_CMD ufw allow "${port}/${proto}"
                    echo "$MSG_PORT_OPENED: ${port}/${proto}"
                fi
            done
            return
        fi
        echo "$MSG_FIREWALL_INACTIVE"
        return
    fi

    if command -v firewall-cmd >/dev/null 2>&1; then
        if $SUDO_CMD firewall-cmd --state >/dev/null 2>&1; then
            for proto in tcp udp; do
                if $SUDO_CMD firewall-cmd --query-port="${port}/${proto}" >/dev/null 2>&1; then
                    if [ "$port" = "22" ]; then
                        echo "$MSG_PORT_22_UNCHANGED: ${port}/${proto}"
                    else
                        echo "$MSG_PORT_ALREADY_OPEN: ${port}/${proto}"
                    fi
                else
                    $SUDO_CMD firewall-cmd --permanent --add-port="${port}/${proto}" >/dev/null
                    echo "$MSG_PORT_OPENED: ${port}/${proto}"
                fi
            done
            $SUDO_CMD firewall-cmd --reload >/dev/null
            return
        fi
        echo "$MSG_FIREWALL_INACTIVE"
        return
    fi

    if command -v iptables >/dev/null 2>&1; then
        for proto in tcp udp; do
            if $SUDO_CMD iptables -C INPUT -p "$proto" --dport "$port" -j ACCEPT >/dev/null 2>&1; then
                if [ "$port" = "22" ]; then
                    echo "$MSG_PORT_22_UNCHANGED: ${port}/${proto}"
                else
                    echo "$MSG_PORT_ALREADY_OPEN: ${port}/${proto}"
                fi
            else
                $SUDO_CMD iptables -I INPUT -p "$proto" --dport "$port" -j ACCEPT
                echo "$MSG_PORT_OPENED: ${port}/${proto}"
            fi
        done
        return
    fi

    echo "$MSG_FIREWALL_NOT_FOUND"
}

open_node_ports() {
    local base_port="$1"
    local extra_ports="$2"
    local ports
    local port

    ports=$(normalize_port_list "$base_port $extra_ports")
    if [ -z "${ports// /}" ]; then
        echo "$MSG_NO_VALID_PORTS"
        return
    fi

    echo "$MSG_PORTS"
    for port in $ports; do
        ensure_port_open "$port"
    done
    echo "$MSG_PORTS_DONE"
}

echo "$MSG_MODE_SELECT"
echo "$MSG_MODE_0"
echo "$MSG_MODE_1"
echo "$MSG_MODE_2"
echo "$MSG_MODE_3"
echo "$MSG_MODE_4"
read -r install_mode
case "$install_mode" in
0)
    echo "$MSG_CANCEL"
    exit 0
    ;;
1|2|3|4)
    ;;
*)
    echo "$MSG_MODE_INVALID"
    install_mode="1"
    ;;
esac

if [ "$install_mode" = "2" ]; then
    saved_node_port=$(get_installed_node_port)
    if [ -z "$saved_node_port" ]; then
        saved_node_port=2222
        echo "$MSG_SAVED_NODE_PORT_NOT_FOUND"
    else
        echo "$MSG_SAVED_NODE_PORT_FOUND: $saved_node_port"
    fi

    echo "$MSG_ADDITIONAL_PORTS"
    read -r additional_ports_input

    echo "$MSG_PORTS_ONLY_START"
    open_node_ports "$saved_node_port" "$additional_ports_input"
    exit 0
fi

if [ "$install_mode" = "3" ]; then
    clean_install=true
fi

if [ "$install_mode" = "4" ]; then
    reconfigure_only=true
    echo "$MSG_RECONFIGURE_ONLY"
fi

echo "$MSG_MTU_CONFIRM"
read -r response
case "$response" in
[yY])
    $SUDO_CMD netplan set ethernets.eth0.mtu=1450 && $SUDO_CMD netplan apply
;;
*)
    echo "$MSG_SKIP_MTU"
;;
esac

echo "$MSG_NODE_PORT"
read -r NODE_PORT
case "$NODE_PORT" in
"")
    NODE_PORT=2222
;;
esac

echo "$MSG_ADDITIONAL_PORTS"
read -r additional_ports_input

echo "$MSG_SECRET"
read -r SECRET_KEY

while [[ -z "$SECRET_KEY" ]]; do
    echo "$MSG_SECRET_EMPTY"
    read -r response
    case "$response" in
    [yY])
        echo "$MSG_SECRET"
        read -r SECRET_KEY
    ;;
    *)
        echo "$MSG_CANCEL"
        exit 1
    ;;
    esac
done

echo "$MSG_UPDATE_CONFIRM"
read -r response
case "$response" in
[yY])
    $SUDO_CMD apt update && $SUDO_CMD apt upgrade -y
;;
*)
    echo "$MSG_SKIP_UPDATE"
    skip_update=true
;;
esac

# Настройки интерфейса (пример: установка и настройка Xfce для GUI, если нужно)
# Если вам нужен GUI, раскомментируйте следующие строки:
# sudo apt install -y xfce4 xfce4-goodies
# echo "Настройка интерфейса завершена."

if ! $reconfigure_only; then
    # Проверка Nginx
    if command -v nginx >/dev/null 2>&1; then
        echo "$MSG_NGINX_FOUND"
        read -r response
        case "$response" in
        [yY])
            $SUDO_CMD systemctl stop nginx 2>/dev/null || true
            $SUDO_CMD apt-get remove --purge -y nginx nginx-common nginx-full nginx-core 2>/dev/null || true
            $SUDO_CMD apt-get autoremove -y
            echo "$MSG_NGINX_REMOVED"
        ;;
        *)
            echo "$MSG_NGINX_UNCHANGED"
        ;;
        esac
    fi

    # Проверка Caddy
    if command -v caddy >/dev/null 2>&1; then
        echo "$MSG_CADDY_FOUND"
        read -r response
        case "$response" in
        [yY])
            $SUDO_CMD systemctl stop caddy 2>/dev/null || true
            $SUDO_CMD apt-get remove --purge -y caddy 2>/dev/null || true
            $SUDO_CMD apt-get autoremove -y
            echo "$MSG_CADDY_REMOVED"
        ;;
        *)
            echo "$MSG_CADDY_UNCHANGED"
        ;;
        esac
    fi

    # Проверка Docker
    if command -v docker >/dev/null 2>&1; then
        # Проверка наличия контейнеров
        CONTAINERS=$($SUDO_CMD docker ps -a --format '{{.Names}}\t{{.Image}}\t{{.Status}}' 2>/dev/null)
        if [[ -n "$CONTAINERS" ]]; then
            echo "$MSG_DOCKER_CONTAINERS_FOUND"
            echo "$CONTAINERS"
            echo "$MSG_DOCKER_CONTAINERS_REMOVE"
            read -r response
            case "$response" in
            [yY])
                $SUDO_CMD docker stop $($SUDO_CMD docker ps -q) 2>/dev/null || true
                $SUDO_CMD docker rm -f $($SUDO_CMD docker ps -aq) 2>/dev/null || true
                $SUDO_CMD docker volume rm $($SUDO_CMD docker volume ls -q) 2>/dev/null || true
                $SUDO_CMD docker rmi -f $($SUDO_CMD docker images -q) 2>/dev/null || true
                echo "$MSG_DOCKER_CONTAINERS_REMOVED"
            ;;
            *)
                echo "$MSG_DOCKER_CONTAINERS_UNCHANGED"
            ;;
            esac
        else
            echo "$MSG_DOCKER_NO_CONTAINERS"
        fi

        echo "$MSG_DOCKER_CHECK"
        read -r response
        case "$response" in
        [yY])
            echo "$MSG_DOCKER_CLEAN"
            $SUDO_CMD systemctl stop docker 2>/dev/null || true
            $SUDO_CMD apt-get remove --purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker.io 2>/dev/null || true
            $SUDO_CMD apt-get autoremove -y
            skip_docker=false
        ;;
        *)
            echo "$MSG_DOCKER_UNCHANGED"
            skip_docker=true
        ;;
        esac
    fi
else
    if command -v docker >/dev/null 2>&1; then
        skip_docker=true
    else
        skip_docker=false
    fi
fi

case "$skip_docker" in
true)
    : # Docker left as-is
;;
*)
    echo "$MSG_INSTALL_DOCKER"
    if ! command -v curl >/dev/null 2>&1; then
        $SUDO_CMD apt update
        $SUDO_CMD apt install -y curl
    fi
    curl -fsSL https://get.docker.com | $SUDO_CMD sh

    echo "$MSG_START_DOCKER"
    $SUDO_CMD systemctl start docker
    $SUDO_CMD systemctl enable docker
;;
esac

if $reconfigure_only; then
    $SUDO_CMD systemctl restart docker 2>/dev/null || $SUDO_CMD systemctl start docker
    $SUDO_CMD systemctl enable docker
fi

ensure_sysctl_setting() {
    local key="$1"
    local value="$2"
    local file="/etc/sysctl.conf"
    local duplicates
    local key_escaped

    echo "${key}=${value}" | $SUDO_CMD tee -a "$file" > /dev/null

    duplicates=$($SUDO_CMD awk -F= -v target_key="$key" '
    {
        current_key=$1
        gsub(/[[:space:]]/, "", current_key)
        if (current_key ~ /^#/) {
            next
        }
        if (current_key == target_key) {
            count++
        }
    }
    END {
        print count+0
    }
    ' "$file")

    if [ "$duplicates" -gt 1 ]; then
        key_escaped=$(printf '%s\n' "$key" | sed 's/[.[\*^$()+?{|]/\\&/g')
        $SUDO_CMD sed -i "/^[[:space:]]*${key_escaped}[[:space:]]*=/d" "$file"
        echo "${key}=${value}" | $SUDO_CMD tee -a "$file" > /dev/null
    fi
}

echo "$MSG_IPV6"
$SUDO_CMD sysctl -w net.ipv6.conf.all.disable_ipv6=1
$SUDO_CMD sysctl -w net.ipv6.conf.default.disable_ipv6=1
$SUDO_CMD sysctl -w net.ipv6.conf.lo.disable_ipv6=1
ensure_sysctl_setting "net.ipv6.conf.all.disable_ipv6" "1"
ensure_sysctl_setting "net.ipv6.conf.default.disable_ipv6" "1"
ensure_sysctl_setting "net.ipv6.conf.lo.disable_ipv6" "1"

echo "$MSG_BBR"
$SUDO_CMD sysctl -w net.core.default_qdisc=fq
$SUDO_CMD sysctl -w net.ipv4.tcp_congestion_control=bbr
ensure_sysctl_setting "net.core.default_qdisc" "fq"
ensure_sysctl_setting "net.ipv4.tcp_congestion_control" "bbr"
$SUDO_CMD sysctl -p

open_node_ports "$NODE_PORT" "$additional_ports_input"

if $clean_install; then
    echo "$MSG_CLEAN_REINSTALL"
    if [ -f /opt/remnanode/docker-compose.yml ]; then
        cd /opt/remnanode && $SUDO_CMD docker compose down -v --remove-orphans 2>/dev/null || true
    fi
    $SUDO_CMD docker rm -f remnanode 2>/dev/null || true
    $SUDO_CMD rm -rf /opt/remnanode
fi

echo "$MSG_REMNANODE"
$SUDO_CMD mkdir -p /opt/remnanode
$SUDO_CMD chmod 755 /opt/remnanode
$SUDO_CMD tee /opt/remnanode/docker-compose.yml > /dev/null <<EOF
version: '3.8'
services:
  remnanode:
    container_name: remnanode
    hostname: remnanode
    image: remnawave/node:latest
    network_mode: host
    restart: always
    cap_add:
      - NET_ADMIN
    ulimits:
      nofile:
        soft: 1048576
        hard: 1048576
    environment:
      - NODE_PORT=$NODE_PORT
      - SECRET_KEY=$SECRET_KEY
EOF

$SUDO_CMD chmod 644 /opt/remnanode/docker-compose.yml

cd /opt/remnanode && $SUDO_CMD docker compose up -d --force-recreate


echo "$MSG_COMPLETE"
echo "$MSG_REBOOT"