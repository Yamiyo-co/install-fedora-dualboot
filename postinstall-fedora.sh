#!/bin/bash
set -e

#
# VARIABLES
#
green="\e[0;92m"
red="\e[0;91m"
reset="\e[0m"
username="${USER}"
log_path="$(realpath "$0").log"

#
# FUNCTIONS
#

logSection() {
    local section="$1"
    {
        echo "###"
        echo "### [ ${section} ]"
        echo "###"
    } >> "$log_path"
}

logMessage() {
    local message="$1"
    echo "# ${message}" >> "$log_path"
}

printSection() {
    local section="$1"
    echo -e "${green}[ ${section} ]${reset}"
}

printError() {
    local error="$1"
    echo -e "${red}${error}${reset}" > "/dev/stderr"
}

userInstall() {
    printSection "UTILISATEUR"
    logSection "USER"

    ## Adding Flathub to user dependencies
    echo "    FLATPAK: Ajout de la source Flathub pour l'utilisateur"
    logMessage "FLATPAK: Adding Flathub remote to user remotes"
    flatpak remote-add --user --if-not-exists flathub "https://flathub.org/repo/flathub.flatpakrepo" 

    ## Configurations
    echo "    MIMEAPPS: Ajout de mimeapps.list aux configurations de l'utilisateur"
    logMessage "MIMEAPPS: Adding mimeapps.list to user configurations"
    mkdir --parents "${HOME}/bin/"
    cp "./files/home/user/.config/mimeapps.list" "${HOME}/.config/mimeapps.list"

    ## Preparing apps dir and app icon dirs
    echo "    DESKTOP ICONS: Creation des dossiers d'icones de bureau pour l'utilisateur"
    logMessage "DESKTOP ICONS: Creating desktop icons directories for user"
    mkdir --parents \
        "${HOME}/applications/" \
        "${HOME}/.local/share/icons/hicolor/128x128/apps/" \
        "${HOME}/.local/share/icons/hicolor/512x512/apps/" \
        "${HOME}/.local/share/icons/hicolor/scalable/apps/"
}

systemInstall() {
    printSection "SYSTEME"
    logSection "SYSTEM"

    ## Disabling sudo paswword prompt during system configuration 
    echo "    SUDO: Desactivation de la demande de mot de passe sudo pour les installations et les configurations systeme"
    logMessage "SUDO: Disabling sudo password prompt for system installation and configuration"
    echo "${username} ALL=(ALL) NOPASSWD: ALL" | sudo tee "/etc/sudoers.d/nopassword_postinstall_fedora" > "/dev/null"

    ## Setting prompt color for root to bold red
    echo "    TERMINAL: Configuration de l'entete de ligne de commande du terminal en gras rouge pour root"
    logMessage "TERMINAL: Setting prompt color for root to bold red"
    sudo mkdir --parents "/root/bashrc.d/"
    echo "export PROMPT_COLOR=1;32" | sudo tee "/root/bashrc.d/terminal.sh" > "/dev/null" 

    ## Disabling unwanted repos
    echo "    DNF: Desactivation des depots non voulus"
    logMessage "DNF: Disabling unwanted repos"
    sudo dnf --quiet config-manager setopt \
        copr:copr.fedorainfracloud.org:phracek:PyCharm.enabled=0 \
        fedora-cisco-openh264.enabled=0

    ## Enabling rpmfusion's repo for nvidia drivers
    echo "    DNF: Activation des depots RPMFUSION"
    logMessage "DNF: Enabling RPMFUSION repos" 
    sudo dnf --quiet config-manager setopt \
        rpmfusion-nonfree-nvidia-driver.enabled=1 \
        rpmfusion-nonfree-steam.enabled=1

    ## Updating packages
    echo "    DNF: Mise a jour du systeme"
    logMessage "DNF: Updating system"
    sudo dnf --quiet --assumeyes upgrade &>> "$log_path"

    ## Installing last driver packages
    echo "    DNF: Installation des derniers pilotes"
    logMessage "DNF: Installing latest drivers"
    sudo dnf --quiet --assumeyes install \
        akmod-nvidia \
        steam-devices \
    &>> "$log_path"

    ## Installing Docker
    echo "    DOCKER: Installation de Docker"
    logMessage "DOCKER: Installing Docker"
    sudo dnf --quiet config-manager addrepo --overwrite --from-repofile="https://download.docker.com/linux/fedora/docker-ce.repo"
    sudo dnf --quiet --assumeyes install \
        docker-ce-cli \
        docker-ce \
        containerd.io \
    &>> "$log_path"

    ### Enabling Docker at start
    echo "    DOCKER: Enabling Docker at start"
    logMessage "DOCKER: Enabling Docker at start"
    sudo systemctl --quiet enable docker

    ## Creating Docker certificate directory
    echo "    DOCKER: Creation des repertoires de certificats pour Docker"
    logMessage "DOCKER: Creating Docker certificate directory"
    sudo mkdir --parents "/etc/docker/certs.d/"

    # Adding Flathub remote to system available remotes
    echo "    FLATPAK: Ajout de la source Flathub"
    logMessage "FLATPAK: Adding Flathub remote"
    sudo flatpak remote-add --system --if-not-exists flathub "https://dl.flathub.org/repo/flathub.flatpakrepo"

    ## Keeping only Flathub flatpak remote
    echo "    FLATPAK: Suppression des sources non voulues pour ne garder que Flathub"
    logMessage "FLATPAK: Removing unwanted remotes to keep only Flathub"
    unset flatpak_remotes
    readarray -t flatpak_remotes <<< "$(sudo flatpak remote-list --show-disabled --columns=name)"
    for remote_name in "${flatpak_remotes[@]}"; do
        if [ "${remote_name}" != 'flathub' ]; then
            sudo flatpak remote-delete "${remote_name}"
        fi
    done

    ## Installing system wide Flatpak apps
    echo "    FLATPAK: Installation des applications Flatpak"
    logMessage "FLATPAK: Installing Flatpak apps"
    sudo flatpak install --system --noninteractive --assumeyes flathub \
        com.bitwarden.desktop \
        com.github.tchx84.Flatseal \
        com.mattjakeman.ExtensionManager \
        com.nextcloud.desktopclient.nextcloud \
        io.gitlab.librewolf-community \
        md.obsidian.Obsidian \
        org.gimp.GIMP \
        org.gnome.Calendar \
        org.gnome.Decibels \
        org.gnome.FileRoller \
        org.gnome.Loupe \
        org.gnome.Papers \
        org.gnome.Showtime \
        org.gnome.SimpleScan \
        org.gnome.TextEditor \
        org.gnome.baobab \
        org.inkscape.Inkscape \
        org.libreoffice.LibreOffice \
        org.mozilla.Thunderbird \
        org.mozilla.firefox \
        org.onlyoffice.desktopeditors \
    &>> "$log_path"

    ## Installing GNOME extensions
    echo "    GNOME: Installation des extensions Gnome"
    logMessage "GNOME: Installing Gnome extensions"
    unset extension_urls
    declare -A extension_urls
    extension_urls+=(
        ["middleclickclose@paolo.tranquilli.gmail.com"]="https://extensions.gnome.org/extension-data/middleclickclosepaolo.tranquilli.gmail.com.v35.shell-extension.zip"
        ["nightthemeswitcher@romainvigier.fr"]="https://extensions.gnome.org/extension-data/nightthemeswitcherromainvigier.fr.v80.shell-extension.zip"
    )

    for extension_uuid in "${!extension_urls[@]}"
    do
        echo "        - ${extension_uuid}"
        logMessage "    - ${extension_uuid}"
        sudo rm --recursive --force "/usr/share/gnome-shell/extensions/${extension_uuid}/"
        sudo wget --quiet --output-document "/tmp/${extension_uuid}.zip" "${extension_urls[$extension_uuid]}"
        sudo mkdir --parents "/tmp/${extension_uuid}/"
        sudo unzip -qq -o "/tmp/${extension_uuid}.zip" -d "/tmp/${extension_uuid}/"
        sudo mv "/tmp/${extension_uuid}/" "/usr/share/gnome-shell/extensions/"
        sudo rm --recursive --force "/tmp/${extension_uuid}.zip" "/tmp/${extension_uuid}/"
        sudo chmod 644 "/usr/share/gnome-shell/extensions/${extension_uuid}/metadata.json"
        sudo glib-compile-schemas "/usr/share/gnome-shell/extensions/${extension_uuid}/schemas/"
    done

    ## Installing patched font for terminal
    echo "    FONT: Installation de la police SourceCodePro"
    logMessage "FONT: Installing SourceCodePro Font"
    sudo wget --quiet --output-document "/tmp/SourceCodePro.zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/SourceCodePro.zip"
    sudo unzip -qq -o "/tmp/SourceCodePro.zip" -d "/usr/share/fonts/sauce-code-pro/"
    sudo rm "/tmp/SourceCodePro.zip"

    ## Setting custom environment variables
    echo "    VIM: Definition de Vim comme edite par defaut dans le terminal"
    logMessage "VIM: Setting Vim as default editor"
    echo "export EDITOR=\"/usr/bin/vim\"" | sudo tee "/etc/profile.d/sh.local" > /dev/null

    echo "    VIM: Ajout des alias relatifs a Vim dans /etc/profile.d/"
    logMessage "VIM: Adding Vim related aliases to /etc/profile.d/"
    sudo cp "./files/etc/profile.d/vim.sh" "/etc/profile.d/vim.sh"

    ## Disabling systemd-resolved for OpenVPN to work well with custom DNS
    echo "    RESOLVED: Desactivation de resolved"
    logMessage "RESOLVED: Disabling resolved"
    sudo systemctl --quiet disable --now systemd-resolved
    sudo rm "/etc/resolv.conf"
    sudo systemctl --quiet restart NetworkManager

    ## Installing SSH autocompletion
    echo "    SSH: Ajout de l'autocompletion pour SSH"
    logMessage "SSH: Adding SSH autocompletion"
    sudo cp "./files/etc/bash_completion.d/ssh_completion" "/etc/bash_completion.d/ssh"
    sudo chown root:root "/etc/bash_completion.d/ssh"
    sudo chmod 644 "/etc/bash_completion.d/ssh"

    ## Installing custom commands
    echo "    CUSTOM: Installation des commandes personnalisees"
    logMessage "CUSTOM: Installing custom commands"
    ### BTOP++ update
    echo "        - update-btop"
    logMessage "    - update-btop"
    sudo cp "./files/usr/local/sbin/update-btop.sh" "/usr/local/sbin/update-btop"
    sudo chown root:root "/usr/local/sbin/update-btop"
    sudo chmod 744 "/usr/local/sbin/update-btop"
    ### Open VM
    echo "        - openvm"
    logMessage "    - openvm"
    sudo cp "./files/usr/local/bin/openvm.sh" "/usr/local/bin/openvm"
    sudo chown root:root "/usr/local/bin/openvm"
    sudo chmod 755 "/usr/local/bin/openvm"
    ### Pandock
    echo "        - pandock"
    logMessage "    - pandock"
    sudo cp "./files/usr/local/bin/pandock.sh" "/usr/local/bin/pandock"
    sudo chown root:root "/usr/local/bin/pandock"
    sudo chmod 755 "/usr/local/bin/pandock"
    ### Sync Obsidian
    echo "        - sync-obsidian"
    logMessage "    - sync-obsidian"
    sudo cp "./files/usr/local/bin/sync-obsidian.sh" "/usr/local/bin/sync-obsidian"
    sudo chown root:root "/usr/local/bin/sync-obsidian"
    sudo chmod 755 "/usr/local/bin/sync-obsidian"

    ## Using custom commands to install apps
    echo "    CUSTOM: Installation des applications en utilisant les commandes personnalisees"
    logMessage "CUSTOM: Installing apps using custom commands"
    ## BTOP++
    echo "        - BTOP++"
    logMessage "    - BTOP++"
    sudo update-btop > "/dev/null"

    ## App icons
    echo "    DESKTOP: Ajout des icones de bureau"
    logMessage "DESKTOP: Adding desktop icons"
    ### Creating required directories
    sudo mkdir --parents \
        "/usr/local/share/icons/hicolor/512x512/apps/" \
        "/usr/local/share/icons/hicolor/scalable/apps/" \
        "/usr/local/share/applications/"
    
    ### tmux
    echo "        - TMUX"
    logMessage "    - TMUX"
    sudo cp "./files/usr/local/share/icons/hicolor/512x512/apps/tmux.png" "/usr/local/share/icons/hicolor/512x512/apps/tmux.png"
    sudo cp "./files/usr/local/share/icons/hicolor/scalable/apps/tmux.svg" "/usr/local/share/icons/hicolor/scalable/apps/tmux.svg"
    sudo cp "./files/usr/local/share/applications/tmux.desktop" "/usr/local/share/applications/tmux.desktop"

    ## Backgrounds
    echo "    BACKGROUNDS: Ajout des sets de fonds d'ecran Fedora"
    logMessage "BACKGROUNDS: Adding Fedora background sets"
    unset background_versions
    background_versions="35 39 41"
    for bv in $background_versions; do
        echo "        - Set de fonds d'ecran de Fedora ${bv}"
        logMessage "    - Fedora ${bv} background set"
        ### Creating required directories
        sudo mkdir --parents "/usr/share/backgrounds/custom/f${bv}/"
        ### Installing backgrounds
        sudo cp "./files/usr/share/backgrounds/custom/f${bv}/f${bv}-day.png" "/usr/share/backgrounds/custom/f${bv}/f${bv}-day.png"
        sudo cp "./files/usr/share/backgrounds/custom/f${bv}/f${bv}-night.png" "/usr/share/backgrounds/custom/f${bv}/f${bv}-night.png"
        ### Installing background set configurations
        sudo cp "./files/usr/share/gnome-background-properties/f${bv}.xml" "/usr/share/gnome-background-properties/f${bv}.xml"
        sudo cp "./files/usr/share/backgrounds/custom/f${bv}/f${bv}.xml" "/usr/share/backgrounds/custom/f${bv}/f${bv}.xml"
    done

    ## Enabling back sudo password prompt
    echo "    SUDO: Reactivation de la demande de mot de passe sudo"
    logMessage "SUDO: Enabling back sudo password prompt"
    sudo rm "/etc/sudoers.d/nopassword_postinstall_fedora"
}

devInstall() {
    printSection "DEVELOPPEMENT"
    logSection "DEVELOPMENT"
    ## Creating git directories
    echo "    GIT: Creation des repertoires Git dans le HOME"
    logMessage "GIT: Creating Git directories in HOME"
    mkdir --parents "${HOME}/git/" 

    ## Installing NVChad vor NeoVim
    echo "    NVCHAD: Installation de NVChad"
    logMessage "NVCHAD: Installing NVChad"
    if ! [ -d "${HOME}/.config/nvim" ]; then
        git clone --quiet "https://github.com/NvChad/starter" "${HOME}/.config/nvim"
    fi
}

gamingInstall() {
    printSection "JEUX"
    logSection "GAMING"

    ## Creating user games directory
    echo "    GAMES: Creation du repertoire de jeux Game dans le HOME"
    logMessage "GAMES: Creating Games directory in HOME"
    mkdir --parents "${HOME}/Games/"

    ## Installing Flatpak gaming apps for user
    echo "    FLATPAK: Installation des applications Flatpak"
    logMessage "FLATPAK: Installing Flatpak applications"
    flatpak install --user --noninteractive --assumeyes flathub \
        com.usebottles.bottles \
        com.valvesoftware.Steam \
        net.pcsx2.PCSX2 \
    &>> "$log_path"

    ## Minecraft
    echo "    MINECRAFT: Installation de Minecraft"
    logMessage "MINECRAFT: Installing Minecraft"
    wget --quiet --output-document "${HOME}/Games/minecraft-launcher.tar.gz" "https://launcher.mojang.com/download/Minecraft.tar.gz"
    tar --directory "${HOME}/Games/" -zxf "${HOME}/Games/minecraft-launcher.tar.gz"
    chmod 755 "${HOME}/Games/minecraft-launcher/minecraft-launcher"
    rm "${HOME}/Games/minecraft-launcher.tar.gz"

    echo "    MINECRAFT: Ajout de l'icone de bureau Minecraft"
    logMessage "MINECRAFT: Adding Minecraft desktop icon"
    cp "./files/home/user/.local/share/icons/hicolor/512x512/apps/minecraft.png" "${HOME}/.local/share/icons/hicolor/512x512/apps/minecraft.png"
    cp "./files/home/user/.local/share/icons/hicolor/scalable/apps/minecraft.svg" "${HOME}/.local/share/icons/hicolor/scalable/apps/minecraft.svg"
    cp "./files/home/user/.local/share/applications/minecraft.desktop" "${HOME}/.local/share/applications/minecraft.desktop"
}

printNextSteps() {
    local system=$1
    local dev=$2
    local gaming=$3

    printSection "ETAPES SUIVANTES"
    echo ""
    echo "    Les étapes qui suivent sont à faire manuellement :"
    echo "    Si une carte Nvidia est utilisée :"
    echo "      - reboot"
    echo "      - flatpak update --assumeyes"

    if [ "${gaming}" -eq 1 ]; then
        echo "    Installer les jeux :"
        echo "      - Minecraft Dungeons (Bottles)    : https://launcher.mojang.com/download/MinecraftInstaller.msi"
        echo "      - Genshin Impact (Bottles)        : https://sg-public-api.hoyoverse.com/event/download_porter/trace/hyp_global/hyphoyoverse/default"
        echo ""
    fi

    if [ "${dev}" -eq 1 ]; then
        echo "    Ajouter l'utilisateur au groupe docker :"
        echo "      - sudo usermod -aG docker,libvirt ${USER}"
        echo ""
        echo "    Restaurer :"
        echo "      - Clefs SSH"
        echo "      - Clef GPG"
        echo "      - Certificats VPN"
        echo "      - Certificats SSL privés"
        echo ""
    fi
}

printHelp() {
    echo ""
    printSection "UTILISATION"
    echo "    $0 [options]"
    echo ""
    printSection "OPTIONS DISPONIBLES"
    echo "    --help         : Affiche la documentation de la commande."
    echo "    --system       : Met à jour et installe des paquets avec dnf et configure le système. (requiert les privilèges d'administrateur)"
    echo "    --dev          : Prépare le compte pour le développement."
    echo "    --gaming       : Prépare le compte pour jouer aux jeux vidéos."
    echo "    --all          : Équivaut à --system --dev --gaming"
    echo ""
}

#
# BEGIN
#

# Requirements verifications
if ! [ -f "${PWD}/postinstall-fedora.sh" ]; then
    echo -e "${red}Vous devez exécuter ce script depuis le dossier contenant ce dernier.${reset}" > "/dev/stderr"
    exit 1
fi

if [ 0 -eq "$(id --user)" ]; then
    echo -e "${red}Vous devez exécuter ce script sans les privilèges administrateur.${reset}" > "/dev/stderr"
    exit 1
fi

# Args variables
system=0
dev=0
gaming=0

# Arguments handling
for opt in "$@"; do
    case "$opt" in
    "--help")
        printHelp
        exit 0
        ;;
    "--all")
        system=1
        dev=1
        gaming=1
        ;;
    "--system")
        system=1
        ;;
    "--dev")
        dev=1
        ;;
    "--gaming")
        gaming=1
        ;;
    *)
        printError "Argument invalide : ${opt}"
        exit 1
        ;;
    esac
done

logSection "START"
echo ""
printSection "POST-INSTALLATION DEBUT"
echo ""

# Specific installations
if [ 1 -eq $system ]; then
    systemInstall
fi

# User initial configuration
userInstall

if [ 1 -eq $dev ]; then
    devInstall
fi

if [ 1 -eq $gaming ]; then
    gamingInstall
fi

printNextSteps $system $dev $gaming

echo ""
printSection "POST-INSTALLATION FIN"
echo ""
logSection "END"

#
# End
#
exit 0
