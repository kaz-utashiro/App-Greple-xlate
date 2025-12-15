# NAME

App::Greple::xlate - greple için çeviri destek modülü

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

    greple -Mxlate::gpt4 --xlate pattern target-file

    greple -Mxlate::gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

# VERSION

Version 0.9922

# DESCRIPTION

**Greple** **xlate** modülü istenen metin bloklarını bulur ve bunları çevrilmiş metinle değiştirir. Şu anda arka uç motoru olarak DeepL (`deepl.pm`), ChatGPT 4.1 (`gpt4.pm`) ve GPT-5 (`gpt5.pm`) modülleri uygulanmıştır.

Perl'in pod tarzında yazılmış bir belgedeki normal metin bloklarını çevirmek istiyorsanız, **greple** komutunu `xlate::deepl` ve `perl` modülüyle aşağıdaki gibi kullanın:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

Bu komutta, `^([\w\pP].*\n)+` desen dizgesi, alfa-sayısal ve noktalama harfiyle başlayan ardışık satırlar anlamına gelir. Bu komut, çevrilecek alanı vurgulanmış olarak gösterir. **--all** seçeneği, tüm metni üretmek için kullanılır.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Ardından seçili alanı çevirmek için `--xlate` seçeneğini ekleyin. Böylece, istenen bölümleri bulur ve bunları **deepl** komut çıktısıyla değiştirir.

Varsayılan olarak, özgün ve çevrilmiş metin [git(1)](http://man.he.net/man1/git) ile uyumlu "çatışma işaretleyicisi" biçiminde yazdırılır. `ifdef` biçimini kullanarak, [unifdef(1)](http://man.he.net/man1/unifdef) komutuyla istenen kısmı kolayca alabilirsiniz. Çıktı biçimi **--xlate-format** seçeneğiyle belirtilebilir.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Tüm metni çevirmek istiyorsanız, **--match-all** seçeneğini kullanın. Bu, tüm metni eşleyen `(?s).+` desenini belirtmek için bir kısayoldur.

Çatışma işaretleyicisi biçimindeki veriler, [sdif](https://metacpan.org/pod/App%3A%3Asdif) komutu ve `-V` seçeneğiyle yan yana stilde görüntülenebilir. Dize bazında karşılaştırmanın anlamı olmadığından, `--no-cdif` seçeneği önerilir. Metni renklendirmenize gerek yoksa, `--no-textcolor` (veya `--no-tc`) belirtin.

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

İşleme belirtilen birimler halinde yapılır, ancak birden fazla satırdan oluşan boş olmayan metin dizisi söz konusu olduğunda, bunlar birlikte tek bir satıra dönüştürülür. Bu işlem şu şekilde gerçekleştirilir:

- Her satırın başındaki ve sonundaki boşluk karakterleri kaldırılır.
- Bir satır tam genişlikte bir noktalama karakteriyle bitiyorsa, sonraki satırla birleştirin.
- Bir satır tam genişlikli bir karakterle bitiyor ve sonraki satır tam genişlikli bir karakterle başlıyorsa, satırları birleştirin.
- Satırın sonu veya başı tam genişlikli bir karakter değilse, araya bir boşluk karakteri ekleyerek birleştirin.

Önbellek verileri normalleştirilmiş metne göre yönetilir, bu nedenle normalleştirme sonuçlarını etkilemeyen değişiklikler yapılsa bile, önbelleğe alınmış çeviri verileri yine de geçerli olacaktır.

Bu normalleştirme işlemi yalnızca birinci (0’ıncı) ve çift numaralı desen için gerçekleştirilir. Dolayısıyla aşağıdaki gibi iki desen belirtildiğinde, ilk desene uyan metin normalleştirmeden sonra işlenecek, ikinci desene uyan metin için ise normalleştirme işlemi yapılmayacaktır.

    greple -Mxlate -E normalized -E not-normalized

Bu nedenle, birden çok satırı tek bir satırda birleştirerek işlenecek metin için ilk deseni; önceden biçimlendirilmiş metin için ikinci deseni kullanın. İlk desende eşleşecek metin yoksa, `(?!)` gibi hiçbir şeyle eşleşmeyen bir desen kullanın.

# MASKING

Bazen, çevrilmesini istemediğiniz metin bölümleri vardır. Örneğin, markdown dosyalarındaki etiketler. DeepL, böyle durumlarda hariç tutulacak metin kısmının XML etiketlerine dönüştürülmesini, çevrilmesini ve çeviri tamamlandıktan sonra geri yüklenmesini önerir. Bunu desteklemek için, çeviriden masklanacak kısımları belirtmek mümkündür.

    --xlate-setopt maskfile=MASKPATTERN

Bu, dosya \`MASKPATTERN\`ın her satırını bir düzenli ifade olarak yorumlar, ona uyan dizeleri çevirir ve işlemden sonra geri alır. `#` ile başlayan satırlar yok sayılır.

Karmaşık desen, ters eğik çizgi ile kaçışlı satır sonları kullanılarak birden çok satıra yazılabilir.

Metnin maskeleme ile nasıl dönüştürüldüğü **--xlate-mask** seçeneğiyle görülebilir.

Bu arayüz deneyseldir ve gelecekte değişime tabidir.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Eşleşen her alan için çeviri işlemini çağırın.

    Bu seçenek olmadan, **greple** normal bir arama komutu gibi davranır. Böylece, gerçek işi başlatmadan önce dosyanın hangi kısmının çeviriye tabi olacağını kontrol edebilirsiniz.

    Komut sonucu standart çıktıya gider; gerekirse dosyaya yönlendirin veya [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) modülünü kullanmayı düşünün.

    Seçenek **--xlate**, **--color=never** seçeneğiyle **--xlate-color** seçeneğini çağırır.

    **--xlate-fold** seçeneğiyle, dönüştürülmüş metin belirtilen genişliğe göre katlanır. Varsayılan genişlik 70'tir ve **--xlate-fold-width** seçeneğiyle ayarlanabilir. Gömülü işlem için dört sütun ayrılmıştır, bu nedenle her satır en fazla 74 karakter tutabilir.

- **--xlate-engine**=_engine_

    Kullanılacak çeviri motorunu belirtir. `-Mxlate::deepl` gibi motor modülünü doğrudan belirtirseniz, bu seçeneği kullanmanıza gerek yoktur.

    Şu anda aşağıdaki motorlar mevcuttur

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4.1
    - **gpt4o**: gpt-4o-mini

        **gpt-4o** arayüzü kararsızdır ve şu anda doğru çalışacağı garanti edilemez.

    - **gpt5**: gpt-5

- **--xlate-labor**
- **--xlabor**

    Çeviri motorunu çağırmak yerine, sizin çalışmanız beklenir. Çevrilecek metni hazırladıktan sonra, bunlar panoya kopyalanır. Bunları forma yapıştırmanız, sonucu panoya kopyalamanız ve enter'a basmanız beklenir.

- **--xlate-to** (Default: `EN-US`)

    Hedef dili belirtin. **DeepL** motorunu kullanırken, kullanılabilir dilleri `deepl languages` komutuyla alabilirsiniz.

- **--xlate-format**=_format_ (Default: `conflict`)

    Orijinal ve çevrilmiş metin için çıktı biçimini belirtin.

    `xtxt` dışındaki aşağıdaki biçimler, çevrilecek kısmın satırların bir koleksiyonu olduğunu varsayar. Aslında bir satırın yalnızca bir kısmını çevirmek mümkündür, ancak `xtxt` dışında bir biçim belirtmek anlamlı sonuçlar üretmez.

    - **conflict**, **cm**

        Orijinal ve dönüştürülmüş metin [git(1)](http://man.he.net/man1/git) çatışma belirteci biçiminde yazdırılır.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Orijinal dosyayı bir sonraki [sed(1)](http://man.he.net/man1/sed) komutuyla geri yükleyebilirsiniz.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Orijinal ve çevrilmiş metin, markdown'un özel konteyner stilinde çıktı alınır.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Yukarıdaki metin HTML'de aşağıdaki gibi çevrilecektir.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Varsayılan olarak iki nokta sayısı 7'dir. `:::::` gibi bir iki nokta dizisi belirtirseniz, 7 iki nokta yerine bu kullanılır.

    - **ifdef**

        Orijinal ve dönüştürülmüş metin [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` biçiminde yazdırılır.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Yalnızca Japonca metni **unifdef** komutuyla alabilirsiniz:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Özgün ve dönüştürülmüş metin, araya tek bir boş satır konularak yazdırılır. `space+` için, dönüştürülmüş metinden sonra ayrıca bir satır sonu da çıktılanır.

    - **xtxt**

        Biçim `xtxt` (çevirilmiş metin) ya da bilinmeyense, yalnızca çevrilmiş metin yazdırılır.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Bir seferde API’ye gönderilecek metnin azami uzunluğunu belirtin. Öntanımlı değer, ücretsiz DeepL hesap hizmetine göredir: API için 128K (**--xlate**) ve pano arayüzü için 5000 (**--xlate-labor**). Pro hizmeti kullanıyorsanız bu değerleri değiştirebilirsiniz.

- **--xlate-maxline**=_n_ (Default: 0)

    Bir seferde API’ye gönderilecek metnin azami satır sayısını belirtin.

    Her seferinde tek bir satırı çevirmek istiyorsanız bu değeri 1 olarak ayarlayın. Bu seçenek, `--xlate-maxlen` seçeneğine göre önceliklidir.

- **--xlate-prompt**=_text_

    Çeviri motoruna gönderilecek özel bir istem belirtin. Bu seçenek yalnızca ChatGPT motorları (gpt3, gpt4, gpt4o) kullanılırken kullanılabilir. Yapay zekâ modeline belirli talimatlar vererek çeviri davranışını özelleştirebilirsiniz. İstem `%s` içeriyorsa hedef dil adıyla değiştirilir.

- **--xlate-context**=_text_

    Çeviri motoruna gönderilecek ek bağlam bilgisi belirtin. Birden çok bağlam dizesi sağlamak için bu seçenek birden çok kez kullanılabilir. Bağlam bilgisi, çeviri motorunun arka planı anlamasına ve daha doğru çeviriler üretmesine yardımcı olur.

- **--xlate-glossary**=_glossary_

    Çeviri için kullanılacak bir sözlük (glossary) kimliği belirtin. Bu seçenek yalnızca DeepL motoru kullanılırken kullanılabilir. Sözlük kimliği DeepL hesabınızdan alınmalı ve belirli terimlerin tutarlı çevirisini sağlar.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Çeviri sonucunu gerçek zamanlı olarak STDERR çıktısında görün.

- **--xlate-stripe**

    Eşleşen kısmı zebra şeritleme tarzında göstermek için [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) modülünü kullanın. Bu, eşleşen bölümler art arda bağlandığında kullanışlıdır.

    Renk paleti, terminalin arka plan rengine göre değiştirilir. Açıkça belirtmek isterseniz **--xlate-stripe-light** veya **--xlate-stripe-dark** kullanabilirsiniz.

- **--xlate-mask**

    Maskeleme işlevini uygulayın ve dönüştürülmüş metni geri yükleme olmadan olduğu gibi görüntüleyin.

- **--match-all**

    Dosyanın tüm metnini hedef alan olarak ayarlayın.

- **--lineify-cm**
- **--lineify-colon**

    `cm` ve `colon` biçimlerinde çıktı satır satır bölünüp biçimlendirilir. Bu nedenle, bir satırın yalnızca bir bölümü çevrilecekse beklenen sonuç elde edilemez. Bu filtreler, bir satırın bir kısmının çevrilmesiyle bozulan çıktıyı normal satır bazlı çıktıya düzeltir.

    Mevcut uygulamada, bir satırın birden fazla bölümü çevrilirse bunlar bağımsız satırlar olarak çıktılanır.

# CACHE OPTIONS

**xlate** modülü, her dosya için çevirinin önbelleğe alınmış metnini depolayabilir ve sunucuya sorma yükünü ortadan kaldırmak için yürütmeden önce bunu okuyabilir. Öntanımlı önbellek stratejisi `auto` ile, hedef dosya için önbellek dosyası mevcut olduğunda yalnızca önbellek verileri tutulur.

Önbellek yönetimini başlatmak veya mevcut tüm önbellek verilerini temizlemek için **--xlate-cache=clear** kullanın. Bu seçenekle bir kez çalıştırıldığında, önbellek dosyası yoksa yeni bir önbellek dosyası oluşturulur ve ardından otomatik olarak korunur.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Önbellek dosyası mevcutsa onu koruyun.

    - `create`

        Boş bir önbellek dosyası oluşturun ve çıkın.

    - `always`, `yes`, `1`

        Hedef normal bir dosya olduğu sürece her durumda önbelleği koruyun.

    - `clear`

        Önce önbellek verilerini temizleyin.

    - `never`, `no`, `0`

        Var olsa bile asla önbellek dosyasını kullanmayın.

    - `accumulate`

        Varsayılan davranışta, kullanılmayan veriler önbellek dosyasından kaldırılır. Bunları kaldırmak istemiyor ve dosyada tutmak istiyorsanız `accumulate` kullanın.
- **--xlate-update**

    Bu seçenek, gerekli olmasa bile önbellek dosyasını güncellemeye zorlar.

# COMMAND LINE INTERFACE

Dağıtıma dahil edilen `xlate` komutunu kullanarak bu modülü komut satırından kolayca kullanabilirsiniz. Kullanım için `xlate` man sayfasına bakın.

`xlate` komutu, `--to-lang`, `--from-lang`, `--engine` ve `--file` gibi GNU tarzı uzun seçenekleri destekler. Tüm mevcut seçenekleri görmek için `xlate -h` kullanın.

`xlate` komutu Docker ortamıyla birlikte çalışır; bu nedenle elinizde hiçbir şey kurulu olmasa bile Docker mevcut olduğu sürece kullanabilirsiniz. `-D` veya `-C` seçeneğini kullanın.

Docker işlemleri, bağımsız bir komut olarak da kullanılabilen `dozo` betiği tarafından yönetilir. `dozo` betiği, kalıcı kapsayıcı ayarları için `.dozorc` yapılandırma dosyasını destekler.

Ayrıca, çeşitli belge stilleri için makefile’lar sağlandığından, özel bir belirtim olmadan diğer dillere çeviri mümkündür. `-M` seçeneğini kullanın.

Docker ve `make` seçeneklerini birleştirerek `make` komutunu Docker ortamında çalıştırabilirsiniz.

`xlate -C` gibi çalıştırmak, geçerli çalışma git deposu bağlanmış bir kabuğu başlatacaktır.

Ayrıntılar için ["SEE ALSO"](#see-also) bölümündeki Japonca makaleyi okuyun.

# EMACS

Emacs düzenleyicisinden `xlate` komutunu kullanmak için depoda bulunan `xlate.el` dosyasını yükleyin. `xlate-region` işlevi belirtilen bölgeyi çevirir. Varsayılan dil `EN-US`’dür ve önek argümanıyla çağırarak dili belirtebilirsiniz.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    DeepL hizmeti için kimlik doğrulama anahtarınızı ayarlayın.

- OPENAI\_API\_KEY

    OpenAI kimlik doğrulama anahtarı.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

DeepL ve ChatGPT için komut satırı araçlarını kurmanız gerekir.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt4](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt4)

[App::Greple::xlate::gpt5](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt5)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Docker konteyner imajı.

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    `xlate` ve `dozo` betiklerinde seçenek ayrıştırma için kullanılan `getoptlong.sh` kütüphanesi.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python kütüphanesi ve CLI komutu.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python Kütüphanesi

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI komut satırı arayüzü

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Hedef metin deseni hakkında ayrıntılar için **greple** kılavuzuna bakın. Eşleşme alanını sınırlamak için **--inside**, **--outside**, **--include**, **--exclude** seçeneklerini kullanın.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    **greple** komutunun sonucuyla dosyaları değiştirmek için `-Mupdate` modülünü kullanabilirsiniz.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    **sdif** kullanarak, **-V** seçeneğiyle yan yana çatışma işaretçisi biçimini gösterin.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe** modülü, **--xlate-stripe** seçeneğiyle kullanılır.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Sadece gerekli kısımları DeepL API ile çevirip değiştiren Greple modülü (Japonca)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    DeepL API modülüyle 15 dilde belgeler üretme (Japonca)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    DeepL API ile otomatik çeviri Docker ortamı (Japonca)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
