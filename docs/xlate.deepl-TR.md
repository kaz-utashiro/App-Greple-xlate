# NAME

App::Greple::xlate - greple için çeviri destek modülü

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.9909

# DESCRIPTION

**Greple** **xlate** modülü istenen metin bloklarını bulur ve bunları çevrilmiş metinle değiştirir. Şu anda DeepL (`deepl.pm`) ve ChatGPT (`gpt3.pm`) modülü bir arka uç motoru olarak uygulanmaktadır. Gpt-4 ve gpt-4o için deneysel destek de dahil edilmiştir.

Perl'ün pod stilinde yazılmış bir belgedeki normal metin bloklarını çevirmek istiyorsanız, **greple** komutunu `xlate::deepl` ve `perl` modülü ile aşağıdaki gibi kullanın:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

Bu komutta, `^([\w\pP].*\n)+` kalıp dizesi alfa-sayısal ve noktalama harfleriyle başlayan ardışık satırlar anlamına gelir. Bu komut çevrilecek alanı vurgulanmış olarak gösterir. **--all** seçeneği metnin tamamını üretmek için kullanılır.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Daha sonra seçilen alanı çevirmek için `--xlate` seçeneğini ekleyin. Ardından, istenen bölümleri bulacak ve bunları **deepl** komut çıktısı ile değiştirecektir.

Varsayılan olarak, orijinal ve çevrilmiş metin [git(1)](http://man.he.net/man1/git) ile uyumlu "conflict marker" biçiminde yazdırılır. `ifdef` formatını kullanarak, [unifdef(1)](http://man.he.net/man1/unifdef) komutu ile istediğiniz kısmı kolayca alabilirsiniz. Çıktı biçimi **--xlate-format** seçeneği ile belirtilebilir.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Eğer metnin tamamını çevirmek istiyorsanız, **--match-all** seçeneğini kullanın. Bu, metnin tamamıyla eşleşen `(?s).+` kalıbını belirtmek için kısa yoldur.

Çatışma işaretleyici formatı verileri, `-V` seçeneği ile `sdif` komutu ile yan yana tarzda görüntülenebilir. Dize bazında karşılaştırma yapmanın bir anlamı olmadığından, `--no-cdif` seçeneği önerilir. Metni renklendirmeniz gerekmiyorsa, `--no-textcolor` (veya `--no-tc`) seçeneğini belirtin.

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

İşlem belirtilen birimler halinde yapılır, ancak birden fazla boş olmayan metin satırı dizisi olması durumunda, bunlar birlikte tek bir satıra dönüştürülür. Bu işlem aşağıdaki gibi gerçekleştirilir:

- Her satırın başındaki ve sonundaki beyaz boşluğu kaldırın.
- Bir satır tam genişlikte bir noktalama karakteriyle bitiyorsa, sonraki satırla birleştirin.
- Bir satır tam genişlikte bir karakterle bitiyorsa ve bir sonraki satır tam genişlikte bir karakterle başlıyorsa, satırları birleştirin.
- Bir satırın sonu veya başı tam genişlikte bir karakter değilse, boşluk karakteri ekleyerek birleştirin.

Önbellek verileri normalleştirilmiş metne göre yönetilir, bu nedenle normalleştirme sonuçlarını etkilemeyen değişiklikler yapılsa bile önbelleğe alınan çeviri verileri etkili olmaya devam edecektir.

Bu normalleştirme işlemi yalnızca ilk (0.) ve çift numaralı kalıp için gerçekleştirilir. Bu nedenle, aşağıdaki gibi iki kalıp belirtilirse, ilk kalıpla eşleşen metin normalleştirmeden sonra işlenecek ve ikinci kalıpla eşleşen metin üzerinde normalleştirme işlemi yapılmayacaktır.

    greple -Mxlate -E normalized -E not-normalized

Bu nedenle, birden fazla satırı tek bir satırda birleştirerek işlenecek metin için ilk kalıbı kullanın ve önceden biçimlendirilmiş metin için ikinci kalıbı kullanın. İlk kalıpta eşleşecek metin yoksa, `(?!)` gibi hiçbir şeyle eşleşmeyen bir kalıp kullanın.

# MASKING

Bazen, çevrilmesini istemediğiniz metin bölümleri olabilir. Örneğin, markdown dosyalarındaki etiketler. DeepL bu gibi durumlarda, metnin hariç tutulacak kısmının XML etiketlerine dönüştürülmesini, çevrilmesini ve çeviri tamamlandıktan sonra geri yüklenmesini önerir. Bunu desteklemek için, çeviriden maskelenecek kısımları belirtmek mümkündür.

    --xlate-setopt maskfile=MASKPATTERN

Bu, \`MASKPATTERN\` dosyasının her satırını düzenli bir ifade olarak yorumlayacak, bununla eşleşen dizeleri çevirecek ve işlemden sonra geri dönecektir. `#` ile başlayan satırlar yok sayılır.

Karmaşık desen ters eğik çizgi ile birden fazla satıra yazılabilir.

Maskeleme ile metnin nasıl dönüştürüldüğü **--xlate-mask** seçeneği ile görülebilir.

Bu arayüz deneyseldir ve gelecekte değiştirilebilir.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Eşleşen her alan için çeviri işlemini çağırın.

    Bu seçenek olmadan, **greple** normal bir arama komutu gibi davranır. Böylece, asıl işi çağırmadan önce dosyanın hangi bölümünün çeviriye tabi olacağını kontrol edebilirsiniz.

    Komut sonucu standart çıkışa gider, bu nedenle gerekirse dosyaya yönlendirin veya [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) modülünü kullanmayı düşünün.

    **--xlate** seçeneği **--color=never** seçeneği ile **--xlate-color** seçeneğini çağırır.

    **--xlate-fold** seçeneği ile, dönüştürülen metin belirtilen genişlikte katlanır. Varsayılan genişlik 70'tir ve **--xlate-fold-width** seçeneği ile ayarlanabilir. Çalıştırma işlemi için dört sütun ayrılmıştır, bu nedenle her satır en fazla 74 karakter alabilir.

- **--xlate-engine**=_engine_

    Kullanılacak çeviri motorunu belirtir. Motor modülünü `-Mxlate::deepl` gibi doğrudan belirtirseniz, bu seçeneği kullanmanıza gerek yoktur.

    Şu anda, aşağıdaki motorlar mevcuttur

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4-turbo
    - **gpt4o**: gpt-4o-mini

        **gpt-4o**'nun arayüzü kararsızdır ve şu anda doğru çalışacağı garanti edilemez.

- **--xlate-labor**
- **--xlabor**

    Çeviri motorunu çağırmak yerine sizin çalışmanız beklenmektedir. Çevrilecek metin hazırlandıktan sonra panoya kopyalanır. Bunları forma yapıştırmanız, sonucu panoya kopyalamanız ve return tuşuna basmanız beklenir.

- **--xlate-to** (Default: `EN-US`)

    Hedef dili belirtin. **DeepL** motorunu kullanırken `deepl languages` komutu ile mevcut dilleri alabilirsiniz.

- **--xlate-format**=_format_ (Default: `conflict`)

    Orijinal ve çevrilmiş metin için çıktı formatını belirtin.

    `xtxt` dışındaki aşağıdaki biçimler çevrilecek parçanın bir satır koleksiyonu olduğunu varsayar. Aslında, bir satırın yalnızca bir kısmını çevirmek mümkündür, ancak `xtxt` dışında bir biçim belirtmek anlamlı sonuçlar üretmeyecektir.

    - **conflict**, **cm**

        Orijinal ve dönüştürülmüş metin [git(1)](http://man.he.net/man1/git) çakışma işaretleyici biçiminde yazdırılır.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Bir sonraki [sed(1)](http://man.he.net/man1/sed) komutu ile orijinal dosyayı kurtarabilirsiniz.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Orijinal ve çevrilmiş metin, markdown'un özel kapsayıcı stilinde çıktı olarak verilir.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Yukarıdaki metin HTML'de aşağıdakine çevrilecektir.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        İki nokta üst üste sayısı varsayılan olarak 7'dir. `:::::` gibi iki nokta üst üste dizisi belirtirseniz, 7 iki nokta üst üste yerine kullanılır.

    - **ifdef**

        Orijinal ve dönüştürülmüş metin [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` biçiminde yazdırılır.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        **unifdef** komutu ile sadece Japonca metni alabilirsiniz:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Orijinal ve dönüştürülmüş metin tek bir boş satırla ayrılarak yazdırılır. `space+` için, dönüştürülen metinden sonra bir satırsonu çıktısı da verir.

    - **xtxt**

        Biçim `xtxt` (çevrilmiş metin) veya bilinmiyorsa, yalnızca çevrilmiş metin yazdırılır.

- **--xlate-maxlen**=_chars_ (Default: 0)

    API'ye bir kerede gönderilecek maksimum metin uzunluğunu belirtin. Varsayılan değer ücretsiz DeepL hesap hizmeti için ayarlanmıştır: API için 128K (**--xlate**) ve pano arayüzü için 5000 (**--xlate-labor**). Pro hizmeti kullanıyorsanız bu değerleri değiştirebilirsiniz.

- **--xlate-maxline**=_n_ (Default: 0)

    API'ye bir kerede gönderilecek maksimum metin satırını belirtin.

    Her seferinde bir satır çevirmek istiyorsanız bu değeri 1 olarak ayarlayın. Bu seçenek `--xlate-maxlen` seçeneğine göre önceliklidir.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Çeviri sonucunu STDERR çıktısında gerçek zamanlı olarak görün.

- **--xlate-stripe**

    Eşleşen kısmı zebra şeritleme yöntemiyle göstermek için [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) modülünü kullanın. Bu, eşleşen parçalar arka arkaya bağlandığında kullanışlıdır.

    Renk paleti terminalin arka plan rengine göre değiştirilir. Açıkça belirtmek isterseniz, **--xlate-stripe-light** veya **--xlate-stripe-dark** kullanabilirsiniz.

- **--xlate-mask**

    Maskeleme işlevini gerçekleştirin ve dönüştürülen metni geri yükleme yapmadan olduğu gibi görüntüleyin.

- **--match-all**

    Dosyanın tüm metnini hedef alan olarak ayarlayın.

# CACHE OPTIONS

**xlate** modülü her dosya için önbellekte çeviri metnini saklayabilir ve sunucuya sorma ek yükünü ortadan kaldırmak için yürütmeden önce okuyabilir. Varsayılan önbellek stratejisi `auto` ile, önbellek verilerini yalnızca hedef dosya için önbellek dosyası mevcut olduğunda tutar.

Önbellek yönetimini başlatmak veya mevcut tüm önbellek verilerini temizlemek için **--xlate-cache=clear** seçeneğini kullanın. Bu seçenekle çalıştırıldığında, mevcut değilse yeni bir önbellek dosyası oluşturulacak ve daha sonra otomatik olarak korunacaktır.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Eğer varsa önbellek dosyasını koruyun.

    - `create`

        Boş önbellek dosyası oluştur ve çık.

    - `always`, `yes`, `1`

        Hedef normal dosya olduğu sürece önbelleği yine de korur.

    - `clear`

        Önce önbellek verilerini temizleyin.

    - `never`, `no`, `0`

        Var olsa bile önbellek dosyasını asla kullanmayın.

    - `accumulate`

        Varsayılan davranışa göre, kullanılmayan veriler önbellek dosyasından kaldırılır. Bunları kaldırmak ve dosyada tutmak istemiyorsanız, `accumulate` kullanın.
- **--xlate-update**

    Bu seçenek, gerekli olmasa bile önbellek dosyasını güncellemeye zorlar.

# COMMAND LINE INTERFACE

Bu modülü, dağıtımda bulunan `xlate` komutunu kullanarak komut satırından kolayca kullanabilirsiniz. Kullanım için `xlate` man sayfasına bakın.

`xlate` komutu Docker ortamı ile uyumlu olarak çalışır, bu nedenle elinizde kurulu bir şey olmasa bile Docker mevcut olduğu sürece kullanabilirsiniz. `-D` veya `-C` seçeneğini kullanın.

Ayrıca, çeşitli belge stilleri için makefiles sağlandığından, özel bir belirtim olmadan diğer dillere çeviri mümkündür. `-M` seçeneğini kullanın.

Docker ve `make` seçeneklerini birleştirerek `make` seçeneğini Docker ortamında da çalıştırabilirsiniz.

`xlate -C` gibi çalıştırmak, mevcut çalışan git deposunun bağlı olduğu bir kabuk başlatacaktır.

Ayrıntılar için ["SEE ALSO"](#see-also) bölümündeki Japonca makaleyi okuyun.

# EMACS

Emacs editöründen `xlate` komutunu kullanmak için depoda bulunan `xlate.el` dosyasını yükleyin. `xlate-region` fonksiyonu verilen bölgeyi çevirir. Varsayılan dil `EN-US`'dir ve prefix argümanı ile çağırarak dili belirtebilirsiniz.

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

DeepL ve ChatGPT için komut satırı araçlarını yüklemeniz gerekir.

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

    Hedef metin kalıbı hakkında ayrıntılı bilgi için **greple** kılavuzuna bakın. Eşleşen alanı sınırlamak için **--inside**, **--outside**, **--include**, **--exclude** seçeneklerini kullanın.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Dosyaları **greple** komutunun sonucuna göre değiştirmek için `-Mupdate` modülünü kullanabilirsiniz.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    **-V** seçeneği ile çakışma işaretleyici formatını yan yana göstermek için **sdif** kullanın.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    **--xlate-stripe** seçeneği ile Greple **stripe** modülü kullanımı.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Sadece gerekli kısımları çevirmek ve değiştirmek için Greple modülü DeepL API (Japonca)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    DeepL API modülü ile 15 dilde belge oluşturma (Japonca)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    DeepL API ile otomatik çeviri Docker ortamı (Japonca)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
