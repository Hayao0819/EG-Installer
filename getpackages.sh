P_server="127.0.0.1:8888/list.sh"
wget -O "l" -S $P_server
x=0
while read line;do
x=$(($x+1))
ofn=$(cd $(dirname $0) && pwd)"/scripts/"${x}".sh"
echo -n $line | sed 's/===改行コード===/\n/g' > ${ofn}
done < "l"
