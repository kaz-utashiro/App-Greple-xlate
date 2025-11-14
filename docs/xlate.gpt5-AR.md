# NAME

App::Greple::xlate - وحدة دعم الترجمة لأداة greple

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

    greple -Mxlate::gpt4 --xlate pattern target-file

    greple -Mxlate::gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

# VERSION

Version 0.9915

# DESCRIPTION

**Greple** **xlate** تعثر الوحدة على كتل النص المطلوبة وتستبدلها بالنص المُترجَم. حاليًا تم تنفيذ وحدات DeepL (`deepl.pm`)، وChatGPT 4.1 (`gpt4.pm`)، وGPT-5 (`gpt5.pm`) كمحرّكات خلفية.

إذا كنت تريد ترجمة كتل نصية عادية في مستند مكتوب بأسلوب POD الخاص بلغة Perl، فاستخدم أمر **greple** مع الوحدة `xlate::deepl` و`perl` بهذا الشكل:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

في هذا الأمر، تعني سلسلة النمط `^([\w\pP].*\n)+` أسطرًا متتالية تبدأ بحروف وأرقام وعلامات ترقيم. يعرض هذا الأمر المنطقة المراد ترجمتها مميّزة. يُستخدم الخيار **--all** لإنتاج النص الكامل.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

ثم أضف الخيار `--xlate` لترجمة المنطقة المحددة. عندها سيعثر على الأقسام المطلوبة ويستبدلها بمخرجات أمر **deepl**.

افتراضيًا، يُطبع النص الأصلي والمُترجَم بصيغة "علامات التعارض" المتوافقة مع [git(1)](http://man.he.net/man1/git). باستخدام صيغة `ifdef` يمكنك الحصول على الجزء المطلوب بواسطة أمر [unifdef(1)](http://man.he.net/man1/unifdef) بسهولة. يمكن تحديد تنسيق الإخراج عبر الخيار **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

إذا كنت تريد ترجمة النص بالكامل، فاستخدم الخيار **--match-all**. هذا اختصار لتحديد النمط `(?s).+` الذي يطابق النص بأكمله.

يمكن عرض بيانات تنسيق علامات التعارض بأسلوب جنبًا إلى جنب بواسطة أمر [sdif](https://metacpan.org/pod/App%3A%3Asdif) مع الخيار `-V`. ولأنه لا معنى للمقارنة على أساس كل سطر على حدة، يُنصح بالخيار `--no-cdif`. إذا لم تكن بحاجة إلى تلوين النص، فحدّد `--no-textcolor` (أو `--no-tc`).

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

تُجرى المعالجة بوحدات محددة، ولكن في حالة تسلسل من عدة أسطر من نص غير فارغ، تُحوَّل معًا إلى سطر واحد. تُنفَّذ هذه العملية على النحو التالي:

- أزل المسافات البيضاء من بداية ونهاية كل سطر.
- إذا انتهى السطر بعلامة ترقيم بعرض كامل، فادمجه مع السطر التالي.
- إذا انتهى السطر بمحرف بعرض كامل وبدأ السطر التالي بمحرف بعرض كامل، فادمج السطرين.
- إذا لم يكن أحد طرفي السطر (النهاية أو البداية) محرفًا بعرض كامل، فادمجهما بإدراج مسافة.

تُدار بيانات التخزين المؤقت بناءً على النص المُطَبَّع، لذا حتى إذا أُجريت تعديلات لا تؤثر في نتائج التطبيع، ستظل بيانات الترجمة المخبأة فعّالة.

تُجرى عملية التطبيع فقط للنمط الأول (ذي الفهرس 0) والأنماط ذات الأرقام الزوجية. لذلك، إذا تم تحديد نمطين كما يلي، فسيُعالَج النص المطابق للنمط الأول بعد التطبيع، ولن تُجرى أي عملية تطبيع على النص المطابق للنمط الثاني.

    greple -Mxlate -E normalized -E not-normalized

لذا استخدم النمط الأول للنص الذي سيُعالَج بضمّ عدة أسطر إلى سطر واحد، واستخدم النمط الثاني للنص مُسبق التنسيق. إذا لم يكن هناك نص يطابق النمط الأول، فاستخدم نمطًا لا يطابق أي شيء مثل `(?!)`.

# MASKING

أحيانًا توجد أجزاء من النص لا تريد ترجمتها. على سبيل المثال، الوسوم في ملفات Markdown. تقترح DeepL في مثل هذه الحالات تحويل الجزء المراد استثناؤه إلى وسوم XML، ثم ترجمته، ثم استعادته بعد اكتمال الترجمة. لدعم ذلك، يمكن تحديد الأجزاء التي سيتم حجبها من الترجمة.

    --xlate-setopt maskfile=MASKPATTERN

سيفسر كل سطر من الملف \`MASKPATTERN\` كتع表达 نمطي (regular expression)، تُترجم السلاسل المطابقة له، ثم تُعاد إلى حالتها بعد المعالجة. تُتجاهل الأسطر التي تبدأ بـ `#`.

يمكن كتابة نمط معقد على عدة أسطر مع إخفاء سطر جديد بواسطة الشرطة المائلة العكسية.

يمكن رؤية كيفية تحويل النص بواسطة الحجب عبر خيار **--xlate-mask**.

هذا الواجهة تجريبية وقابلة للتغيير في المستقبل.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    تفعيل عملية الترجمة لكل منطقة مطابقة.

    بدون هذا الخيار، يتصرف **greple** كأمر بحث عادي. لذا يمكنك التحقق من أي جزء من الملف سيكون موضوعًا للترجمة قبل تنفيذ العمل الفعلي.

    تذهب نتيجة الأمر إلى المخرج القياسي، لذا أعد توجيهها إلى ملف عند الحاجة، أو فكر في استخدام وحدة [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    الخيار **--xlate** يستدعي خيار **--xlate-color** مع خيار **--color=never**.

    مع خيار **--xlate-fold**، يُطوى النص المحول بعرض محدد. العرض الافتراضي 70 ويمكن تعيينه بواسطة خيار **--xlate-fold-width**. تُحجز أربع أعمدة لعملية الإدراج، لذا يمكن لكل سطر أن يحمل حتى 74 حرفًا كحد أقصى.

- **--xlate-engine**=_engine_

    يحدد محرك الترجمة المراد استخدامه. إذا حددت وحدة المحرك مباشرة مثل `-Mxlate::deepl`، فلست بحاجة لاستخدام هذا الخيار.

    في هذا الوقت، المحركات التالية متاحة

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4.1
    - **gpt4o**: gpt-4o-mini

        واجهة **gpt-4o** غير مستقرة ولا يمكن ضمان عملها بشكل صحيح في الوقت الحالي.

    - **gpt5**: gpt-5

- **--xlate-labor**
- **--xlabor**

    بدلاً من استدعاء محرك الترجمة، يُتوقع أن تقوم بالعمل يدويًا. بعد تحضير النص المراد ترجمته، تُنسخ إلى الحافظة. يُتوقع منك لصقها في النموذج، نسخ النتيجة إلى الحافظة، ثم الضغط على Enter.

- **--xlate-to** (Default: `EN-US`)

    حدد اللغة الهدف. يمكنك الحصول على اللغات المتاحة بواسطة أمر `deepl languages` عند استخدام محرك **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    حدد تنسيق الإخراج للنص الأصلي والمترجم.

    تفترض التنسيقات التالية غير `xtxt` أن الجزء المراد ترجمته عبارة عن مجموعة من الأسطر. في الواقع، من الممكن ترجمة جزء فقط من السطر، لكن تحديد تنسيق غير `xtxt` لن ينتج نتائج ذات معنى.

    - **conflict**, **cm**

        يُطبع النص الأصلي والنص المحول بتنسيق علامات تعارض [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        يمكنك استعادة الملف الأصلي بالأمر التالي [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        يُخرَج النص الأصلي والنص المترجم بأسلوب الحاوية المخصصة في Markdown.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        سيُترجم النص أعلاه إلى ما يلي في HTML.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        عدد النقطتين الرأسيتين هو 7 افتراضيًا. إذا حددت تسلسل نقطتين مثل `:::::`، فسيُستخدم بدلًا من 7 نقطتين.

    - **ifdef**

        يُطبع النص الأصلي والمحّول بتنسيق [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        يمكنك جلب النص الياباني فقط بواسطة الأمر **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        يتم طباعة النص الأصلي والمحَوَّل مفصولين بسطر فارغ واحد. بالنسبة إلى `space+`، يتم أيضًا إخراج سطر جديد بعد النص المحوَّل.

    - **xtxt**

        إذا كان التنسيق `xtxt` (النص المترجم) أو غير معروف، فسيتم طباعة النص المترجم فقط.

- **--xlate-maxlen**=_chars_ (Default: 0)

    حدد الحد الأقصى لطول النص الذي سيتم إرساله إلى واجهة برمجة التطبيقات مرة واحدة. القيمة الافتراضية مضبوطة كما في خدمة حساب DeepL المجانية: 128K لواجهة برمجة التطبيقات (**--xlate**) و5000 لواجهة الحافظة (**--xlate-labor**). قد تتمكن من تغيير هذه القيم إذا كنت تستخدم خدمة Pro.

- **--xlate-maxline**=_n_ (Default: 0)

    حدد الحد الأقصى لعدد أسطر النص التي سيتم إرسالها إلى واجهة برمجة التطبيقات مرة واحدة.

    عيّن هذه القيمة إلى 1 إذا كنت تريد ترجمة سطر واحد في كل مرة. لهذا الخيار أولوية على خيار `--xlate-maxlen`.

- **--xlate-prompt**=_text_

    حدد موجهًا مخصصًا ليُرسل إلى محرك الترجمة. هذا الخيار متاح فقط عند استخدام محركات ChatGPT (gpt3 وgpt4 وgpt4o). يمكنك تخصيص سلوك الترجمة بتقديم تعليمات محددة لنموذج الذكاء الاصطناعي. إذا كان الموجه يحتوي على `%s`، فسيتم استبداله باسم اللغة المستهدفة.

- **--xlate-context**=_text_

    حدد معلومات سياقية إضافية تُرسل إلى محرك الترجمة. يمكن استخدام هذا الخيار عدة مرات لتقديم عدة سلاسل سياقية. تساعد المعلومات السياقية محرك الترجمة على فهم الخلفية وإنتاج ترجمات أكثر دقة.

- **--xlate-glossary**=_glossary_

    حدد معرّف مسرد لاستخدامه في الترجمة. هذا الخيار متاح فقط عند استخدام محرك DeepL. يجب الحصول على معرّف المسرد من حساب DeepL لديك ويضمن ترجمة متسقة للمصطلحات المحددة.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    اعرض نتيجة الترجمة في الوقت الحقيقي في مخرجات STDERR.

- **--xlate-stripe**

    استخدم وحدة [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) لإظهار الجزء المطابق بأسلوب التظليل المخطط (zebra striping). يكون هذا مفيدًا عندما تكون الأجزاء المتطابقة متصلة على التوالي.

    يتم تبديل لوحة الألوان وفقًا للون خلفية الطرفية. إذا أردت التحديد صراحة، يمكنك استخدام **--xlate-stripe-light** أو **--xlate-stripe-dark**.

- **--xlate-mask**

    نفّذ وظيفة الإخفاء واعرض النص المحوَّل كما هو دون استرجاع.

- **--match-all**

    عيّن كامل نص الملف كمنطقة هدف.

- **--lineify-cm**
- **--lineify-colon**

    في حالتي تنسيقي `cm` و`colon`، يتم تقسيم الإخراج وتنسيقه سطرًا بسطر. لذلك، إذا كان من المقرر ترجمة جزء فقط من سطر، فلن يمكن الحصول على النتيجة المتوقعة. تعمل هذه المرشحات على إصلاح الإخراج الذي فسد بسبب ترجمة جزء من السطر إلى إخراج طبيعي سطرًا بسطر.

    في التنفيذ الحالي، إذا تُرجمت أجزاء متعددة من سطر واحد، يتم إخراجها كسطور مستقلة.

# CACHE OPTIONS

يمكن لوحدة **xlate** تخزين نص مترجم مؤقتًا لكل ملف وقراءته قبل التنفيذ لإزالة كلفة الاستعلام من الخادم. باستخدام استراتيجية التخزين المؤقت الافتراضية `auto`، تتم المحافظة على بيانات التخزين المؤقت فقط عندما يوجد ملف التخزين المؤقت للملف الهدف.

استخدم **--xlate-cache=clear** لبدء إدارة التخزين المؤقت أو لتنظيف جميع بيانات التخزين المؤقت الموجودة. بعد التنفيذ بهذا الخيار، سيتم إنشاء ملف تخزين مؤقت جديد إن لم يكن موجودًا ثم تتم صيانته تلقائيًا بعد ذلك.

- --xlate-cache=_strategy_
    - `auto` (Default)

        حافظ على ملف التخزين المؤقت إذا كان موجودًا.

    - `create`

        أنشئ ملف تخزين مؤقت فارغًا ثم اخرج.

    - `always`, `yes`, `1`

        حافظ على ذاكرة التخزين المؤقت على أي حال طالما أن الهدف ملف عادي.

    - `clear`

        امسح بيانات ذاكرة التخزين المؤقت أولاً.

    - `never`, `no`, `0`

        لا تستخدم ملف ذاكرة التخزين المؤقت مطلقًا حتى إذا كان موجودًا.

    - `accumulate`

        وفقًا للسلوك الافتراضي، تتم إزالة البيانات غير المستخدمة من ملف ذاكرة التخزين المؤقت. إذا كنت لا تريد إزالتها وتريد الاحتفاظ بها في الملف، استخدم `accumulate`.
- **--xlate-update**

    يفرض هذا الخيار تحديث ملف ذاكرة التخزين المؤقت حتى إذا لم يكن ذلك ضروريًا.

# COMMAND LINE INTERFACE

يمكنك استخدام هذه الوحدة بسهولة من سطر الأوامر باستخدام أمر `xlate` المُضمَّن في التوزيعة. راجع صفحة الدليل `xlate` للاستخدام.

يعمل أمر `xlate` بالتنسيق مع بيئة Docker، لذا حتى إذا لم يكن لديك أي شيء مُثبّت محليًا، يمكنك استخدامه طالما أن Docker متاح. استخدم خيار `-D` أو `-C`.

أيضًا، نظرًا لتوفّر ملفات make لأنماط مستندات متنوعة، فإن الترجمة إلى لغات أخرى ممكنة دون مواصفات خاصة. استخدم خيار `-M`.

يمكنك أيضًا الجمع بين خياري Docker و`make` بحيث يمكنك تشغيل `make` في بيئة Docker.

التشغيل مثل `xlate -C` سيؤدي إلى إطلاق صدفة مع ربط مستودع git العامل الحالي.

اقرأ المقال الياباني في قسم ["SEE ALSO"](#see-also) للتفاصيل.

# EMACS

حمّل ملف `xlate.el` المُضمَّن في المستودع لاستخدام أمر `xlate` من محرر Emacs. تقوم دالة `xlate-region` بترجمة المنطقة المحددة. اللغة الافتراضية هي `EN-US` ويمكنك تحديد اللغة عند استدعائها مع معامل بادئة.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    عيّن مفتاح المصادقة لخدمة DeepL.

- OPENAI\_API\_KEY

    مفتاح مصادقة OpenAI.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

عليك تثبيت أدوات سطر الأوامر لكل من DeepL وChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt4](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt4)

[App::Greple::xlate::gpt5](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt5)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    صورة حاوية Docker.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    مكتبة DeepL لبايثون وأمر CLI.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    مكتبة OpenAI لبايثون

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    واجهة سطر الأوامر لـ OpenAI

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    راجع دليل **greple** للتفاصيل حول نمط نص الهدف. استخدم الخيارات **--inside** و**--outside** و**--include** و**--exclude** لتقييد منطقة المطابقة.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    يمكنك استخدام وحدة `-Mupdate` لتعديل الملفات بنتيجة أمر **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    استخدم **sdif** لإظهار تنسيق علامات التعارض جنبًا إلى جنب مع خيار **-V**.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    تُستخدم وحدة Greple **stripe** بواسطة خيار **--xlate-stripe**.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    وحدة Greple للترجمة والاستبدال للأجزاء الضرورية فقط باستخدام واجهة DeepL API (باللغة اليابانية)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    إنشاء مستندات بـ 15 لغة باستخدام وحدة DeepL API (باللغة اليابانية)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    بيئة Docker للترجمة الآلية باستخدام DeepL API (باللغة اليابانية)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
