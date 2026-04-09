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
    MSG_DOCKER_CHECK="Docker is already installed. Reinstall? (y/n)"
    MSG_SKIP_DOCKER="Skipping Docker installation."
    MSG_INSTALL_DOCKER="Installing Docker..."
    MSG_REMOVE_OLD="Removing old Docker versions, if any"
    MSG_START_DOCKER="Starting Docker..."
    MSG_DOCKER_UNCHANGED="Docker left unchanged."
    MSG_BBR="Configuring BBR for network optimization..."
    MSG_REMNANODE="Installing RemnaNode..."
    MSG_COMPLETE="Installation completed!"
    MSG_REBOOT="If the system was updated, a reboot may be required (check with sudo reboot if needed)."
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
    MSG_DOCKER_CHECK="Docker уже установлен. Переустановить? (y/n)"
    MSG_SKIP_DOCKER="Пропускаем установку Docker."
    MSG_INSTALL_DOCKER="Установка Docker..."
    MSG_REMOVE_OLD="# Удаление старых версий Docker, если есть"
    MSG_START_DOCKER="Запуск Docker..."
    MSG_DOCKER_UNCHANGED="Docker оставлен без изменений."
    MSG_BBR="Настройка BBR для оптимизации сети..."
    MSG_REMNANODE="Установка RemnaNode..."
    MSG_COMPLETE="Установка завершена!"
    MSG_REBOOT="Если система была обновлена, возможно, потребуется перезагрузка (проверьте с sudo reboot если нужно)."
;;
esac

echo "$MSG_NODE_PORT"
read -r NODE_PORT
case "$NODE_PORT" in
"")
    NODE_PORT=2222
;;
esac

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

echo "$MSG_UPDATE"
$SUDO_CMD apt update && $SUDO_CMD apt upgrade -y

# Настройки интерфейса (пример: установка и настройка Xfce для GUI, если нужно)
# Если вам нужен GUI, раскомментируйте следующие строки:
# sudo apt install -y xfce4 xfce4-goodies
# echo "Настройка интерфейса завершена."

# Инициализация переменной
skip_docker=false

# Проверка Docker
if command -v docker >/dev/null 2>&1; then
    echo "$MSG_DOCKER_CHECK"
    read -r response
    case "$response" in
    [yY])
    ;;
    *)
        echo "$MSG_SKIP_DOCKER"
        skip_docker=true
    ;;
    esac
fi

case "$skip_docker" in
true)
    echo "$MSG_DOCKER_UNCHANGED"
;;
*)
    echo "$MSG_INSTALL_DOCKER"
    # Удаление старых версий Docker, если есть
    $SUDO_CMD apt remove -y docker docker-engine docker.io containerd runc || true

    # Установка Docker
    $SUDO_CMD apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO_CMD gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | $SUDO_CMD tee /etc/apt/sources.list.d/docker.list > /dev/null
    $SUDO_CMD apt update
    $SUDO_CMD apt install -y docker-ce docker-ce-cli containerd.io

    echo "$MSG_START_DOCKER"
    $SUDO_CMD systemctl start docker
    $SUDO_CMD systemctl enable docker
;;
esac

echo "$MSG_BBR"
$SUDO_CMD sysctl -w net.core.default_qdisc=fq
$SUDO_CMD sysctl -w net.ipv4.tcp_congestion_control=bbr
echo "net.core.default_qdisc=fq" | $SUDO_CMD tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" | $SUDO_CMD tee -a /etc/sysctl.conf
$SUDO_CMD sysctl -p

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

cd /opt/remnanode && $SUDO_CMD docker compose up -d


echo "$MSG_COMPLETE"
echo "$MSG_REBOOT"