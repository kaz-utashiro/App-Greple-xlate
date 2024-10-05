# NAME

App::Greple::xlate - модуль поддержки перевода для greple  

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.37

# DESCRIPTION

**Greple** **xlate** модуль находит желаемые текстовые блоки и заменяет их переведенным текстом. В настоящее время реализованы модули DeepL (`deepl.pm`) и ChatGPT (`gpt3.pm`) в качестве движка на стороне сервера. Экспериментальная поддержка gpt-4 и gpt-4o также включена.  

Если вы хотите перевести обычные текстовые блоки в документе, написанном в стиле pod Perl, используйте команду **greple** с `xlate::deepl` и `perl` следующим образом:  

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

В этой команде строка шаблона `^(\w.*\n)+` означает последовательные строки, начинающиеся с алфавитно-цифровой буквы. Эта команда показывает область, которую нужно перевести, выделенной. Опция **--all** используется для получения всего текста.  

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Затем добавьте опцию `--xlate`, чтобы перевести выбранную область. Затем она найдет желаемые секции и заменит их выводом команды **deepl**.  

По умолчанию оригинальный и переведенный текст выводятся в формате "маркер конфликта", совместимом с [git(1)](http://man.he.net/man1/git). Используя формат `ifdef`, вы можете легко получить желаемую часть с помощью команды [unifdef(1)](http://man.he.net/man1/unifdef). Формат вывода можно указать с помощью опции **--xlate-format**.  

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Если вы хотите перевести весь текст, используйте опцию **--match-all**. Это сокращение для указания шаблона `(?s).+`, который соответствует всему тексту.  

Данные формата маркера конфликта можно просмотреть в боковом стиле с помощью команды `sdif` с опцией `-V`. Поскольку нет смысла сравнивать на основе каждой строки, рекомендуется использовать опцию `--no-cdif`. Если вам не нужно окрашивать текст, укажите `--no-textcolor` (или `--no-tc`).  

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Обработка выполняется в указанных единицах, но в случае последовательности нескольких строк непустого текста они объединяются в одну строку. Эта операция выполняется следующим образом:  

- Удалите пробелы в начале и в конце каждой строки.  
- Если строка заканчивается символом пунктуации полного размера, объедините с следующей строкой.  
- Если строка заканчивается символом полного размера, а следующая строка начинается с символа полного размера, объедините строки.  
- Если либо конец, либо начало строки не является символом полного размера, объедините их, вставив пробел.  

Кэшированные данные управляются на основе нормализованного текста, поэтому даже если вносятся изменения, которые не влияют на результаты нормализации, кэшированные данные перевода все равно будут действительны.  

Этот процесс нормализации выполняется только для первого (0-го) и четных шаблонов. Таким образом, если два шаблона указаны следующим образом, текст, соответствующий первому шаблону, будет обработан после нормализации, и никакой процесс нормализации не будет выполнен для текста, соответствующего второму шаблону.  

    greple -Mxlate -E normalized -E not-normalized

Поэтому используйте первый шаблон для текста, который будет обрабатываться путем объединения нескольких строк в одну строку, и используйте второй шаблон для предварительно отформатированного текста. Если в первом шаблоне нет текста для сопоставления, то используйте шаблон, который не соответствует ничему, такой как `(?!)`.

# MASKING

Иногда есть части текста, которые вы не хотите переводить. Например, теги в markdown файлах. DeepL предлагает в таких случаях преобразовать часть текста, которую нужно исключить, в XML теги, перевести, а затем восстановить после завершения перевода. Чтобы поддержать это, можно указать части, которые нужно скрыть от перевода.  

    --xlate-setopt maskfile=MASKPATTERN

Это будет интерпретировать каждую строку файла \`MASKPATTERN\` как регулярное выражение, переводить строки, соответствующие ему, и восстанавливать после обработки. Строки, начинающиеся с `#`, игнорируются.  

Этот интерфейс является экспериментальным и может измениться в будущем.  

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Запустите процесс перевода для каждой совпадающей области.  

    Без этой опции **greple** ведет себя как обычная команда поиска. Так что вы можете проверить, какая часть файла будет подлежать переводу, прежде чем запускать фактическую работу.  

    Результат команды выводится в стандартный вывод, поэтому перенаправьте в файл, если это необходимо, или рассмотрите возможность использования модуля [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).  

    Опция **--xlate** вызывает опцию **--xlate-color** с опцией **--color=never**.  

    С опцией **--xlate-fold** преобразованный текст складывается по указанной ширине. Ширина по умолчанию составляет 70 и может быть установлена с помощью опции **--xlate-fold-width**. Четыре колонки зарезервированы для операции run-in, поэтому каждая строка может содержать максимум 74 символа.  

- **--xlate-engine**=_engine_

    Указывает используемый переводческий движок. Если вы указываете модуль движка напрямую, например `-Mxlate::deepl`, вам не нужно использовать эту опцию.  

    В настоящее время доступны следующие движки  

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4-turbo
    - **gpt4o**: gpt-4o-mini

        Интерфейс **gpt-4o** нестабилен и не может гарантировать правильную работу в данный момент.  

- **--xlate-labor**
- **--xlabor**

    Вместо вызова переводческого движка от вас ожидается работа. После подготовки текста для перевода он копируется в буфер обмена. От вас ожидается вставить его в форму, скопировать результат в буфер обмена и нажать Enter.  

- **--xlate-to** (Default: `EN-US`)

    Укажите целевой язык. Вы можете получить доступные языки с помощью команды `deepl languages`, когда используете движок **DeepL**.  

- **--xlate-format**=_format_ (Default: `conflict`)

    Укажите формат вывода для оригинального и переведенного текста.  

    Следующие форматы, кроме `xtxt`, предполагают, что часть, подлежащая переводу, представляет собой коллекцию строк. На самом деле возможно перевести только часть строки, и указание формата, отличного от `xtxt`, не даст значительных результатов.  

    - **conflict**, **cm**

        Оригинальный и преобразованный текст выводятся в формате [git(1)](http://man.he.net/man1/git) маркера конфликта.  

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Вы можете восстановить оригинальный файл с помощью следующей команды [sed(1)](http://man.he.net/man1/sed).  

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Оригинальный и преобразованный текст напечатаны в [git(1)](http://man.he.net/man1/git) разметке **div** в стиле блоков.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Это означает:

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Количество двоеточий по умолчанию равно 7. Если вы укажете последовательность двоеточий, например, `:::::`, она будет использоваться вместо 7 двоеточий.

    - **ifdef**

        Оригинальный и преобразованный текст выводятся в формате [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.  

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Вы можете получить только японский текст с помощью команды **unifdef**:  

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Оригинальный и преобразованный текст печатаются, разделенные одним пробелом.
        Для `space+` также выводится новая строка после преобразованного текста.

    - **xtxt**

        Если формат `xtxt` (переведенный текст) или неизвестен, выводится только переведенный текст.  

- **--xlate-maxlen**=_chars_ (Default: 0)

    Укажите максимальную длину текста, который будет отправлен в API за один раз. Значение по умолчанию установлено для бесплатного сервиса DeepL: 128K для API (**--xlate**) и 5000 для интерфейса буфера обмена (**--xlate-labor**). Вы можете изменить эти значения, если используете Pro сервис.  

- **--xlate-maxline**=_n_ (Default: 0)

    Укажите максимальное количество строк текста, которое будет отправлено в API за один раз.

    Установите это значение в 1, если вы хотите переводить по одной строке за раз. Этот параметр имеет приоритет над опцией `--xlate-maxlen`.  

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Смотрите результат перевода в реальном времени в выводе STDERR.  

- **--match-all**

    Установите весь текст файла в качестве целевой области.  

# CACHE OPTIONS

Модуль **xlate** может хранить кэшированный текст перевода для каждого файла и считывать его перед выполнением, чтобы устранить накладные расходы на запрос к серверу. При стратегии кэширования по умолчанию `auto` он поддерживает данные кэша только тогда, когда файл кэша существует для целевого файла.  

- --cache-clear

    Опция **--cache-clear** может быть использована для инициации управления кэшем или для обновления всех существующих данных кэша. После выполнения с этой опцией будет создан новый файл кэша, если он не существует, и затем автоматически поддерживаться впоследствии.  

- --xlate-cache=_strategy_
    - `auto` (Default)

        Поддерживайте файл кэша, если он существует.  

    - `create`

        Создайте пустой файл кэша и выйдите.  

    - `always`, `yes`, `1`

        Поддерживайте кэш в любом случае, если целевой файл является обычным файлом.  

    - `clear`

        Сначала очистите данные кэша.  

    - `never`, `no`, `0`

        Никогда не используйте файл кэша, даже если он существует.  

    - `accumulate`

        По умолчанию неиспользуемые данные удаляются из файла кэша. Если вы не хотите их удалять и хотите сохранить в файле, используйте `accumulate`.  

# COMMAND LINE INTERFACE

Вы можете легко использовать этот модуль из командной строки, используя команду `xlate`, включенную в дистрибутив. Смотрите информацию справки `xlate` для использования.  

Команда `xlate` работает в связке с окружением Docker, так что даже если у вас нет ничего установленного под рукой, вы можете использовать ее, если Docker доступен. Используйте опции `-D` или `-C`.  

Кроме того, поскольку предоставлены makefiles для различных стилей документов, перевод на другие языки возможен без специальной спецификации. Используйте опцию `-M`.  

Вы также можете комбинировать опции Docker и make, чтобы вы могли запускать make в окружении Docker.  

Запуск, как `xlate -GC`, запустит оболочку с текущим рабочим репозиторием git, смонтированным.  

Читать японскую статью в разделе ["SEE ALSO"](#see-also) для подробностей.  

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

Загрузите файл `xlate.el`, включенный в репозиторий, чтобы использовать команду `xlate` из редактора Emacs. Функция `xlate-region` переводит заданный регион. Язык по умолчанию - `EN-US`, и вы можете указать язык, вызывая его с префиксным аргументом.  

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Установите свой ключ аутентификации для сервиса DeepL.  

- OPENAI\_API\_KEY

    Ключ аутентификации OpenAI.  

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Вам необходимо установить инструменты командной строки для DeepL и ChatGPT.  

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)  

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)  

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)  

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)  

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)  

[https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)  

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    Библиотека Python DeepL и команда CLI.  

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Библиотека Python OpenAI  

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Интерфейс командной строки OpenAI  

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Смотрите руководство **greple** для подробностей о шаблоне целевого текста. Используйте опции **--inside**, **--outside**, **--include**, **--exclude**, чтобы ограничить область совпадения.  

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Вы можете использовать модуль `-Mupdate` для изменения файлов по результатам команды **greple**.  

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Используйте **sdif**, чтобы показать формат маркера конфликта рядом с опцией **-V**.  

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Модуль Greple для перевода и замены только необходимых частей с помощью API DeepL (на японском)  

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Генерация документов на 15 языках с помощью модуля API DeepL (на японском)  

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Автоматический перевод Docker окружения с использованием DeepL API (на японском)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.