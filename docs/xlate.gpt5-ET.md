# NAME

App::Greple::xlate - tõlke tugimoodul greple jaoks

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

    greple -Mxlate::gpt4 --xlate pattern target-file

    greple -Mxlate --xlate-engine gpt4 --xlate pattern target-file

# VERSION

Version 0.9913

# DESCRIPTION

**Greple** **xlate** moodul leiab soovitud tekstiplokid ja asendab need tõlgitud tekstiga. Praegu on tagaplaanil mootoritena rakendatud DeepL (`deepl.pm`) ja ChatGPT 4.1 (`gpt4.pm`) moodul.

Kui soovite tõlkida tavalisi tekstiplokke dokumendis, mis on kirjutatud Perli pod-stiilis, kasutage käsku **greple** koos `xlate::deepl` ja `perl` mooduliga järgmiselt:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

Selles käsus tähendab mustrijada `^([\w\pP].*\n)+` järjestikuseid ridu, mis algavad tähtnumbrilise ja kirjavahemärgi märgiga. See käsk näitab tõlkimiseks valitud ala esiletõstetuna. Valikut **--all** kasutatakse kogu teksti kuvamiseks.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Seejärel lisage valik `--xlate`, et tõlkida valitud ala. Seejärel leiab see soovitud jaotised ja asendab need käsu **deepl** väljundiga.

Vaikimisi prinditakse originaal ja tõlgitud tekst „konfliktimärgi” vormingus, mis on ühilduv [git(1)](http://man.he.net/man1/git)-ga. Kasutades vormingut `ifdef`, saate soovitud osa hõlpsasti kätte käsuga [unifdef(1)](http://man.he.net/man1/unifdef). Väljundvormingut saab määrata valikuga **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Kui soovite tõlkida kogu teksti, kasutage valikut **--match-all**. See on otsetee mustri `(?s).+` määramiseks, mis vastab kogu tekstile.

Konfliktimärgi vormingu andmeid saab vaadata kõrvuti stiilis käsuga [sdif](https://metacpan.org/pod/App%3A%3Asdif) koos valikuga `-V`. Kuna üksikute stringide kaupa võrdlemisel pole mõtet, on soovitatav valik `--no-cdif`. Kui te ei pea teksti värvima, määrake `--no-textcolor` (või `--no-tc`).

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Töötlemine toimub määratud ühikutes, kuid mitme järjestikuse tühjade ridadeta tekstiridade korral ühendatakse need koos üheks reaks. See toiming tehakse järgmiselt:

- Eemaldage iga rea algusest ja lõpust tühikud.
- Kui rida lõpeb täislaiuses kirjavahemärgiga, liidetakse järgmise reaga.
- Kui rida lõpeb täislaiuses märgiga ja järgmine rida algab täislaiuses märgiga, liidetakse read.
- Kui kas rea lõpp või algus ei ole täislaiuses märk, ühendage need, lisades tühiku.

Puhvriandmeid hallatakse normaliseeritud teksti alusel, seega isegi kui tehakse muudatusi, mis ei mõjuta normaliseerimise tulemust, jäävad puhverdatud tõlkeandmed kehtima.

See normaliseerimisprotsess tehakse ainult esimesele (0.) ja paarisnumbrilistele mustritele. Seega, kui on määratud kaks mustrit järgmiselt, töödeldakse esimesele mustrile vastav tekst pärast normaliseerimist ning teisele mustrile vastava teksti puhul normaliseerimist ei tehta.

    greple -Mxlate -E normalized -E not-normalized

Seetõttu kasutage esimest mustrit teksti jaoks, mida tuleb töödelda mitme rea ühendamisega üheks reaks, ja teist mustrit eelformindatud teksti jaoks. Kui esimesele mustrile ei vasta ühtegi teksti, kasutage mustrit, mis millelegi ei vasta, näiteks `(?!)`.

# MASKING

Mõnikord on tekstis osasid, mida te ei soovi tõlkida. Näiteks sildid markdown-failides. DeepL soovitab sellistel juhtudel tõlkimisest välja jäetav osa teisendada XML-siltideks, lasta see läbi tõlke ja taastada pärast tõlkimise lõppu. Selle toetamiseks on võimalik määrata osad, mis tuleb tõlkimise eest maskeerida.

    --xlate-setopt maskfile=MASKPATTERN

See tõlgendab faili \`MASKPATTERN\` iga rida regulaaravaldiseina, tõlgib sellega sobivad stringid ja taastab need pärast töötlemist. Ridu, mis algavad `#`, eiratakse.

Keerukat mustrit saab kirjutada mitmele reale, kasutades taandejärgset reavahetust tagurpidi kaldkriipsuga.

Kuidas tekst maskeerimise käigus muundatakse, on nähtav valikuga **--xlate-mask**.

See liides on eksperimentaalne ja võib tulevikus muutuda.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Käivitab tõlkeprotsessi iga vaste piirkonna jaoks.

    Ilma selle valikuta käitub **greple** nagu tavaline otsingukäsk. Nii saate enne tegeliku töö käivitamist kontrollida, milline faili osa läheb tõlkimisele.

    Käsu tulemus läheb standardsesse väljundisse, seega suunake vajadusel faili või kaaluge mooduli [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) kasutamist.

    Valik **--xlate** kutsub välja valiku **--xlate-color** koos valikuga **--color=never**.

    Valikuga **--xlate-fold** murtakse teisendatud tekst etteantud laiusele. Vaikelaius on 70 ja seda saab määrata valikuga **--xlate-fold-width**. Neli veergu on reserveeritud jooksva sisestuse jaoks, seega mahub igale reale maksimaalselt 74 märki.

- **--xlate-engine**=_engine_

    Määrab kasutatava tõlkemootori. Kui täpsustate mootori mooduli otse, näiteks `-Mxlate::deepl`, ei pea te seda valikut kasutama.

    Praegu on saadaval järgmised mootorid

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4.1
    - **gpt4o**: gpt-4o-mini

        **gpt-4o** liides on ebastabiilne ja praegu ei saa selle korrektset toimimist garanteerida.

- **--xlate-labor**
- **--xlabor**

    Tõlkemootori kutsumise asemel eeldatakse, et teete töö ise. Pärast tõlgitava teksti ettevalmistamist kopeeritakse need lõikepuhvrisse. Eeldatakse, et kleebite need vormi, kopeerite tulemuse lõikepuhvrisse ja vajutate Enter.

- **--xlate-to** (Default: `EN-US`)

    Määrake sihtkeel. Saadavalolevaid keeli saate `deepl languages` käsuga, kui kasutate mootorit **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Määrake originaal- ja tõlketeksti väljundvorming.

    Järgnevad vormingud peale `xtxt` eeldavad, et tõlgitav osa on ridade kogum. Tegelikult on võimalik tõlkida ainult osa reast, kuid muu kui `xtxt` vormingu määramine ei anna mõtestatud tulemust.

    - **conflict**, **cm**

        Algne ja teisendatud tekst prinditakse [git(1)](http://man.he.net/man1/git) konfliktimarkerite vormingus.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Algse faili saate taastada järgmise käsuga [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Algne ja tõlgitud tekst väljastatakse markdown’i kohandatud konteineri stiilis.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Ülaltoodud tekst teisendatakse HTML-is järgnevaks.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Koolonite arv on vaikimisi 7. Kui määrate koolonite jada nagu `:::::`, kasutatakse seda 7 kooloni asemel.

    - **ifdef**

        Algne ja teisendatud tekst prinditakse vormingus [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Ainult jaapanikeelse teksti saate kätte käsuga **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Algne ja teisendatud tekst prinditakse, eraldatuna ühe tühja reaga. `space+` korral väljastatakse teisendatud teksti järel ka reavahetus.

    - **xtxt**

        Kui vorming on `xtxt` (tõlgitud tekst) või tundmatu, prinditakse ainult tõlgitud tekst.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Määra maksimaalne teksti pikkus, mis korraga API-le saadetakse. Vaikeväärtus on määratud DeepL tasuta konto teenuse järgi: 128K API jaoks (**--xlate**) ja 5000 lõikepuhvri liidese jaoks (**--xlate-labor**). Kui kasutad Pro-teenust, võid neid väärtusi muuta.

- **--xlate-maxline**=_n_ (Default: 0)

    Määra maksimaalne ridade arv, mis korraga API-le saadetakse.

    Sea see väärtus 1, kui soovid tõlkida ühe rea kaupa. See valik on ülimuslik valiku `--xlate-maxlen` suhtes.

- **--xlate-prompt**=_text_

    Määra kohandatud viip, mis saadetakse tõlkemootorile. See valik on saadaval ainult ChatGPT mootorite (gpt3, gpt4, gpt4o) kasutamisel. Saad kohandada tõlke käitumist, andes mudelile konkreetsed juhised. Kui viip sisaldab `%s`, asendatakse see sihtkeele nimega.

- **--xlate-context**=_text_

    Määra täiendav kontekstiinfo, mis saadetakse tõlkemootorile. Seda valikut saab kasutada mitu korda, et edastada mitu kontekstistringi. Kontekst aitab tõlkemootoril tausta mõista ja anda täpsemaid tõlkeid.

- **--xlate-glossary**=_glossary_

    Määra sõnastiku ID, mida tõlkimisel kasutada. See valik on saadaval ainult DeepL mootori kasutamisel. Sõnastiku ID tuleb hankida oma DeepL kontolt ning see tagab kindlate terminite ühtlase tõlke.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Vaata tõlketulemust reaalajas STDERR-väljundis.

- **--xlate-stripe**

    Kasuta moodulit [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe), et näidata sobitatud osa sebramustriga. See on kasulik, kui sobitatud osad paiknevad vahetult üksteise järel.

    Värvipalett lülitub vastavalt terminali taustavärvile. Kui soovid seda selgesõnaliselt määrata, võid kasutada **--xlate-stripe-light** või **--xlate-stripe-dark**.

- **--xlate-mask**

    Tee maskimine ja kuva teisendatud tekst taastamata kujul.

- **--match-all**

    Sea kogu faili tekst sihtalaks.

- **--lineify-cm**
- **--lineify-colon**

    Vormingute `cm` ja `colon` puhul jagatakse väljund ridade kaupa ja vormindatakse vastavalt. Seetõttu ei saa oodatud tulemust, kui tõlgitakse ainult osa reast. Need filtrid parandavad väljundi, mis on rikutud rea osalise tõlkimise tõttu, viies selle normaalse reahaaval väljundi kujule.

    Praeguses teostuses, kui ühest reast tõlgitakse mitu osa, väljastatakse need sõltumatute ridadena.

# CACHE OPTIONS

Moodul **xlate** saab talletada iga faili tõlke puhverdatud teksti ja lugeda selle enne täitmist, et vältida päringute esitamise ülekulu serverile. Vaikimisi puhverdamisstrateegia `auto` korral hoitakse puhvriandmeid ainult siis, kui sihtfaili jaoks on olemas puhverfail.

Kasuta **--xlate-cache=clear**, et algatada puhvri haldus või puhastada kogu olemasolev puhvriandmestik. Kui see valik on korra käivitatud, luuakse uus puhverfail, kui seda ei ole, ja seda hallatakse edaspidi automaatselt.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Säilita puhverfail, kui see eksisteerib.

    - `create`

        Loo tühi puhverfail ja välju.

    - `always`, `yes`, `1`

        Säilita vahemälu igal juhul, kui siht on tavaline fail.

    - `clear`

        Tühjenda esmalt vahemälu andmed.

    - `never`, `no`, `0`

        Ära kasuta vahemälufaili isegi siis, kui see olemas on.

    - `accumulate`

        Vaikimisi eemaldatakse kasutamata andmed vahemälufailist. Kui sa ei soovi neid eemaldada ja tahad faili alles jätta, kasuta `accumulate`.
- **--xlate-update**

    See valik sunnib vahemälufaili uuendama isegi siis, kui see pole vajalik.

# COMMAND LINE INTERFACE

Seda moodulit saab hõlpsasti kasutada käsurealt, kasutades levitusega kaasas olevat käsku `xlate`. Vaata kasutusjuhiseid man-lehelt `xlate`.

Käsk `xlate` töötab kooskõlas Dockeri keskkonnaga, seega isegi kui sul pole midagi lokaalselt paigaldatud, saad seda kasutada seni, kuni Docker on saadaval. Kasuta valikut `-D` või `-C`.

Samuti, kuna on pakutud mitmesuguste dokumendistiilide makefile’e, on tõlkimine teistesse keeltesse võimalik ilma erisäteteta. Kasuta valikut `-M`.

Võid kombineerida ka Docker ja `make` valikud, et käitada `make` Dockeri keskkonnas.

Käivitamine kujul `xlate -C` avab shelli, kus jooksev töökoopia git-repositoorium on ühendatud.

Loe üksikasju jaapani artiklist jaotisest ["SEE ALSO"](#see-also).

# EMACS

Laadi repositooriumis olev `xlate.el` fail, et kasutada Emacsis käsku `xlate`. Funktsioon `xlate-region` tõlgib etteantud piirkonna. Vaikimisi keel on `EN-US` ning keelt saab määrata seda prefiksargumendiga kutsudes.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Sea oma DeepL teenuse autentimisvõti.

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

[App::Greple::xlate::gpt4](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt4)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Dockeri konteineripilt.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python’i teek ja CLI käsk.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python’i teek

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI käsurea liides

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Vaata sihtteksti mustri üksikasju käsiraamatust **greple**. Kasuta valikuid **--inside**, **--outside**, **--include**, **--exclude** vastendusala piiramiseks.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Saad kasutada moodulit `-Mupdate`, et muuta faile käsu **greple** tulemuste põhjal.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Kasuta **sdif**, et näidata konfliktimärgendite formaati kõrvuti valikuga **-V**.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe** moodulit kasutatakse valikuga **--xlate-stripe**.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Greple moodul vajalike osade tõlkimiseks ja asendamiseks ainult DeepL API-ga (jaapani keeles)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Dokumentide genereerimine 15 keeles DeepL API mooduliga (jaapani keeles)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Automaatse tõlke Docker-keskkond DeepL API-ga (jaapani keeles)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
