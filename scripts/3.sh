name="Gparted"
package_name="gparted"
description="ディスクのパーティションを操作します"
run_preparing=false

install () {
 apt install ${package_name}
}

uninstall () {
 apt purge ${package_name} && apt autoremove
}