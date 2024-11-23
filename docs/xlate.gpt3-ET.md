# NAME

App::Greple::xlate - tõlketoe moodul greple jaoks

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.9901

# DESCRIPTION

**Greple** **xlate** moodul leiab soovitud tekstiplokid ja asendab need tõlgitud tekstiga. Praegu on tagumise mootorina kasutusel DeepL (`deepl.pm`) ja ChatGPT (`gpt3.pm`) moodul. Katseversioonid gpt-4 ja gpt-4o toetusest on samuti saadaval.

Kui soovite tõlkida tavalisi tekstiplokke Perl'i pod-stiilis kirjutatud dokumendis, kasutage **greple** käsku koos `xlate::deepl` ja `perl` mooduliga järgmiselt:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

Selles käsu `^([\w\pP].*\n)+` muster tähendab järjestikuseid ridu, mis algavad alfa-numbrilise ja kirjavahemärgiga. See käsk näitab tõlgitavat ala esile tõstetult. Valikut **--all** kasutatakse kogu teksti tootmiseks.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Seejärel lisage `--xlate` valik, et tõlkida valitud ala. Seejärel otsib see soovitud jaotised üles ning asendab need **deepl** käsu väljundiga.

Vaikimisi prinditakse algne ja tõlgitud tekst "konfliktimärgendi" formaadis, mis on ühilduv [git(1)](http://man.he.net/man1/git)-ga. Kasutades `ifdef` formaati, saate soovitud osa hõlpsasti kätte [unifdef(1)](http://man.he.net/man1/unifdef) käsu abil. Väljundi formaati saab määrata **--xlate-format** valikuga.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Kui soovite tõlkida terve teksti, kasutage **--match-all** valikut. See on otsetee, et määrata mustrit `(?s).+`, mis sobib tervele tekstile.

Konfliktimärgistuse vormingu andmeid saab vaadata kõrvuti stiilis `sdif` käsu abil `-V` valikuga. Kuna mõttekas pole võrrelda iga stringi alusel, soovitatakse kasutada valikut `--no-cdif`. Kui te ei vaja teksti värvimist, määrake `--no-textcolor` (või `--no-tc`).

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Töötlemine toimub määratletud üksustes, kuid mitme rea järjestikuse mitte-tühja teksti korral teisendatakse need koos üheks reaks. See toiming viiakse läbi järgmiselt:

- Eemaldatakse tühikud iga rea algusest ja lõpust.
- Kui rida lõpeb täispikkusega kirjavahemärgiga, siis ühenda see järgmise reaga.
- Kui rida lõpeb täislaia tähemärgiga ja järgmine rida algab täislaia tähemärgiga, ühendatakse read.
- Kui rea lõpus või alguses pole täislaia tähemärki, ühendatakse nad, sisestades tühikumärgi.

Vahemälu andmeid haldab normaliseeritud teksti põhjal, seega isegi kui tehakse muudatusi, mis normaliseerimistulemusi ei mõjuta, jäävad vahemälus olevad tõlkeandmed endiselt kehtima.

See normaliseerimisprotsess viiakse läbi ainult esimese (0.) ja paarisarvulise mustri jaoks. Seega, kui kaks mustrit on määratud järgmiselt, siis esimesele mustrile vastava teksti töödeldakse pärast normaliseerimist ning teisele mustrile vastava teksti puhul normaliseerimisprotsessi ei teostata.

    greple -Mxlate -E normalized -E not-normalized

Seetõttu kasutage esimest mustrit teksti jaoks, mis tuleb töödelda, kombineerides mitu rida üheks reaks, ning kasutage teist mustrit eelvormindatud teksti jaoks. Kui esimeses mustris pole teksti, mida sobitada, kasutage mustrit, mis ei sobita midagi, näiteks `(?!)`.

# MASKING

Aeg-ajalt on tekstiosi, mida te ei soovi tõlkida. Näiteks märgendeid märkmete failides. DeepL soovitab sellistel juhtudel tõlkimata jäetav osa teisendada XML-märgenditeks, tõlkida ja seejärel pärast tõlke lõpetamist taastada. Selle toetamiseks on võimalik määrata tõlkimisest varjatavad osad.

    --xlate-setopt maskfile=MASKPATTERN

See tõlgib iga \`MASKPATTERN\` faili rea tõlgendamiseks regulaaravaldistena ja taastab pärast töötlemist. Ridadega, mis algavad `#`, ei tegeleta.

Kompleksne muster saab kirjutada mitmele reale tagurpidi kaldkriipsuga põimitud uuele reale.

Kuidas tekst muudetakse varjamise abil, saab näha valikuga **--xlate-mask**.

See liides on eksperimentaalne ja võib tulevikus muutuda.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Käivitage tõlkimisprotsess iga sobiva ala jaoks.

    Ilma selle valikuta käitub **greple** nagu tavaline otsingukäsk. Seega saate enne tegeliku töö käivitamist kontrollida, milline osa failist saab tõlkeobjektiks.

    Käsu tulemus läheb standardväljundisse, nii et suunake see vajadusel faili või kaaluge [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) mooduli kasutamist.

    Valik **--xlate** kutsub välja valiku **--xlate-color** koos valikuga **--color=never**.

    Valikuga **--xlate-fold** volditakse teisendatud tekst määratud laiusega. Vaikimisi laius on 70 ja seda saab määrata valikuga **--xlate-fold-width**. Neli veergu on reserveeritud run-in toimingu jaoks, nii et iga rida võib sisaldada kõige rohkem 74 tähemärki.

- **--xlate-engine**=_engine_

    Määrab kasutatava tõlke mootori. Kui määrate mootori mooduli otse, näiteks `-Mxlate::deepl`, siis pole selle valiku kasutamine vajalik.

    Sel hetkel on saadaval järgmised mootorid

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4-turbo
    - **gpt4o**: gpt-4o-mini

        **gpt-4o** liides on ebastabiilne ega pruugi hetkel korralikult töötada.

- **--xlate-labor**
- **--xlabor**

    Tõlke mootori kutsumise asemel oodatakse, et te töötaksite ise. Pärast teksti ettevalmistamist tõlkimiseks kopeeritakse need lõikelauale. Oodatakse, et kleepiksite need vormi, kopeeriksite tulemuse lõikelauale ja vajutaksite tagastusklahvi.

- **--xlate-to** (Default: `EN-US`)

    Määrake sihtkeel. Saate saada saadaolevad keeled käsu `deepl languages` abil, kui kasutate **DeepL** mootorit.

- **--xlate-format**=_format_ (Default: `conflict`)

    Määrake algse ja tõlgitud teksti väljundi vorming.

    Järgmised vormingud peale `xtxt` eeldavad, et tõlgitav osa koosneb ridadest. Tegelikult on võimalik tõlkida ainult osa reast ning muu vormingu määramine peale `xtxt` ei anna mõistlikke tulemusi.

    - **conflict**, **cm**

        Originaal- ja tõlgitud tekst on trükitud [git(1)](http://man.he.net/man1/git) konfliktimärgendi formaadis.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Saate algse faili taastada järgmise [sed(1)](http://man.he.net/man1/sed) käsu abil.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        \`\`\`html

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        &lt;div class="original">

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Vaikimisi on koolonite arv 7. Kui määratlete koolonite jada nagu `:::::`, kasutatakse seda 7 kooloni asemel.

    - **ifdef**

        Originaal- ja tõlgitud tekst on trükitud [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` formaadis.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Saate ainult jaapani keelse teksti kätte **unifdef** käsu abil:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Original text:

    - **xtxt**

        Kui vorming on `xtxt` (tõlgitud tekst) või tundmatu, prinditakse ainult tõlgitud tekst.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Tõlgi järgnev tekst eesti keelde, rida-realt.

- **--xlate-maxline**=_n_ (Default: 0)

    Määrake korraga API-le saadetavate tekstiridade maksimaalne arv.

    Seadke see väärtus 1, kui soovite tõlkida ühe rea korraga. See valik on prioriteetsem kui `--xlate-maxlen` valik.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Vaadake tõlke tulemust reaalajas STDERR väljundis.

- **--xlate-stripe**

    Kasuta [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) moodulit, et näidata sobitatud osa sebralise triibulise moega. See on kasulik, kui sobitatud osad on omavahel ühendatud.

    Värvipalett vahetub vastavalt terminali taustavärvile. Kui soovid seda selgelt määratleda, saad kasutada valikuid **--xlate-stripe-light** või **--xlate-stripe-dark**.

- **--xlate-mask**

    Täida varjamisfunktsioon ja kuvage teisendatud tekst ilma taastamiseta.

- **--match-all**

    Määrake faili kogu tekst sihtalaks.

# CACHE OPTIONS

**xlate** moodul saab salvestada tõlke teksti vahemällu iga faili jaoks ja lugeda selle enne täitmist, et kõrvaldada päringu ülekoormus. Vaikimisi vahemälu strateegia `auto` korral hoitakse vahemälu andmeid ainult siis, kui sihtfaili jaoks on olemas vahemälu fail.

Kasuta **--xlate-cache=clear** vahemälu haldamise alustamiseks või olemasoleva vahemäluandmete puhastamiseks. Selle valikuga käivitamisel luuakse uus vahemälu fail, kui seda pole olemas, ja seejärel hoitakse seda automaatselt.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Hoia vahemälu faili, kui see on olemas.

    - `create`

        Loo tühi vahemälu fail ja välju.

    - `always`, `yes`, `1`

        Hoia vahemälu igal juhul, kui sihtfail on tavaline fail.

    - `clear`

        Kustuta kõigepealt vahemälu andmed.

    - `never`, `no`, `0`

        Ära kasuta vahemälu faili isegi siis, kui see on olemas.

    - `accumulate`

        Vaikimisi käitumise korral eemaldatakse kasutamata andmed vahemälu failist. Kui te ei soovi neid eemaldada ja soovite neid failis hoida, kasutage `accumulate`.
- **--xlate-update**

    See valik sunnib värskendama vahemälu faili isegi siis, kui see pole vajalik.

# COMMAND LINE INTERFACE

Saate seda moodulit hõlpsalt kasutada käsurealt, kasutades jaotises sisalduvat `xlate` käsku. Vaadake kasutamiseks `xlate` man lehte.

`xlate` käsk töötab koos Dockeri keskkonnaga, seega saate seda kasutada ka siis, kui teil pole midagi installitud, kui Docker on saadaval. Kasutage `-D` või `-C` valikut.

Lisaks on saadaval erinevate dokumentide stiilide jaoks makefailid, mis võimaldavad tõlkida teistesse keeltesse ilma eriliste spetsifikatsioonideta. Kasutage `-M` valikut.

Saate ka Dockeri ja make valikuid kombineerida, et saaksite make käivitada Dockeri keskkonnas.

Käivitades näiteks `xlate -GC`, käivitatakse käskluskonsool, kus on praegune töötav git-i hoidla ühendatud.

Lugege jaapani keelse artikli üksikasjade kohta ["VAATA KA"](#vaata-ka) jaotises.

    xlate [ options ] -t lang file [ greple options ]
        -h   help
        -v   show version
        -d   debug
        -n   dry-run
        -a   use API
        -c   just check translation area
        -r   refresh cache
        -u   force update cache
        -s   silent mode
        -e # translation engine (*deepl, gpt3, gpt4, gpt4o)
        -p # pattern to determine translation area
        -x # file containing mask patterns
        -w # wrap line by # width
        -o # output format (*xtxt, cm, ifdef, space, space+, colon)
        -f # from lang (ignored)
        -t # to lang (required, no default)
        -m # max length per API call
        -l # show library files (XLATE.mk, xlate.el)
        --   end of option
        N.B. default is marked as *

    Make options
        -M   run make
        -n   dry-run

    Docker options
        -D * run xlate on the container with the same parameters
        -C * execute following command on the container, or run shell
        -S * start the live container
        -A * attach to the live container
        N.B. -D/-C/-A terminates option handling

        -G   mount git top-level directory
        -H   mount home directory
        -V # specify mount directory
        -U   do not mount
        -R   mount read-only
        -L   do not remove and keep live container
        -K   kill and remove live container
        -E # specify environment variable to be inherited
        -I # docker image or version (default: tecolicom/xlate:version)

    Control Files:
        *.LANG    translation languates
        *.FORMAT  translation foramt (xtxt, cm, ifdef, colon, space)
        *.ENGINE  translation engine (deepl, gpt3, gpt4, gpt4o)

# EMACS

Laadige `xlate.el` fail, mis on kaasasolevas hoidlas, et kasutada `xlate` käsku Emacs redaktorist. `xlate-region` funktsioon tõlgib antud piirkonna. Vaikimisi keel on `EN-US` ja saate keele määrata eesliiteargumendiga.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Seadistage oma autentimisvõti DeepL-teenuse jaoks.

- OPENAI\_API\_KEY

    OpenAI autentimisvõti.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Peate installima käsurea tööriistad DeepL ja ChatGPT jaoks.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Dockeri konteineri pilt.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Pythoni teek ja käsurea käsk.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Pythoni teek

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI käsurealiides

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Vaadake **greple** käsiraamatut sihtteksti mustrite üksikasjade kohta. Piirake vastavust **--inside**, **--outside**, **--include**, **--exclude** valikutega.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Saate kasutada `-Mupdate` moodulit failide muutmiseks **greple** käsu tulemuse põhjal.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Kasutage **sdif** konfliktimärgendi vormingu kuvamiseks kõrvuti **-V** valikuga.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe** moodulit kasutatakse valikuga **--xlate-stripe**.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Greple moodul tõlkimiseks ja asendamiseks ainult vajalike osadega DeepL API abil (jaapani keeles)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Dokumentide genereerimine 15 keeles DeepL API mooduliga (jaapani keeles)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Automaatse tõlke Dockeri keskkond DeepL API abil (jaapani keeles)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
