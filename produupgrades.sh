#!/bin/bash

# Проверка дистрибутива
if ! command -v lsb_release &> /dev/null || ! grep -qiP 'ubuntu|debian' /etc/os-release; then
    echo "Скрипт работает только на Debian/Ubuntu!"
    exit 1
fi

# Получение данных дистрибутива
DISTRO_ID=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
DISTRO_CODENAME=$(lsb_release -cs)

# Установка компонентов
sudo apt update
sudo apt install -y unattended-upgrades apt-listchanges

# Резервное копирование
BACKUP_DIR="/etc/apt/backup-$(date +%Y%m%d)"
sudo mkdir -p "$BACKUP_DIR"
sudo cp /etc/apt/apt.conf.d/50unattended-upgrades "$BACKUP_DIR" 2>/dev/null || true
sudo cp /etc/apt/apt.conf.d/20auto-upgrades "$BACKUP_DIR" 2>/dev/null || true

# Настройка 50unattended-upgrades
sudo tee /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null <<EOT
// Разрешить обновления безопасности и стабильные обновления
Unattended-Upgrade::Allowed-Origins {
    "${DISTRO_ID}:${DISTRO_CODENAME}-security";
    "${DISTRO_ID}:${DISTRO_CODENAME}-updates";
};

// Базовый чёрный список
Unattended-Upgrade::Package-Blacklist {
    "linux-image-*";
    "linux-headers-*";
    "nvidia-*";
    "zfs-*";
};

// Дополнительные настройки
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Mail "admin@example.com";
EOT

# Настройка 20auto-upgrades
sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null <<EOT
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOT

# Интерактивное добавление пакетов
CONFIG_FILE="/etc/apt/apt.conf.d/50unattended-upgrades"

echo "Текущий чёрный список:"
grep -A 15 'Package-Blacklist' "$CONFIG_FILE" | tail -n +2 | grep -v '};'

read -p "Добавить пакеты в чёрный список? (y/N): " answer

if [[ "$answer" =~ [yY] ]]; then
    read -p "Введите пакеты через пробел: " packages
    
    # Валидация и добавление
    for pkg in $packages; do
        if [[ ! "$pkg" =~ ^[a-z0-9.+-]+$ ]]; then
            echo "Ошибка: '$pkg' - некорректное имя!"
            exit 1
        fi
        sudo sed -i "/Package-Blacklist {/a\ \ \ \ \"$pkg\";" "$CONFIG_FILE"
    done
    
    echo -e "\nОбновлённый чёрный список:"
    grep -A 15 'Package-Blacklist' "$CONFIG_FILE" | tail -n +2 | grep -v '};'
fi

# Финал
echo -e "\n\033[32mНастройка завершена! Проверка:\033[0m"
sudo unattended-upgrades --dry-run --debug