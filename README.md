# スクリーンショット
![スクリーンショット](https://raw.githubusercontent.com/Hayao0819/screenshots/master/eg-installer_2020-01-07_20-30-51.png)

# 概要
GUIでパッケージをインストールできるウィザードです。  
ArchLinux派生ディストリビューションを構築する際の初期セットアップとして作成しました。  

# 各ディストリビューション向けパッケージ
## ArchLinux
[こちらのPKGBUILD](https://github.com/Hayao0819/EG-Installer-PKGBUILD)よりビルドするか、[私のリポジトリ](https://github.com/Hayao0819/archlinux-repo)からインストールしてください。
## Ubuntu
SereneTeamが管理、開発を行っている[SereneStartdash](https://github.com/Hayao0819/serene-startdash)をご利用ください。

# 試しに使う
ArchLinuxの場合は、簡単に試すことができます。  

```bash
git clone https://github.com/Hayao0819/EG-Installer.git eg-installer/
cd eg-installer/
chmod +x eg-installer
./eg-installer -pa
```


# 依存関係
- bash
- polkit
- zenity

# アップデーターについて
アップデーターは[こちら](https://gist.github.com/Hayao0819/6135651937954048fd1cb3c31f6b64b5)にあります。  
このアップデーターはv1.6以降からのアップデートにのみ対応していますので、それ以前のバージョンでは使用しないでください。（正常にバージョン取得を行えずにエラーになります。）  
アップデーターはsoftwaresまで上書きするので、ディストリビューターは使用しないでください。
