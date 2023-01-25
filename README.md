[![Actions Status](https://github.com/kaz-utashiro/App-Greple-deepl/actions/workflows/test.yml/badge.svg)](https://github.com/kaz-utashiro/App-Greple-deepl/actions)
# NAME

App::Greple::deepl - deepl module for greple

# SYNOPSIS

    greple -Mdeepl --xlate target-file

# DESCRIPTION

**Greple** **deepl** module find text blocks and replace them by the
translated text produced by the **deepl** command.

If you want to translate normal text block in [pod](https://metacpan.org/pod/pod) style document,
use **greple** command with `deepl` and `perl` module like this:

    greple -Mdeepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Pattern `^(\w.*\n)+` means consecutive lines starting with
alpha-numeric character.  This command will find and replace them by
the **deepl** command output.

Option **--all** is used to produce entire text.

By default, original and translated text is printed in the conflict
marker format compatible with [git(1)](http://man.he.net/man1/git).  Using `ifdef` format, you
can get desired part by [unifdef(1)](http://man.he.net/man1/unifdef) command easily.  Format can be
specified by **--deepl-format** option.

If you want to translate entire text, use **--deepl-match-entire**
option.  This is a short-cut to specify the pattern matches entire
text `(?s).*`.

# OPTIONS

- **--xlate**

    Invoke the translation process for each matched area.

    Without this option, **greple** behaves as a normal search command.  So
    you can check which part of the file will be subject of the
    translation before invoking actual work.

    Command result goes to standard out, so redirect to file if necessary,
    or consider to use [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) module.

- **--xlate-to** (DEFAULT: `JA`)

    Specify the target language.  You can get available languages by
    `deepl languages` command.

- **--deepl-format**=_format_ (DEFAULT: conflict)

    Specify the output format for original and translated text.

    - **conflict**

        Print original and translated text in [git(1)](http://man.he.net/man1/git) conflict marker format.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        You can recover the original file by next [sed(1)](http://man.he.net/man1/sed) command.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        Print original and translated text in [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` format.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        You can retrieve only Japanese text by the **unifdef** command:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        Print original and translated text separated by single blank line.

    - **none**

        If the format is `none` or unkown, only translated text is printed.

- **--**\[**no-**\]**deepl-progress** (DEFAULT: True)

    See the tranlsation result in real time in the STDERR output.

- **--**\[**no-**\]**deepl-join** (DEFAULT: True)

    By default, continuous non-space lines are connected together to make
    a single line paragraph.  If you don't need this operation, use
    **--no-deepl-join** option.

- **--deepl-fold**
- **--deepl-fold-width**=_n_ (DEFAULT: 70)

    Fold converted text by the specified width.  Default width is 70 and
    can be set by **--deepl-fold-width** option.  Four columns are reserved
    for run-in operation, so each line could hold 74 characters at most.

- **--deepl-match-entire**

    Set the whole text of the file as a target area.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Set your authentication key for DeepL service.

# SEE ALSO

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python library and CLI command.

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    See the **greple** manual for the detail about target text pattern.
    Use **--inside**, **--outside**, **--include**, **--exclude** options to
    limit the matching area.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    You can use `-Mupdate` module to modify files by the result of
    **greple** command.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright ©︎ 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
