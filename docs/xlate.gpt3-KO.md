# NAME

App::Greple::xlate - greple을 위한 번역 지원 모듈

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.3101

# DESCRIPTION

**Greple** **xlate** 모듈은 원하는 텍스트 블록을 찾아 번역된 텍스트로 대체합니다. 현재 DeepL (`deepl.pm`)과 ChatGPT (`gpt3.pm`) 모듈이 백엔드 엔진으로 구현되어 있습니다. gpt-4에 대한 실험적인 지원도 포함되어 있습니다.

만약 Perl의 pod 스타일로 작성된 문서에서 일반 텍스트 블록을 번역하려면 다음과 같이 `xlate::deepl`과 `perl` 모듈을 사용하는 **greple** 명령을 사용하십시오.

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

이 명령에서 패턴 문자열 `^(\w.*\n)+`은 알파벳과 숫자로 시작하는 연속된 줄을 의미합니다. 이 명령은 번역할 영역을 강조 표시합니다. 옵션 **--all**은 전체 텍스트를 생성하는 데 사용됩니다.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

그런 다음 선택한 영역을 번역하려면 `--xlate` 옵션을 추가하십시오. 그러면 원하는 섹션을 찾아 **deepl** 명령의 출력으로 대체합니다.

기본적으로 원본 및 번역된 텍스트는 [git(1)](http://man.he.net/man1/git)과 호환되는 "충돌 마커" 형식으로 출력됩니다. `ifdef` 형식을 사용하면 [unifdef(1)](http://man.he.net/man1/unifdef) 명령을 사용하여 원하는 부분을 쉽게 얻을 수 있습니다. 출력 형식은 **--xlate-format** 옵션으로 지정할 수 있습니다.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

전체 텍스트를 번역하려면 **--match-all** 옵션을 사용하십시오. 이는 전체 텍스트와 일치하는 `(?s).+` 패턴을 지정하는 단축키입니다.

충돌 표시자 형식 데이터는 `sdif` 명령어와 `-V` 옵션을 사용하여 측면별 스타일로 볼 수 있습니다. 문자열 단위로 비교하는 것은 의미가 없으므로 `--no-cdif` 옵션이 권장됩니다. 텍스트에 색상을 입힐 필요가 없다면 `--no-color` 또는 `--cm 'TEXT*='`를 지정하십시오.

    sdif -V --cm '*TEXT=' --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    매치된 영역마다 번역 프로세스를 호출합니다.

    이 옵션 없이 **greple**은 일반 검색 명령으로 동작합니다. 따라서 실제 작업을 호출하기 전에 파일의 어느 부분이 번역의 대상이 될지 확인할 수 있습니다.

    명령 결과는 표준 출력으로 전달되므로 필요한 경우 파일로 리디렉션하거나 [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) 모듈을 사용하는 것을 고려하십시오.

    옵션 **--xlate**은 **--xlate-color** 옵션을 **--color=never** 옵션과 함께 호출합니다.

    **--xlate-fold** 옵션으로 변환된 텍스트를 지정된 너비로 접힙니다. 기본 너비는 70이며 **--xlate-fold-width** 옵션으로 설정할 수 있습니다. 네 개의 열은 run-in 작업을 위해 예약되어 있으므로 각 줄에는 최대 74자까지 포함될 수 있습니다.

- **--xlate-engine**=_engine_

    사용할 번역 엔진을 지정합니다. `-Mxlate::deepl`과 같이 엔진 모듈을 직접 지정하는 경우에는 이 옵션을 사용할 필요가 없습니다.

- **--xlate-labor**
- **--xlabor**

    번역 엔진을 호출하는 대신, 직접 작업하도록 요청됩니다. 번역할 텍스트를 준비한 후, 해당 텍스트를 클립보드에 복사합니다. 그런 다음, 해당 텍스트를 양식에 붙여넣고, 결과를 클립보드에 복사한 후, Enter 키를 누르도록 요청됩니다.

- **--xlate-to** (Default: `EN-US`)

    대상 언어를 지정합니다. **DeepL** 엔진을 사용할 때 `deepl languages` 명령으로 사용 가능한 언어를 얻을 수 있습니다.

- **--xlate-format**=_format_ (Default: `conflict`)

    원본 및 번역된 텍스트의 출력 형식을 지정합니다.

    - **conflict**, **cm**

        원본과 변환된 텍스트는 [git(1)](http://man.he.net/man1/git) 충돌 표시자 형식으로 출력됩니다.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        다음 [sed(1)](http://man.he.net/man1/sed) 명령으로 원본 파일을 복구할 수 있습니다.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        원본과 변환된 텍스트는 [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` 형식으로 출력됩니다.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        **unifdef** 명령으로 일본어 텍스트만 검색할 수 있습니다:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        원본과 변환된 텍스트는 한 줄의 공백으로 구분되어 출력됩니다.

    - **xtxt**

        형식이 `xtxt` (번역된 텍스트)이거나 알 수 없는 경우, 번역된 텍스트만 출력됩니다.

- **--xlate-maxlen**=_chars_ (Default: 0)

    다음 텍스트를 한국어로 번역하십시오. 한 번에 API에 보낼 수 있는 텍스트의 최대 길이를 지정하십시오. 기본값은 무료 DeepL 계정 서비스에 대해 128K로 설정되어 있으며, 클립보드 인터페이스에 대해서는 5000으로 설정되어 있습니다. Pro 서비스를 사용하는 경우 이 값을 변경할 수 있을 수도 있습니다.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    STDERR 출력에서 실시간으로 번역 결과를 확인합니다.

- **--match-all**

    파일의 전체 텍스트를 대상 영역으로 설정합니다.

# CACHE OPTIONS

**xlate** 모듈은 각 파일의 번역 캐시 텍스트를 저장하고 실행 전에 읽어들여 서버에 요청하는 오버헤드를 제거할 수 있습니다. 기본 캐시 전략인 `auto`로 설정하면 대상 파일에 대해 캐시 파일이 존재할 때만 캐시 데이터를 유지합니다.

- --cache-clear

    **--cache-clear** 옵션은 캐시 관리를 초기화하거나 모든 기존 캐시 데이터를 새로 고칠 때 사용할 수 있습니다. 이 옵션으로 실행하면 캐시 파일이 없는 경우 새로운 캐시 파일이 생성되고 이후 자동으로 유지됩니다.

- --xlate-cache=_strategy_
    - `auto` (Default)

        캐시 파일이 있으면 유지합니다.

    - `create`

        빈 캐시 파일을 생성하고 종료합니다.

    - `always`, `yes`, `1`

        대상이 일반 파일인 한 캐시를 계속 유지합니다.

    - `clear`

        먼저 캐시 데이터를 지웁니다.

    - `never`, `no`, `0`

        캐시 파일을 사용하지 않습니다.

    - `accumulate`

        기본 동작으로 캐시 파일에서 사용되지 않는 데이터가 제거됩니다. 이를 제거하지 않고 파일에 유지하려면 `accumulate`를 사용하십시오.

# COMMAND LINE INTERFACE

이 배포에 포함된 `xlate` 명령을 사용하여 이 모듈을 쉽게 명령 줄에서 사용할 수 있습니다. 사용법은 `xlate` 도움말 정보를 참조하십시오.

`xlate` 명령은 Docker 환경과 함께 작동하므로, 아무것도 설치하지 않은 상태에서 Docker가 사용 가능하다면 사용할 수 있습니다. `-D` 또는 `-C` 옵션을 사용하십시오.

또한, 다양한 문서 스타일에 대한 makefile이 제공되므로, 특별한 지정 없이 다른 언어로 번역할 수 있습니다. `-M` 옵션을 사용하십시오.

Docker와 make 옵션을 결합하여 Docker 환경에서 make를 실행할 수도 있습니다.

`xlate -GC`와 같이 실행하면 현재 작업 중인 git 저장소가 마운트된 셸이 시작됩니다.

자세한 내용은 ["SEE ALSO"](#see-also) 섹션에 있는 일본어 기사를 읽어보세요.

    xlate [ options ] -t lang file [ greple options ]
        -h   help
        -v   show version
        -d   debug
        -n   dry-run
        -a   use API
        -c   just check translation area
        -r   refresh cache
        -s   silent mode
        -e # translation engine (default "deepl")
        -p # pattern to determine translation area
        -w # wrap line by # width
        -o # output format (default "xtxt", or "cm", "ifdef")
        -f # from lang (ignored)
        -t # to lang (required, no default)
        -m # max length per API call
        -l # show library files (XLATE.mk, xlate.el)
        --   terminate option parsing
    Make options
        -M   run make
        -n   dry-run
    Docker options
        -G   mount git top-level directory
        -B   run in non-interactive (batch) mode
        -R   mount read-only
        -E * specify environment variable to be inherited
        -I * specify altanative docker image (default: tecolicom/xlate:version)
        -D * run xlate on the container with the rest parameters
        -C * run following command on the container, or run shell

    Control Files:
        *.LANG    translation languates
        *.FORMAT  translation foramt (xtxt, cm, ifdef)
        *.ENGINE  translation engine (deepl or gpt3)

# EMACS

Emacs 편집기에서 `xlate` 명령을 사용하려면 저장소에 포함된 `xlate.el` 파일을 로드하십시오. `xlate-region` 함수는 지정된 영역을 번역합니다. 기본 언어는 `EN-US`이며 접두사 인수로 언어를 지정할 수 있습니다.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    DeepL 서비스의 인증 키를 설정하십시오.

- OPENAI\_API\_KEY

    OpenAI 인증 키입니다.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

DeepL과 ChatGPT의 명령 줄 도구를 설치해야 합니다.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

[https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python 라이브러리 및 CLI 명령입니다.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python 라이브러리

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI 명령 줄 인터페이스

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    대상 텍스트 패턴에 대한 자세한 내용은 **greple** 매뉴얼을 참조하십시오. 일치하는 영역을 제한하려면 **--inside**, **--outside**, **--include**, **--exclude** 옵션을 사용하십시오.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    **greple** 명령의 결과로 파일을 수정하는 데 `-Mupdate` 모듈을 사용할 수 있습니다.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    **-V** 옵션과 함께 충돌 마커 형식을 옆에 나란히 표시하려면 **sdif**를 사용하십시오.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    DeepL API를 사용하여 필요한 부분만 번역 및 교체하는 Greple 모듈 (일본어로)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    DeepL API 모듈을 사용하여 15개 언어로 문서 생성 (일본어로)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    DeepL API를 사용한 자동 번역 Docker 환경 (일본어로)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
