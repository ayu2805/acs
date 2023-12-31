#!/bin/sh

if [ "$(id -u)" = 0 ]; then
    echo "######################################################################"
    echo "This script should NOT be run as root user as it may create unexpected"
    echo " problems and you may have to reinstall Arch. So run this script as a"
    echo "  normal user. You will be asked for a sudo password when necessary"
    echo "######################################################################"
    exit 1
fi

read -p "Enter your Full Name: " fn
if [ -n "$fn" ]; then
    un=$(whoami)
    sudo chfn -f "$fn" "$un"
else
    echo ""
fi
sudo cp pacman.conf /etc/
sudo mkdir /etc/pacman.d/hooks/
sudo cp gutenprint.hook /etc/pacman.d/hooks/
sudo pacman -Syu --needed --noconfirm pacman-contrib
echo ""
read -r -p "Do you want to install Reflector? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    sudo pacman -Syu --needed --noconfirm reflector
    echo -e "--save /etc/pacman.d/mirrorlist\n-p https\n-c 'Netherlands,United States'\n-l 10\n--sort rate" | sudo tee /etc/xdg/reflector/reflector.conf > /dev/null
    #Change location as per your need
    echo ""
    echo "It will take time to fetch the server/mirrors so please wait"
    echo ""
    if [ "$(pactree -r reflector)" ]; then
        sudo systemctl restart reflector
    else
        sudo systemctl enable --now reflector 
        sudo systemctl enable reflector.timer
    fi
fi

echo ""
if [ "$(pactree -r yay-bin)" ]; then
    echo "Yay is already installed"
else
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    yes | makepkg -si
    cd ..
    rm -rf yay-bin
fi

echo ""
sudo pacman -Syu --needed --noconfirm - < tpkg
sudo systemctl enable touchegg
sudo systemctl enable --now ufw
sudo ufw enable
sudo systemctl enable --now cups
sudo cp cups /etc/ufw/applications.d/
sudo cupsctl --share-printers
sudo ufw app update CUPS
sudo ufw allow CUPS
sudo systemctl enable sshd avahi-daemon
sudo cp /usr/share/doc/avahi/ssh.service /etc/avahi/services/
sudo ufw allow SSH
chsh -s /bin/fish
sudo chsh -s /bin/fish
pipx ensurepath
sudo cp 40-libinput.conf /usr/share/X11/xorg.conf.d/

echo ""
read -r -p "Do you want to install Samba? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    sudo pacman -Syu --needed --noconfirm samba
    sudo cp smb.conf /etc/samba/
    sudo systemctl enable smb nmb
    echo -e "[Share]\ncomment = Samba Share\npath = /home/"$(whoami)"/Share\nwritable = yes\nbrowsable = yes\nguest ok = no" | sudo tee -a /etc/samba/smb.conf > /dev/null
    mkdir ~/Share
    echo ""
    sudo smbpasswd -a $(whoami)
    sudo cp samba /etc/ufw/applications.d/
    sudo ufw app update SMB
    sudo ufw allow SMB
    sudo ufw allow CIFS
fi

sudo sed -i 's/Logo=1/Logo=0/' /etc/libreoffice/sofficerc

echo -e "VISUAL=nvim\nEDITOR=nvim\nQT_QPA_PLATFORMTHEME=qt6ct" | sudo tee /etc/environment > /dev/null
grep -qF "set number" /etc/xdg/nvim/sysinit.vim || echo "set number" | sudo tee -a /etc/xdg/nvim/sysinit.vim > /dev/null
grep -qF "set wrap!" /etc/xdg/nvim/sysinit.vim || echo "set wrap!" | sudo tee -a /etc/xdg/nvim/sysinit.vim > /dev/null

echo ""
echo "Installing Lightdm..."
echo ""
sudo pacman -Syu --needed --noconfirm lightdm numlockx lightdm-webkit-theme-litarvan 
sudo systemctl enable lightdm
sudo sed -i 's/^#greeter-setup-script=/greeter-setup-script=\/usr\/bin\/numlockx\ on/' /etc/lightdm/lightdm.conf
sudo sed -i 's/^\#greeter-session=.*/greeter-session=lightdm-webkit2-greeter/' /etc/lightdm/lightdm.conf
sudo sed -i 's/^webkit_theme\s*=.*/webkit_theme        = litarvan/' /etc/lightdm/lightdm-webkit2-greeter.conf


echo ""
read -r -p "Do you want to install WhiteSur gtk and icon theme? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    
    git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git --depth=1
    cd WhiteSur-gtk-theme/
    sudo ./install.sh -o normal -i arch
    ./install.sh -o normal -l -i arch
    cd ..
    rm -rf WhiteSur-gtk-theme/

    git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git --depth=1
    cd WhiteSur-icon-theme/
    sudo ./install.sh -a
    cd ..
    rm -rf WhiteSur-icon-theme/
fi

echo ""
echo "Installing Cinnamon..."
echo ""
sudo pacman -Syu --needed --noconfirm - < cin
gsettings set org.cinnamon.desktop.interface gtk-theme "WhiteSur-Dark"
gsettings set org.cinnamon.theme name "WhiteSur-Dark"
gsettings set org.cinnamon.desktop.interface icon-theme "WhiteSur-dark"

echo ""
read -r -p "Do you want to configure git? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    read -p "Enter your Git name: " git_name
    read -p "Enter your Git email: " git_email
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    echo ""
    read -r -p "Do you want generate SSH keys? [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo ""
	ssh-keygen -C "$git_email"
	git config --global gpg.format ssh
  	git config --global user.signingkey /home/$un/.ssh/id_ed25519.pub
        echo ""
        echo "Make changes accordingly if SSH key is generated again"
    fi
fi

echo ""
read -r -p "Do you want to install TLP? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo ""
    sudo pacman -Syu --needed --noconfirm tlp tlp-rdw smartmontools ethtool gnome-power-manager
    sudo systemctl enable tlp.service
    sudo systemctl enable NetworkManager-dispatcher.service
    sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket
    sudo tlp start
fi


echo ""
read -r -p "Do you want Bluetooth Service? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    sudo pacman -Syu --needed --noconfirm bluez bluez-utils blueman
    sudo systemctl enable bluetooth
fi

echo ""
read -r -p "Do you want to install VS Codium (from AUR)? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    yay -Syu --needed --noconfirm vscodium-bin
fi

echo ""
read -r -p "Do you want to install HPLIP(Driver for HP printers)? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    sudo pacman -Syu --needed --noconfirm hplip sane python-pillow rpcbind python-reportlab
    hp-plugin -i
fi

cp -r qt5ct ~/.config
cp -r qt6ct ~/.config
cp -r galculator ~/.config
cp -r Thunar ~/.config
cp -r Kvantum ~/.config
cp QtProject.conf ~/.config

echo ""
echo "You can now reboot your system "
