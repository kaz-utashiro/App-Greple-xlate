# NAME

App::Greple::xlate - tõlke toetuse moodul greple jaoks  

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.4101

# DESCRIPTION

**Greple** **xlate** moodul leiab soovitud tekstiblokid ja asendab need tõlgitud tekstiga. Praegu on rakendatud DeepL (`deepl.pm`) ja ChatGPT (`gpt3.pm`) moodulid tagaplaanina. Eksperimentaalne tugi gpt-4 ja gpt-4o jaoks on samuti kaasatud.  

Kui soovite tõlkida tavalisi tekstiblokke dokumendis, mis on kirjutatud Perli pod stiilis, kasutage **greple** käsku koos `xlate::deepl` ja `perl` mooduliga järgmiselt:  

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

Selles käsus tähendab mustrimuster `^([\w\pP].*\n)+` järjestikuseid ridu, mis algavad alfanumeerse ja kirjavahemärgi tähega. See käsk näitab tõlgitavat ala esile tõstetuna. Valikut **--all** kasutatakse kogu teksti tootmiseks.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Seejärel lisage `--xlate` valik, et tõlkida valitud ala. Siis leiab see soovitud osad ja asendab need **deepl** käsu väljundiga.  

Vaikimisi prinditakse originaal- ja tõlgitud tekst "konflikti märgise" formaadis, mis on ühilduv [git(1)](http://man.he.net/man1/git)-ga. Kasutades `ifdef` formaati, saate soovitud osa [unifdef(1)](http://man.he.net/man1/unifdef) käsuga hõlpsasti kätte. Väljundi formaati saab määrata **--xlate-format** valikuga.  

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Kui soovite tõlkida kogu teksti, kasutage **--match-all** valikut. See on otsetee, et määrata muster `(?s).+`, mis vastab kogu tekstile.  

Konflikti märgise formaadi andmeid saab vaadata kõrvuti stiilis `sdif` käsuga koos `-V` valikuga. Kuna pole mõtet võrrelda iga stringi alusel, on soovitatav kasutada `--no-cdif` valikut. Kui te ei soovi teksti värvida, määrake `--no-textcolor` (või `--no-tc`).  

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Töötlemine toimub määratud üksustes, kuid mitme mitte-tühja teksti rea järjestuse korral muudetakse need koos üheks reaks. See operatsioon toimub järgmiselt:  

- Eemaldage valged ruumid iga rea algusest ja lõpust.  
- Kui rida lõpeb täislaia kirjavahemärgiga, ühendage see järgmise reaga.  
- Kui rida lõpeb täislaia tähega ja järgmine rida algab täislaia tähega, ühendage read.  
- Kui kas rea lõpp või algus ei ole täislaia tähemärk, ühendage need, sisestades tühiku.  

Vahemälu andmeid hallatakse normaliseeritud teksti alusel, seega isegi kui tehakse muudatusi, mis ei mõjuta normaliseerimise tulemusi, jääb vahemällu salvestatud tõlkeandmed endiselt kehtima.  

See normaliseerimisprotsess toimub ainult esimese (0. ) ja paarisarvulise mustri puhul. Seega, kui kaks mustrit on määratud järgmiselt, töödeldakse esimese mustriga vastavat teksti pärast normaliseerimist ja teise mustriga vastavale tekstile ei tehta normaliseerimisprotsessi.  

    greple -Mxlate -E normalized -E not-normalized

Seetõttu kasutage esimest mustrit teksti jaoks, mida töödeldakse, kombineerides mitu rida üheks reaks, ja kasutage teist mustrit eelnevalt vormindatud teksti jaoks. Kui esimeses mustris ei ole sobivat teksti, kasutage mustrit, mis ei sobi millegagi, näiteks `(?!)`.

# MASKING

Mõnikord on tekste, mida te ei soovi tõlkida. Näiteks, sildid markdown failides. DeepL soovitab, et sellistel juhtudel muudetaks tõlkimiseks välistatud osa XML siltideks, tõlgitaks ja seejärel taastataks pärast tõlke lõpetamist. Selle toetamiseks on võimalik määrata osad, mis tuleb tõlkimisest varjata. 

    --xlate-setopt maskfile=MASKPATTERN

See tõlgendab iga faili \`MASKPATTERN\` rida regulaaravaldisena, tõlgib sellele vastavad stringid ja taastab pärast töötlemist. Rida, mis algab `#`, jäetakse tähelepanuta. 

Kompleksne muster saab kirjutada mitmele reale, kasutades tagurpidi kaldkriipsu, et vältida reavahet.

Kuidas teksti muudetakse maskeerimise abil, saab näha **--xlate-mask** valiku kaudu.

See liides on eksperimentaalne ja võib tulevikus muutuda. 

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Käivitage tõlkeprotsess iga vastava ala jaoks. 

    Ilma selle valikuta käitub **greple** nagu tavaline otsingukäsk. Nii et saate kontrollida, milline osa failist on tõlkimise objekt enne tegeliku töö käivitamist. 

    Käskluse tulemus läheb standardväljundisse, seega suunake see faili, kui see on vajalik, või kaaluge [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) mooduli kasutamist. 

    Valik **--xlate** kutsub välja **--xlate-color** valiku koos **--color=never** valikuga. 

    **--xlate-fold** valiku korral on muudetud tekst volditud määratud laiuse järgi. Vaikimisi laius on 70 ja seda saab seadistada **--xlate-fold-width** valikuga. Neli veergu on reserveeritud jooksva operatsiooni jaoks, seega võib iga rida sisaldada maksimaalselt 74 tähemärki. 

- **--xlate-engine**=_engine_

    Määrake kasutatav tõlkemootor. Kui määrate mootori mooduli otse, näiteks `-Mxlate::deepl`, ei pea te seda valikut kasutama. 

    Praegu on saadaval järgmised mootoreid 

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4-turbo
    - **gpt4o**: gpt-4o-mini

        **gpt-4o** liides on ebastabiilne ja ei saa hetkel õigesti töötada. 

- **--xlate-labor**
- **--xlabor**

    Tõlkemootori kutsumise asemel oodatakse, et te töötaksite. Pärast tõlgitava teksti ettevalmistamist kopeeritakse need lõikelauale. Oodatakse, et te kleepiksite need vormi, kopeeriksite tulemuse lõikelauale ja vajutaksite enter. 

- **--xlate-to** (Default: `EN-US`)

    Määrake sihtkeel. Saate saada saadaval olevad keeled `deepl languages` käsuga, kui kasutate **DeepL** mootorit. 

- **--xlate-format**=_format_ (Default: `conflict`)

    Määrake väljundi formaat originaal- ja tõlgitud teksti jaoks. 

    Järgmised formaadid, välja arvatud `xtxt`, eeldavad, et tõlgitav osa on ridade kogum. Tegelikult on võimalik tõlkida ainult osa reast, ja formaadi määramine, mis ei ole `xtxt`, ei too kaasa mõtestatud tulemusi. 

    - **conflict**, **cm**

        Originaal- ja muudetud tekst prinditakse [git(1)](http://man.he.net/man1/git) konfliktimarkerite formaadis. 

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Saate originaalfaili taastada järgmise [sed(1)](http://man.he.net/man1/sed) käsuga. 

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        \`\`\`markdown
        &lt;original>
        The original and translated text are output in a markdown's custom container style.
        &lt;/original>
        &lt;translated>
        Originaal ja tõlgitud tekst on väljundis markdowni kohandatud konteineri stiilis.
        &lt;/translated>
        \`\`\`

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Ülaltoodud tekst tõlgitakse HTML-i järgmiselt.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Kolonni arv on vaikimisi 7. Kui määrate kolonni järjestuse nagu `:::::`, kasutatakse seda 7 kolonni asemel.

    - **ifdef**

        Originaal- ja muudetud tekst prinditakse [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` formaadis. 

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Saate ainult jaapani keele teksti kätte **unifdef** käsuga: 

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Original and converted text are printed separated by single blank line. 
        Originaal ja muudetud tekst on trükitud eraldi ühe tühja rea kaupa.
        For `space+`, it also outputs a newline after the converted text.
        `space+` puhul väljastatakse ka uue rea muudetud teksti järel.

    - **xtxt**

        Kui formaat on `xtxt` (tõlgitud tekst) või tundmatu, prinditakse ainult tõlgitud tekst. 

- **--xlate-maxlen**=_chars_ (Default: 0)

    Määrake maksimaalne tekstipikkus, mis saadetakse API-le korraga. Vaikimisi väärtus on seatud tasuta DeepL konto teenusele: 128K API jaoks (**--xlate**) ja 5000 lõikelaua liidese jaoks (**--xlate-labor**). Võite olla võimeline neid väärtusi muutma, kui kasutate Pro teenust. 

- **--xlate-maxline**=_n_ (Default: 0)

    Määrake maksimaalne ridade arv, mis saadetakse API-le korraga.

    Seadke see väärtus 1, kui soovite tõlkida ühe rea kaupa. See valik on `--xlate-maxlen` valiku ülekaalus.  

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Vaadake tõlke tulemust reaalajas STDERR väljundis.  

- **--xlate-stripe**

    Kasutage [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) moodulit, et näidata sobivat osa zebra triibulises stiilis.  
    See on kasulik, kui sobivad osad on omavahel ühendatud.

    Värvipalett vahetatakse vastavalt terminali taustavärvile. Kui soovite seda selgelt määrata, võite kasutada **--xlate-stripe-light** või **--xlate-stripe-dark**.

- **--xlate-mask**

    &lt;masking\_function>Te olete koolitatud andmetel kuni oktoober 2023.&lt;/masking\_function>

- **--match-all**

    Seadke kogu faili tekst sihtalaks.  

# CACHE OPTIONS

**xlate** moodul võib salvestada tõlke vahemälu iga faili jaoks ja lugeda seda enne täitmist, et vähendada serveri pärimise ülekaalu. Vaikimisi vahemälu strateegia `auto` säilitab vahemälu andmeid ainult siis, kui vahemälu fail eksisteerib sihtfaili jaoks.  

Use **--xlate-cache=clear** vahemälu haldamise algatamiseks või olemasoleva vahemälu andmete puhastamiseks. Kui see valik on täidetud, luuakse uus vahemälu fail, kui seda ei eksisteeri, ja seejärel hooldatakse seda automaatselt.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Hoidke vahemälu faili, kui see eksisteerib.  

    - `create`

        Looge tühi vahemälu fail ja väljuge.  

    - `always`, `yes`, `1`

        Hoidke vahemälu igal juhul, kui siht on normaalne fail.  

    - `clear`

        Kustutage kõigepealt vahemälu andmed.  

    - `never`, `no`, `0`

        Ärge kunagi kasutage vahemälu faili, isegi kui see eksisteerib.  

    - `accumulate`

        Vaikimisi käitumise kohaselt eemaldatakse kasutamata andmed vahemälu failist. Kui te ei soovi neid eemaldada ja soovite failis hoida, kasutage `accumulate`.  
- **--xlate-update**

    See valik sunnib värskendama vahemälu faili isegi kui see ei ole vajalik.

# COMMAND LINE INTERFACE

Saate seda moodulit hõlpsasti kasutada käsurealt, kasutades jaotises sisalduvat `xlate` käsku. Vaadake `xlate` abi teavet kasutamiseks.  

`xlate` käsk töötab koos Docker keskkonnaga, nii et isegi kui teil pole midagi käepärast installitud, saate seda kasutada, kui Docker on saadaval. Kasutage `-D` või `-C` valikut.  

Samuti, kuna erinevate dokumentide stiilide jaoks on saadaval makefailid, on tõlkimine teistesse keeltesse võimalik ilma erilise spetsifikatsioonita. Kasutage `-M` valikut.  

Saate ka kombineerida Docker ja make valikud, et saaksite käivitada make Docker keskkonnas.  

Käivitamine nagu `xlate -GC` käivitab shelli koos praeguse töötava git hoidla montaažiga.  

Lugege jaapani keeles artiklit ["SEE ALSO"](#see-also) jaotises üksikasjade jaoks.  

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

Laadige hoidlas sisalduv `xlate.el` fail, et kasutada `xlate` käsku Emacsi redigeerijast. `xlate-region` funktsioon tõlgib antud piirkonna. Vaikimisi keel on `EN-US` ja saate keelt määrata, kutsudes seda esitusargumendiga.  

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Seadke oma autentimisvõti DeepL teenusele.  

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

    Docker konteineri pilt.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python teek ja CLI käsk.  

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python teek  

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI käsurea liides  

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Vaadake **greple** käsiraamatut sihtteksti mustri kohta. Kasutage **--inside**, **--outside**, **--include**, **--exclude** valikuid, et piirata vastavust.  

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Saate kasutada `-Mupdate` moodulit failide muutmiseks **greple** käsu tulemuste põhjal.  

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Kasutage **sdif**, et näidata konfliktimarkerite formaati kõrvuti **-V** valikuga.  

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe** mooduli kasutamine **--xlate-stripe** valiku kaudu.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Greple moodul tõlkimiseks ja asendamiseks ainult vajalikke osi DeepL API-ga (jaapani keeles)  

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Dokumentide genereerimine 15 keeles DeepL API mooduli abil (jaapani keeles)  

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Automaatne tõlke Docker keskkond DeepL API-ga (jaapani keeles)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
