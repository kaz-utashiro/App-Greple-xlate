# NAME

App::Greple::xlate - vertaalondersteuningsmodule voor greple

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

    greple -Mxlate::gpt4 --xlate pattern target-file

    greple -Mxlate::gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

# VERSION

Version 0.9916

# DESCRIPTION

**Greple** **xlate** module vindt de gewenste tekstblokken en vervangt deze door de vertaalde tekst. Momenteel zijn DeepL (`deepl.pm`), ChatGPT 4.1 (`gpt4.pm`) en GPT-5 (`gpt5.pm`) modules geïmplementeerd als back-end engine.

Als je normale tekstblokken in een document geschreven in de Perl's pod-stijl wilt vertalen, gebruik dan het **greple** commando met `xlate::deepl` en `perl` module zoals dit:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

In dit commando betekent de patroonstring `^([\w\pP].*\n)+` opeenvolgende regels die beginnen met een alfanumeriek teken of leesteken. Dit commando toont het te vertalen gebied gemarkeerd. Optie **--all** wordt gebruikt om de volledige tekst te produceren.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Voeg vervolgens de `--xlate` optie toe om het geselecteerde gebied te vertalen. Dan worden de gewenste secties gevonden en vervangen door de uitvoer van het **deepl** commando.

Standaard worden originele en vertaalde tekst afgedrukt in het "conflict marker" formaat dat compatibel is met [git(1)](http://man.he.net/man1/git). Met het `ifdef` formaat kun je het gewenste deel eenvoudig verkrijgen met het [unifdef(1)](http://man.he.net/man1/unifdef) commando. Het uitvoerformaat kan worden gespecificeerd met de **--xlate-format** optie.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Als je de volledige tekst wilt vertalen, gebruik dan de **--match-all** optie. Dit is een snelkoppeling om het patroon `(?s).+` te specificeren dat overeenkomt met de volledige tekst.

Conflictmarkeringformaatgegevens kunnen in zij-aan-zij stijl worden bekeken met het [sdif](https://metacpan.org/pod/App%3A%3Asdif) commando met de `-V` optie. Aangezien het geen zin heeft om per tekenreeks te vergelijken, wordt de `--no-cdif` optie aanbevolen. Als u de tekst niet hoeft te kleuren, geef dan `--no-textcolor` (of `--no-tc`) op.

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

De verwerking gebeurt in opgegeven eenheden, maar in het geval van een reeks van meerdere regels niet-lege tekst, worden deze samen omgezet in één regel. Deze bewerking wordt als volgt uitgevoerd:

- Verwijder witruimte aan het begin en einde van elke regel.
- Als een regel eindigt met een volbreedte leesteken, voeg samen met de volgende regel.
- Als een regel eindigt met een volbreedte teken en de volgende regel begint met een volbreedte teken, voeg de regels samen.
- Als het einde of het begin van een regel geen volbreedte teken is, voeg ze dan samen door een spatie toe te voegen.

Cachegegevens worden beheerd op basis van de genormaliseerde tekst, dus zelfs als er wijzigingen worden aangebracht die geen invloed hebben op het normalisatieresultaat, blijft de vertaalde cachegegevens effectief.

Dit normalisatieproces wordt alleen uitgevoerd voor het eerste (0e) en even genummerde patroon. Dus als twee patronen als volgt worden opgegeven, wordt de tekst die overeenkomt met het eerste patroon verwerkt na normalisatie, en wordt er geen normalisatie uitgevoerd op de tekst die overeenkomt met het tweede patroon.

    greple -Mxlate -E normalized -E not-normalized

Gebruik daarom het eerste patroon voor tekst die moet worden verwerkt door meerdere regels samen te voegen tot één regel, en gebruik het tweede patroon voor vooraf opgemaakte tekst. Als er geen tekst is die overeenkomt met het eerste patroon, gebruik dan een patroon dat nergens mee overeenkomt, zoals `(?!)`.

# MASKING

Af en toe zijn er delen van tekst die je niet wilt vertalen. Bijvoorbeeld, tags in markdown-bestanden. DeepL stelt voor om in zulke gevallen het te vertalen deel om te zetten naar XML-tags, te vertalen, en daarna na de vertaling te herstellen. Om dit te ondersteunen, is het mogelijk om de delen die van vertaling uitgesloten moeten worden, te specificeren.

    --xlate-setopt maskfile=MASKPATTERN

Dit zal elke regel van het bestand \`MASKPATTERN\` interpreteren als een reguliere expressie, strings die hiermee overeenkomen vertalen, en na verwerking terugzetten. Regels die beginnen met `#` worden genegeerd.

Complexe patronen kunnen over meerdere regels worden geschreven met een backslash-escaped nieuwe regel.

Hoe de tekst wordt getransformeerd door maskering kan worden bekeken met de **--xlate-mask** optie.

Deze interface is experimenteel en kan in de toekomst veranderen.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Start het vertaalproces voor elk overeenkomend gebied.

    Zonder deze optie gedraagt **greple** zich als een normale zoekopdracht. Zo kun je controleren welk deel van het bestand onderwerp van vertaling zal zijn voordat je het daadwerkelijke werk uitvoert.

    Het resultaat van het commando gaat naar standaarduitvoer, dus omleiden naar een bestand indien nodig, of overweeg het gebruik van de [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) module.

    Optie **--xlate** roept de **--xlate-color** optie aan met de **--color=never** optie.

    Met de **--xlate-fold** optie wordt de geconverteerde tekst opgevouwen tot de opgegeven breedte. De standaardbreedte is 70 en kan worden ingesteld met de **--xlate-fold-width** optie. Vier kolommen zijn gereserveerd voor run-in-operatie, dus elke regel kan maximaal 74 tekens bevatten.

- **--xlate-engine**=_engine_

    Specificeert de te gebruiken vertaalmachine. Als je het engine-module direct specificeert, zoals `-Mxlate::deepl`, hoef je deze optie niet te gebruiken.

    Op dit moment zijn de volgende engines beschikbaar

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4.1
    - **gpt4o**: gpt-4o-mini

        **gpt-4o**'s interface is instabiel en kan momenteel niet gegarandeerd correct werken.

    - **gpt5**: gpt-5

- **--xlate-labor**
- **--xlabor**

    In plaats van de vertaalmachine aan te roepen, wordt van je verwacht dat je het werk uitvoert. Nadat de te vertalen tekst is voorbereid, worden ze naar het klembord gekopieerd. Je wordt geacht ze in het formulier te plakken, het resultaat naar het klembord te kopiëren en op enter te drukken.

- **--xlate-to** (Default: `EN-US`)

    Specificeer de doeltaal. Je kunt beschikbare talen opvragen met het `deepl languages` commando wanneer je de **DeepL** engine gebruikt.

- **--xlate-format**=_format_ (Default: `conflict`)

    Specificeer het uitvoerformaat voor originele en vertaalde tekst.

    De volgende formaten anders dan `xtxt` gaan ervan uit dat het te vertalen deel een verzameling regels is. In feite is het mogelijk om slechts een deel van een regel te vertalen, maar het specificeren van een ander formaat dan `xtxt` zal geen zinvolle resultaten opleveren.

    - **conflict**, **cm**

        Originele en geconverteerde tekst worden afgedrukt in [git(1)](http://man.he.net/man1/git) conflictmarkeringsformaat.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Je kunt het originele bestand herstellen met het volgende [sed(1)](http://man.he.net/man1/sed) commando.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        De originele en vertaalde tekst worden weergegeven in een aangepaste containerstijl van markdown.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Bovenstaande tekst wordt als volgt vertaald naar HTML.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Het aantal dubbele punten is standaard 7. Als je een dubbelepuntreeks opgeeft zoals `:::::`, wordt deze gebruikt in plaats van 7 dubbele punten.

    - **ifdef**

        Originele en geconverteerde tekst worden afgedrukt in [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` formaat.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Je kunt alleen Japanse tekst ophalen met het **unifdef** commando:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Originele en geconverteerde tekst worden afgedrukt, gescheiden door een enkele lege regel.

    - **xtxt**

        Voor `space+` wordt er ook een nieuwe regel na de geconverteerde tekst toegevoegd.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Als het formaat `xtxt` (vertaalde tekst) of onbekend is, wordt alleen de vertaalde tekst afgedrukt.

- **--xlate-maxline**=_n_ (Default: 0)

    Specificeer de maximale lengte van de tekst die in één keer naar de API mag worden gestuurd. De standaardwaarde is ingesteld zoals voor de gratis DeepL-accountservice: 128K voor de API (**--xlate**) en 5000 voor de klembordinterface (**--xlate-labor**). Mogelijk kunt u deze waarde wijzigen als u de Pro-service gebruikt.

    Specificeer het maximaal aantal regels tekst dat in één keer naar de API mag worden gestuurd.

- **--xlate-prompt**=_text_

    Geef een aangepaste prompt op die naar de vertaalmachine wordt gestuurd. Deze optie is alleen beschikbaar bij gebruik van ChatGPT-engines (gpt3, gpt4, gpt4o). Je kunt het vertaalgedrag aanpassen door specifieke instructies aan het AI-model te geven. Als de prompt `%s` bevat, wordt deze vervangen door de naam van de doeltaal.

- **--xlate-context**=_text_

    Geef extra contextinformatie op die naar de vertaalmachine wordt gestuurd. Deze optie kan meerdere keren worden gebruikt om meerdere contextstrings te leveren. De contextinformatie helpt de vertaalmachine de achtergrond te begrijpen en nauwkeurigere vertalingen te produceren.

- **--xlate-glossary**=_glossary_

    Geef een woordenlijst-ID op die voor de vertaling wordt gebruikt. Deze optie is alleen beschikbaar bij gebruik van de DeepL-engine. De woordenlijst-ID moet uit je DeepL-account worden verkregen en zorgt voor consistente vertaling van specifieke termen.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Stel deze waarde in op 1 als u één regel tegelijk wilt vertalen. Deze optie heeft voorrang op de `--xlate-maxlen`-optie.

- **--xlate-stripe**

    Bekijk het vertaalresultaat in realtime in de STDERR-uitvoer.

    Gebruik de [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)-module om het overeenkomende gedeelte in zebra-streepjesstijl weer te geven. Dit is handig wanneer de overeenkomende delen direct aan elkaar zijn gekoppeld.

- **--xlate-mask**

    Het kleurenpalet wordt aangepast aan de achtergrondkleur van de terminal. Als u dit expliciet wilt opgeven, kunt u **--xlate-stripe-light** of **--xlate-stripe-dark** gebruiken.

- **--match-all**

    Voer de maskeringsfunctie uit en toon de geconverteerde tekst zoals deze is, zonder herstel.

- **--lineify-cm**
- **--lineify-colon**

    In het geval van de `cm`- en `colon`-formaten wordt de uitvoer regel voor regel gesplitst en opgemaakt. Daarom kan het verwachte resultaat niet worden verkregen als slechts een deel van een regel wordt vertaald. Deze filters herstellen uitvoer die is beschadigd door een deel van een regel te vertalen naar normale regel-voor-regel uitvoer.

    In de huidige implementatie worden meerdere vertaalde delen van een regel als onafhankelijke regels weergegeven.

# CACHE OPTIONS

Stel de volledige tekst van het bestand in als doelgebied.

De **xlate**-module kan gecachte vertaalde tekst per bestand opslaan en deze vóór uitvoering lezen om de overhead van het opvragen bij de server te elimineren. Met de standaard cache-strategie `auto` wordt cachedata alleen onderhouden als het cachebestand voor het doelbestand bestaat.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Gebruik **--xlate-cache=clear** om cachebeheer te starten of om alle bestaande cachedata op te schonen. Na uitvoering met deze optie wordt een nieuw cachebestand aangemaakt als er nog geen bestaat en daarna automatisch onderhouden.

    - `create`

        Onderhoud het cachebestand als het bestaat.

    - `always`, `yes`, `1`

        Maak een leeg cachebestand aan en sluit af.

    - `clear`

        Onderhoud de cache in ieder geval zolang het doel een normaal bestand is.

    - `never`, `no`, `0`

        Wis eerst de cachedata.

    - `accumulate`

        Gebruik nooit een cachebestand, zelfs niet als het bestaat.
- **--xlate-update**

    Standaard wordt ongebruikte data uit het cachebestand verwijderd. Als u deze niet wilt verwijderen en in het bestand wilt houden, gebruik dan `accumulate`.

# COMMAND LINE INTERFACE

Met deze optie wordt het cachebestand geforceerd bijgewerkt, zelfs als dit niet nodig is.

Het `xlate` commando ondersteunt GNU-stijl lange opties zoals `--to-lang`, `--from-lang`, `--engine` en `--file`. Gebruik `xlate -h` om alle beschikbare opties te zien.

U kunt deze module eenvoudig vanaf de opdrachtregel gebruiken met het `xlate`-commando dat bij de distributie is inbegrepen. Zie de `xlate`-manpagina voor gebruik.

Docker-bewerkingen worden afgehandeld door het `xrun` script, dat ook als een zelfstandige opdracht kan worden gebruikt. Het `xrun` script ondersteunt het `.xrunrc` configuratiebestand voor persistente containerinstellingen.

Het `xlate`-commando werkt samen met de Docker-omgeving, dus zelfs als u niets hebt geïnstalleerd, kunt u het gebruiken zolang Docker beschikbaar is. Gebruik de `-D`- of `-C`-optie.

Omdat er ook makefiles voor verschillende documentstijlen worden meegeleverd, is vertaling naar andere talen mogelijk zonder speciale specificatie. Gebruik de `-M`-optie.

U kunt ook de Docker- en `make`-opties combineren, zodat u `make` in een Docker-omgeving kunt uitvoeren.

Uitvoeren zoals `xlate -C` start een shell met de huidige werkende git-repository aangekoppeld.

# EMACS

Laad het `xlate.el` bestand dat in de repository is opgenomen om het `xlate` commando vanuit de Emacs-editor te gebruiken. `xlate-region` functie vertaalt het opgegeven gebied. De standaardtaal is `EN-US` en je kunt de taal specificeren door het met een prefix-argument aan te roepen.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Stel je authenticatiesleutel voor de DeepL-service in.

- OPENAI\_API\_KEY

    OpenAI authenticatiesleutel.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Je moet de commandoregeltools voor DeepL en ChatGPT installeren.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt4](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt4)

[App::Greple::xlate::gpt5](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt5)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Docker container image.

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    De `getoptlong.sh` bibliotheek wordt gebruikt voor optieparsing in de `xlate` en `xrun` scripts.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python-bibliotheek en CLI-commando.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python-bibliotheek

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI commandoregelinterface

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Zie de **greple** handleiding voor details over het doeltekstpatroon. Gebruik de opties **--inside**, **--outside**, **--include**, **--exclude** om het zoekgebied te beperken.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Je kunt de `-Mupdate` module gebruiken om bestanden aan te passen op basis van het resultaat van het **greple** commando.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Gebruik **sdif** om het conflictmarkeringsformaat naast elkaar te tonen met de **-V** optie.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe** module wordt gebruikt met de **--xlate-stripe** optie.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Greple-module om alleen de noodzakelijke delen te vertalen en te vervangen met de DeepL API (in het Japans)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Documenten genereren in 15 talen met de DeepL API-module (in het Japans)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Automatische vertaal-Dockeromgeving met DeepL API (in het Japans)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
