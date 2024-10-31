# NAME

App::Greple::xlate - greple için çeviri desteği modülü

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.43

# DESCRIPTION

**Greple** **xlate** modülü istenilen metin bloklarını bulur ve bunları çevrilmiş metinle değiştirir. Şu anda DeepL (`deepl.pm`) ve ChatGPT (`gpt3.pm`) modülleri arka uç motor olarak uygulanmıştır. Ayrıca gpt-4 ve gpt-4o için deneysel destek de bulunmaktadır.

Eğer Perl'in pod stiliyle yazılmış bir belgedeki normal metin bloklarını çevirmek istiyorsanız, şu şekilde **greple** komutunu `xlate::deepl` ve `perl` modülü ile kullanın:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

Bu komutta, desen dizesi `^([\w\pP].*\n)+` alfa-nümerik ve noktalama işareti harfi ile başlayan ardışık satırları ifade eder. Bu komut, çevrilecek alanı vurgular.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Ardından seçilen alanı çevirmek için `--xlate` seçeneğini ekleyin. Ardından, istenen bölümleri bulacak ve bunları **deepl** komutunun çıktısıyla değiştirecektir.

Varsayılan olarak, orijinal ve çevrilmiş metin [git(1)](http://man.he.net/man1/git) ile uyumlu "çatışma işaretçisi" formatında yazdırılır. `ifdef` formatını kullanarak, istediğiniz bölümü [unifdef(1)](http://man.he.net/man1/unifdef) komutuyla kolayca alabilirsiniz. Çıktı formatı **--xlate-format** seçeneğiyle belirtilebilir.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Tüm metni çevirmek isterseniz, **--match-all** seçeneğini kullanın. Bu, tüm metni eşleştiren `(?s).+` desenini belirtmek için bir kısayoldur.

Çatışma işaretçisi biçim veri, `-V` seçeneği ile `sdif` komutuyla yan yana stilinde görüntülenebilir. Satır bazında karşılaştırma yapmanın anlamsız olduğu için `--no-cdif` seçeneği önerilir. Metni renklendirmeniz gerekmiyorsa, `--no-textcolor` (veya `--no-tc`) belirtin.

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

İşleme belirtilen birimlerde yapılır, ancak birden fazla satırın ardışık olarak işlenmesi durumunda, bunlar birlikte tek bir satıra dönüştürülür. Bu işlem şu şekilde gerçekleştirilir:

- Her satırın başında ve sonundaki boşlukları kaldırın.
- Eğer bir satır tam genişlikte bir noktalama işareti karakteri ile biterse, bir sonraki satırla birleştirin.
- Bir satır tam genişlikli bir karakterle biterse ve bir sonraki satır tam genişlikli bir karakterle başlarsa, satırları birleştirin.
- Bir satırın sonu veya başı tam genişlikli bir karakter değilse, aralarına bir boşluk karakteri ekleyerek birleştirin.

Önbellek verileri, normalize edilmiş metne dayalı olarak yönetilir, bu nedenle normalleştirme sonuçlarını etkilemeyen değişiklikler yapılsa bile, önbelleğe alınan çeviri verileri hala etkilidir.

Bu normalleştirme işlemi sadece ilk (0'ıncı) ve çift numaralı desen için gerçekleştirilir. Dolayısıyla, iki desen şu şekilde belirlenmişse, ilk desene uyan metin normalleştirmenin ardından işlenecek ve ikinci desene uyan metin üzerinde herhangi bir normalleştirme işlemi gerçekleştirilmeyecektir.

    greple -Mxlate -E normalized -E not-normalized

Bu nedenle, birden fazla satırı tek bir satıra birleştirerek işlenecek metin için ilk deseni kullanın ve önceden biçimlendirilmiş metin için ikinci deseni kullanın. İlk desende eşleşecek metin yoksa, hiçbir şeyi eşleştirmeyen bir desen kullanın, örneğin `(?!)`.

# MASKING

Ara sıra, çevrilmesini istemediğiniz metin parçaları olabilir. Örneğin, markdown dosyalarındaki etiketler. DeepL, bu tür durumlarda çevrilmemesi gereken metin parçasının dışlanacak kısmının XML etiketlerine dönüştürülmesini, çevirilmesini ve ardından çeviri işlemi tamamlandıktan sonra geri yüklenmesini önerir. Bunu desteklemek için çeviriden saklanacak kısımların belirtilebilmesi mümkündür.

    --xlate-setopt maskfile=MASKPATTERN

Bu, \`MASKPATTERN\` dosyasının her satırını bir düzenli ifade olarak yorumlayacak, eşleşen dizeleri çevirecek ve işlem sonrasında geri dönecektir. `#` ile başlayan satırlar görmezden gelinir.

Karmaşık desen, ters eğik çizgi ile kaçış karakteri kullanılarak birden fazla satıra yazılabilir.

Metnin maskeleme ile nasıl dönüştürüldüğü, **--xlate-mask** seçeneği ile görülebilir.

Bu arayüz deneyseldir ve gelecekte değişebilir.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Her eşleşen alan için çeviri sürecini başlatın.

    Bu seçenek olmadan, **greple** normal bir arama komutu gibi davranır. Bu nedenle, gerçek çalışmayı başlatmadan önce dosyanın hangi bölümünün çeviri konusu olacağını kontrol edebilirsiniz.

    Komut sonucu standart çıktıya gider, bu nedenle gerekiyorsa dosyaya yönlendirin veya [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) modülünü kullanmayı düşünün.

    **--xlate** seçeneği **--xlate-color** seçeneğini **--color=never** seçeneğiyle çağırır.

    **--xlate-fold** seçeneğiyle dönüştürülen metin belirtilen genişlikte katlanır. Varsayılan genişlik 70'tir ve **--xlate-fold-width** seçeneğiyle ayarlanabilir. Dört sütun, çalıştırma işlemi için ayrılmıştır, bu nedenle her satır en fazla 74 karakter tutabilir.

- **--xlate-engine**=_engine_

    Kullanılacak çeviri motorunu belirtir. `-Mxlate::deepl` gibi doğrudan motor modülünü belirtirseniz, bu seçeneği kullanmanıza gerek yoktur.

    Şu anda, aşağıdaki motorlar mevcuttur

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4-turbo
    - **gpt4o**: gpt-4o-mini

        **gpt-4o**'nun arayüzü şu anda kararlı değildir ve doğru çalışacağı garanti edilemez.

- **--xlate-labor**
- **--xlabor**

    Çeviri motorunu çağırmak yerine, sizin çalışmanız beklenmektedir. Çevrilecek metni hazırladıktan sonra, metin panosuna kopyalanır. Metni forma yapıştırmanız, sonucu metin panosuna kopyalamanız ve enter tuşuna basmanız beklenmektedir.

- **--xlate-to** (Default: `EN-US`)

    Hedef dilini belirtin. **DeepL** motorunu kullanırken `deepl languages` komutuyla mevcut dilleri alabilirsiniz.

- **--xlate-format**=_format_ (Default: `conflict`)

    Orijinal ve çevrilmiş metin için çıktı formatını belirtin.

    `xtxt` dışındaki aşağıdaki formatlar, çevrilecek kısmın bir dizi satır olduğunu varsayar. Aslında, bir satırın sadece bir kısmını çevirmek mümkündür ve `xtxt` dışındaki bir format belirtmek anlamlı sonuçlar üretmeyecektir.

    - **conflict**, **cm**

        Orjinal ve çevrilmiş metin [git(1)](http://man.he.net/man1/git) çakışma işaretçisi formatında yazdırılır.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Orijinal dosyayı aşağıdaki [sed(1)](http://man.he.net/man1/sed) komutuyla geri alabilirsiniz.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        \`\`\`markdown

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        The original and translated text are output in a markdown's custom container style.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Varsayılan olarak iki nokta üst üste sayısı 7'dir. Eğer `:::::` gibi iki nokta üst üste dizisi belirtirseniz, bu 7 iki nokta üst üste yerine kullanılır.

    - **ifdef**

        Orjinal ve çevrilmiş metin [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` formatında yazdırılır.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        **unifdef** komutuyla yalnızca Japonca metni alabilirsiniz:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Hello, how can I help you today?

    - **xtxt**

        Format `xtxt` (çevrilmiş metin) veya bilinmeyen ise, yalnızca çevrilmiş metin yazdırılır.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Aşağıdaki metni Türkçe'ye satır satır çevirin.

- **--xlate-maxline**=_n_ (Default: 0)

    API'ye aynı anda gönderilecek maksimum satır sayısını belirtin.

    Eğer bir seferde sadece bir satır çevirmek istiyorsanız, bu değeri 1 olarak ayarlayın. Bu seçenek, `--xlate-maxlen` seçeneğinden önceliklidir.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    STDERR çıktısında gerçek zamanlı çeviri sonucunu görün.

- **--xlate-stripe**

    Tüm metni üretmek için seçenek **--all** kullanılır.

    Eşleşen kısmı zebra şeritli bir moda göre göstermek için [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) modülü kullanılır. Bu, eşleşen kısımlar birbiri ardına bağlı olduğunda faydalıdır.

- **--xlate-mask**

    Maskeleme işlemini gerçekleştirin ve dönüştürülmüş metni geri yükleme olmadan görüntüleyin.

- **--match-all**

    Dosyanın tüm metnini hedef alan olarak ayarlayın.

# CACHE OPTIONS

**xlate** modülü, her dosyanın çeviri önbelleğini saklayabilir ve sunucuya sorma işleminin üstesinden gelmek için yürütmeden önce onu okuyabilir. Varsayılan önbellek stratejisi `auto` ile, hedef dosya için önbellek verisi yalnızca önbellek dosyası varsa tutulur.

Önbellek yönetimini başlatmak veya mevcut tüm önbellek verilerini temizlemek için **--xlate-cache=clear** kullanın. Bu seçenekle birlikte çalıştırıldığında, bir önbellek dosyası mevcut değilse yeni bir dosya oluşturulacak ve ardından otomatik olarak bakımı yapılacaktır.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Önbellek dosyasını varsa koruyun.

    - `create`

        Boş önbellek dosyası oluşturun ve çıkın.

    - `always`, `yes`, `1`

        Hedef normal dosya olduğu sürece her durumda önbelleği sürdürün.

    - `clear`

        Öncelikle önbellek verilerini temizleyin.

    - `never`, `no`, `0`

        Önbellek dosyasını varsa kullanmayın.

    - `accumulate`

        Varsayılan davranışa göre, kullanılmayan veriler önbellek dosyasından kaldırılır. Onları kaldırmak istemezseniz ve dosyada tutmak isterseniz, `accumulate` kullanın.
- **--xlate-update**

    Bu seçenek, gerekli olmasa bile önbellek dosyasını güncellemeye zorlar.

# COMMAND LINE INTERFACE

Dağıtımda bulunan `xlate` komutunu kullanarak bu modülü kolayca komut satırından kullanabilirsiniz. Kullanım için `xlate` yardım bilgilerine bakın.

`xlate` komutu Docker ortamı ile birlikte çalışır, bu yüzden elinizde herhangi bir şey yüklü olmasa bile Docker mevcut olduğu sürece kullanabilirsiniz. `-D` veya `-C` seçeneğini kullanın.

Ayrıca, çeşitli belge stilleri için makefile'lar sağlandığından, özel bir belirtim olmadan diğer dillere çeviri yapmak mümkündür. `-M` seçeneğini kullanın.

Docker ve make seçeneklerini birleştirerek make'i Docker ortamında çalıştırabilirsiniz.

`xlate -GC` gibi çalıştırırsanız, mevcut çalışma dizinine bağlı olan bir kabuk başlatılır.

Ayrıntılar için ["DAHA FAZLASI"](#daha-fazlasi) bölümündeki Japonca makaleyi okuyun.

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
        -x # file containing mask patterns
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
        -I * docker image name or version (default: tecolicom/xlate:version)
        -D * run xlate on the container with the rest parameters
        -C * run following command on the container, or run shell
    
    Control Files:
        *.LANG    translation languates
        *.FORMAT  translation foramt (xtxt, cm, ifdef, colon, space)
        *.ENGINE  translation engine (deepl, gpt3, gpt4, gpt4o)

# EMACS

Emacs düzenleyicisinden `xlate` komutunu kullanmak için depoda bulunan `xlate.el` dosyasını yükleyin. `xlate-region` işlevi verilen bölgeyi çevirir. Varsayılan dil `EN-US`'dir ve dil belirtmek için ön ek argümanını kullanabilirsiniz.

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

DeepL ve ChatGPT için komut satırı araçlarını yüklemeniz gerekmektedir.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Docker konteyner görüntüsü.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python kütüphanesi ve CLI komutu.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python Kütüphanesi

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI komut satırı arabirimi

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Hedef metin deseni hakkında ayrıntılar için **greple** kılavuzuna bakın. Eşleşme alanını sınırlamak için **--inside**, **--outside**, **--include**, **--exclude** seçeneklerini kullanın.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Dosyaları **greple** komutunun sonucuna göre değiştirmek için `-Mupdate` modülünü kullanabilirsiniz.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    **-V** seçeneğiyle çakışma işaretçi formatını yan yana göstermek için **sdif** kullanın.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe** modülü, **--xlate-stripe** seçeneği ile kullanılır.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    DeepL API ile sadece gerekli kısımları çevirmek ve değiştirmek için Greple modülü (Japonca olarak)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    DeepL API modülü ile 15 dilde belge oluşturma (Japonca olarak)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    DeepL API ile otomatik çeviri Docker ortamı (Japonca olarak)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
