#!/bin/bash
set -e

echo "==== Atualizando sistema ===="
sudo pacman -Syu --noconfirm

echo "==== Kernel otimizado ===="
sudo pacman -S --noconfirm linux-zen linux-zen-headers amd-ucode

echo "==== Xorg e utilitários ===="
sudo pacman -S --noconfirm \
xorg-server xorg-xinit xorg-xrandr xorg-xsetroot \
xdg-utils xclip xdo

echo "==== Drivers AMD ===="
sudo pacman -S --noconfirm mesa vulkan-radeon libva-mesa-driver mesa-vdpau

echo "==== Build tools e suckless deps ===="
sudo pacman -S --noconfirm base-devel git stow

echo "==== NetworkManager ===="
sudo pacman -S --noconfirm networkmanager network-manager-applet
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager

echo "==== Audio e PipeWire ===="
sudo pacman -S --noconfirm pipewire pipewire-pulse wireplumber pamixer

echo "==== Power Management e TLP ===="
sudo pacman -S --noconfirm tlp acpi
sudo systemctl enable tlp

# Limite de bateria 80%
sudo sed -i 's/^#START_CHARGE_THRESH_BAT0=.*/START_CHARGE_THRESH_BAT0=40/' /etc/tlp.conf
sudo sed -i 's/^#STOP_CHARGE_THRESH_BAT0=.*/STOP_CHARGE_THRESH_BAT0=80/' /etc/tlp.conf
sudo systemctl restart tlp

echo "==== zram e earlyoom ===="
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

echo "==== Compilando dwm power-user ===="
mkdir -p ~/src
cd ~/src
git clone https://git.suckless.org/dwm
cd dwm

# Adicionar patches simples: statusbar, vol/brightness control
# (statusbar via scripts separados)
sudo pacman -S --noconfirm acpi xorg-xrandr brightnessctl

# Copiar configuração customizada
cat <<EOF > config.h
/* Minimal dwm config com binds para ThinkPad */
static const char *fonts[] = { "monospace:size=10" };
static const char dmenufont[] = "monospace:size=10";

static const char *termcmd[]  = { "st", NULL };
static const char *browser[]  = { "firefox", NULL };

#include <X11/XF86keysym.h>
static Key keys[] = {
    /* modifier                     key        function        argument */
    { MODKEY,                       XK_Return, spawn,          {.v = termcmd } },
    { MODKEY,                       XK_b,      spawn,          {.v = browser } },
    /* volume up/down/mute */
    { 0, XF86XK_AudioRaiseVolume,    spawn, SHCMD("pamixer --allow-boost -i 5") },
    { 0, XF86XK_AudioLowerVolume,    spawn, SHCMD("pamixer --allow-boost -d 5") },
    { 0, XF86XK_AudioMute,           spawn, SHCMD("pamixer -t") },
    /* brightness up/down */
    { 0, XF86XK_MonBrightnessUp,     spawn, SHCMD("brightnessctl set +10%") },
    { 0, XF86XK_MonBrightnessDown,   spawn, SHCMD("brightnessctl set 10%-") },
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
exec dwm
EOF

echo "==== Criando script de statusbar ===="
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

echo ""
echo "==== INSTALAÇÃO POWER-USER COMPLETA ===="
echo "Reinicie o sistema e rode: startx"
