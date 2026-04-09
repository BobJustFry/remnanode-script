# RemnaNode Installer

## Описание / Description

### РУ
Автоматизированный скрипт установщика для развертывания RemnaNode на Ubuntu Linux. Скрипт выполняет полную настройку системы, включая обновление ОС, установку Docker, оптимизацию сети с помощью BBR, и развертывание контейнера RemnaNode.

### EN
An automated installer script for deploying RemnaNode on Ubuntu Linux. The script performs complete system configuration, including OS updates, Docker installation, network optimization with BBR, and RemnaNode container deployment.

---

## Требования к системе / System Requirements

### Минимальные требования / Minimum Requirements
- **ОС / OS**: Ubuntu 20.04 LTS или выше / Ubuntu 20.04 LTS or higher
- **Рекомендуемая версия / Recommended Version**: **Ubuntu 24.04 LTS**
- **Процессор / CPU**: 1 ядро минимум / 1 core minimum
- **ОЗУ / RAM**: 2 GB минимум / 2 GB minimum
- **Место на диске / Disk Space**: 10 GB минимум / 10 GB minimum
- **Интернет / Internet**: Стабильное подключение / Stable connection

### Поддерживаемые системы / Supported Systems
- Ubuntu 24.04 LTS (Recommended / Рекомендуется)
- Ubuntu 22.04 LTS
- Ubuntu 20.04 LTS
- Debian 12 (Bookworm)
- Debian 11 (Bullseye)
- Linux Mint (на основе Ubuntu / Ubuntu-based)

### Тестирование / Testing
✅ Проверено на / Tested on: **Ubuntu 24.04 LTS**

## Запуск прямо с GitHub / Run Directly from GitHub

### РУ
Можно запустить скрипт напрямую с GitHub без предварительного скачивания:

```bash
curl -L -o install.sh https://raw.githubusercontent.com/BobJustFry/remnanode-script/main/remnanode-install.sh && sudo bash install.sh
```

Если хотите сначала скачать файл и проверить перед запуском:

```bash
curl -fsSL -o remnanode-install.sh https://raw.githubusercontent.com/BobJustFry/remnanode-script/main/remnanode-install.sh
chmod +x remnanode-install.sh
sudo ./remnanode-install.sh
```

### EN
You can run the script directly from GitHub without downloading it first:

```bash
curl -L -o install.sh https://raw.githubusercontent.com/BobJustFry/remnanode-script/main/remnanode-install.sh && sudo bash install.sh
```

If you prefer to download and verify the file first:

```bash
curl -fsSL -o remnanode-install.sh https://raw.githubusercontent.com/BobJustFry/remnanode-script/main/remnanode-install.sh
chmod +x remnanode-install.sh
sudo ./remnanode-install.sh
```
---

## Что делает скрипт / What the Script Does

1. **Обновление системы / System Update**
   - Обновляет пакеты и ядро системы
   - Updates system packages and kernel

2. **Установка Docker / Docker Installation**
   - Проверяет наличие Docker и предлагает переустановку
   - Устанавливает Docker CE из официального репозитория
   - Checks for Docker and offers reinstallation option
   - Installs Docker CE from official repository

3. **Настройка BBR / BBR Configuration**
   - Включает алгоритм BBR для оптимизации сети
   - Улучшает пропускную способность и снижает задержку
   - Enables BBR algorithm for network optimization
   - Improves bandwidth and reduces latency

4. **Развертывание RemnaNode / RemnaNode Deployment**
   - Создает директорию `/opt/remnanode`
   - Генерирует `docker-compose.yml` с вашими параметрами
   - Запускает контейнер RemnaNode
   - Creates `/opt/remnanode` directory
   - Generates `docker-compose.yml` with your parameters
   - Starts RemnaNode container

---

## Использование / Usage

### Запуск скрипта / Running the Script

```bash
chmod +x remnanode-install.sh
sudo ./remnanode-install.sh
```

### Интерактивные параметры / Interactive Parameters

При запуске скрипт попросит ввести:

1. **Язык / Language**: Выберите English (1) или Русский (2)
2. **NODE_PORT**: Порт для RemnaNode (по умолчанию 2222)
3. **SECRET_KEY**: Секретный ключ для RemnaNode (обязательно)

### Пример / Example

```
Choose language / Выберите язык:
1. English
2. Русский
2

Введите NODE_PORT (по умолчанию 2222):
2222

Введите SECRET_KEY для RemnaNode:
your_secret_key_here

```

---

## Возможности / Features

- ✅ Поддержка двух языков (English & Русский) / Support for two languages (English & Russian)
- ✅ Автоматическая установка Docker с проверкой / Automatic Docker installation with checking
- ✅ Оптимизация сети с BBR / Network optimization with BBR
- ✅ Валидация SECRET_KEY (не может быть пустым) / SECRET_KEY validation (cannot be empty)
- ✅ Динамические параметры NODE_PORT / Dynamic NODE_PORT parameters
- ✅ Проверка на низкие лимиты файлов (ulimit) / File descriptor limits check (ulimit)
- ✅ Автоматический перезапуск контейнера / Automatic container restart
- ✅ Автоматическая работа с правами доступа (root или sudo) / Automatic permissions handling (root or sudo)

---

## После установки / After Installation

### Проверка статуса контейнера / Check Container Status

```bash
sudo docker ps -a | grep remnanode
```

### Просмотр логов / View Logs

```bash
sudo docker logs remnanode
```

### Остановка контейнера / Stop Container

```bash
sudo docker stop remnanode
```

### Удаление контейнера / Remove Container

```bash
sudo docker rm remnanode
```

---

## Переменные окружения / Environment Variables

В `docker-compose.yml` используются две основные переменные:

- **NODE_PORT**: Порт для доступа к RemnaNode (по умолчанию 2222)
- **SECRET_KEY**: Секретный ключ для аутентификации

---

## Оптимизация BBR / BBR Optimization

BBR (Bottleneck Bandwidth and Round-trip time) — это алгоритм управления перегруженностью TCP, который:
- Увеличивает пропускную способность
- Снижает задержку (latency)
- Улучшает качество соединения

Применяется автоматически без перезагрузки.

---

## Требования к пользователю / User Requirements

- Доступ к учетной записи root или sudo
- Root/sudo account access
- Стабильное интернет-соединение
- Stable internet connection
- Минимальные знания Linux
- Basic Linux knowledge

---

## Решение проблем / Troubleshooting

### Проблема: Docker не устанавливается
**Решение / Solution**: Убедитесь, что интернет-соединение стабильно и у вас есть доступ sudo.

### Проблема: Ошибка при запуске контейнера
**Решение / Solution**: Проверьте логи: `sudo docker logs remnanode`

### Проблема: Порт 2222 уже используется
**Решение / Solution**: Введите другой порт при запуске скрипта.

---

## Лицензия / License

Этот скрипт предоставляется как есть для установки RemnaNode.

---

## Контакты / Contact

Для вопросов и поддержки обратитесь к документации RemnaNode.

---

**Рекомендуемая версия Ubuntu: 24.04 LTS**
**Recommended Ubuntu Version: 24.04 LTS**
