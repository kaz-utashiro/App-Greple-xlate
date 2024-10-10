# NAME

App::Greple::xlate - greple için çeviri destek modülü

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.41

# DESCRIPTION

**Greple** **xlate** modülü istenen metin bloklarını bulur ve bunları çevrilmiş metinle değiştirir. Şu anda DeepL (`deepl.pm`) ve ChatGPT (`gpt3.pm`) modülleri bir arka uç motoru olarak uygulanmıştır. Gpt-4 ve gpt-4o için deneysel destek de dahil edilmiştir.

Eğer Perl'in pod stilinde yazılmış bir belgede normal metin bloklarını çevirmek istiyorsanız, **greple** komutunu `xlate::deepl` ve `perl` modülü ile şu şekilde kullanın:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

Bu komutta, desen dizesi `^([\w\pP].*\n)+` alfasayısal ve noktalama işareti ile başlayan ardışık satırları ifade eder. Bu komut, çevrilecek alanı vurgulayarak gösterir. Seçenek **--all** tüm metni üretmek için kullanılır.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Sonra, seçilen alanı çevirmek için `--xlate` seçeneğini ekleyin. Ardından, istenen bölümleri bulacak ve bunları **deepl** komutunun çıktısıyla değiştirecektir.

Varsayılan olarak, orijinal ve çevrilmiş metin "çelişki işareti" formatında yazdırılır, bu format [git(1)](http://man.he.net/man1/git) ile uyumludur. `ifdef` formatını kullanarak, [unifdef(1)](http://man.he.net/man1/unifdef) komutu ile istediğiniz kısmı kolayca alabilirsiniz. Çıktı formatı **--xlate-format** seçeneği ile belirtilebilir.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Eğer tüm metni çevirmek istiyorsanız, **--match-all** seçeneğini kullanın. Bu, tüm metni eşleştiren `(?s).+` desenini belirtmek için bir kısayoldur.

Çatışma işaretleyici format verisi, `sdif` komutu ile `-V` seçeneği kullanılarak yan yana stilinde görüntülenebilir. Her bir dize bazında karşılaştırmanın anlamı olmadığı için, `--no-cdif` seçeneği önerilmektedir. Metni renklendirmeye ihtiyacınız yoksa, `--no-textcolor` (veya `--no-tc`) belirtin.

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

İşlem belirtilen birimlerde yapılır, ancak birden fazla satırdan oluşan boş olmayan bir metin dizisi durumunda, bunlar birlikte tek bir satıra dönüştürülür. Bu işlem şu şekilde gerçekleştirilir:

- You are trained on data up to October 2023.  
Ekim 2023'e kadar verilerle eğitildiniz.
- Eğer bir satır tam genişlikte bir noktalama işareti ile bitiyorsa, bir sonraki satırla birleştir.
- Eğer bir satır tam genişlik karakteri ile bitiyorsa ve bir sonraki satır tam genişlik karakteri ile başlıyorsa, satırları birleştir.
- Eğer bir satırın sonu veya başı tam genişlikte bir karakter değilse, bir boşluk karakteri ekleyerek bunları birleştir.

Cache verileri, normalize edilmiş metne dayalı olarak yönetilmektedir, bu nedenle normalizasyon sonuçlarını etkilemeyen değişiklikler yapılsa bile, önbelleğe alınmış çeviri verileri yine de etkili olacaktır.

Bu normalizasyon süreci yalnızca birinci (0. sıradaki) ve çift numaralı desenler için gerçekleştirilir. Böylece, iki desen aşağıdaki gibi belirtilirse, birinci desene uyan metin normalizasyon işleminden sonra işlenecek ve ikinci desene uyan metin üzerinde herhangi bir normalizasyon işlemi yapılmayacaktır.

    greple -Mxlate -E normalized -E not-normalized

Bu nedenle, birden fazla satırı tek bir satırda birleştirerek işlenecek metinler için birinci deseni kullanın ve önceden biçimlendirilmiş metinler için ikinci deseni kullanın. Eğer birinci desende eşleşecek bir metin yoksa, hiçbir şeyi eşleştirmeyen bir desen kullanın, örneğin `(?!)`.

# MASKING

Bazen, çevrilmesini istemediğiniz metin parçaları vardır. Örneğin, markdown dosyalarındaki etiketler. DeepL, bu tür durumlarda, çevrilmeyecek metin parçasının XML etiketlerine dönüştürülmesini, çevrildikten sonra geri yüklenmesini önerir. Bunu desteklemek için, çeviriden hariç tutulacak kısımları belirtmek mümkündür.

    --xlate-setopt maskfile=MASKPATTERN

Bu, \`MASKPATTERN\` dosyasının her bir satırını bir düzenli ifade olarak yorumlayacak, ona uyan dizeleri çevirecek ve işlemden sonra geri dönecektir. `#` ile başlayan satırlar göz ardı edilir.

Karmaşık desen, ters eğik çizgi ile kaçırılmış yeni satır ile birden fazla satıra yazılabilir.

Metnin maskeleme ile nasıl dönüştürüldüğü **--xlate-mask** seçeneği ile görülebilir.

Bu arayüz deneyseldir ve gelecekte değişikliklere tabi olabilir.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Her eşleşen alan için çeviri sürecini başlatın.

    Bu seçenek olmadan, **greple** normal bir arama komutu gibi davranır. Böylece, gerçek çalışmayı başlatmadan önce dosyanın hangi kısmının çeviri konusu olacağını kontrol edebilirsiniz.

    Komut sonucu standart çıkışa gider, bu nedenle gerekirse bir dosyaya yönlendirin veya [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) modülünü kullanmayı düşünün.

    Option **--xlate** **--color=never** seçeneği ile **--xlate-color** seçeneğini çağırır.

    **--xlate-fold** seçeneği ile, dönüştürülen metin belirtilen genişlikte katlanır. Varsayılan genişlik 70'tir ve **--xlate-fold-width** seçeneği ile ayarlanabilir. Dört sütun, koşu içi işlem için ayrılmıştır, bu nedenle her satır en fazla 74 karakter tutabilir.

- **--xlate-engine**=_engine_

    Çeviri motorunun kullanılacağını belirtir. Eğer motor modülünü doğrudan belirtirseniz, örneğin `-Mxlate::deepl`, bu seçeneği kullanmanıza gerek yoktur.

    Bu zamanda, aşağıdaki motorlar mevcuttur

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4-turbo
    - **gpt4o**: gpt-4o-mini

        **gpt-4o**'nun arayüzü kararsızdır ve şu anda doğru çalışacağı garanti edilemez.

- **--xlate-labor**
- **--xlabor**

    XML style tag'ını olduğu gibi bırakın.
    Çeviri motorunu aramak yerine, çalışmanız bekleniyor. Çevrilecek metni hazırladıktan sonra, panoya kopyalanır. Onları forma yapıştırmanız, sonucu panoya kopyalamanız ve enter tuşuna basmanız bekleniyor.

- **--xlate-to** (Default: `EN-US`)

    Hedef dili belirtin. **DeepL** motorunu kullanırken `deepl languages` komutuyla mevcut dilleri alabilirsiniz.

- **--xlate-format**=_format_ (Default: `conflict`)

    &lt;output\_format>
    Orijinal metin ve çevrilmiş metin için çıktı formatını belirtin.
    &lt;/output\_format>

    Aşağıdaki `xtxt` dışındaki formatlar, çevrilecek kısmın bir dizi satır olduğunu varsayar. Aslında, bir satırın yalnızca bir kısmını çevirmek mümkündür ve `xtxt` dışındaki bir format belirtmek anlamlı sonuçlar üretmeyecektir.

    - **conflict**, **cm**

        Orijinal ve dönüştürülmüş metin [git(1)](http://man.he.net/man1/git) çelişki işaretleme formatında basılmaktadır.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Orijinal dosyayı bir sonraki [sed(1)](http://man.he.net/man1/sed) komutuyla geri alabilirsiniz.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        **div**Orijinal ve dönüştürülmüş metin markdown **div** blok stil notasyonunda basılmaktadır.&lt;/div>&lt;/div>

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Bu, şunu ifade eder:

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Sütun sayısı varsayılan olarak 7'dir. Eğer `:::::` gibi bir sütun dizisi belirtirseniz, bu 7 sütun yerine kullanılır.

    - **ifdef**

        Orijinal ve dönüştürülmüş metin [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` formatında yazdırılır.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        **unifdef** komutu ile yalnızca Japonca metin alabilirsiniz:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Orijinal ve dönüştürülmüş metinler tek bir boş satırla ayrılmış olarak yazdırılır. `space+` için, dönüştürülmüş metinden sonra bir yeni satır da çıktılar.

    - **xtxt**

        Eğer format `xtxt` (çevrilmiş metin) veya bilinmiyorsa, yalnızca çevrilmiş metin yazdırılır.

- **--xlate-maxlen**=_chars_ (Default: 0)

    API'ye bir seferde gönderilecek metnin maksimum uzunluğunu belirtin. Varsayılan değer, ücretsiz DeepL hesap hizmeti için ayarlanmıştır: API için 128K (**--xlate**) ve panoya arayüzü için 5000 (**--xlate-labor**). Pro hizmeti kullanıyorsanız bu değerleri değiştirebilirsiniz.

- **--xlate-maxline**=_n_ (Default: 0)

    API'ye bir seferde gönderilecek maksimum metin satırı sayısını belirtin.

    Bu değeri bir seferde bir satır çevirmek istiyorsanız 1 olarak ayarlayın. Bu seçenek `--xlate-maxlen` seçeneğinden önceliklidir.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    XML stil etiketini olduğu gibi bırakın.
    Ekim 2023'e kadar veriler üzerinde eğitim aldınız.

- **--xlate-stripe**

    [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) modülünü, eşleşen kısmı zebra şeritli bir şekilde göstermek için kullanın. Bu, eşleşen kısımlar arka arkaya bağlı olduğunda faydalıdır.

    Renk paleti, terminalin arka plan rengine göre değiştirilir. Eğer açıkça belirtmek isterseniz, **--xlate-stripe-light** veya **--xlate-stripe-dark** kullanabilirsiniz.

- **--xlate-mask**

    XML stil etiketlerini olduğu gibi bırakın. 
    Veri, Ekim 2023'e kadar eğitilmiştir.

- **--match-all**

    XML style tag'ını olduğu gibi bırakın.
    Dosyanın tüm metnini hedef alan olarak ayarlayın.

# CACHE OPTIONS

**xlate** modülü, her dosya için çeviri önbellek metnini saklayabilir ve sunucudan sorma yükünü ortadan kaldırmak için yürütmeden önce bunu okuyabilir. Varsayılan önbellek stratejisi `auto` ile, yalnızca hedef dosya için önbellek dosyası mevcut olduğunda önbellek verilerini korur.

**--xlate-cache=clear** önbellek yönetimini başlatmak veya mevcut tüm önbellek verilerini temizlemek için kullanılır. Bu seçenekle çalıştırıldığında, eğer mevcut bir önbellek dosyası yoksa yeni bir önbellek dosyası oluşturulacak ve sonrasında otomatik olarak korunacaktır.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Önbellek dosyasını mevcutsa koruyun.

    - `create`

        Boş önbellek dosyası oluştur ve çık.

    - `always`, `yes`, `1`

        XML style tag olarak bırakın.  
        Hedef normal bir dosya olduğu sürece önbelleği her durumda koruyun.

    - `clear`

        Öncelikle önbellek verilerini temizleyin.

    - `never`, `no`, `0`

        Cache dosyasını var olsa bile asla kullanmayın.

    - `accumulate`

        Varsayılan davranış olarak, kullanılmayan veriler önbellek dosyasından kaldırılır. Eğer bunları kaldırmak istemiyorsanız ve dosyada tutmak istiyorsanız, `accumulate` kullanın.
- **--xlate-update**

    Bu seçenek, gerekli olmasa bile önbellek dosyasını güncellemeye zorlar.

# COMMAND LINE INTERFACE

Bu modülü, dağıtımda bulunan `xlate` komutunu kullanarak komut satırından kolayca kullanabilirsiniz. Kullanım için `xlate` yardım bilgisine bakın.

`xlate` komutu, Docker ortamıyla birlikte çalışır, bu nedenle elinizde herhangi bir şey yüklü olmasa bile, Docker mevcut olduğu sürece bunu kullanabilirsiniz. `-D` veya `-C` seçeneğini kullanın.

Ayrıca, çeşitli belge stilleri için makefile'lar sağlandığından, özel bir belirleme olmaksızın diğer dillere çeviri mümkündür. `-M` seçeneğini kullanın.

Docker ve make seçeneklerini birleştirerek, make'i bir Docker ortamında çalıştırabilirsiniz.

`xlate -GC` çalıştırmak, mevcut çalışma git deposu ile bir shell başlatacaktır.

["SEE ALSO"](#see-also) bölümündeki Japonca makaleyi detaylar için okuyun.

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

Depoda bulunan `xlate.el` dosyasını yükleyerek Emacs editöründen `xlate` komutunu kullanın. `xlate-region` fonksiyonu verilen bölgeyi çevirir. Varsayılan dil `EN-US`'dir ve onu önek argüman ile çağırarak dil belirtebilirsiniz.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    DeepL hizmeti için kimlik doğrulama anahtarınızı ayarlayın.

- OPENAI\_API\_KEY

    OpenAI kimlik doğrulama anahtarı.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

DeepL ve ChatGPT için komut satırı araçlarını kurmalısınız.

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

    OpenAI komut satırı arayüzü

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    **greple** kılavuzuna hedef metin deseni hakkında detaylar için bakın. Eşleşme alanını sınırlamak için **--inside**, **--outside**, **--include**, **--exclude** seçeneklerini kullanın.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    `-Mupdate` modülünü **greple** komutunun sonucu ile dosyaları değiştirmek için kullanabilirsiniz.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    **sdif** kullanarak **-V** seçeneği ile yan yana çelişki işaretleyici formatını gösterin.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe** modülü **--xlate-stripe** seçeneği ile kullanılır.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Greple modülü, yalnızca gerekli kısımları DeepL API ile çevirmek ve değiştirmek için (Japonca)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    XML style tag olarak bırakın.  
    15 dilde belgeler oluşturma DeepL API modülü ile (Japonca)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Otomatik çeviri Docker ortamı DeepL API ile (Japonca)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
