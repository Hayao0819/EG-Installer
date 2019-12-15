P_server="https://raw.githubusercontent.com/naoko1010hh/package-gui-installer/master/list.sh"
wget -O "l" -S $P_server
x=0
while read line;do
x=$(($x+1))
ofn=$(cd $(dirname $0) && pwd)"/scripts/"${x}".sh"
echo -n $line | sed 's/===改行コード===/\n/g' > ${ofn}
done < "l"
