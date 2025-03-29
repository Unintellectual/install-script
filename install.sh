#!/bin/bash

# Define the list of programs to install
PROGRAMS=(
  base-devel
  build-essential
  btop
  curl
  firefox-esr
  flatpak
  git
  cura
  blender
  dunst
  neofetch
  meshlab
  gh
  golang
  i3-wm
  i3status
  kitty
  lxappearance
  mousepad
  nitrogen
  nodejs
  okular
  pavucontrol
  rofi
  ttf-ms-fonts
  vim
  nodejs
  ntfs-3g
  wget
  mpv
  obsidian
  openscad
  scrot
  slock
  sxiv
  thunar

  qbittorrent
)

MISSING_PACKAGES=()

# Detect the package manager
if command -v dnf &>/dev/null; then
  PKG_MANAGER="dnf"
elif command -v apt &>/dev/null; then
  PKG_MANAGER="apt"
elif command -v pacman &>/dev/null; then
  PKG_MANAGER="pacman"
elif command -v xbps-install &>/dev/null; then
  PKG_MANAGER="xbps-install"
else
  echo "Unsupported package manager. Exiting."
  exit 1
fi

# Update package lists
if [[ "$PKG_MANAGER" == "apt" ]]; then
  sudo apt update -y
elif [[ "$PKG_MANAGER" == "dnf" ]]; then
  sudo dnf check-update -y
elif [[ "$PKG_MANAGER" == "pacman" ]]; then
  sudo pacman -Sy --noconfirm
elif [[ "$PKG_MANAGER" == "xbps-install" ]]; then
  sudo xbps-install -Suy
fi

# Install each program in the list
for PROGRAM in "${PROGRAMS[@]}"; do
  echo "Installing $PROGRAM..."
  if [[ "$PKG_MANAGER" == "apt" ]]; then
    if ! sudo apt install -y "$PROGRAM"; then
      echo "$PROGRAM could not be installed with apt."
      MISSING_PACKAGES+=("$PROGRAM")
    fi
  elif [[ "$PKG_MANAGER" == "dnf" ]]; then
    if ! sudo dnf install -y "$PROGRAM"; then
      echo "$PROGRAM could not be installed with dnf."
      MISSING_PACKAGES+=("$PROGRAM")
    fi
  elif [[ "$PKG_MANAGER" == "pacman" ]]; then
    if ! sudo pacman -S --noconfirm "$PROGRAM"; then
      echo "$PROGRAM could not be installed with pacman."
      MISSING_PACKAGES+=("$PROGRAM")
    fi
  elif [[ "$PKG_MANAGER" == "xbps-install" ]]; then
    if ! sudo xbps-install -y "$PROGRAM"; then
      echo "$PROGRAM could not be installed with xbps-install."
      MISSING_PACKAGES+=("$PROGRAM")
    fi
  fi
  echo "$PROGRAM installation completed."
done

# Add Flathub remote if not already added
if ! flatpak remote-list | grep -q flathub; then
  echo "Adding Flathub remote..."
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# Install Flatpak applications
echo "Installing Flatpak applications..."
flatpak install -y flathub com.obsproject.Studio || echo "Failed to install OBS Studio."
flatpak install -y flathub org.nomad.MissionCenter || echo "Failed to install Mission Center."
flatpak install -y flathub org.onlyoffice.desktopeditors || echo "Failed to install only office"
flatpak install -y flathub org.kicad.KiCad || echo "Failed to install KiCad"
flatpak install -y flathub  com.discordapp.Discord || echo "Failed to install Discord"
flatpak install -y flathub com.github.tchx84.Flatseal || echo "Failed to install Flatseal"

# Authenticate GitHub CLI
echo "Authenticating GitHub CLI..."
if gh auth login; then
  echo "GitHub authentication successful."

  # Create Projects directory if it doesn't exist
  PROJECTS_DIR="$HOME/Projects"
  mkdir -p "$PROJECTS_DIR"
  cd "$PROJECTS_DIR"

  # Clone repositories
  echo "Cloning repositories..."
  git clone git@github.com:Unintellectual/automatic-succotash.git || echo "Failed to clone automatic-succotash."
else
  echo "GitHub CLI authentication failed."
fi



echo "All programs installation process completed."
