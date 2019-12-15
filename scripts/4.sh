name="Grub-Customizer"
package_name="grub-customizer"
description="ブートローダーであるGrub2のカスタマイズをGUIで簡単に行なえます。"
run_preparing=false

install () {
 apt install ${package_name}
}

uninstall () {
 apt purge ${package_name} && apt autoremove
}