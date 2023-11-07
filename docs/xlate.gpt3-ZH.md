# NAME

App::Greple::xlate - greple的翻译支持模块

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.26

# DESCRIPTION

**Greple** **xlate**模块通过查找文本块并用翻译后的文本替换它们。包括DeepL（`deepl.pm`）和ChatGPT（`gpt3.pm`）模块作为后端引擎。

如果您想要翻译[pod](https://metacpan.org/pod/pod)样式文档中的普通文本块，请使用以下命令：**greple**命令与`xlate::deepl`和`perl`模块一起使用，如下所示：

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

模式`^(\w.*\n)+`表示以字母数字字符开头的连续行。此命令显示要翻译的区域。选项**--all**用于生成整个文本。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

然后添加`--xlate`选项来翻译所选区域。它将找到并用**deepl**命令的输出替换它们。

默认情况下，原始文本和翻译后的文本以与[git(1)](http://man.he.net/man1/git)兼容的"冲突标记"格式打印。使用`ifdef`格式，您可以通过[unifdef(1)](http://man.he.net/man1/unifdef)命令轻松获取所需部分。可以通过**--xlate-format**选项指定格式。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

如果要翻译整个文本，请使用**--match-all**选项。这是指定模式匹配整个文本`(?s).+`的快捷方式。

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    为每个匹配的区域调用翻译过程。

    如果没有此选项，**greple**将作为普通搜索命令运行。因此，在调用实际工作之前，您可以检查文件的哪个部分将成为翻译的对象。

    命令结果输出到标准输出，如果需要，请重定向到文件，或考虑使用[App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)模块。

    选项**--xlate**调用**--xlate-color**选项，并带有**--color=never**选项。

    使用**--xlate-fold**选项，转换后的文本将按指定的宽度折叠。默认宽度为70，可以通过**--xlate-fold-width**选项设置。四列用于run-in操作，因此每行最多可以容纳74个字符。

- **--xlate-engine**=_engine_

    指定要使用的翻译引擎。如果直接指定引擎模块，如`-Mxlate::deepl`，则不需要使用此选项。

- **--xlate-labor**
- **--xlabor**

    而不是调用翻译引擎，您需要为其工作。在准备好要翻译的文本后，将其复制到剪贴板。您需要将其粘贴到表单中，将结果复制到剪贴板，并按回车键。

- **--xlate-to** (Default: `EN-US`)

    指定目标语言。使用**DeepL**引擎时，可以通过`deepl languages`命令获取可用语言。

- **--xlate-format**=_format_ (Default: `conflict`)

    指定原始和翻译文本的输出格式。

    - **conflict**, **cm**

        以[git(1)](http://man.he.net/man1/git)冲突标记格式打印原始和翻译文本。

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        您可以通过下一个[sed(1)](http://man.he.net/man1/sed)命令恢复原始文件。

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        以[cpp(1)](http://man.he.net/man1/cpp) `#ifdef`格式打印原始和翻译文本。

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        您可以通过**unifdef**命令仅检索日语文本：

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        以单个空行分隔打印原始和翻译文本。

    - **xtxt**

        如果格式为`xtxt`（翻译文本）或未知，则仅打印翻译文本。

- **--xlate-maxlen**=_chars_ (Default: 0)

    指定一次发送到API的文本的最大长度。默认值设置为免费帐户服务的值：API为128K（**--xlate**），剪贴板接口为5000（**--xlate-labor**）。如果您使用专业服务，可以更改这些值。

- **--**\[**no-**\]**xlate-progress** (Default: True)

    将以下文本翻译成中文。

- **--match-all**

    在 STDERR 输出中实时查看翻译结果。

# CACHE OPTIONS

将整个文件的文本设置为目标区域。

- --cache-clear

    **xlate** 模块可以为每个文件存储翻译的缓存文本，并在执行之前读取它，以消除向服务器请求的开销。使用默认的缓存策略 `auto`，它仅在目标文件的缓存文件存在时维护缓存数据。

- --xlate-cache=_strategy_
    - `auto` (Default)

        **--cache-clear** 选项可用于初始化缓存管理或刷新所有现有的缓存数据。执行此选项后，如果不存在缓存文件，则会创建一个新的缓存文件，然后自动进行维护。

    - `create`

        如果缓存文件存在，则维护缓存文件。

    - `always`, `yes`, `1`

        创建空的缓存文件并退出。

    - `clear`

        只要目标是普通文件，就始终维护缓存。

    - `never`, `no`, `0`

        首先清除缓存数据。

    - `accumulate`

        即使存在缓存文件，也不要使用缓存文件。

# COMMAND LINE INTERFACE

默认情况下，未使用的数据将从缓存文件中删除。如果您不想删除它们并保留在文件中，请使用 `accumulate`。

# EMACS

您可以通过使用存储库中包含的 `xlate` 命令从命令行轻松使用此模块。有关用法，请参阅 `xlate` 帮助信息。

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    加载存储库中包含的 `xlate.el` 文件以从 Emacs 编辑器中使用 `xlate` 命令。`xlate-region` 函数翻译给定的区域。默认语言为 `EN-US`，您可以使用前缀参数调用它来指定语言。

- OPENAI\_API\_KEY

    OpenAI身份验证密钥。

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

您需要安装DeepL和ChatGPT的命令行工具。

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

为 DeepL 服务设置您的身份验证密钥。

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    [App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python库

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI命令行界面

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    DeepL Python 库和 CLI 命令。

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    有关目标文本模式的详细信息，请参阅 **greple** 手册。使用 **--inside**、**--outside**、**--include**、**--exclude** 选项来限制匹配区域。

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    您可以使用 `-Mupdate` 模块根据 **greple** 命令的结果修改文件。

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.