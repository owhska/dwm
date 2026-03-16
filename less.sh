#!/bin/bash
set -e

echo "==== Atualizando sistema ===="
sudo pacman -Syu --noconfirm

echo "==== Kernel Zen + microcode AMD ===="
sudo pacman -S --noconfirm linux-zen linux-zen-headers amd-ucode

echo "==== Configurando systemd-boot (EFI) ===="
sudo bootctl --path=/boot install
sudo mkdir -p /boot/loader/entries
sudo bash -c 'cat <<EOF > /boot/loader/loader.conf
default arch.conf
timeout 2
EOF'

sudo bash -c 'cat <<EOF > /boot/loader/entries/arch.conf
title   Arch Linux Zen
linux   /vmlinuz-linux-zen
initrd  /amd-ucode.img
initrd  /initramfs-linux-zen.img
options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/nvme0n1p2) rw quiet splash
EOF'

echo "==== Instalando Xorg e utilitários ===="
sudo pacman -S --noconfirm xorg-server xorg-xinit xorg-xrandr xorg-xsetroot xdg-utils xclip xdo

echo "==== Drivers AMD ===="
sudo pacman -S --noconfirm mesa vulkan-radeon libva-mesa-driver mesa-vdpau

echo "==== Ferramentas base ===="
sudo pacman -S --noconfirm base-devel git stow wget curl unzip neovim ranger htop fastfetch

echo "==== Rede ===="
sudo pacman -S --noconfirm networkmanager network-manager-applet
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager

echo "==== Audio moderno ===="
sudo pacman -S --noconfirm pipewire pipewire-pulse wireplumber pamixer

echo "==== Power management ===="
sudo pacman -S --noconfirm tlp acpi brightnessctl
sudo systemctl enable tlp

# Limite bateria 80%
sudo sed -i 's/^#START_CHARGE_THRESH_BAT0=.*/START_CHARGE_THRESH_BAT0=79/' /etc/tlp.conf
sudo sed -i 's/^#STOP_CHARGE_THRESH_BAT0=.*/STOP_CHARGE_THRESH_BAT0=80/' /etc/tlp.conf
sudo systemctl restart tlp

echo "==== zram + earlyoom ===="
sudo pacman -S --noconfirm zram-generator earlyoom
sudo systemctl enable earlyoom
sudo mkdir -p /etc/systemd/zram-generator.conf.d
sudo bash -c 'cat <<EOF > /etc/systemd/zram-generator.conf.d/zram.conf
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF'

echo "==== CPU governor performance ===="
sudo pacman -S --noconfirm cpupower
sudo systemctl enable cpupower
sudo bash -c 'cat <<EOF > /etc/default/cpupower
governor="performance"
EOF'

echo "==== Instalando yay (AUR helper) ===="
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd ~
rm -rf /tmp/yay

echo "==== Configurando layout de teclado BR ThinkPad ===="
sudo localectl set-keymap br-thinkpad

echo "==== Instalando tema Adwaita-dark ===="
sudo pacman -S --noconfirm gnome-themes-extra

echo "==== Compilando dwm power-user ===="
mkdir -p ~/src
cd ~/src
git clone https://git.suckless.org/dwm
cd dwm

sudo pacman -S --noconfirm acpi xorg-xrandr

cat <<EOF > config.h
#include <X11/XF86keysym.h>
static const char *fonts[] = { "monospace:size=10" };
static const char dmenufont[] = "monospace:size=10";
static const char *termcmd[]  = { "st", NULL };
static const char *browser[]  = { "firefox", NULL };

static Key keys[] = {
    { MODKEY, XK_Return, spawn, {.v = termcmd } },
    { MODKEY, XK_b, spawn, {.v = browser } },
    /* Volume keys */
    { 0, XF86XK_AudioRaiseVolume, spawn, SHCMD("pamixer --allow-boost -i 5") },
    { 0, XF86XK_AudioLowerVolume, spawn, SHCMD("pamixer --allow-boost -d 5") },
    { 0, XF86XK_AudioMute, spawn, SHCMD("pamixer -t") },
    /* Brightness keys */
    { 0, XF86XK_MonBrightnessUp, spawn, SHCMD("brightnessctl set +10%") },
    { 0, XF86XK_MonBrightnessDown, spawn, SHCMD("brightnessctl set 10%-") },
};
EOF

sudo make clean install
cd ~
rm -rf ~/src/dwm

echo "==== Configurando .xinitrc ===="
mkdir -p ~/.config/dwm
cat <<EOF > ~/.xinitrc
nm-applet &
picom &
~/.dwm/scripts/statusbar.sh &
export GTK_THEME=Adwaita:dark
setxkbmap -model thinkpad -layout br -variant thinkpad
exec dwm
EOF

echo "==== Criando statusbar ===="
mkdir -p ~/.dwm/scripts
cat <<'EOF' > ~/.dwm/scripts/statusbar.sh
#!/bin/bash
while true; do
  CPU=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print int(usage)"%"}')
  MEM=$(free -h | awk '/^Mem:/ {print $3 "/" $2}')
  BAT=$(cat /sys/class/power_supply/BAT0/capacity)%
  VOL=$(pamixer --get-volume-human)
  xsetroot -name "CPU:$CPU | MEM:$MEM | BAT:$BAT | VOL:$VOL"
  sleep 1
done
EOF
chmod +x ~/.dwm/scripts/statusbar.sh

echo "==== Instalando picom ===="
sudo pacman -S --noconfirm picom

echo "==== Criando script de atualização automática Arch + AUR ===="
mkdir -p ~/scripts
cat <<'EOF' > ~/scripts/update_arch.sh
#!/bin/bash
sudo pacman -Syu --noconfirm
yay -Syu --noconfirm
EOF
chmod +x ~/scripts/update_arch.sh

echo ""
echo "==== INSTALL FINAL EXTREMO COMPLETO ===="
echo "Reinicie o sistema e rode: startx"
echo "Atualize o sistema com: ~/scripts/update_arch.sh"
