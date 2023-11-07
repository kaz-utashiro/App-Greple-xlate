# NAME

App::Greple::xlate - grepleの翻訳サポートモジュール

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.26

# DESCRIPTION

**Greple** **xlate**モジュールは、テキストブロックを検索して翻訳テキストで置き換える機能を提供します。バックエンドエンジンとしてDeepL（`deepl.pm`）とChatGPT（`gpt3.pm`）モジュールを含めてください。

[pod](https://metacpan.org/pod/pod)スタイルのドキュメントで通常のテキストブロックを翻訳する場合は、次のように`xlate::deepl`と`perl`モジュールを使用して**greple**コマンドを使用します：

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

パターン`^(\w.*\n)+`は、英数字で始まる連続した行を意味します。このコマンドは翻訳対象のエリアを表示します。オプション**--all**は、全体のテキストを生成するために使用されます。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

次に、選択したエリアを翻訳するために`--xlate`オプションを追加します。これにより、**deepl**コマンドの出力でそれらが検索され、置換されます。

デフォルトでは、元のテキストと翻訳されたテキストは[git(1)](http://man.he.net/man1/git)と互換性のある「競合マーカー」形式で表示されます。`ifdef`形式を使用すると、[unifdef(1)](http://man.he.net/man1/unifdef)コマンドで所望の部分を取得できます。形式は**--xlate-format**オプションで指定できます。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

テキスト全体を翻訳する場合は、**--match-all**オプションを使用します。これは、パターンがテキスト全体に一致することを指定するためのショートカットです（`(?s).+`）。

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    一致したエリアごとに翻訳プロセスを呼び出します。

    このオプションを指定しない場合、**greple**は通常の検索コマンドとして動作します。したがって、実際の作業を呼び出す前に、ファイルのどの部分が翻訳の対象になるかを確認できます。

    コマンドの結果は標準出力に表示されるため、必要に応じてファイルにリダイレクトするか、[App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)モジュールを使用することを検討してください。

    オプション**--xlate**は、**--xlate-color**オプションを**--color=never**オプションとともに呼び出します。

    **--xlate-fold**オプションを使用すると、変換されたテキストが指定された幅で折り返されます。デフォルトの幅は70で、**--xlate-fold-width**オプションで設定できます。4つの列はランイン操作に予約されているため、各行には最大で74文字が含まれることができます。

- **--xlate-engine**=_engine_

    使用する翻訳エンジンを指定します。`-Mxlate::deepl`のようにエンジンモジュールを直接指定する場合は、このオプションを使用する必要はありません。

- **--xlate-labor**
- **--xlabor**

    翻訳エンジンを呼び出す代わりに、翻訳するためのテキストを準備し、クリップボードにコピーします。フォームに貼り付け、結果をクリップボードにコピーしてEnterキーを押すことを期待しています。

- **--xlate-to** (Default: `EN-US`)

    対象言語を指定します。**DeepL**エンジンを使用する場合は、`deepl languages`コマンドで使用可能な言語を取得できます。

- **--xlate-format**=_format_ (Default: `conflict`)

    元のテキストと翻訳されたテキストの出力形式を指定します。

    - **conflict**, **cm**

        元のテキストと翻訳されたテキストを[git(1)](http://man.he.net/man1/git)の競合マーカー形式で表示します。

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        次の[sed(1)](http://man.he.net/man1/sed)コマンドで元のファイルを復元できます。

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        元のテキストと翻訳されたテキストを[cpp(1)](http://man.he.net/man1/cpp)の`#ifdef`形式で表示します。

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        **unifdef**コマンドで日本語のテキストのみを取得できます：

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        元のテキストと翻訳されたテキストを1つの空白行で区切って表示します。

    - **xtxt**

        形式が`xtxt`（翻訳されたテキスト）または不明な場合、翻訳されたテキストのみが表示されます。

- **--xlate-maxlen**=_chars_ (Default: 0)

    一度にAPIに送信されるテキストの最大長を指定します。デフォルト値は無料アカウントサービス用に設定されています：API用に128K、クリップボードインターフェース用に5000です。Proサービスを使用している場合は、これらの値を変更できる場合があります。

- **--**\[**no-**\]**xlate-progress** (Default: True)

    STDERR出力でリアルタイムに翻訳結果を確認します。

- **--match-all**

    ファイルの全体のテキストを対象エリアとして設定します。

# CACHE OPTIONS

**xlate**モジュールは、各ファイルの翻訳のキャッシュテキストを保存し、実行前にそれを読み込んでサーバーへの問い合わせのオーバーヘッドを排除することができます。デフォルトのキャッシュ戦略`auto`では、対象ファイルのキャッシュファイルが存在する場合にのみキャッシュデータを保持します。

- --cache-clear

    **--cache-clear**オプションを使用してキャッシュ管理を開始するか、すべての既存のキャッシュデータを更新できます。このオプションで実行すると、キャッシュファイルが存在しない場合は新しいキャッシュファイルが作成され、その後自動的にメンテナンスされます。

- --xlate-cache=_strategy_
    - `auto` (Default)

        キャッシュファイルが存在する場合はメンテナンスします。

    - `create`

        空のキャッシュファイルを作成して終了します。

    - `always`, `yes`, `1`

        対象が通常のファイルである限り、常にキャッシュをメンテナンスします。

    - `clear`

        まずキャッシュデータをクリアします。

    - `never`, `no`, `0`

        キャッシュファイルを使用しないでください。

    - `accumulate`

        デフォルトの動作では、キャッシュファイルから未使用のデータが削除されます。それらを削除せずにファイルに保持したい場合は、`accumulate`を使用してください。

# COMMAND LINE INTERFACE

コマンドラインからは、リポジトリに含まれる`xlate`コマンドを使用して、このモジュールを簡単に利用することができます。使用方法については、`xlate`のヘルプ情報を参照してください。

# EMACS

Emacsエディタから`xlate`コマンドを使用するには、リポジトリに含まれる`xlate.el`ファイルをロードしてください。`xlate-region`関数は指定された領域を翻訳します。デフォルトの言語は`EN-US`であり、プレフィックス引数を使用して言語を指定することができます。

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    DeepLサービスの認証キーを設定してください。

- OPENAI\_API\_KEY

    OpenAIの認証キーです。

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

DeepLとChatGPTのコマンドラインツールをインストールする必要があります。

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL PythonライブラリとCLIコマンドです。

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Pythonライブラリ

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAIコマンドラインインターフェース

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    対象のテキストパターンに関する詳細については、**greple**マニュアルを参照してください。一致する範囲を制限するために、**--inside**、**--outside**、**--include**、**--exclude**オプションを使用できます。

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    **greple**コマンドの結果を使用してファイルを変更するために、`-Mupdate`モジュールを使用することができます。

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    **-V**オプションとともに、衝突マーカーフォーマットを並べて表示するために**sdif**を使用してください。

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.