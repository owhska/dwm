#!/bin/bash
set -e

echo "==== Atualizando sistema ===="
sudo pacman -Syu --noconfirm

echo "==== Instalando kernel otimizado ===="
sudo pacman -S --noconfirm linux-zen linux-zen-headers amd-ucode

echo "==== Instalando Xorg ===="
sudo pacman -S --noconfirm \
xorg-server \
xorg-xinit \
xorg-xrandr \
xorg-xsetroot

echo "==== Drivers AMD ===="
sudo pacman -S --noconfirm \
mesa \
vulkan-radeon \
libva-mesa-driver \
mesa-vdpau

echo "==== Ambiente suckless ===="
sudo pacman -S --noconfirm \
dwm \
dmenu \
st

echo "==== Compositor ===="
sudo pacman -S --noconfirm picom

echo "==== Audio moderno ===="
sudo pacman -S --noconfirm \
pipewire \
pipewire-pulse \
wireplumber

echo "==== Ferramentas essenciais ===="
sudo pacman -S --noconfirm \
neovim \
ranger \
htop \
fastfetch \
git \
base-devel \
wget \
curl \
unzip

echo "==== Power management ===="
sudo pacman -S --noconfirm tlp
sudo systemctl enable tlp

echo "==== CPU tools ===="
sudo pacman -S --noconfirm cpupower
sudo systemctl enable cpupower

echo "==== Instalando zram ===="
sudo pacman -S --noconfirm zram-generator

sudo mkdir -p /etc/systemd/zram-generator.conf.d

sudo bash -c 'cat <<EOF > /etc/systemd/zram-generator.conf.d/zram.conf
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF'

echo "==== Instalando earlyoom ===="
sudo pacman -S --noconfirm earlyoom
sudo systemctl enable earlyoom

echo "==== Instalando yay (AUR helper) ===="
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm

echo "==== Criando .xinitrc ===="
cat <<EOF > ~/.xinitrc
picom &
exec dwm
EOF

echo "==== Configurando picom ===="
mkdir -p ~/.config/picom

cat <<EOF > ~/.config/picom/picom.conf
backend = "glx";
vsync = true;
shadow = false;
fading = false;
EOF

echo "==== Configurando CPU performance ===="
sudo bash -c 'cat <<EOF > /etc/default/cpupower
governor="performance"
EOF'

echo "==== Instalação finalizada ===="
echo ""
echo "Reinicie o sistema."
echo "Depois rode:"
echo "startx"
