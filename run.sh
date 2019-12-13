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
function user_check () {
    if [[ $(getent passwd $1 > /dev/null ; printf $?) = 0 ]]; then
        printf 0
        return 0
    else
        printf 1
        return 1
    fi
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


# ディスプレイチェック
if [[ -z $DISPLAY ]]; then
    echo "GUI環境で起動してください。" >&2
    exit 1
fi


# AURユーザー
function ask_user () {
    export aur_user=$(window --entry --text="パッケージのビルドに使用する一般ユーザーを入力してください。")
    if [[ -z $aur_user ]]; then
        error "ユーザー名を入力してください。"
        ask_user
    fi
    if [[ $aur_user = "root" ]]; then
        error "一般ユーザーを入力してください。"
        ask_user
    fi
}
ask_user
while [ $(user_check $aur_user) = 1 ]; do
    error "存在しているユーザを入力してください。"
    ask_user
done


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
        --text="インストールしたいパッケージを選択してください。"
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

if [[ $(type -t preraring) = "function" ]]; then
    preraring | loading "パッケージをビルドしています"
fi

yes | install | loading "パッケージ$nameをインストールしています"

