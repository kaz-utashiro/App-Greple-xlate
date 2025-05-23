# NAME

App::Greple::xlate - модуль поддержки перевода для greple

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

    greple -Mxlate::gpt4 --xlate pattern target-file

    greple -Mxlate --xlate-engine gpt4 --xlate pattern target-file

# VERSION

Version 0.9912

# DESCRIPTION

Модуль **Greple** **xlate** находит нужные текстовые блоки и заменяет их переведенным текстом. В настоящее время в качестве внутреннего движка реализован модуль DeepL (`deepl.pm`) и ChatGPT 4.1 (`gpt4.pm`).

Если вы хотите перевести обычные текстовые блоки в документе, написанном в стиле Perl's pod, используйте команду **greple** с модулем `xlate::deepl` и `perl` следующим образом:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

В этой команде шаблонная строка `^([\w\pP].*\n)+` означает последовательные строки, начинающиеся с букв алфавитно-цифрового ряда и знаков препинания. Эта команда показывает область, которую нужно перевести, выделенной. Опция **--all** используется для перевода всего текста.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Затем добавьте опцию `--xlate` для перевода выделенной области. После этого программа найдет нужные участки и заменит их выводом команды **--deepl**.

По умолчанию оригинальный и транслированный текст печатается в формате "маркер конфликта", совместимом с [git(1)](http://man.he.net/man1/git). Используя формат `ifdef`, можно легко получить нужную часть командой [unifdef(1)](http://man.he.net/man1/unifdef). Выходной формат может быть задан опцией **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Если требуется перевести весь текст, используйте опцию **--match-all**. Это сокращение для указания шаблона `(?s).+`, который соответствует всему тексту.

Данные в формате конфликтных маркеров можно просматривать в стиле "бок о бок" с помощью команды [sdif](https://metacpan.org/pod/App%3A%3Asdif) с опцией `-V`. Поскольку сравнивать по каждой строке не имеет смысла, рекомендуется использовать опцию `--no-cdif`. Если вам не нужно окрашивать текст, укажите `--no-textcolor` (или `--no-tc`).

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Обработка выполняется в заданных единицах, но в случае последовательности из нескольких строк непустого текста они преобразуются в одну строку. Эта операция выполняется следующим образом:

- Удалите пробелы в начале и конце каждой строки.
- Если строка заканчивается полноразмерным символом препинания, объедините ее со следующей строкой.
- Если строка заканчивается символом полной ширины и следующая строка начинается символом полной ширины, объедините строки.
- Если конец или начало строки не являются символами полной ширины, объедините их, вставив символ пробела.

Кэш-данные управляются на основе нормализованного текста, поэтому даже если будут внесены изменения, не влияющие на результаты нормализации, кэшированные данные перевода будут по-прежнему эффективны.

Этот процесс нормализации выполняется только для первого (0-го) и четного шаблона. Таким образом, если два шаблона указаны следующим образом, то текст, соответствующий первому шаблону, будет обработан после нормализации, а для текста, соответствующего второму шаблону, процесс нормализации не будет выполняться.

    greple -Mxlate -E normalized -E not-normalized

Поэтому используйте первый шаблон для текста, который должен быть обработан путем объединения нескольких строк в одну, а второй - для предварительно отформатированного текста. Если в первом шаблоне нет текста для проверки, используйте шаблон, который ничему не соответствует, например `(?!)`.

# MASKING

Иногда встречаются части текста, которые не нужно переводить. Например, теги в файлах формата markdown. На сайте DeepL предлагается в таких случаях преобразовывать исключаемые части текста в XML-теги, переводить их, а затем восстанавливать после завершения перевода. Чтобы поддержать эту идею, можно указать части, которые нужно замаскировать от перевода.

    --xlate-setopt maskfile=MASKPATTERN

При этом каждая строка файла \`MASKPATTERN\` будет интерпретироваться как регулярное выражение, переводить строки, соответствующие ему, и возвращаться после обработки. Строки, начинающиеся с `#`, игнорируются.

Сложный шаблон может быть записан в нескольких строках с обратным слешем, сопровождаемым новой строкой.

Как текст преобразуется при маскировании, можно увидеть с помощью опции **--xlate-mask**.

Этот интерфейс является экспериментальным и может быть изменен в будущем.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Запустите процесс перевода для каждой совпавшей области.

    Без этой опции **greple** ведет себя как обычная команда поиска. Таким образом, вы можете проверить, какая часть файла будет подвергнута переводу, прежде чем вызывать фактическую работу.

    Результат команды выводится в стандартный аут, поэтому при необходимости перенаправьте его в файл или воспользуйтесь модулем [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    Опция **--xlate** вызывает опцию **--xlate-color** с опцией **--color=never**.

    С опцией **--xlate-fold** преобразованный текст сворачивается на указанную ширину. Ширина по умолчанию равна 70 и может быть задана опцией **--xlate-fold-width**. Для обкатки зарезервировано четыре колонки, поэтому в каждой строке может содержаться не более 74 символов.

- **--xlate-engine**=_engine_

    Определяет используемый движок перевода. Если вы указываете модуль движка напрямую, например `-Mxlate::deepl`, то этот параметр использовать не нужно.

    На данный момент доступны следующие движки

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4.1
    - **gpt4o**: gpt-4o-mini

        Интерфейс **gpt-4o** нестабилен и в настоящее время не может быть гарантированно корректной работы.

- **--xlate-labor**
- **--xlabor**

    Вместо того чтобы вызывать механизм перевода, вы должны работать на него. После подготовки текста для перевода он копируется в буфер обмена. Вы должны вставить их в форму, скопировать результат в буфер обмена и нажать кнопку return.

- **--xlate-to** (Default: `EN-US`)

    Укажите целевой язык. Вы можете получить доступные языки с помощью команды `deepl languages` при использовании движка **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Укажите формат вывода оригинального и переведенного текста.

    Следующие форматы, кроме `xtxt`, предполагают, что переводимая часть представляет собой набор строк. На самом деле можно перевести только часть строки, но указание формата, отличного от `xtxt`, не даст значимых результатов.

    - **conflict**, **cm**

        Оригинальный и преобразованный текст печатаются в формате [git(1)](http://man.he.net/man1/git) маркеров конфликтов.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Вы можете восстановить исходный файл следующей командой [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Оригинальный и переведенный текст выводятся в пользовательском стиле контейнера markdown.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Приведенный выше текст будет переведен в HTML следующим образом.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Количество двоеточий по умолчанию равно 7. Если вы укажете последовательность двоеточий, например `:::::`, то она будет использоваться вместо 7 двоеточий.

    - **ifdef**

        Оригинальный и преобразованный текст печатаются в формате [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Вы можете восстановить только японский текст командой **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Оригинальный и преобразованный текст выводятся на печать, разделенные одной пустой строкой. Для `пробел+` после преобразованного текста также выводится новая строка.

    - **xtxt**

        Если формат `xtxt` (переведенный текст) или неизвестен, печатается только переведенный текст.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Укажите максимальную длину текста, передаваемого в API за один раз. По умолчанию установлено значение, как для бесплатного сервиса DeepL: 128К для API (**--xlate**) и 5000 для интерфейса буфера обмена (**--xlate-labor**). Вы можете изменить эти значения, если используете услугу Pro.

- **--xlate-maxline**=_n_ (Default: 0)

    Укажите максимальное количество строк текста, которое будет отправлено в API за один раз.

    Установите значение 1, если вы хотите переводить по одной строке за раз. Этот параметр имеет приоритет перед параметром `--xlate-maxlen`.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Результат перевода можно увидеть в реальном времени в выводе STDERR.

- **--xlate-stripe**

    Используйте модуль [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe), чтобы показать совпадающие части в виде полосок зебры. Это удобно, когда совпадающие части соединены встык.

    Цветовая палитра переключается в соответствии с цветом фона терминала. Если вы хотите указать его явно, можно использовать **--xlate-stripe-light** или **--xlate-stripe-dark**.

- **--xlate-mask**

    Выполните функцию маскирования и отобразите преобразованный текст как есть, без восстановления.

- **--match-all**

    Установите весь текст файла в качестве целевой области.

- **--lineify-cm**
- **--lineify-colon**

    В случае форматов `cm` и `colon` вывод разбивается и форматируется построчно. Поэтому, если перевести только часть строки, ожидаемый результат не будет получен. Эти фильтры исправляют вывод, испорченный переводом части строки в обычный построчный вывод.

    В текущей реализации, если переводится несколько частей строки, они выводятся как независимые строки.

# CACHE OPTIONS

Модуль **xlate** может хранить кэшированный текст перевода для каждого файла и считывать его перед выполнением, чтобы исключить накладные расходы на запрос к серверу. При стратегии кэширования по умолчанию `auto`, он сохраняет данные кэша только тогда, когда файл кэша существует для целевого файла.

Используйте **--xlate-cache=clear**, чтобы запустить управление кэшем или очистить все существующие данные кэша. После выполнения этой опции будет создан новый файл кэша, если он не существует, а затем он будет автоматически поддерживаться.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Сохранять файл кэша, если он существует.

    - `create`

        Создать пустой файл кэша и выйти.

    - `always`, `yes`, `1`

        Сохранять кэш в любом случае, пока целевой файл является обычным файлом.

    - `clear`

        Сначала очистите данные кэша.

    - `never`, `no`, `0`

        Никогда не использовать файл кэша, даже если он существует.

    - `accumulate`

        По умолчанию неиспользуемые данные удаляются из файла кэша. Если вы не хотите удалять их и сохранять в файле, используйте `accumulate`.
- **--xlate-update**

    Эта опция заставляет обновлять файл кэша, даже если в этом нет необходимости.

# COMMAND LINE INTERFACE

Вы можете легко использовать этот модуль из командной строки с помощью команды `xlate`, входящей в дистрибутив. Информацию об использовании см. на странице руководства `xlate`.

Команда `xlate` работает совместно со средой Docker, поэтому даже если у вас ничего не установлено, вы можете использовать ее, пока доступен Docker. Используйте опцию `-D` или `-C`.

Кроме того, поскольку в комплекте поставляются make-файлы для различных стилей документов, перевод на другие языки возможен без специальных уточнений. Используйте опцию `-M`.

Вы также можете комбинировать опции Docker и `make`, чтобы запустить `make` в среде Docker.

Выполнение `xlate -C` запустит оболочку с подключенным текущим рабочим git-репозиторием.

Подробности читайте в японской статье в разделе ["SEE ALSO"](#see-also).

# EMACS

Загрузите файл `xlate.el`, включенный в репозиторий, чтобы использовать команду `xlate` из редактора Emacs. Функция `xlate-region` переводит заданный регион. Язык по умолчанию - `EN-US`, и вы можете указать язык, вызывая ее с помощью аргумента prefix.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Задайте ключ аутентификации для сервиса DeepL.

- OPENAI\_API\_KEY

    Ключ аутентификации OpenAI.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Необходимо установить инструменты командной строки для DeepL и ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt4](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt4)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Образ контейнера Docker.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Библиотека Python и команда CLI.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Библиотека OpenAI Python

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Интерфейс командной строки OpenAI

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Подробную информацию о шаблоне целевого текста см. в руководстве **greple**. Используйте опции **--inside**, **--outside**, **--include**, **--exclude** для ограничения области совпадения.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Вы можете использовать модуль `-Mupdate` для модификации файлов по результатам команды **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Используйте **sdif**, чтобы показать формат маркера конфликта бок о бок с опцией **-V**.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Использование модуля Greple **stripe** с помощью опции **--xlate-stripe**.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Модуль Greple для перевода и замены только необходимых частей с помощью DeepL API (на японском языке)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Генерация документов на 15 языках с помощью модуля DeepL API (на японском языке)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Автоматический перевод Docker-окружения с помощью DeepL API (на японском языке)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
