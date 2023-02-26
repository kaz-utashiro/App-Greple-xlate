# NAME

App::Greple::xlate - greple 用の翻訳サポートモジュール

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

# DESCRIPTION

**Greple** **xlate** モジュールは、テキストブロックを見つけ、翻訳されたテキストに置き換える。現在、**xlate::deepl**モジュールが対応しているのはDeepLサービスのみである。

[pod](https://metacpan.org/pod/pod)形式の文書中の通常のテキストブロックを翻訳したい場合は、**greple**コマンドと`xlate::deepl`モジュール、`perl`モジュールを使って、以下のようにする。

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

パターン `^(\w.*n)+` は、英数字で始まる連続した行を意味する。このコマンドは、翻訳される領域を表示する。オプション**--all**は、テキスト全体を翻訳するために使用する。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

次に、`--xlate`オプションを追加して、選択された領域を翻訳する。これは、**deepl**コマンドの出力でそれらを見つけて置き換える。

デフォルトでは、原文と訳文が [git(1)](http://man.he.net/man1/git) と互換性のある "conflict marker" フォーマットで出力される。`ifdef` 形式を用いると、[unifdef(1)](http://man.he.net/man1/unifdef) コマンドで簡単に目的の部分を得ることができる。**--xlate-format**オプションでフォーマットを指定することができる。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

テキスト全体を翻訳したい場合は、**--match-entire**オプションを使用する。これは、`(?s).*`というテキスト全体にマッチするパターンを指定するためのショートカットである。

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    マッチした部分ごとに翻訳処理を起動する。

    このオプションがない場合、**greple**は通常の検索コマンドとして動作する。したがって、ファイルのどの部分が翻訳の対象となるかを、実際の作業を始める前に確認することができる。

    コマンドの結果は標準出力されますので、必要に応じてファイルにリダイレクトするか、[App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)モジュールの使用を検討してください。

    **--xlate**オプションは、**--xlate-color**オプションを**--color=never**オプションで呼び出する。

    **--xlate-fold**オプションでは、変換されたテキストを指定した幅で折り返す。デフォルトの幅は70で、**--xlate-fold-width**オプションで設定することができる。ランイン動作のために4列が確保されているので、1行には最大で74文字が格納できる。

- **--xlate-engine**=_engine_

    使用する翻訳エンジンを指定する。モジュール`xlate::deepl`で`--xlate-engine=deepl`として宣言されているので、このオプションを使う必要はない。

- **--xlate-to** (Default: `JA`)

    ターゲット言語を指定する。**DeepL**エンジン使用時は、`deepl languages`コマンドで利用可能な言語を取得できる。

- **--xlate-format**=_format_ (Default: conflict)

    原文と訳文の出力形式を指定する。

    - **conflict**

        原文と訳文を[git(1)](http://man.he.net/man1/git)コンフリクトマーカー形式で出力する。

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        次の[sed(1)](http://man.he.net/man1/sed)コマンドで元のファイルを復元することができる。

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        原文と訳文を[cpp(1)](http://man.he.net/man1/cpp) `#ifdef`形式で出力する。

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        **unifdef**コマンドで日本語テキストのみを取り出すことができる。

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        原文と訳文を1行の空白で区切って表示する。

    - **none**

        `none`またはunknownの場合、翻訳されたテキストのみが表示される。

- **--**\[**no-**\]**xlate-progress** (Default: True)

    翻訳結果はSTDERR出力にリアルタイムで表示される。

- **--match-entire**

    ファイルの全テキストを対象範囲に設定する。

# CACHE OPTIONS

**xlate**モジュールは、各ファイルの翻訳テキストをキャッシュしておき、実行前にそれを読むことで、サーバーへの問い合わせのオーバーヘッドをなくすことができる。デフォルトのキャッシュ戦略`auto`では、対象ファイルに対してキャッシュファイルが存在する場合のみ、キャッシュデータを保持する。対応するキャッシュファイルが存在しない場合は、作成しない。

- --xlate-cache=_strategy_
    - `auto` (Default)

        キャッシュファイルが存在する場合は、それを保持する。

    - `create`

        空のキャッシュ・ファイルを作成して終了する。

    - `always`, `yes`, `1`

        対象が通常ファイルである限り、とにかくキャッシュを維持する。

    - `never`, `no`, `0`

        キャッシュ・ファイルが存在しても、決して使用しない。

    - `accumulate`

        デフォルトの動作では、未使用のデータはキャッシュファイルから削除される。削除せずに保持する場合は、`蓄積`を使用してください。

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    DeepLサービス用の認証キーを設定する。

# SEE ALSO

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL PythonライブラリとCLIコマンドを使用する。

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    対象テキストパターンの詳細については、**greple**のマニュアルを参照してください。**--inside**, **--outside**, **--include**, **--exclude**オプションでマッチング範囲を限定してください。

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    `-Mupdate`モジュールを用いると、**greple**コマンドの結果をもとにファイルを修正することができる。

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    **sdif**を使用すると、**-V**オプションと並べてコンフリクトマーカのフォーマットを表示することができる。

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
