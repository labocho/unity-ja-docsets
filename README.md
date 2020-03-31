# 概要

日本語の Unity ドキュメンテーション (https://docs.unity3d.com/ja/) を Dash (http://kapeli.com/) で閲覧できる形式 (Docset) にするツールです。


# 使い方

Ruby (>= 2.5.0), bundler, git が必要です。

    git clone git://github.com/labocho/unity-ja-docsets.git
    cd unity-ja-docsets
    bundle install

    # 作成可能なバージョンのリストを表示
    bin/rake versions
    # 指定したバージョンの Docset を作成してインストールします
    bin/rake install VERSION=2019.3

Dash を再起動すればインストールしたドキュメントが追加されます。

# ライセンス

- 本ソフトウェアは MIT License (http://www.opensource.org/licenses/mit-license.php) で提供します。
