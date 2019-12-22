#!/usr/bin/env bash

# EG-Installer
# SereneTeam (c) 2019.
# Twitter: @Serene_JP
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email : shun819.mail@gmail.com



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
# 改行する場合は \n と記述してください。　



#-- 設定 --#
settings=$(cd $(dirname $0) && pwd)/config
version=1.4



#-- エラーチェック --#
set -eu



#-- 変数定義 --#
current_path=$(cd $(dirname $0) && pwd)/$(basename $0)
current_dir=$(dirname $current_path)
options=$@
unset run



#-- 関数定義 --#

function call_me () {
    export recall=true
    bash ${0} $options
}

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
        --info \
        --width="$1" \
        --height="$2" \
        --text="$3"
}

# ユーザーチェック
function user_check () {
    if [[ $(getent passwd $1 > /dev/null ; printf $?) = 0 ]]; then
        if [[ -z $1 ]]; then
            printf 1
        fi
        printf 0
    else
        printf 1
    fi
}

# 設定上の関数チェック
function check_func () {
    if [[ ! $(type -t $1) = "function" ]]; then
        error 800 100 "$2"
        exit 1
    fi
}

# パッケージチェック
check_pkg () {
    if [[ -n $(installed_list | grep -x "$1") ]]; then
        printf 0
    else
        printf 1
    fi
}

# 値の初期化
function clear_variable () {
    unset name
    unset package_name
    unset description
    unset run_preparing
    unset install
    unset uninstall
    unset preparing
}



#-- ディスプレイチェック --#
if [[ -z $DISPLAY ]]; then
    echo "GUI環境で起動してください。" >&2
    exit 1
fi



#-- Rootチェック --#
if [[ ! $UID = 0 ]]; then
    if [[ ! -f /tmp/user || -w /tmp/user ]]; then
        echo -n 'aur_user=' > /tmp/user
        echo "$(whoami)" >> /tmp/user
    fi
    pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY $current_path $options> /dev/null
    exit
fi



#-- 設定読み込み --#
set +eu
if [[ ! -f $settings ]]; then
    error 600 100 "$settingsが存在しません。"
    exit 1
fi
source $settings
if [[ -z $ID ]]; then
    source /etc/os-release
fi
set -eu



#-- アイコンチェック --#
if [[ ! -f $window_icon ]]; then
    error 600 100 "$window_iconが存在しません。"
    exit 1
fi



#-- バージョン情報 --#
function show_version () {
    window \
        --info \
        --width="600" \
        --height="100" \
        --text="＝＝　EG-Intaler　＝＝\nVersion:　${version}\nYamada　Hayao　shun819.mail@gmail.com"
}



#-- デバッグ用引数 --#
set +eu
while getopts 'adhpr:s:t:u:v' arg; do
    case "${arg}" in
        a) export ID=arch;;
        d) installed_list () { ${pacman} -Q | awk '{print $2}'; }; [[ ! $recall = true ]] && echo "dpkg,apt用のinstalled_listを使用します。" > /dev/null ;;
        h) info 600 100 "==　デバッグ用　==\nこれはデバッグ用オプションです。通常利用はしないでください。\n$settingsを変更することで値を保存できます。\n\n-a　:　ArchLinuxモードを強制的に有効化します。\n-d　:　dpkg,apt用のinstalled_listを使用します。\n-h　:　このヘルプを表示します。このオプションが有効な場合、他のオプションは無視されます。\n-p　:　pacman用のinstalled_listを使用します。\n-v　:　バージョン情報を表示します。\n-s　[スクリプトディレクトリ]　:　スクリプトディレクトリを指定します。\n-t　[　ウィンドウタイトル　]　:　ウィンドウタイトルを指定します。\n-u　[　　　ユーザー名　　　]　:　パッケージのビルドに使用するユーザーを指定します。\n"; exit 0;;
        p) installed_list () { ${pacman} -Q | awk '{print $1}'; }; [[ ! $recall = true ]] && echo "pacman用のinstalled_listを使用します。" > /dev/null ;;
        r) direct_execution=true;if [[ ! $recall = true ]]; then case ${OPTARG} in 1) run="パッケージのクリーンアップ";; 2) run="パッケージのアップグレード";; 3) run="パッケージの追加と削除" ;; esac; else exit 0; fi;;
        s) script_dir=${OPTARG};;
        t) window_text=${OPTARG};;
        u) aur_user=${OPTARG};;
        v) show_version;exit 0;;
        "") : ;;
        #* ) exit 1;;
    esac
done
set -eu



#-- check_pkgについて --#
check_func installed_list "$settingsで、installed_listをディストリビューションごとに設定してください。\nわからない場合は、ディストリビューションの配布元へ連絡してください。"



#-- スクリプトディレクトリのチェック --#
if [[ ! -d $script_dir ]]; then
    error 600 100 "$script_dirが存在しません。"
    exit
fi



#-- pacapt --#
if [[ ! $ID = "arch" || ! $ID = "arch32" ]]; then
    if [[ ! -f $pacman ]]; then
        error 600 100 "$pacmanが存在しません。"
        exit 1
    fi
    if [[ ! -x $pacman ]]; then
        chmod 755 $pacman
    fi
else
    pacman=pacman
fi



#-- AURユーザー --#
set +eu
if [[ ! $recall = true ]]; then
    if [[ $ID = "arch" || $ID = "arch32" ]]; then
        function ask_user () {
            set -eu
            aur_user=$(window --entry --text="パッケージのビルドに使用する一般ユーザーを入力してください。")
            set +eu
            if [[ -z $aur_user ]]; then
                error 600 100 "ユーザー名を入力してください。"
                ask_user
            fi
            if [[ $aur_user = "root" ]]; then
                error 600 100 "一般ユーザーを入力してください。"
                ask_user
            fi
        }
        if [[ -n $aur_user ]]; then
            if [[ $aur_user = root ]]; then
                error 600 100 "rootは使用できません。"
                ask_user
            else
                warning 600 100 "デバッグ用引数で指定されたユーザー($aur_user)を使用します。この設定は/tmp/userに保存されます。"
            fi
        elif [[ -f /tmp/user ]]; then
            source /tmp/user
            info 600 100 "/etc/userに保存されているユーザー($aur_user)を使用します。"
            [[ -z $aur_user ]] && ask_user
        elif [[ ! $SUDO_USER = root ]]; then
            aur_user=$SUDO_USER
            info 600 100 "sudoで使用されていたユーザー($aur_user)を使用します。この設定は/tmp/userに保存されます。"
        else
            ask_user
        fi
        while [ $(user_check $aur_user) = 1 ]; do
            error 600 100 "指定されたユーザー($aur_user)は正しくありません。"
            ask_user
        done
        if [[ -f /tmp/user ]]; then
            rm -f /tmp/user
        fi
        echo -n 'aur_user=' > /tmp/user
        echo "$aur_user" >> /tmp/user
        export aur_user=$aur_user
    fi
fi
set -eu



#-- クリーンアップ --#
function cleanup () {
    $pacman -Scc --noconfirm　| loading 600 100 "クリーンアップを実行中です。"
    if [[ $ID = "arch" || $ID = "arch32" ]]; then
        if [[ -n $(pacman -Qttdq) ]]; then
            $pacman -Qttdq | $pacman -Rsnc - | loading 600 100 "クリーンアップを実行中です。"
        fi
    else
        $pacman -Rsn --noconfirm | loading 600 100 "クリーンアップを実行中です"
    fi
}



#-- データベースのアップデート --#
function update_db () {
    $pacman -Syy --noconfirm
}



#-- パッケージのアップグレード --#
function upgrade_pkg () {
    $pacman -Syu --noconfirm
}



#-- インストールとアンインストール --#
function install_and_uninstall () {
    # スクリプト読み込み
    scripts=($(cd $script_dir; ls *.entry; cd ..))
    for package in ${scripts[@]}; do
        source $script_dir/$package

        function check_func () {
            if [[ ! $(type -t $1) = "function" ]]; then
                error 600 100 "スクリプト$packageの$1関数が間違っています。"
                exit 1
            fi
        }
        function check_variable () {
            eval variable=$1
            if [[ -z $variable ]]; then
                error 600 100 "スクリプト$packageに$variable変数が間違っています。"
                exit 1
            fi
        }

        check_variable name
        check_variable package_name
        check_variable description
        check_variable run_preparing
        check_func install
        check_func uninstall
        if $run_preparing; then
            check_func preparing
        fi
        clear_variable
    done



    # リスト

    window \
        --warning \
        --width="600" \
        --height="100" \
        --text="スクリプトの読み込みを行います。これにはしばらく時間がかかる場合があります。\nしばらくたっても表示されない場合はターミナル上でスクリプトを実行してみてください。" \
        --ok-label="読み込み開始"

    gen_list () {
        window \
            --list \
            --checklist \
            --column="選択" \
            --column="パッケージ" \
            --column="インストール済" \
            --column="説明" \
            --width="900" \
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
    }

    selected_list=$(gen_list; exit_code=$?)
    selected_list=(${selected_list//'|'/ })
    if [[ ! $exit_code = 0 && -z $selected_list ]]; then
        error 600 100 "パッケージが選択されませんでした。トップに戻ります。"
        call_me $options
        exit
    fi


    # データベースの更新
    update_db | loading 600 100 "リポジトリデータベースを更新しています。"



    # 実行

    for selected in ${selected_list[@]}; do
        # 選択パッケージに対応しているファイルを探す
        scripts=($(cd $script_dir; ls *.entry; cd ..))
        for package in ${scripts[@]}; do
            set name
            set description
            set preparing
            set install

            source $script_dir/$package
            if [[ $name = $selected ]]; then
                break
            fi
            clear_variable
        done

        # インストール or アンインストール
        source $script_dir/$package

        if [[ $(check_pkg $package_name) = 1 ]]; then
            window \
                --question \
                --text="パッケージ$nameをインストールします。よろしいですか？" \
                --ok-label="続行する" \
                --cancel-label="中断する" \
                --width=600 \
                --height=100
            if $run_preparing; then
                preparing | loading 600 100 "パッケージをビルドしています"
            fi
            install | loading 600 100 "パッケージ$nameをインストールしています"
        else
            window \
                --question \
                --text="パッケージ$nameをアンインストールします。よろしいですか？" \
                --ok-label="続行する" \
                --cancel-label="中断する" \
                --width=600 \
                --height=100
            uninstall | loading 600 100 "パッケージ$nameをアンインストールしています。"
        fi
    done
    info 600 100 "処理が完了しました。\n詳細はターミナルを参照してください。"
}



#-- 実行 --#
set +eu
unset exit_code

# メニュー
if [[ ! $direct_execution = true ]]; then
    run=$(
        window \
            --info \
            --text="何を実行しますか？" \
            --ok-label="終了する" \
            $(
                # ArchLinux用メニュー
                if [[ $ID = "arch" || $ID = "arch32" ]]; then
                    echo "--extra-button=保存されているAURユーザーデータを削除"
                fi
            ) \
            --extra-button="パッケージのクリーンアップ" \
            --extra-button="パッケージのアップグレード" \
            --extra-button="パッケージの追加と削除" \
            --width="300" \
            --height="100"
    )
    exit_code=$?
    case $exit_code in
                0 ) exit 0 ;;
                * ) :;;
    esac
fi
case $run in
    "パッケージの追加と削除" ) install_and_uninstall ;;
    "パッケージのアップグレード" ) upgrade_pkg | loading 600 100 "パッケージのアップグレードを行っています。" ;;
    "保存されているAURユーザーデータを削除" ) rm -f /tmp/user ; info 600 100 "保存されているユーザーを削除しました" ; exit 0;;
    "パッケージのクリーンアップ" ) cleanup ;;
    * ) exit 1 ;;
esac
set -eu



#-- 最初に戻る --#
call_me $options
