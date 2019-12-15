name="Papirusアイコンテーマ"
package_name="papirus-icon-theme"
description="フラットなアイコンテーマ"
run_preparing=false


function install () {
 pacman -S --noconfirm $package_name
}

uninstall () {
 pacman -Rsn --noconfirm ${package_name}
}