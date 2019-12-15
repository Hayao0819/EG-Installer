name="Grub-Customizer"
package_name="grub-customizer"
description="ブートローダーであるGrub2のカスタマイズをGUIで簡単に行なえます。"
run_preparing=false

install () {
 pacman -S --noconfirm ${package_name}
}

uninstall () {
 pacman -Rsn --noconfirm ${package_name}
}