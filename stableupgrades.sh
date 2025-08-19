#!/bin/bash
set -euo pipefail

# Проверка дистрибутива
if ! grep -qiE 'ubuntu|debian' /etc/os-release; then
    echo "Скрипт работает только на Debian/Ubuntu!"
    exit 1
fi

DISTRO_ID=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
DISTRO_CODENAME=$(lsb_release -cs)
CONFIG_FILE="/etc/apt/apt.conf.d/50unattended-upgrades"
BACKUP_DIR="/etc/apt/backup-$(date +%Y%m%d)"

# Установка пакетов
sudo apt update && sudo apt install -y unattended-upgrades apt-listchanges

# Бэкап конфигов
sudo mkdir -p "$BACKUP_DIR"
for f in 50unattended-upgrades 20auto-upgrades; do
    [[ -f /etc/apt/apt.conf.d/$f ]] && sudo cp /etc/apt/apt.conf.d/$f "$BACKUP_DIR"/
done

# Запись конфигураций
sudo tee "$CONFIG_FILE" > /dev/null <<EOT
Unattended-Upgrade::Allowed-Origins {
    "${DISTRO_ID}:${DISTRO_CODENAME}-security";
    "${DISTRO_ID}:${DISTRO_CODENAME}-updates";
};
Unattended-Upgrade::Package-Blacklist {
    "linux-image-*";
    "linux-headers-*";
    "zfs-*";
};
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Mail "admin@example.com";
EOT

sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null <<'EOT'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOT

# Добавление пакетов в чёрный список
echo "Текущий чёрный список:"
grep -A 15 'Package-Blacklist' "$CONFIG_FILE" | grep -vE '};|Package-Blacklist'

read -rp "Добавить пакеты в чёрный список? (y/N): " answer
if [[ "$answer" =~ ^[yY]$ ]]; then
    read -rp "Введите пакеты через пробел: " packages
    for pkg in $packages; do
        [[ "$pkg" =~ ^[a-z0-9.+-]+$ ]] || { echo "Ошибка: '$pkg' - некорректное имя!"; exit 1; }
        sudo sed -i "/Package-Blacklist {/a\    \"$pkg\";" "$CONFIG_FILE"
    done
    echo -e "\nОбновлённый чёрный список:"
    grep -A 15 'Package-Blacklist' "$CONFIG_FILE" | grep -vE '};|Package-Blacklist'
fi

# Завершение
echo -e "\n\033[32mНастройка завершена! Проверка:\033[0m"
sudo unattended-upgrades --dry-run --debug
