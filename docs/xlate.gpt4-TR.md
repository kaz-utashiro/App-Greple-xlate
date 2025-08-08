# NAME

App::Greple::xlate - greple için çeviri destek modülü

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

    greple -Mxlate::gpt4 --xlate pattern target-file

    greple -Mxlate --xlate-engine gpt4 --xlate pattern target-file

# VERSION

Version 0.9912

# DESCRIPTION

**Greple** **xlate** modül, istenen metin bloklarını bulur ve bunları çevrilmiş metinle değiştirir. Şu anda DeepL (`deepl.pm`) ve ChatGPT 4.1 (`gpt4.pm`) modülleri arka uç motoru olarak uygulanmıştır.

Perl'in pod stilinde yazılmış bir belgede normal metin bloklarını çevirmek istiyorsanız, **greple** komutunu `xlate::deepl` ve `perl` modülleriyle şu şekilde kullanın:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

Bu komutta, desen dizesi `^([\w\pP].*\n)+` alfa-sayısal ve noktalama işaretiyle başlayan ardışık satırları ifade eder. Bu komut, çevrilecek alanı vurgulanmış olarak gösterir. **--all** seçeneği, tüm metni üretmek için kullanılır.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Daha sonra seçili alanı çevirmek için `--xlate` seçeneğini ekleyin. Ardından, istenen bölümleri bulacak ve bunları **deepl** komutunun çıktısıyla değiştirecektir.

Varsayılan olarak, orijinal ve çevrilmiş metin, [git(1)](http://man.he.net/man1/git) ile uyumlu "çakışma işaretleyici" formatında yazdırılır. `ifdef` formatını kullanarak, [unifdef(1)](http://man.he.net/man1/unifdef) komutuyla kolayca istediğiniz bölümü alabilirsiniz. Çıktı formatı **--xlate-format** seçeneğiyle belirtilebilir.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Tüm metni çevirmek istiyorsanız, **--match-all** seçeneğini kullanın. Bu, tüm metni eşleştiren `(?s).+` desenini belirtmek için bir kısayoldur.

Çakışma işaretleyici biçimindeki veriler, [sdif](https://metacpan.org/pod/App%3A%3Asdif) komutu ile `-V` seçeneği kullanılarak yan yana biçimde görüntülenebilir. Karşılaştırmanın dize bazında yapılmasının anlamı olmadığından, `--no-cdif` seçeneği önerilir. Metni renklendirmenize gerek yoksa, `--no-textcolor` (veya `--no-tc`) belirtin.

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

İşlem belirtilen birimlerde yapılır, ancak birden fazla satırdan oluşan boş olmayan metin dizileri durumunda, bunlar birlikte tek bir satıra dönüştürülür. Bu işlem şu şekilde gerçekleştirilir:

- Her satırın başındaki ve sonundaki boşluklar kaldırılır.
- Bir satır tam genişlikte bir noktalama işaretiyle bitiyorsa, bir sonraki satırla birleştirilir.
- Bir satır tam genişlikte bir karakterle bitiyor ve sonraki satır tam genişlikte bir karakterle başlıyorsa, satırlar birleştirilir.
- Bir satırın sonu veya başı tam genişlikte bir karakter değilse, araya bir boşluk karakteri eklenerek birleştirilirler.

Önbellek verileri normalleştirilmiş metne göre yönetilir, bu nedenle normalleştirme sonuçlarını etkilemeyen değişiklikler yapılsa bile, önbelleğe alınmış çeviri verileri geçerli olmaya devam eder.

Bu normalleştirme işlemi yalnızca ilk (0. indeksli) ve çift numaralı desenler için gerçekleştirilir. Bu nedenle, aşağıdaki gibi iki desen belirtildiğinde, ilk desene uyan metin normalleştirmeden sonra işlenir ve ikinci desene uyan metin üzerinde normalleştirme işlemi yapılmaz.

    greple -Mxlate -E normalized -E not-normalized

Bu nedenle, birden fazla satırı tek bir satırda birleştirerek işlenecek metinler için ilk deseni, önceden biçimlendirilmiş metinler için ise ikinci deseni kullanın. İlk desende eşleşecek metin yoksa, `(?!)` gibi hiçbir şeyle eşleşmeyen bir desen kullanın.

# MASKING

Bazen, çeviri yapılmasını istemediğiniz metin bölümleri olabilir. Örneğin, markdown dosyalarındaki etiketler gibi. DeepL, bu gibi durumlarda çevrilmeyecek metin bölümünün XML etiketlerine dönüştürülmesini, çevrilmesini ve ardından çeviri tamamlandıktan sonra eski haline getirilmesini önerir. Bunu desteklemek için, çeviriden maskelenecek bölümleri belirtmek mümkündür.

    --xlate-setopt maskfile=MASKPATTERN

Bu, \`MASKPATTERN\` dosyasının her satırını bir düzenli ifade olarak yorumlar, eşleşen dizeleri çevirir ve işleme sonrası geri alır. `#` ile başlayan satırlar yok sayılır.

Karmaşık desenler, ters eğik çizgiyle kaçışlı yeni satır kullanılarak birden fazla satıra yazılabilir.

Maskelenerek metnin nasıl dönüştürüldüğü **--xlate-mask** seçeneğiyle görülebilir.

Bu arayüz deneyseldir ve gelecekte değişikliğe tabidir.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Her eşleşen alan için çeviri işlemini başlatın.

    Bu seçenek olmadan, **greple** normal bir arama komutu gibi davranır. Yani, gerçek işlemi başlatmadan önce dosyanın hangi bölümünün çeviriye tabi olacağını kontrol edebilirsiniz.

    Komut sonucu standart çıktıya gider, bu nedenle gerekirse dosyaya yönlendirin veya [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) modülünü kullanmayı düşünün.

    **--xlate** seçeneği, **--xlate-color** seçeneğini **--color=never** seçeneğiyle çağırır.

    **--xlate-fold** seçeneğiyle, dönüştürülen metin belirtilen genişlikte katlanır. Varsayılan genişlik 70'tir ve **--xlate-fold-width** seçeneğiyle ayarlanabilir. Dört sütun çalıştırma işlemi için ayrılmıştır, bu nedenle her satır en fazla 74 karakter tutabilir.

- **--xlate-engine**=_engine_

    Kullanılacak çeviri motorunu belirtir. `-Mxlate::deepl` gibi motor modülünü doğrudan belirtirseniz, bu seçeneği kullanmanıza gerek yoktur.

    Şu anda, aşağıdaki motorlar mevcuttur

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4.1
    - **gpt4o**: gpt-4o-mini

        **gpt-4o**'ün arayüzü kararsızdır ve şu anda düzgün çalışacağı garanti edilemez.

- **--xlate-labor**
- **--xlabor**

    Çeviri motorunu çağırmak yerine, sizin çalışmanız beklenir. Çevrilecek metni hazırladıktan sonra, bunlar panoya kopyalanır. Bunları forma yapıştırmanız, sonucu panoya kopyalamanız ve enter tuşuna basmanız beklenir.

- **--xlate-to** (Default: `EN-US`)

    Hedef dili belirtin. **DeepL** motorunu kullanırken `deepl languages` komutuyla mevcut dilleri alabilirsiniz.

- **--xlate-format**=_format_ (Default: `conflict`)

    Orijinal ve çevrilmiş metin için çıktı biçimini belirtin.

    `xtxt` dışında aşağıdaki biçimler, çevrilecek bölümün bir satır koleksiyonu olduğunu varsayar. Aslında, bir satırın yalnızca bir bölümünü çevirmek mümkündür, ancak `xtxt` dışında bir biçim belirtmek anlamlı sonuçlar üretmez.

    - **conflict**, **cm**

        Orijinal ve dönüştürülmüş metin [git(1)](http://man.he.net/man1/git) çakışma işaretleyici biçiminde yazdırılır.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Bir sonraki [sed(1)](http://man.he.net/man1/sed) komutuyla orijinal dosyayı geri yükleyebilirsiniz.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Orijinal ve çevrilmiş metin, markdown'un özel kapsayıcı stilinde çıktı olarak verilir.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Yukarıdaki metin HTML olarak aşağıdaki şekilde çevrilecektir.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Varsayılan olarak iki nokta sayısı 7'dir. `:::::` gibi bir iki nokta dizisi belirtirseniz, 7 yerine bu kullanılır.

    - **ifdef**

        Orijinal ve dönüştürülmüş metin [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` biçiminde yazdırılır.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Sadece Japonca metni **unifdef** komutuyla alabilirsiniz:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Orijinal ve dönüştürülmüş metin tek bir boş satırla ayrılarak yazdırılır.

    - **xtxt**

        `space+`

- **--xlate-maxlen**=_chars_ (Default: 0)

    Ayrıca dönüştürülmüş metinden sonra da bir satır sonu ekler.

- **--xlate-maxline**=_n_ (Default: 0)

    Eğer format `xtxt` (çevirilmiş metin) veya bilinmiyorsa, sadece çevrilmiş metin yazdırılır.

    API'ye bir seferde gönderilecek metnin maksimum uzunluğunu belirtin. Varsayılan değer, ücretsiz DeepL hesap servisi için ayarlanmıştır: API için 128K (**--xlate**) ve pano arayüzü için 5000 (**--xlate-labor**). Pro servisi kullanıyorsanız bu değerleri değiştirebilirsiniz.

- **--xlate-prompt**=_text_

    Çeviri motoruna gönderilecek özel bir istem belirtin. Bu seçenek yalnızca ChatGPT motorları (gpt3, gpt4, gpt4o) kullanılırken mevcuttur. Yapay zeka modeline belirli talimatlar vererek çeviri davranışını özelleştirebilirsiniz. Eğer istemde `%s` bulunuyorsa, bu kısım hedef dil adıyla değiştirilecektir.

- **--xlate-context**=_text_

    Çeviri motoruna gönderilecek ek bağlam bilgisi belirtin. Bu seçenek birden fazla kez kullanılarak birden fazla bağlam dizesi sağlanabilir. Bağlam bilgisi, çeviri motorunun arka planı anlamasına ve daha doğru çeviriler üretmesine yardımcı olur.

- **--xlate-glossary**=_glossary_

    Çeviri için kullanılacak bir sözlük kimliği belirtin. Bu seçenek yalnızca DeepL motoru kullanılırken mevcuttur. Sözlük kimliği DeepL hesabınızdan alınmalı ve belirli terimlerin tutarlı şekilde çevrilmesini sağlar.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    API'ye bir seferde gönderilecek maksimum metin satırı sayısını belirtin.

- **--xlate-stripe**

    Her seferinde bir satır çevirmek istiyorsanız bu değeri 1 olarak ayarlayın. Bu seçenek `--xlate-maxlen` seçeneğine öncelik verir.

    Çeviri sonucunu gerçek zamanlı olarak STDERR çıktısında görün.

- **--xlate-mask**

    Eşleşen kısmı zebra şeritli şekilde göstermek için [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) modülünü kullanın. Bu, eşleşen kısımlar arka arkaya bağlandığında kullanışlıdır.

- **--match-all**

    Renk paleti, terminalin arka plan rengine göre değiştirilir. Açıkça belirtmek isterseniz **--xlate-stripe-light** veya **--xlate-stripe-dark** kullanabilirsiniz.

- **--lineify-cm**
- **--lineify-colon**

    `cm` ve `colon` formatları durumunda, çıktı satır satır bölünür ve biçimlendirilir. Bu nedenle, bir satırın yalnızca bir kısmı çevrilecekse, beklenen sonuç elde edilemez. Bu filtreler, bir satırın bir kısmının çevrilmesiyle bozulan çıktıyı, normal satır satır çıktıya dönüştürür.

    Mevcut uygulamada, bir satırın birden fazla kısmı çevrilirse, bunlar bağımsız satırlar olarak çıktı verilir.

# CACHE OPTIONS

Maskeleme işlevini gerçekleştirir ve dönüştürülmüş metni olduğu gibi restorasyon yapmadan gösterir.

Dosyanın tüm metnini hedef alan olarak ayarlayın.

- --xlate-cache=_strategy_
    - `auto` (Default)

        **xlate** modülü, her dosya için çeviri önbellekli metni depolayabilir ve çalıştırmadan önce okuyarak sunucuya sorma yükünü ortadan kaldırır. Varsayılan önbellek stratejisi `auto` ile, hedef dosya için önbellek dosyası mevcutsa yalnızca önbellek verilerini tutar.

    - `create`

        Önbellek yönetimini başlatmak veya mevcut tüm önbellek verilerini temizlemek için **--xlate-cache=clear** kullanın. Bu seçenekle çalıştırıldığında, önbellek dosyası yoksa yeni bir tane oluşturulur ve ardından otomatik olarak yönetilir.

    - `always`, `yes`, `1`

        Önbellek dosyası mevcutsa onu koruyun.

    - `clear`

        Boş bir önbellek dosyası oluşturun ve çıkın.

    - `never`, `no`, `0`

        Hedef normal dosya olduğu sürece her durumda önbelleği koruyun.

    - `accumulate`

        Önce önbellek verilerini temizleyin.
- **--xlate-update**

    Önbellek dosyası mevcut olsa bile asla kullanmayın.

# COMMAND LINE INTERFACE

Varsayılan davranış olarak, kullanılmayan veriler önbellek dosyasından kaldırılır. Bunları kaldırmak istemiyorsanız ve dosyada tutmak istiyorsanız `accumulate` kullanın.

Bu seçenek, gerek olmasa bile önbellek dosyasını güncellemeye zorlar.

Bu modülü komut satırından kolayca kullanmak için dağıtıma dahil edilen `xlate` komutunu kullanabilirsiniz. Kullanımı için `xlate` man sayfasına bakın.

`xlate` komutu Docker ortamı ile birlikte çalışır, bu nedenle elinizde hiçbir şey kurulu olmasa bile Docker mevcut olduğu sürece kullanabilirsiniz. `-D` veya `-C` seçeneğini kullanın.

Ayrıca, çeşitli belge stilleri için makefile'lar sağlandığından, özel bir belirtim olmadan diğer dillere çeviri mümkündür. `-M` seçeneğini kullanın.

Docker ve `make` seçeneklerini birleştirerek `make` komutunu Docker ortamında çalıştırabilirsiniz.

# EMACS

Depodaki `xlate.el` dosyasını yükleyerek Emacs editöründen `xlate` komutunu kullanabilirsiniz.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    `xlate-region` fonksiyonu verilen bölgeyi çevirir.

- OPENAI\_API\_KEY

    Varsayılan dil `EN-US`'dir ve önek argümanla çağırarak dili belirtebilirsiniz.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

DeepL servisi için kimlik doğrulama anahtarınızı ayarlayın.

OpenAI kimlik doğrulama anahtarı.

DeepL ve ChatGPT için komut satırı araçlarını yüklemeniz gerekir.

# SEE ALSO

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

[App::Greple::xlate::gpt4](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt4)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    [App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Docker konteyner imajı.

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    DeepL Python kütüphanesi ve CLI komutu.

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    OpenAI Python Kütüphanesi

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    OpenAI komut satırı arayüzü

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Hedef metin deseniyle ilgili ayrıntılar için **greple** kılavuzuna bakın. Eşleşme alanını sınırlamak için **--inside**, **--outside**, **--include**, **--exclude** seçeneklerini kullanın.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    `-Mupdate` modülünü, **greple** komutunun sonucu ile dosyaları değiştirmek için kullanabilirsiniz.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Çakışma işaretleyici biçimini **-V** seçeneğiyle yan yana göstermek için **sdif** kullanın.

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Greple **stripe** modülü, **--xlate-stripe** seçeneğiyle kullanılır.

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    DeepL API ile yalnızca gerekli kısımları çevirip değiştiren Greple modülü (Japonca)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
