# NAME

App::Greple::xlate - Greple tõlkimise tugimoodul

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.4101

# DESCRIPTION

**Greple** **xlate** moodul leiab soovitud tekstiplokid ja asendab need tõlgitud tekstiga. Praegu on tagasiside mootorina rakendatud DeepL (`deepl.pm`) ja ChatGPT (`gpt3.pm`) moodul. Eksperimentaalne tugi gpt-4 ja gpt-4o on samuti lisatud.

Kui soovite tõlkida tavalisi tekstiplokke Perli pod-stiilis kirjutatud dokumendis, kasutage käsku **greple** koos `xlate::deepl` ja `perl` mooduliga niimoodi:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

Selles käsus tähendab musterjada `^([\w\pP].*\n)+` järjestikuseid ridu, mis algavad tähtnumbrilise ja kirjavahemärgiga. See käsk näitab tõlgitavat ala esile tõstetud kujul. Valikut **--all** kasutatakse kogu teksti koostamiseks.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Seejärel lisatakse valik `--xlate`, et tõlkida valitud ala. Seejärel leitakse soovitud lõigud ja asendatakse need käsu **deepl** väljundiga.

Vaikimisi trükitakse algne ja tõlgitud tekst [git(1)](http://man.he.net/man1/git)-ga ühilduvas "konfliktimärkide" formaadis. Kasutades `ifdef` formaati, saab soovitud osa hõlpsasti kätte käsuga [unifdef(1)](http://man.he.net/man1/unifdef). Väljundi formaati saab määrata valikuga **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Kui soovite tõlkida kogu teksti, kasutage valikut **--match-all**. See on otsetee, et määrata muster `(?s).+`, mis vastab kogu tekstile.

Konfliktimärgistuse formaadis andmeid saab vaadata külg-üles stiilis käsuga `sdif` koos valikuga `-V`. Kuna sõnepõhiselt pole mõtet võrrelda, on soovitatav kasutada valikut `--no-cdif`. Kui teil ei ole vaja teksti värvida, määrake `--no-textcolor` (või `--no-tc`).

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Töötlemine toimub kindlaksmääratud ühikutes, kuid mitme mittetäieliku tekstirea järjestuse korral teisendatakse need kokku üheks reaks. See operatsioon toimub järgmiselt:

- Eemaldatakse valge tühik iga rea alguses ja lõpus.
- Kui rida lõpeb täies laiuses kirjavahemärgiga, ühendage see järgmise reaga.
- Kui rida lõpeb täies laiuses märgiga ja järgmine rida algab täies laiuses märgiga, ühendatakse read.
- Kui rea lõpp või algus ei ole täies laiuses märk, ühendage need, lisades tühiku.

Vahemälu andmeid hallatakse normaliseeritud teksti alusel, nii et isegi kui tehakse muudatusi, mis ei mõjuta normaliseerimise tulemusi, on vahemälus olevad tõlkeandmed ikkagi tõhusad.

See normaliseerimisprotsess viiakse läbi ainult esimese (0.) ja paarisnumbrilise mustri puhul. Seega, kui kaks mustrit on määratud järgmiselt, töödeldakse pärast normaliseerimist esimesele mustrile vastavat teksti ja teisele mustrile vastavat teksti ei normaliseerita.

    greple -Mxlate -E normalized -E not-normalized

Seetõttu kasutage esimest mustrit teksti puhul, mida tuleb töödelda mitme rea ühendamise teel üheks reaks, ja teist mustrit eelnevalt vormindatud teksti puhul. Kui esimeses mustris ei ole sobivat teksti, kasutage mustrit, mis ei vasta millelegi, näiteks `(?!)`.

# MASKING

Mõnikord on tekstiosasid, mida te ei soovi tõlkida. Näiteks markdown-failide sildid. DeepL soovitab sellistel juhtudel konverteerida välja jäetav tekstiosa XML-tähtedeks, tõlkida ja pärast tõlkimise lõpetamist taastada. Selle toetamiseks on võimalik määrata osad, mis tuleb tõlkimisest välja jätta.

    --xlate-setopt maskfile=MASKPATTERN

See tõlgendab iga rida failis \`MASKPATTERN\` regulaaravaldisena, tõlgib sellele vastavad stringid ja taastab pärast töötlemist. `#`-ga algavaid ridu ignoreeritakse.

Keerulise mustri võib kirjutada mitmele reale koos kaldkriipsu eskaga newline.

Seda, kuidas tekst on maskeerimise abil muudetud, saab näha valiku **--xlate-mask** abil.

See liides on eksperimentaalne ja võib tulevikus muutuda.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Käivitage tõlkimisprotsess iga sobitatud ala jaoks.

    Ilma selle valikuta käitub **greple** nagu tavaline otsingukäsklus. Seega saate enne tegeliku töö käivitamist kontrollida, millise faili osa kohta tehakse tõlge.

    Käsu tulemus läheb standardväljundisse, nii et vajadusel suunake see faili ümber või kaaluge mooduli [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) kasutamist.

    Valik **--xlate** kutsub **--xlate-color** valiku **--color=never** valikul.

    Valikuga **--xlate-fold** volditakse konverteeritud tekst määratud laiusega. Vaikimisi laius on 70 ja seda saab määrata valikuga **--xlate-fold-width**. Neli veergu on reserveeritud sisselülitamiseks, nii et iga rida võib sisaldada maksimaalselt 74 märki.

- **--xlate-engine**=_engine_

    Määratleb kasutatava tõlkemootori. Kui määrate mootori mooduli otse, näiteks `-Mxlate::deepl`, ei pea seda valikut kasutama.

    Praegu on saadaval järgmised mootorid

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4-turbo
    - **gpt4o**: gpt-4o-mini

        **gpt-4o** liides on ebastabiilne ja hetkel ei saa garanteerida selle korrektset toimimist.

- **--xlate-labor**
- **--xlabor**

    Selle asemel, et kutsuda tõlkemootorit, oodatakse tööd. Pärast tõlgitava teksti ettevalmistamist kopeeritakse need lõikelauale. Eeldatakse, et te kleebite need vormi, kopeerite tulemuse lõikelauale ja vajutate return.

- **--xlate-to** (Default: `EN-US`)

    Määrake sihtkeel. **DeepL** mootori kasutamisel saate saadaval olevad keeled kätte käsuga `deepl languages`.

- **--xlate-format**=_format_ (Default: `conflict`)

    Määrake originaal- ja tõlgitud teksti väljundformaat.

    Järgmised vormingud, välja arvatud `xtxt`, eeldavad, et tõlgitav osa on ridade kogum. Tegelikult on võimalik tõlkida ainult osa reast ja muu formaadi kui `xtxt` määramine ei anna mõttekaid tulemusi.

    - **conflict**, **cm**

        Algne ja teisendatud tekst trükitakse [git(1)](http://man.he.net/man1/git) konfliktimärgistuse formaadis.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Originaalfaili saate taastada järgmise käsuga [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Algne ja tõlgitud tekst väljastatakse markdowni kohandatud konteineri stiilis.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Ülaltoodud tekst tõlgitakse HTML-is järgmiselt.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Koolonite arv on vaikimisi 7. Kui määrate koolonite järjestuse nagu `:::::`, kasutatakse seda 7 kooloni asemel.

    - **ifdef**

        Algne ja teisendatud tekst trükitakse [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` formaadis.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Saate ainult jaapani teksti taastada käsuga **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Algne ja teisendatud tekst on trükitud ühe tühja reaga eraldatud. `space+` puhul väljastab see ka uue rea pärast teisendatud teksti.

    - **xtxt**

        Kui formaat on `xtxt` (tõlgitud tekst) või tundmatu, trükitakse ainult tõlgitud tekst.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Määrake API-le korraga saadetava teksti maksimaalne pikkus. Vaikeväärtus on määratud nagu tasuta DeepL kontoteenuse puhul: 128K API jaoks (**--xlate**) ja 5000 lõikelaua liidesele (**--xlate-labor**). Saate neid väärtusi muuta, kui kasutate Pro teenust.

- **--xlate-maxline**=_n_ (Default: 0)

    Määrake API-le korraga saadetava teksti maksimaalne ridade arv.

    Määrake selle väärtuseks 1, kui soovite tõlkida ühe rea korraga. See valik on ülimuslik valikust `--xlate-maxlen`.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Näete tõlkimise tulemust reaalajas STDERR-väljundist.

- **--xlate-stripe**

    Kasutage [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) moodulit, et näidata sobitatud osa sebratriibu moodi. See on kasulik siis, kui sobitatud osad on omavahel ühendatud.

    Värvipalett vahetatakse vastavalt terminali taustavärvile. Kui soovite seda selgesõnaliselt määrata, võite kasutada **--xlate-stripe-light** või **--xlate-stripe-dark**.

- **--xlate-mask**

    Sooritage maskeerimisfunktsioon ja kuvage teisendatud tekst sellisena, nagu see on, ilma taastamiseta.

- **--match-all**

    Määrake kogu faili tekst sihtkohaks.

# CACHE OPTIONS

**xlate** moodul võib salvestada iga faili tõlketeksti vahemällu ja lugeda seda enne täitmist, et kõrvaldada serveri küsimisega kaasnev koormus. Vaikimisi vahemälustrateegia `auto` puhul säilitab ta vahemälu andmeid ainult siis, kui vahemälufail on sihtfaili jaoks olemas.

Kasutage **--xlate-cache=clear**, et alustada vahemälu haldamist või puhastada kõik olemasolevad vahemälu andmed. Selle valikuga käivitamisel luuakse uus vahemälufail, kui seda ei ole veel olemas, ja seejärel hooldatakse seda automaatselt.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Säilitada vahemälufaili, kui see on olemas.

    - `create`

        Loob tühja vahemälufaili ja väljub.

    - `always`, `yes`, `1`

        Säilitab vahemälu andmed niikuinii, kui sihtfail on tavaline fail.

    - `clear`

        Tühjendage esmalt vahemälu andmed.

    - `never`, `no`, `0`

        Ei kasuta kunagi vahemälufaili, isegi kui see on olemas.

    - `accumulate`

        Vaikimisi käitumise kohaselt eemaldatakse kasutamata andmed vahemälufailist. Kui te ei soovi neid eemaldada ja failis hoida, kasutage `accumulate`.
- **--xlate-update**

    See valik sunnib uuendama vahemälufaili isegi siis, kui see pole vajalik.

# COMMAND LINE INTERFACE

Seda moodulit saab hõlpsasti kasutada käsurealt, kasutades distributsioonis sisalduvat käsku `xlate`. Kasutamise kohta vaata `xlate` abiinfot.

`xlate` käsk töötab koos Dockeri keskkonnaga, nii et isegi kui teil ei ole midagi paigaldatud, saate seda kasutada, kui Docker on saadaval. Kasutage valikut `-D` või `-C`.

Samuti, kuna makefile'id erinevate dokumendistiilide jaoks on olemas, on tõlkimine teistesse keeltesse võimalik ilma spetsiaalse täpsustuseta. Kasutage valikut `-M`.

Saate ka Dockeri ja make'i valikuid kombineerida, nii et saate make'i käivitada Dockeri keskkonnas.

Käivitamine nagu `xlate -GC` käivitab shell'i, kuhu on paigaldatud praegune töötav git-repositoorium.

Lugege üksikasjalikult Jaapani artiklit ["SEE ALSO"](#see-also) osas.

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

Laadige repositooriumis sisalduv fail `xlate.el`, et kasutada `xlate` käsku Emacs redaktorist. `xlate-region` funktsioon tõlkida antud piirkonda. Vaikimisi keel on `EN-US` ja te võite määrata keele, kutsudes seda prefix-argumendiga.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Määrake oma autentimisvõti DeepL teenuse jaoks.

- OPENAI\_API\_KEY

    OpenAI autentimisvõti.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Peate installima käsurea tööriistad DeepL ja ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Dockeri konteineri kujutis.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Pythoni raamatukogu ja CLI käsk.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Pythoni raamatukogu

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI käsurea liides

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Vt **greple** käsiraamatust üksikasjalikult sihttekstimustri kohta. Kasutage **--inside**, **--outside**, **--include**, **--exclude** valikuid, et piirata sobitusala.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Saate kasutada `-Mupdate` moodulit, et muuta faile **greple** käsu tulemuse järgi.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Kasutage **sdif**, et näidata konfliktimärkide formaati kõrvuti valikuga **-V**.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **xlate-stripe** mooduli kasutamine **--xlate-stripe** valikuga.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Greple moodul tõlkida ja asendada ainult vajalikud osad DeepL API (jaapani keeles)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Dokumentide genereerimine 15 keeles DeepL API mooduliga (jaapani keeles).

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Automaatne tõlkekeskkond Docker koos DeepL API-ga (jaapani keeles)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
