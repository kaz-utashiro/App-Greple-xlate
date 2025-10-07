# NAME

App::Greple::xlate - vertaalondersteuningsmodule voor greple

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

    greple -Mxlate::gpt4 --xlate pattern target-file

    greple -Mxlate --xlate-engine gpt4 --xlate pattern target-file

# VERSION

Version 0.9913

# DESCRIPTION

**Greple** **xlate** module vindt gewenste tekstblokken en vervangt deze door de vertaalde tekst. Momenteel zijn DeepL (`deepl.pm`) en ChatGPT 4.1 (`gpt4.pm`) modules geïmplementeerd als back-end engine.

Als je normale tekstblokken in een document in Perl's pod-stijl wilt vertalen, gebruik dan het **greple**-commando met de `xlate::deepl`- en `perl`-module zoals dit:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

In dit commando betekent de patroonstring `^([\w\pP].*\n)+` opeenvolgende regels die beginnen met alfanumerieke en leestekens. Dit commando toont het te vertalen gebied gemarkeerd. Optie **--all** wordt gebruikt om de volledige tekst te produceren.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Voeg vervolgens de optie `--xlate` toe om het geselecteerde gebied te vertalen. Dan worden de gewenste secties gevonden en vervangen door de uitvoer van het **deepl**-commando.

Standaard worden originele en vertaalde tekst afgedrukt in het "conflict marker"-formaat dat compatibel is met [git(1)](http://man.he.net/man1/git). Met `ifdef`-formaat kun je het gewenste deel gemakkelijk verkrijgen met het [unifdef(1)](http://man.he.net/man1/unifdef)-commando. Het uitvoerformaat kan worden gespecificeerd met de optie **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Als je de volledige tekst wilt vertalen, gebruik dan de optie **--match-all**. Dit is een snelkoppeling om het patroon `(?s).+` op te geven dat overeenkomt met de volledige tekst.

Gegevens in conflict marker-formaat kunnen in zij-aan-zij-stijl worden bekeken met het [sdif](https://metacpan.org/pod/App%3A%3Asdif)-commando met optie `-V`. Aangezien het geen zin heeft om per string te vergelijken, wordt de optie `--no-cdif` aanbevolen. Als je de tekst niet hoeft te kleuren, specificeer `--no-textcolor` (of `--no-tc`).

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

De verwerking gebeurt in gespecificeerde eenheden, maar in het geval van een reeks van meerdere regels niet-lege tekst worden ze samen omgezet in één regel. Deze bewerking wordt als volgt uitgevoerd:

- Verwijder witruimte aan het begin en einde van elke regel.
- Als een regel eindigt met een full-width leesteken, concateneer met de volgende regel.
- Als een regel eindigt met een full-width teken en de volgende regel begint met een full-width teken, concateneer de regels.
- Als het einde of het begin van een regel geen full-width teken is, concateneer ze door een spatie in te voegen.

Cachegegevens worden beheerd op basis van de genormaliseerde tekst, dus zelfs als wijzigingen worden aangebracht die de normalisatieresultaten niet beïnvloeden, blijft de vertaalde cachedata effectief.

Dit normalisatieproces wordt alleen uitgevoerd voor het eerste (0e) en even genummerde patroon. Dus als twee patronen als volgt worden opgegeven, wordt de tekst die overeenkomt met het eerste patroon verwerkt na normalisatie, en wordt er geen normalisatieproces uitgevoerd op de tekst die overeenkomt met het tweede patroon.

    greple -Mxlate -E normalized -E not-normalized

Gebruik daarom het eerste patroon voor tekst die moet worden verwerkt door meerdere regels te combineren tot één regel, en gebruik het tweede patroon voor vooraf opgemaakte tekst. Als er geen tekst is die overeenkomt met het eerste patroon, gebruik dan een patroon dat nergens mee overeenkomt, zoals `(?!)`.

# MASKING

Soms zijn er delen van de tekst die je niet wilt vertalen. Bijvoorbeeld tags in markdown-bestanden. DeepL stelt voor om in dergelijke gevallen het te uitsluiten deel van de tekst om te zetten naar XML-tags, te vertalen en daarna na voltooiing van de vertaling te herstellen. Ter ondersteuning hiervan is het mogelijk om de delen die van vertaling moeten worden gemaskeerd op te geven.

    --xlate-setopt maskfile=MASKPATTERN

Hiermee wordt elke regel van het bestand \`MASKPATTERN\` geïnterpreteerd als een reguliere expressie, worden overeenkomende tekenreeksen vertaald en wordt na de verwerking teruggedraaid. Regels die beginnen met `#` worden genegeerd.

Een complex patroon kan over meerdere regels worden geschreven met een backslash-geëscapete regeleinde.

Hoe de tekst door maskering wordt getransformeerd, is te zien met de optie **--xlate-mask**.

Deze interface is experimenteel en kan in de toekomst veranderen.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Start het vertaalproces voor elk overeenkomend gebied.

    Zonder deze optie gedraagt **greple** zich als een normale zoekopdracht. Zo kun je controleren welk deel van het bestand onderwerp van de vertaling zal zijn voordat je het echte werk start.

    Het commandoresultaat gaat naar standaarduitvoer, dus leid indien nodig om naar een bestand, of overweeg het gebruik van de module [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    Optie **--xlate** roept optie **--xlate-color** aan met optie **--color=never**.

    Met optie **--xlate-fold** wordt geconverteerde tekst opgevouwen tot de opgegeven breedte. De standaardbreedte is 70 en kan worden ingesteld met optie **--xlate-fold-width**. Er zijn vier kolommen gereserveerd voor run-in-bewerking, dus elke regel kan maximaal 74 tekens bevatten.

- **--xlate-engine**=_engine_

    Specificeert de te gebruiken vertaalengine. Als je de enginemodule direct specificeert, zoals `-Mxlate::deepl`, hoef je deze optie niet te gebruiken.

    Op dit moment zijn de volgende engines beschikbaar

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4.1
    - **gpt4o**: gpt-4o-mini

        De interface van **gpt-4o** is instabiel en kan op dit moment niet gegarandeerd correct werken.

- **--xlate-labor**
- **--xlabor**

    In plaats van de vertaalengine aan te roepen, wordt verwacht dat jij het werk doet. Na het voorbereiden van de te vertalen tekst worden deze naar het klembord gekopieerd. Je wordt verondersteld ze in het formulier te plakken, het resultaat naar het klembord te kopiëren en op return te drukken.

- **--xlate-to** (Default: `EN-US`)

    Specificeer de doeltaal. Je kunt beschikbare talen opvragen met het commando `deepl languages` wanneer je de engine **DeepL** gebruikt.

- **--xlate-format**=_format_ (Default: `conflict`)

    Specificeer de uitvoerindeling voor originele en vertaalde tekst.

    De volgende indelingen, anders dan `xtxt`, gaan ervan uit dat het te vertalen deel een verzameling regels is. In feite is het mogelijk slechts een gedeelte van een regel te vertalen, maar het specificeren van een andere indeling dan `xtxt` levert geen zinvol resultaat op.

    - **conflict**, **cm**

        Originele en geconverteerde tekst worden afgedrukt in [git(1)](http://man.he.net/man1/git)-conflictmarkeringsformaat.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Je kunt het originele bestand herstellen met het volgende commando [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        De originele en vertaalde tekst worden uitgevoerd in een aangepaste containerstijl van markdown.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Bovenstaande tekst wordt in HTML als volgt vertaald.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Het aantal dubbele punten is standaard 7. Als je een reeks dubbele punten opgeeft zoals `:::::`, wordt die gebruikt in plaats van 7 dubbele punten.

    - **ifdef**

        Originele en geconverteerde tekst worden afgedrukt in [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`-formaat.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Je kunt alleen Japanse tekst ophalen met het commando **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Originele en geconverteerde tekst worden afgedrukt, gescheiden door één lege regel. Voor `space+` wordt ook een regeleinde na de geconverteerde tekst uitgegeven.

    - **xtxt**

        Als het formaat `xtxt` (vertaalde tekst) is of onbekend, wordt alleen de vertaalde tekst afgedrukt.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Geef de maximale lengte op van tekst die in één keer naar de API wordt verzonden. Standaardwaarde is ingesteld zoals voor de gratis DeepL-accountservice: 128K voor de API (**--xlate**) en 5000 voor de klembordinterface (**--xlate-labor**). Mogelijk kunt u deze waarden wijzigen als u de Pro-service gebruikt.

- **--xlate-maxline**=_n_ (Default: 0)

    Geef het maximale aantal regels tekst op dat in één keer naar de API wordt verzonden.

    Stel deze waarde in op 1 als u één regel per keer wilt vertalen. Deze optie heeft voorrang op de optie `--xlate-maxlen`.

- **--xlate-prompt**=_text_

    Geef een aangepaste prompt op die naar de vertaalmachine wordt gestuurd. Deze optie is alleen beschikbaar bij gebruik van ChatGPT-engines (gpt3, gpt4, gpt4o). U kunt het vertaalgedrag aanpassen door specifieke instructies aan het AI-model te geven. Als de prompt `%s` bevat, wordt deze vervangen door de naam van de doeltaal.

- **--xlate-context**=_text_

    Geef extra contextinformatie op die naar de vertaalmachine wordt gestuurd. Deze optie kan meerdere keren worden gebruikt om meerdere contextstrings te leveren. De contextinformatie helpt de vertaalmachine de achtergrond te begrijpen en nauwkeurigere vertalingen te produceren.

- **--xlate-glossary**=_glossary_

    Geef een woordenlijst-ID op die voor vertaling wordt gebruikt. Deze optie is alleen beschikbaar bij gebruik van de DeepL-engine. De woordenlijst-ID moet uit uw DeepL-account worden verkregen en zorgt voor consistente vertaling van specifieke termen.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Bekijk het vertaalresultaat in realtime in de STDERR-uitvoer.

- **--xlate-stripe**

    Gebruik de module [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) om het overeenkomende deel te tonen met zebra-achtige arcering. Dit is handig wanneer de overeenkomende delen rug-aan-rug zijn verbonden.

    Het kleurenpalet wordt geschakeld volgens de achtergrondkleur van de terminal. Als u het expliciet wilt opgeven, kunt u **--xlate-stripe-light** of **--xlate-stripe-dark** gebruiken.

- **--xlate-mask**

    Voer de maskeringsfunctie uit en geef de geconverteerde tekst weer zoals die is, zonder herstel.

- **--match-all**

    Stel de volledige tekst van het bestand in als doelgebied.

- **--lineify-cm**
- **--lineify-colon**

    In het geval van de formaten `cm` en `colon` wordt de output gesplitst en regel voor regel opgemaakt. Daarom kan, als slechts een deel van een regel moet worden vertaald, het verwachte resultaat niet worden verkregen. Deze filters herstellen output die is beschadigd door het vertalen van een deel van een regel naar normale, regel-voor-regel output.

    In de huidige implementatie worden, als meerdere delen van een regel worden vertaald, deze als zelfstandige regels uitgegeven.

# CACHE OPTIONS

De module **xlate** kan gecachete vertalingstekst per bestand opslaan en vóór uitvoering inlezen om de overhead van het vragen aan de server te elimineren. Met de standaardcache-strategie `auto` wordt cachedata alleen onderhouden wanneer het cachebestand voor het doelfile bestaat.

Gebruik **--xlate-cache=clear** om cachebeheer te initiëren of om alle bestaande cachedata op te schonen. Na eenmaal met deze optie te zijn uitgevoerd, wordt een nieuw cachebestand aangemaakt als er nog geen bestaat en daarna automatisch onderhouden.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Onderhoud het cachebestand als het bestaat.

    - `create`

        Maak een leeg cachebestand aan en sluit af.

    - `always`, `yes`, `1`

        Houd de cache toch bij zolang het doel een normaal bestand is.

    - `clear`

        Maak eerst de cachedata leeg.

    - `never`, `no`, `0`

        Gebruik nooit een cachebestand, zelfs niet als het bestaat.

    - `accumulate`

        Standaard worden ongebruikte gegevens uit het cachebestand verwijderd. Als je ze niet wilt verwijderen en in het bestand wilt houden, gebruik dan `accumulate`.
- **--xlate-update**

    Deze optie dwingt een update van het cachebestand af, zelfs als dat niet nodig is.

# COMMAND LINE INTERFACE

Je kunt deze module eenvoudig vanaf de commandoregel gebruiken met het commando `xlate` dat in de distributie is opgenomen. Zie de man-pagina `xlate` voor gebruik.

Het commando `xlate` werkt samen met de Docker-omgeving, dus ook als je niets lokaal hebt geïnstalleerd, kun je het gebruiken zolang Docker beschikbaar is. Gebruik de optie `-D` of `-C`.

Omdat makefiles voor verschillende documentstijlen worden meegeleverd, is vertalen naar andere talen mogelijk zonder speciale specificatie. Gebruik de optie `-M`.

Je kunt ook de Docker- en `make`-opties combineren zodat je `make` in een Docker-omgeving kunt uitvoeren.

Uitvoeren zoals `xlate -C` start een shell met de huidige werkende git-repository gemount.

Lees het Japanse artikel in de sectie ["SEE ALSO"](#see-also) voor details.

# EMACS

Laad het bestand `xlate.el` in de repository om het commando `xlate` vanuit de Emacs-editor te gebruiken. De functie `xlate-region` vertaalt de opgegeven regio. De standaardtaal is `EN-US` en je kunt een taal opgeven door het met een prefix-argument aan te roepen.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Stel je authenticatiesleutel in voor de DeepL-service.

- OPENAI\_API\_KEY

    OpenAI-authenticatiesleutel.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Je moet commandoregelhulpmiddelen voor DeepL en ChatGPT installeren.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt4](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt4)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Docker-containerimage.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python-bibliotheek en CLI-commando.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python-bibliotheek

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI commandoregelinterface

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Zie de handleiding **greple** voor details over het doelsjabloon. Gebruik de opties **--inside**, **--outside**, **--include**, **--exclude** om het matchgebied te beperken.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Je kunt de module `-Mupdate` gebruiken om bestanden te wijzigen op basis van het resultaat van het commando **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Gebruik **sdif** om het conflictmarkeerformaat naast elkaar te tonen met de optie **-V**.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe**-module gebruikt met de optie **--xlate-stripe**.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Greple-module om alleen de noodzakelijke delen te vertalen en te vervangen met de DeepL-API (in het Japans)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Documenten genereren in 15 talen met de DeepL-API-module (in het Japans)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Automatische vertaal-Docker-omgeving met DeepL-API (in het Japans)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
