#!/bin/bash

# Define the list of programs to install
PROGRAMS=(
  base-devel
  btop
  caprine
  curl
  docker
  docker-compose
  dotnet-runtime
  dotnet-sdk
  exa
  firefox
  flatpak
  flameshot
  github-cli
  git
  go
  i3
  i3status
  kitty
  lxappearance
  micro
  mousepad
  nemo
  nitrogen
  nodejs
  pnpm
  okular
  pavucontrol
  picom
  pywalfox
  rofi
  steam
  thunderbird
  tmux
  ttf-ms-fonts
  vim
  vlc
  wget
  zsh
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
sudo flatpak install -y flathub com.wps.Office || echo "Failed to install WPS Office."
sudo flatpak install -y flathub com.pathofbuilding.PathOfBuildingCommunity || echo "Failed to install Path of Building."
sudo flatpak install -y flathub com.obsproject.Studio || echo "Failed to install OBS Studio."
sudo flatpak install -y flathub org.nomad.MissionCenter || echo "Failed to install Mission Center."

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
  git clone git@github.com:Unintellectual/dotfiles.git || echo "Failed to clone dotfiles."
  git clone git@github.com:Unintellectual/MacroMaster.git || echo "Failed to clone MacroMaster."
else
  echo "GitHub CLI authentication failed."
fi



# Replace .bashrc and .zshrc with dotfiles versions
DOTFILES_DIR="$HOME/Projects/dotfiles"
if [ -d "$DOTFILES_DIR" ]; then
  echo "Replacing .bashrc and .zshrc with versions from dotfiles..."
  cp "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc" || echo "Failed to copy .bashrc."
  cp "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc" || echo "Failed to copy .zshrc."

  # Source the new configuration files
  echo "Sourcing .bashrc and .zshrc..."
  source "$HOME/.bashrc" || echo "Failed to source .bashrc."
  source "$HOME/.zshrc" || echo "Failed to source .zshrc."

  # Copy config directories
  echo "Copying configuration directories from dotfiles..."
  for CONFIG in kitty i3 i3status rofi; do
    if [ -d "$DOTFILES_DIR/.config/$CONFIG" ]; then
      mkdir -p "$HOME/.config/$CONFIG"
      cp -r "$DOTFILES_DIR/.config/$CONFIG"/* "$HOME/.config/$CONFIG"/
    fi
  done

  # Copy .local/bin and .local/share directories
  echo "Copying .local/bin and .local/share from dotfiles..."
  mkdir -p "$HOME/.local/bin" "$HOME/.local/share"
  cp -r "$DOTFILES_DIR/.local/bin"/* "$HOME/.local/bin"/ 2>/dev/null || echo "No files in .local/bin to copy."
  cp -r "$DOTFILES_DIR/.local/share"/* "$HOME/.local/share"/ 2>/dev/null || echo "No files in .local/share to copy."
else
  echo "Dotfiles repository not found. Skipping .bashrc, .zshrc, and config directory replacement."
fi

# List missing packages if any
if [ ${#MISSING_PACKAGES[@]} -ne 0 ]; then
  echo "The following packages could not be installed automatically:"
  printf '%s\n' "${MISSING_PACKAGES[@]}"
fi
sudo curl -Lo /usr/bin/theme.sh 'https://git.io/JM70M' && sudo chmod +x /usr/bin/theme.sh

# Install Oh My Zsh
echo "Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || echo "Failed to install Oh My Zsh."
else
  echo "Oh My Zsh is already installed."
fi
echo "All programs installation process completed."
