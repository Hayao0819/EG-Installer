name="Adapta-Theme"
package_name="adapta-gtk-theme"
description="マテリアルデザインに基づいたテーマパック"
run_preparing=false
install () {
 apt install ${package_name}
}
uninstall () {
 apt purge ${package_name} && apt autoremove
}