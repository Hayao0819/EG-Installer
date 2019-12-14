#!/usr/bin/env bash

set -eu

#===== 各基本ウィンドウの使い方 =====#
# プログレスバー
# command | loading [横幅] [高さ] [メッセージ]
#
# エラーウィンドウ
# error [横幅] [高さ] [メッセージ]
#
# 警告ウィンドウ
# warning [横幅] [高さ] [メッセージ]
#
# 情報ウィンドウ
# info [横幅] [高さ] [メッセージ]
#


#-- 設定読み込み --#
source $(cd $(dirname $0) && pwd)/settings.conf


#-- 関数定義 --#

# ウィンドウの基本型
function window () {
    zenity \
        --title="$window_text" \
        --window-icon="$window_icon" \
        $@
}

# 読み込みウィンドウ
function loading () {
    window \
        --progress \
        --auto-close \
        --pulsate \
        --width="$1" \
        --height="$2" \
        --text="$3"
}

# エラーウィンドウ
function error () {
    window \
        --error \
        --width="$1" \
        --height="$2" \
        --text="$3"
}

# 警告ウィンドウ
function warning () {
    window \
        --warning \
        --width="$1" \
        --height="$2" \
        --text="$3"
}

# 情報ウィンドウ
function info () {
    window \
        --info
        --width="$1"
        --height="$2"
        --text="$3"
}

# ユーザーチェック
function user_check () {
    if [[ $(getent passwd $1 > /dev/null ; printf $?) = 0 ]]; then
        printf 0
        return 0
    else
        printf 1
        return 1
    fi
}



#-- 変数定義 --#
script_path=$(cd $(dirname $0) && pwd)/$(basename $0)
script_dir=$(dirname $script_path)
script_dir="$script_dir/scripts"



#-- Rootチェック --#
if [[ ! $UID = 0 ]]; then
    pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY $script_path > /dev/null
    exit
fi



#-- ディスプレイチェック --#
if [[ -z $DISPLAY ]]; then
    echo "GUI環境で起動してください。" >&2
    exit 1
fi



#-- check_pkg関数のチェック --#
if [[ ! $(type -t check_pkg) = "function" ]]; then
    error 600 300 "$(cd $(dirname $0) && pwd)/settings.confのcheck_pkgが正しくありません。"
    exit 1
fi



#-- AURユーザー --#
source /etc/os-release
if [[ $ID = "arch" || $ID = "arch32" ]]; then
    function ask_user () {
        export aur_user=$(window --entry --text="パッケージのビルドに使用する一般ユーザーを入力してください。")
        if [[ -z $aur_user ]]; then
            error 600 300 "ユーザー名を入力してください。"
            ask_user
        fi
        if [[ $aur_user = "root" ]]; then
            error 600 300 "一般ユーザーを入力してください。"
            ask_user
        fi
    }
    ask_user
    while [ $(user_check $aur_user) = 1 ]; do
        error 600 300 "存在しているユーザを入力してください。"
        ask_user
    done
fi



#-- スクリプト読み込み --#
scripts=($(ls $script_dir))
for package in ${scripts[@]}; do
    source $script_dir/$package
    if [[ ! $(type -t install) = "function" ]]; then
        error 600 300 "スクリプト$packageのinstall関数が間違っています。"
        exit 1
    fi
    if [[ -z $name ]]; then
        error 600 300 "スクリプト$packageにname変数が設定されていません。"
        exit 1
    fi
done



#-- リスト --#
selected=$(
    window --list --radiolist \
        --column="インストール" \
        --column="パッケージ" \
        --column="インストールされている" \
        --column="説明" \
        --width="700" \
        --height="500" \
        --text="インストールまたは削除したいパッケージを選択してください。" \
        $(
            scripts=($(ls $script_dir))
            for package in ${scripts[@]}; do
                source $script_dir/$package
                if [[ $(check_pkg $package_name) = 0 ]]; then
                    status_display="はい"
                else
                    status_display="いいえ"
                fi
                echo "FALSE"
                echo "$name"
                echo "$status_display"
                echo "$description"
            done
        )
)



#--- データベースの更新 --#
pacman -Syy --noconfirm | loading 600 300 "リポジトリデータベースを更新しています。"



#-- 選択パッケージに対応しているファイルを探す --#
scripts=($(ls $script_dir))
for package in ${scripts[@]}; do
    set name
    set description
    set preparing
    set install

    source $script_dir/$package
    if [[ $name = $selected ]]; then
        break
    fi
    unset name
    unset description
    unset preparing
    unset run_preparing
    unset install
done



# インストール or アンインストール
source $script_dir/$package

if $run_preparing; then
    preparing | loading 600 300 "パッケージをビルドしています"
fi

if [[ $(check_pkg $package_name) = 1 ]]; then
    install | loading 600 100 "パッケージ$nameをインストールしています"
else
    uninstall | loading 600 100 "パッケージ$nameをアンインストールしています。"
fi



#-- クリーンアップ --#
# pacman -Qttdq | pacman -Rsn | loading 600 300 "不要なパッケージを削除しています。"