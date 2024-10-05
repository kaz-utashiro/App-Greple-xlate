# NAME

App::Greple::xlate - greple을 위한 번역 지원 모듈  

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.37

# DESCRIPTION

**Greple** **xlate** 모듈은 원하는 텍스트 블록을 찾아 번역된 텍스트로 교체합니다. 현재 DeepL (`deepl.pm`) 및 ChatGPT (`gpt3.pm`) 모듈이 백엔드 엔진으로 구현되어 있습니다. gpt-4 및 gpt-4o에 대한 실험적 지원도 포함되어 있습니다.  

Perl의 pod 스타일로 작성된 문서에서 일반 텍스트 블록을 번역하려면 **greple** 명령을 `xlate::deepl` 및 `perl` 모듈과 함께 다음과 같이 사용하십시오:  

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

이 명령에서 패턴 문자열 `^(\w.*\n)+`는 알파벳 숫자 문자로 시작하는 연속적인 줄을 의미합니다. 이 명령은 번역할 영역을 강조 표시하여 보여줍니다. 옵션 **--all**은 전체 텍스트를 생성하는 데 사용됩니다.  

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

그런 다음 `--xlate` 옵션을 추가하여 선택한 영역을 번역합니다. 그러면 원하는 섹션을 찾아 **deepl** 명령 출력으로 교체합니다.  

기본적으로 원본 및 번역된 텍스트는 [git(1)](http://man.he.net/man1/git)과 호환되는 "충돌 마커" 형식으로 인쇄됩니다. `ifdef` 형식을 사용하면 [unifdef(1)](http://man.he.net/man1/unifdef) 명령으로 원하는 부분을 쉽게 얻을 수 있습니다. 출력 형식은 **--xlate-format** 옵션으로 지정할 수 있습니다.  

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

전체 텍스트를 번역하려면 **--match-all** 옵션을 사용하십시오. 이는 전체 텍스트와 일치하는 패턴 `(?s).+`를 지정하는 단축키입니다.  

충돌 마커 형식 데이터는 `sdif` 명령과 `-V` 옵션을 사용하여 나란히 스타일로 볼 수 있습니다. 문자열 단위로 비교하는 것은 의미가 없으므로 `--no-cdif` 옵션을 권장합니다. 텍스트에 색상을 지정할 필요가 없다면 `--no-textcolor` (또는 `--no-tc`)를 지정하십시오.  

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

처리는 지정된 단위로 수행되지만, 비어 있지 않은 텍스트의 여러 줄이 연속된 경우 함께 하나의 줄로 변환됩니다. 이 작업은 다음과 같이 수행됩니다:  

- 각 줄의 시작과 끝에서 공백을 제거합니다.  
- 줄이 전각 구두점 문자로 끝나면 다음 줄과 연결합니다.  
- 줄이 전각 문자로 끝나고 다음 줄이 전각 문자로 시작하면 줄을 연결합니다.  
- 줄의 끝이나 시작이 전각 문자가 아닌 경우 공백 문자를 삽입하여 연결합니다.  

캐시 데이터는 정규화된 텍스트를 기반으로 관리되므로 정규화 결과에 영향을 미치지 않는 수정이 이루어져도 캐시된 번역 데이터는 여전히 유효합니다.  

이 정규화 과정은 첫 번째(0번째) 및 짝수 패턴에 대해서만 수행됩니다. 따라서 두 개의 패턴이 다음과 같이 지정되면, 첫 번째 패턴과 일치하는 텍스트는 정규화 후에 처리되고, 두 번째 패턴과 일치하는 텍스트에는 정규화 과정이 수행되지 않습니다.  

    greple -Mxlate -E normalized -E not-normalized

따라서 여러 줄을 하나의 줄로 결합하여 처리할 텍스트에는 첫 번째 패턴을 사용하고, 미리 형식이 지정된 텍스트에는 두 번째 패턴을 사용하십시오. 첫 번째 패턴에서 일치하는 텍스트가 없으면 `(?!)`와 같이 아무것도 일치하지 않는 패턴을 사용하십시오.

# MASKING

가끔 번역하고 싶지 않은 텍스트 부분이 있습니다. 예를 들어, 마크다운 파일의 태그입니다. DeepL은 이러한 경우 번역에서 제외할 텍스트 부분을 XML 태그로 변환한 후 번역이 완료된 후 복원할 것을 제안합니다. 이를 지원하기 위해 번역에서 마스킹할 부분을 지정할 수 있습니다.  

    --xlate-setopt maskfile=MASKPATTERN

이것은 파일 \`MASKPATTERN\`의 각 줄을 정규 표현식으로 해석하고, 일치하는 문자열을 번역한 후 처리 후 되돌립니다. `#`로 시작하는 줄은 무시됩니다.  

이 인터페이스는 실험적이며 향후 변경될 수 있습니다.  

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    일치하는 각 영역에 대해 번역 프로세스를 호출합니다.  

    이 옵션이 없으면 **greple**는 일반 검색 명령처럼 작동합니다. 따라서 실제 작업을 시작하기 전에 파일의 어떤 부분이 번역 대상이 될지 확인할 수 있습니다.  

    명령 결과는 표준 출력으로 가므로 필요에 따라 파일로 리디렉션하거나 [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) 모듈을 사용하는 것을 고려하십시오.  

    옵션 **--xlate**는 **--xlate-color** 옵션을 **--color=never** 옵션과 함께 호출합니다.  

    **--xlate-fold** 옵션을 사용하면 변환된 텍스트가 지정된 너비로 접힙니다. 기본 너비는 70이며 **--xlate-fold-width** 옵션으로 설정할 수 있습니다. 실행 작업을 위해 네 개의 열이 예약되어 있으므로 각 줄은 최대 74자를 포함할 수 있습니다.  

- **--xlate-engine**=_engine_

    사용할 번역 엔진을 지정합니다. `-Mxlate::deepl`와 같이 엔진 모듈을 직접 지정하면 이 옵션을 사용할 필요가 없습니다.  

    현재 다음 엔진을 사용할 수 있습니다.  

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4-turbo
    - **gpt4o**: gpt-4o-mini

        **gpt-4o**의 인터페이스는 불안정하며 현재 올바르게 작동할 것이라고 보장할 수 없습니다.  

- **--xlate-labor**
- **--xlabor**

    번역 엔진을 호출하는 대신 작업을 수행할 것으로 예상됩니다. 번역할 텍스트를 준비한 후 클립보드에 복사됩니다. 양식에 붙여넣고 결과를 클립보드에 복사한 후 반환 키를 누르기를 기대합니다.  

- **--xlate-to** (Default: `EN-US`)

    대상 언어를 지정합니다. **DeepL** 엔진을 사용할 때 `deepl languages` 명령으로 사용 가능한 언어를 확인할 수 있습니다.  

- **--xlate-format**=_format_ (Default: `conflict`)

    원본 및 번역된 텍스트의 출력 형식을 지정합니다.  

    `xtxt` 이외의 다음 형식은 번역할 부분이 여러 줄의 모음이라고 가정합니다. 실제로는 줄의 일부만 번역할 수 있으며, `xtxt` 이외의 형식을 지정하면 의미 있는 결과를 생성하지 않습니다.  

    - **conflict**, **cm**

        원본 및 변환된 텍스트는 [git(1)](http://man.he.net/man1/git) 충돌 마커 형식으로 인쇄됩니다.  

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        다음 [sed(1)](http://man.he.net/man1/sed) 명령으로 원본 파일을 복구할 수 있습니다.  

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        원본 및 변환된 텍스트는 [git(1)](http://man.he.net/man1/git) 마크다운 **div** 블록 스타일 표기법으로 인쇄됩니다.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        이것은:

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        기본적으로 콜론의 수는 7입니다. `:::::`와 같은 콜론 시퀀스를 지정하면 7개의 콜론 대신 사용됩니다.

    - **ifdef**

        원본 및 변환된 텍스트는 [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` 형식으로 인쇄됩니다.  

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        **unifdef** 명령으로 일본어 텍스트만 검색할 수 있습니다:  

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Original and converted text are printed separated by single blank line. 
        원본 및 변환된 텍스트는 단일 공백 줄로 구분되어 인쇄됩니다.
        For `space+`, it also outputs a newline after the converted text.
        `space+`의 경우, 변환된 텍스트 뒤에 새 줄도 출력됩니다.

    - **xtxt**

        형식이 `xtxt` (번역된 텍스트) 또는 알 수 없는 경우, 번역된 텍스트만 인쇄됩니다.  

- **--xlate-maxlen**=_chars_ (Default: 0)

    한 번에 API에 전송할 최대 텍스트 길이를 지정합니다. 기본값은 무료 DeepL 계정 서비스에 대해 설정되어 있습니다: API (**--xlate**)는 128K, 클립보드 인터페이스 (**--xlate-labor**)는 5000입니다. Pro 서비스를 사용하는 경우 이러한 값을 변경할 수 있습니다.  

- **--xlate-maxline**=_n_ (Default: 0)

    한 번에 API에 전송할 최대 텍스트 줄 수를 지정합니다.

    이 값을 1로 설정하면 한 번에 한 줄씩 번역할 수 있습니다. 이 옵션은 `--xlate-maxlen` 옵션보다 우선합니다.  

- **--**\[**no-**\]**xlate-progress** (Default: True)

    STDERR 출력에서 실시간으로 번역 결과를 확인하세요.  

- **--match-all**

    파일의 전체 텍스트를 대상 영역으로 설정합니다.  

# CACHE OPTIONS

**xlate** 모듈은 각 파일에 대한 번역의 캐시된 텍스트를 저장하고 실행 전에 이를 읽어 서버에 요청하는 오버헤드를 제거할 수 있습니다. 기본 캐시 전략 `auto`를 사용하면 대상 파일에 대한 캐시 파일이 존재할 때만 캐시 데이터를 유지합니다.  

- --cache-clear

    **--cache-clear** 옵션은 캐시 관리를 시작하거나 기존의 모든 캐시 데이터를 새로 고치는 데 사용할 수 있습니다. 이 옵션으로 실행하면 캐시 파일이 존재하지 않을 경우 새 캐시 파일이 생성되고 이후 자동으로 유지됩니다.  

- --xlate-cache=_strategy_
    - `auto` (Default)

        캐시 파일이 존재하는 경우 유지합니다.  

    - `create`

        빈 캐시 파일을 생성하고 종료합니다.  

    - `always`, `yes`, `1`

        대상이 정상 파일인 한 캐시를 어쨌든 유지합니다.  

    - `clear`

        먼저 캐시 데이터를 지웁니다.  

    - `never`, `no`, `0`

        캐시 파일이 존재하더라도 절대 사용하지 않습니다.  

    - `accumulate`

        기본 동작으로 사용되지 않는 데이터는 캐시 파일에서 제거됩니다. 제거하지 않고 파일에 유지하려면 `accumulate`를 사용하세요.  

# COMMAND LINE INTERFACE

배포에 포함된 `xlate` 명령을 사용하여 명령줄에서 이 모듈을 쉽게 사용할 수 있습니다. 사용법은 `xlate` 도움말 정보를 참조하세요.  

`xlate` 명령은 Docker 환경과 함께 작동하므로, 손에 설치된 것이 없어도 Docker가 사용 가능하면 사용할 수 있습니다. `-D` 또는 `-C` 옵션을 사용하세요.  

또한 다양한 문서 스타일에 대한 메이크파일이 제공되므로 특별한 명시 없이 다른 언어로 번역할 수 있습니다. `-M` 옵션을 사용하세요.  

Docker와 메이크 옵션을 결합하여 Docker 환경에서 메이크를 실행할 수 있습니다.  

`xlate -GC`와 같이 실행하면 현재 작업 중인 git 리포지토리가 마운트된 셸이 시작됩니다.  

자세한 내용은 ["SEE ALSO"](#see-also) 섹션의 일본어 기사를 읽으세요.  

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

Emacs 편집기에서 `xlate` 명령을 사용하려면 리포지토리에 포함된 `xlate.el` 파일을 로드하세요. `xlate-region` 함수는 주어진 영역을 번역합니다. 기본 언어는 `EN-US`이며 접두사 인수를 사용하여 언어를 지정할 수 있습니다.  

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    DeepL 서비스에 대한 인증 키를 설정하세요.  

- OPENAI\_API\_KEY

    OpenAI 인증 키.  

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

DeepL 및 ChatGPT를 위한 명령줄 도구를 설치해야 합니다.  

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)  

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)  

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)  

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)  

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)  

[https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)  

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python 라이브러리 및 CLI 명령.  

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python 라이브러리  

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI 명령줄 인터페이스  

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    대상 텍스트 패턴에 대한 자세한 내용은 **greple** 매뉴얼을 참조하세요. **--inside**, **--outside**, **--include**, **--exclude** 옵션을 사용하여 일치하는 영역을 제한하세요.  

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    `-Mupdate` 모듈을 사용하여 **greple** 명령의 결과로 파일을 수정할 수 있습니다.  

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    **sdif**를 사용하여 **-V** 옵션과 함께 충돌 마커 형식을 나란히 표시합니다.  

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    DeepL API를 사용하여 필요한 부분만 번역하고 교체하는 Greple 모듈 (일본어)  

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    DeepL API 모듈을 사용하여 15개 언어로 문서 생성 (일본어)  

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    자동 번역 Docker 환경 DeepL API와 함께 (일본어로)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.