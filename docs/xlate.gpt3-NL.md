# NAME

App::Greple::xlate - vertaalondersteuningsmodule voor greple

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.9905

# DESCRIPTION

Het **Greple** **xlate** module vindt gewenste tekstblokken en vervangt ze door de vertaalde tekst. Momenteel zijn de DeepL (`deepl.pm`) en ChatGPT (`gpt3.pm`) modules geïmplementeerd als back-end engine. Experimentele ondersteuning voor gpt-4 en gpt-4o is ook inbegrepen.

Als je normale tekstblokken wilt vertalen in een document dat is geschreven in de Perl's pod-stijl, gebruik dan het **greple** commando met de `xlate::deepl` en `perl` module als volgt:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

In deze opdracht betekent het patroonreeks `^([\w\pP].*\n)+` opeenvolgende regels die beginnen met een alfanumeriek en leesteken. Deze opdracht toont het gebied dat vertaald moet worden gemarkeerd. Optie **--all** wordt gebruikt om de volledige tekst te produceren.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Voeg vervolgens de optie `--xlate` toe om het geselecteerde gebied te vertalen. Het zal dan de gewenste secties vinden en ze vervangen door de uitvoer van het **deepl** commando.

Standaard worden het oorspronkelijke en vertaalde tekst afgedrukt in het formaat van de "conflict marker" dat compatibel is met [git(1)](http://man.he.net/man1/git). Met behulp van het `ifdef` formaat kun je het gewenste deel krijgen met het [unifdef(1)](http://man.he.net/man1/unifdef) commando. De uitvoerindeling kan worden gespecificeerd met de **--xlate-format** optie.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Als je de hele tekst wilt vertalen, gebruik dan de **--match-all** optie. Dit is een snelkoppeling om het patroon `(?s).+` te specificeren dat de hele tekst matcht.

Conflict marker formaatgegevens kunnen worden bekeken in een zij-aan-zij stijl met het `sdif` commando met de `-V` optie. Aangezien het geen zin heeft om op basis van elke string te vergelijken, wordt de `--no-cdif` optie aanbevolen. Als je de tekst niet hoeft te kleuren, geef dan `--no-textcolor` (of `--no-tc`) op.

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Verwerking gebeurt in opgegeven eenheden, maar in het geval van een reeks van meerdere regels met niet-lege tekst, worden ze samen omgezet in één regel. Deze bewerking wordt als volgt uitgevoerd:

- Verwijder witruimte aan het begin en einde van elke regel.
- Als een regel eindigt met een leesteken in volledige breedte, voeg dan samen met de volgende regel.
- Als een regel eindigt met een volledig breedte karakter en de volgende regel begint met een volledig breedte karakter, voeg dan de regels samen.
- Als het einde of het begin van een regel geen volledig breedte karakter is, voeg ze dan samen door een spatiekarakter in te voegen.

Cachegegevens worden beheerd op basis van de genormaliseerde tekst, dus zelfs als er wijzigingen worden aangebracht die de normalisatieresultaten niet beïnvloeden, blijven de gecachte vertaalgegevens effectief.

Dit normalisatieproces wordt alleen uitgevoerd voor het eerste (0e) en even genummerde patroon. Als er dus twee patronen worden gespecificeerd zoals volgt, zal de tekst die overeenkomt met het eerste patroon worden verwerkt na normalisatie, en er zal geen normalisatieproces worden uitgevoerd op de tekst die overeenkomt met het tweede patroon.

    greple -Mxlate -E normalized -E not-normalized

Gebruik daarom het eerste patroon voor tekst die moet worden verwerkt door meerdere regels tot één regel te combineren, en gebruik het tweede patroon voor vooraf opgemaakte tekst. Als er geen tekst is om overeen te komen met het eerste patroon, gebruik dan een patroon dat niets overeenkomt, zoals `(?!)`.

# MASKING

Af en toe zijn er delen van tekst die je niet vertaald wilt hebben. Bijvoorbeeld tags in markdown-bestanden. DeepL suggereert dat in dergelijke gevallen het te negeren deel van de tekst wordt omgezet naar XML-tags, vertaald en vervolgens wordt hersteld nadat de vertaling is voltooid. Om dit te ondersteunen, is het mogelijk om de delen die niet vertaald moeten worden te specificeren.

    --xlate-setopt maskfile=MASKPATTERN

Dit zal elke regel van het bestand \`MASKPATTERN\` interpreteren als een reguliere expressie, strings die eraan voldoen vertalen en na verwerking terugdraaien. Regels die beginnen met `#` worden genegeerd.

Complex patroon kan worden geschreven op meerdere regels met een backslash geëscapete nieuwe regel.

Hoe de tekst wordt getransformeerd door maskering kan worden gezien via de **--xlate-mask** optie.

Deze interface is experimenteel en kan in de toekomst worden gewijzigd.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Roep het vertaalproces aan voor elk overeenkomend gebied.

    Zonder deze optie gedraagt **greple** zich als een normaal zoekcommando. U kunt dus controleren welk deel van het bestand onderwerp zal zijn van de vertaling voordat u daadwerkelijk aan het werk gaat.

    Het resultaat van het commando wordt naar standaarduitvoer gestuurd, dus leid het om naar een bestand indien nodig, of overweeg het gebruik van de [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) module.

    Optie **--xlate** roept de optie **--xlate-color** aan met de optie **--color=never**.

    Met de optie **--xlate-fold** wordt de geconverteerde tekst gevouwen volgens de opgegeven breedte. De standaardbreedte is 70 en kan worden ingesteld met de optie **--xlate-fold-width**. Vier kolommen zijn gereserveerd voor de run-in bewerking, zodat elke regel maximaal 74 tekens kan bevatten.

- **--xlate-engine**=_engine_

    Specificeert de te gebruiken vertaalmotor. Als je de engine module direct specificeert, zoals `-Mxlate::deepl`, hoef je deze optie niet te gebruiken.

    Op dit moment zijn de volgende engines beschikbaar

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4-turbo
    - **gpt4o**: gpt-4o-mini

        De interface van **gpt-4o** is instabiel en kan op dit moment niet worden gegarandeerd correct te werken.

- **--xlate-labor**
- **--xlabor**

    In plaats van de vertaalmotor aan te roepen, wordt er van jou verwacht dat je het werk doet. Nadat de tekst is voorbereid om te worden vertaald, wordt deze gekopieerd naar het klembord. Je wordt verwacht om ze in het formulier te plakken, het resultaat naar het klembord te kopiëren en op enter te drukken.

- **--xlate-to** (Default: `EN-US`)

    Specificeer de doeltaal. U kunt de beschikbare talen krijgen met het `deepl languages` commando wanneer u de **DeepL** motor gebruikt.

- **--xlate-format**=_format_ (Default: `conflict`)

    Specificeer het uitvoerformaat voor de oorspronkelijke en vertaalde tekst.

    De volgende formaten anders dan `xtxt` gaan ervan uit dat het te vertalen deel een verzameling regels is. In feite is het mogelijk om slechts een deel van een regel te vertalen, en het specificeren van een ander formaat dan `xtxt` zal geen zinvolle resultaten opleveren.

    - **conflict**, **cm**

        Originele en geconverteerde tekst worden afgedrukt in [git(1)](http://man.he.net/man1/git) conflict marker formaat.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        U kunt het oorspronkelijke bestand herstellen met het volgende [sed(1)](http://man.he.net/man1/sed) commando.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        \`\`\`html

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        &lt;div style="background-color: #f4f4f4; color: #333; border-left: 6px solid #c0392b; padding: 10px; margin-bottom: 10px;">

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Aantal dubbele punten is standaard 7. Als je een dubbele puntensequentie opgeeft zoals `:::::`, wordt deze in plaats van 7 dubbele punten gebruikt.

    - **ifdef**

        Originele en geconverteerde tekst worden afgedrukt in [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` formaat.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        U kunt alleen de Japanse tekst ophalen met het **unifdef** commando:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Hello! How can I help you today?

    - **xtxt**

        Als het formaat `xtxt` (vertaalde tekst) of onbekend is, wordt alleen de vertaalde tekst afgedrukt.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Vertaal de volgende tekst naar het Nederlands, regel voor regel.

- **--xlate-maxline**=_n_ (Default: 0)

    Specificeer het maximale aantal regels tekst dat tegelijk naar de API wordt verzonden.

    Stel deze waarde in op 1 als je regel voor regel wilt vertalen. Deze optie heeft voorrang op de `--xlate-maxlen` optie.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Bekijk het vertaalresultaat in realtime in de STDERR-uitvoer.

- **--xlate-stripe**

    Gebruik de [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) module om het overeenkomende deel te tonen in een zebra-strepenpatroon. Dit is handig wanneer de overeenkomende delen aan elkaar zijn gekoppeld.

    Het kleurenpalet wordt aangepast aan de achtergrondkleur van het terminal. Als je dit expliciet wilt specificeren, kun je **--xlate-stripe-light** of **--xlate-stripe-dark** gebruiken.

- **--xlate-mask**

    Voer maskeringsfunctie uit en toon de geconverteerde tekst zoals het is zonder herstel.

- **--match-all**

    Stel de volledige tekst van het bestand in als een doelgebied.

# CACHE OPTIONS

De **xlate** module kan gecachte tekst van vertaling voor elk bestand opslaan en deze lezen vóór de uitvoering om de overhead van het vragen aan de server te elimineren. Met de standaard cache-strategie `auto` wordt de cache alleen behouden wanneer het cachebestand bestaat voor het doelbestand.

Gebruik **--xlate-cache=clear** om cachebeheer te starten of om alle bestaande cachegegevens op te schonen. Zodra dit met deze optie is uitgevoerd, wordt er een nieuw cachebestand aangemaakt als dat nog niet bestaat en vervolgens automatisch onderhouden.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Onderhoud het cachebestand als het bestaat.

    - `create`

        Maak een leeg cachebestand aan en stop.

    - `always`, `yes`, `1`

        Onderhoud de cache hoe dan ook zolang het doel een normaal bestand is.

    - `clear`

        Wis eerst de cachegegevens.

    - `never`, `no`, `0`

        Gebruik nooit het cachebestand, zelfs als het bestaat.

    - `accumulate`

        Standaardgedrag is dat ongebruikte gegevens uit het cachebestand worden verwijderd. Als u ze niet wilt verwijderen en in het bestand wilt bewaren, gebruik dan `accumulate`.
- **--xlate-update**

    Deze optie dwingt het bijwerken van het cachebestand af, zelfs als dit niet nodig is.

# COMMAND LINE INTERFACE

Je kunt dit module eenvoudig vanaf de commandoregel gebruiken door het `xlate` commando te gebruiken dat is opgenomen in de distributie. Bekijk de `xlate` man-pagina voor het gebruik.

Het `xlate` commando werkt samen met de Docker-omgeving, dus zelfs als u niets geïnstalleerd heeft, kunt u het gebruiken zolang Docker beschikbaar is. Gebruik de `-D` of `-C` optie.

Ook worden er makefiles geleverd voor verschillende documentstijlen, zodat vertalingen naar andere talen mogelijk zijn zonder speciale specificatie. Gebruik de `-M` optie.

Je kunt ook de Docker en `make` opties combineren zodat je `make` kunt uitvoeren in een Docker-omgeving.

Als je het uitvoert zoals `xlate -C`, wordt er een shell gestart met het huidige werkende git-repository gemount.

Lees het Japanse artikel in de ["ZIE OOK"](#zie-ook) sectie voor meer details.

# EMACS

Laad het bestand `xlate.el` dat is opgenomen in de repository om het `xlate` commando te gebruiken vanuit de Emacs-editor. De functie `xlate-region` vertaalt het opgegeven gedeelte. De standaardtaal is `EN-US` en je kunt de taal specificeren door het aan te roepen met een voorvoegselargument.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Stel je authenticatiesleutel in voor de DeepL-service.

- OPENAI\_API\_KEY

    OpenAI authenticatiesleutel.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Je moet command line tools installeren voor DeepL en ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Docker-containerbeeld.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python-bibliotheek en CLI-commando.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python-bibliotheek

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI command line interface

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Zie de handleiding van **greple** voor meer informatie over het doelpatroon van de tekst. Gebruik de opties **--inside**, **--outside**, **--include**, **--exclude** om het overeenkomende gebied te beperken.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Je kunt de module `-Mupdate` gebruiken om bestanden te wijzigen op basis van het resultaat van het **greple** commando.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Gebruik **sdif** om het conflictmarkeringsformaat zij aan zij weer te geven met de optie **-V**.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe** module gebruiken via de **--xlate-stripe** optie.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Greple-module om alleen de noodzakelijke delen te vertalen en te vervangen met de DeepL API (in het Japans)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Genereren van documenten in 15 talen met de DeepL API-module (in het Japans)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Automatische vertaling Docker-omgeving met DeepL API (in het Japans)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
