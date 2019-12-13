#!/usr/bin/env bash

set -eu
# 設定読み込み
source ./settings.conf


# 関数定義
function window () {
    zenity \
        --title="$window_text" \
        --window-icon="$window_icon" \
        --width="$window_width" \
        --height="$window_height" \
        $@
}
function loading () {
    window --progress --auto-close --pulsate --text="$@"
}
function error () {
    window --error --text="$@"
}


# 変数定義
script_path=$(cd $(dirname $0) && pwd)/$(basename $0)
script_dir=$(dirname $script_path)
script_dir="$script_dir/scripts"


# Rootチェック
if [[ ! $UID = 0 ]]; then
    pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY $script_path > /dev/null
    exit
fi


# スクリプト読み込み
scripts=($(ls $script_dir))
for package in ${scripts[@]}; do
    source $script_dir/$package
    if [[ ! $(type -t install) = "function" ]]; then
        error "スクリプト$packageのinstall関数が間違っています。"
        exit 1
    fi
    if [[ -z $name ]]; then
        error "スクリプト$packageにname変数が設定されていません。"
        exit 1
    fi
done


# リスト
selected=$(
    window --list --radiolist \
        --column="インストール" \
        --column="パッケージ" \
        --column="説明" \
        $(
            scripts=($(ls $script_dir))
            for package in ${scripts[@]}; do
                source $script_dir/$package
                echo "FALSE"
                echo "$name"
                echo "$description"
            done
        )
)


# インストール
scripts=($(ls $script_dir))
for package in ${scripts[@]}; do
    source $script_dir/$package
    if [[ $name = $selected ]]; then
        break
    fi
done

yes | install | loading "パッケージ$nameをインストールしています"

