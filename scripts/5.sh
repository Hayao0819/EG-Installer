name="Papirusアイコンテーマ"
package_name="papirus-icon-theme"
description="フラットなアイコンテーマ"
run_preparing=false


function install () {
 apt install ${package_name}
}

uninstall () {
 apt purge ${package_name} && apt autoremove
}