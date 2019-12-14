name="Adapta-Theme" 
 package_name="gparted" 
 description="マテリアルデザインに基づいたテーマパック" 
 run_preparing=false 
 function install () { 
 apt install -y $package_name 
 } 
 function uninstall () { 
 apt purge -y ${package_name} && apt autoremove 
 }