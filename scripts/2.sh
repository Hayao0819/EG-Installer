name="Baobab"
package_name="baobab"
description="ディスクのファイルサイズを確認します"
run_preparing=false
install () {
 apt install ${package_name}
}
uninstall () {
 apt purge ${package_name} && apt autoremove
}