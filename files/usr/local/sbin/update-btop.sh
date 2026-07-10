#!/bin/bash

red="\e[0;91m"
reset="\e[0m"

if [ $# -gt 1 ]
then
    echo -e "${red}La commande requiert exactement 0 ou 1 argument : $# donné(s).${reset}" >&2
    echo "UTILISATION"
    echo "  $0 [version]"
    exit 1
fi

btop_url="https://github.com/aristocratos/btop/releases/latest/download/btop-x86_64-unknown-linux-musl.tar.gz"

if [ $# -eq 1 ]
then
    btop_version=$1
    btop_url="https://github.com/aristocratos/btop/releases/download/v${btop_version}/btop-x86_64-unknown-linux-musl.tar.gz"
fi

mkdir --parents "/tmp/btop/"

if ! wget --quiet --output-document "/tmp/btop/btop.tbz" "${btop_url}"
then 
    echo -e "${red}Une erreur s'est produite lors de la récupération de BTOP++. Avez-vous donné une version valide ?${reset}" >&2
    exit 1
fi

tar --directory "/tmp/btop/" --extract --file "/tmp/btop/btop.tbz"

btop_tmp_dir="/tmp/btop/"
if [ -d "/tmp/btop/btop/" ]; then
    btop_tmp_dir=/tmp/btop/btop/
fi

make --directory "${btop_tmp_dir}" install
echo -e "${reset}"
rm --recursive --force "/tmp/btop/"
exit 0

