# NAME

App::Greple::xlate - tõlke tugimoodul greple jaoks

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.9909

# DESCRIPTION

**Greple** **xlate** moodul leiab soovitud tekstilõigud ja asendab need tõlgitud tekstiga. Praegu on DeepL (`deepl.pm`) ja ChatGPT (`gpt3.pm`) moodulid rakendatud taustamootorina. Eksperimentaalne tugi gpt-4 ja gpt-4o jaoks on samuti kaasas.

Kui soovid tõlkida tavalisi tekstilõike dokumendis, mis on kirjutatud Perli pod-stiilis, kasuta **greple** käsku koos `xlate::deepl` ja `perl` mooduliga järgmiselt:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

Selles käsus tähendab mustristräng `^([\w\pP].*\n)+` järjestikuseid ridu, mis algavad tähestiku- või kirjavahemärgiga. See käsk näitab tõlkimiseks valitud ala esile tõstetuna. Valikut **--all** kasutatakse kogu teksti kuvamiseks.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Seejärel lisa `--xlate` valik, et tõlkida valitud ala. Seejärel leitakse soovitud lõigud ja asendatakse need **deepl** käsu väljundiga.

Vaikimisi prinditakse originaal ja tõlgitud tekst "konfliktimarkeri" formaadis, mis on ühilduv [git(1)](http://man.he.net/man1/git)-ga. Kasutades `ifdef` formaati, saad soovitud osa hõlpsasti kätte [unifdef(1)](http://man.he.net/man1/unifdef) käsuga. Väljundvormingut saab määrata **--xlate-format** valikuga.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Kui soovid tõlkida kogu teksti, kasuta **--match-all** valikut. See on otsetee mustri `(?s).+` määramiseks, mis sobib kogu tekstiga.

Konfliktimarkeri formaadis andmeid saab vaadata kõrvuti stiilis `sdif` käsuga koos `-V` valikuga. Kuna pole mõtet võrrelda üksikute stringide kaupa, on soovitatav kasutada `--no-cdif` valikut. Kui pole vaja teksti värvida, määra `--no-textcolor` (või `--no-tc`).

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Töötlemine toimub määratud ühikutes, kuid mitmest järjestikusest mittetühjast reast koosneva jada puhul teisendatakse need koos üheks reaks. See toiming toimub järgmiselt:

- Eemalda iga rea algusest ja lõpust tühikud.
- Kui rida lõpeb täislaiuses kirjavahemärgiga, liida järgmise reaga.
- Kui rida lõpeb täislaiuses märgiga ja järgmine rida algab täislaiuses märgiga, liida read kokku.
- Kui kas rea lõpp või algus ei ole täislaiuses märk, liida need kokku, lisades tühiku.

Vahemälus olevad andmed hallatakse normaliseeritud teksti põhjal, seega kui tehakse muudatusi, mis ei mõjuta normaliseerimise tulemust, jääb vahemällu salvestatud tõlge kehtima.

See normaliseerimisprotsess tehakse ainult esimesele (0.) ja paarisarvulisele mustrile. Seega, kui on määratud kaks mustrit järgmiselt, töödeldakse esimese mustriga sobiv tekst pärast normaliseerimist ja teise mustriga sobivale tekstile normaliseerimist ei rakendata.

    greple -Mxlate -E normalized -E not-normalized

Seetõttu kasuta esimest mustrit tekstile, mida töödeldakse mitme rea ühendamisel üheks reaks, ja teist mustrit eelvormindatud tekstile. Kui esimesele mustrile ei leidu sobivat teksti, kasuta mustrit, mis ei sobi millegagi, näiteks `(?!)`.

# MASKING

Aeg-ajalt on tekstis osi, mida te ei soovi tõlkida. Näiteks märgendid markdown-failides. DeepL soovitab sellistel juhtudel tõlkimisest välja jäetav osa muuta XML-märgenditeks, tõlkida ja seejärel pärast tõlkimist taastada. Selle toetamiseks on võimalik määrata osad, mida tõlkimisel maskeeritakse.

    --xlate-setopt maskfile=MASKPATTERN

See tõlgendab faili \`MASKPATTERN\` iga rida regulaaravaldisena, tõlgib sellele vastavad stringid ja taastab need pärast töötlemist. Ridasi, mis algavad `#`-ga, ignoreeritakse.

Keerulisi mustreid saab kirjutada mitmele reale, kasutades tagasikaldkriipsuga reavahetust.

Kuidas tekst maskeerimise käigus muudetakse, saab näha **--xlate-mask** valiku abil.

See liides on eksperimentaalne ja võib tulevikus muutuda.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Käivita tõlkeprotsess iga leitud ala kohta.

    Ilma selle valikuta käitub **greple** tavalise otsingukäsuna. Nii saad enne tegelikku tööd kontrollida, milline osa failist tõlkimisele allub.

    Käsu tulemus läheb standardväljundisse, seega suuna vajadusel faili või kaalu [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) mooduli kasutamist.

    Valik **--xlate** kutsub välja **--xlate-color** valiku koos **--color=never** valikuga.

    Valikuga **--xlate-fold** murdub teisendatud tekst määratud laiuse järgi. Vaikimisi laius on 70 ja seda saab määrata **--xlate-fold-width** valikuga. Neli veergu on reserveeritud jooksva töö jaoks, seega mahub igale reale maksimaalselt 74 märki.

- **--xlate-engine**=_engine_

    Määrab kasutatava tõlkemootori. Kui määrad mootorimooduli otse, näiteks `-Mxlate::deepl`, ei pea seda valikut kasutama.

    Praegu on saadaval järgmised mootorid

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4-turbo
    - **gpt4o**: gpt-4o-mini

        **gpt-4o** liides on ebastabiilne ja selle korrektset toimimist ei saa hetkel garanteerida.

- **--xlate-labor**
- **--xlabor**

    Tõlkemootori kutsumise asemel eeldatakse, et töötad ise. Pärast tõlkimiseks vajaliku teksti ettevalmistamist kopeeritakse need lõikelauale. Eeldatakse, et kleebid need vormi, kopeerid tulemuse lõikelauale ja vajutad enter.

- **--xlate-to** (Default: `EN-US`)

    Määra sihtkeel. Saad saadaolevad keeled `deepl languages` käsuga, kui kasutad **DeepL** mootorit.

- **--xlate-format**=_format_ (Default: `conflict`)

    Määra originaal- ja tõlgitud teksti väljundvorming.

    Järgnevad vormingud peale `xtxt` eeldavad, et tõlgitav osa on ridade kogum. Tegelikult on võimalik tõlkida ainult osa reast, kuid muu kui `xtxt` vormingu määramine ei anna mõistlikku tulemust.

    - **conflict**, **cm**

        Originaal- ja teisendatud tekst trükitakse [git(1)](http://man.he.net/man1/git) konflikti markerite vormingus.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Originaalfaili saab taastada järgmise [sed(1)](http://man.he.net/man1/sed) käsuga.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Originaal- ja tõlgitud tekst väljastatakse markdown'i kohandatud konteineri stiilis.

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

        Koolonite arv on vaikimisi 7. Kui määrad koolonite jada nagu `:::::`, kasutatakse seda 7 asemel.

    - **ifdef**

        Originaal- ja teisendatud tekst trükitakse [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` vormingus.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Ainult jaapanikeelse teksti saab kätte **unifdef** käsuga:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Originaal- ja teisendatud tekst prinditakse välja ühe tühja reaga eraldatult. `space+` puhul lisatakse teisendatud teksti järel ka reavahetus.

    - **xtxt**

        Kui formaat on `xtxt` (tõlgitud tekst) või tundmatu, prinditakse ainult tõlgitud tekst.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Määra maksimaalne tekstipikkus, mida API-le korraga saata. Vaikeväärtus on seatud tasuta DeepL konto teenuse jaoks: 128K API jaoks (**--xlate**) ja 5000 lõikepuhvri liidese jaoks (**--xlate-labor**). Võid neid väärtusi muuta, kui kasutad Pro teenust.

- **--xlate-maxline**=_n_ (Default: 0)

    Määra maksimaalne ridade arv, mida API-le korraga saata.

    Sea see väärtus 1-le, kui soovid tõlkida ühe rea korraga. See valik on prioriteetsem kui `--xlate-maxlen` valik.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Vaata tõlketulemust reaalajas STDERR väljundis.

- **--xlate-stripe**

    Kasuta [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) moodulit, et näidata sobivat osa sebramustriga. See on kasulik, kui sobivad osad on järjestikku ühendatud.

    Värvipalett vahetub vastavalt terminali taustavärvile. Kui soovid seda selgesõnaliselt määrata, võid kasutada **--xlate-stripe-light** või **--xlate-stripe-dark**.

- **--xlate-mask**

    Tee maskimisfunktsioon ja kuva teisendatud tekst muutmata kujul.

- **--match-all**

    Määra kogu faili tekst sihtalaks.

# CACHE OPTIONS

**xlate** moodul saab salvestada iga faili tõlke vahemällu ja lugeda selle enne täitmist, et vältida serverilt pärimise viivitust. Vaikimisi vahemälustrateegia `auto` korral hoitakse vahemälu ainult siis, kui sihtfaili jaoks on olemas vahemälufail.

Kasuta **--xlate-cache=clear** vahemälu haldamise alustamiseks või kõigi olemasolevate vahemäluandmete puhastamiseks. Kui see valik on korra käivitatud, luuakse uus vahemälufail, kui seda veel pole, ja seda hallatakse automaatselt edasi.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Halda vahemälufaili, kui see eksisteerib.

    - `create`

        Loo tühi vahemälufail ja välju.

    - `always`, `yes`, `1`

        Halda vahemälu igal juhul, kui sihtfail on tavaline fail.

    - `clear`

        Kustuta kõigepealt vahemälu andmed.

    - `never`, `no`, `0`

        Ära kasuta kunagi vahemälufaili, isegi kui see eksisteerib.

    - `accumulate`

        Vaikimisi eemaldatakse kasutamata andmed vahemälufailist. Kui sa ei soovi neid eemaldada ja tahad alles hoida, kasuta `accumulate`.
- **--xlate-update**

    See valik sunnib vahemälufaili uuendama isegi siis, kui see pole vajalik.

# COMMAND LINE INTERFACE

Seda moodulit saab hõlpsasti käsurealt kasutada, kasutades distributsiooniga kaasas olevat `xlate` käsku. Kasutamiseks vaata `xlate` manuaalilehte.

Käsk `xlate` töötab koos Dockeriga, nii et isegi kui sul pole midagi paigaldatud, saad seda kasutada, kui Docker on saadaval. Kasuta `-D` või `-C` valikut.

Kuna on olemas erinevate dokumendistiilide makefile'id, on võimalik tõlkida ka teistesse keeltesse ilma erilise määratluseta. Kasuta `-M` valikut.

Samuti saad kombineerida Dockerit ja `make` valikut, et käivitada `make` Docker-keskkonnas.

Käivitades näiteks `xlate -C` avatakse shell, kus on ühendatud praegune töötav git-hoidla.

Loe jaapani keeles artiklit ["SEE ALSO"](#see-also) jaotises üksikasjade kohta.

# EMACS

Laadi hoidlas olev `xlate.el` fail, et kasutada `xlate` käsku Emacsi redaktoris. `xlate-region` funktsioon tõlgib määratud piirkonna. Vaikimisi keel on `EN-US` ja vajadusel saad keelt määrata, andes ette prefiksi argumendi.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Määra oma DeepL teenuse autentimisvõti.

- OPENAI\_API\_KEY

    OpenAI autentimisvõti.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Pead paigaldama käsurea tööriistad DeepL-i ja ChatGPT jaoks.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Dockeri konteineri kujutis.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL-i Pythoni teek ja CLI käsk.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Pythoni teek

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI käsurea liides

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Vaata **greple** juhendit, et saada täpsemat teavet sihtteksti mustri kohta. Kasuta **--inside**, **--outside**, **--include**, **--exclude** valikuid, et piirata sobitamise ala.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Saad kasutada `-Mupdate` moodulit, et muuta faile **greple** käsu tulemuste põhjal.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Kasuta **sdif** valikut, et kuvada konfliktimärgendite vormingut kõrvuti koos **-V** valikuga.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe** moodulit kasutatakse **--xlate-stripe** valikuga.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Greple moodul, mis tõlgib ja asendab ainult vajalikud osad DeepL API abil (jaapani keeles)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Dokumentide genereerimine 15 keeles DeepL API mooduliga (jaapani keeles)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Automaatne tõlke Dockeri keskkond DeepL API-ga (jaapani keeles)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
