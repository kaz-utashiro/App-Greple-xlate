# NAME

App::Greple::xlate - vertaalondersteuningsmodule voor greple

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.9901

# DESCRIPTION

De module **Greple** **xlate** vindt de gewenste tekstblokken en vervangt ze door de vertaalde tekst. Momenteel zijn DeepL (`deepl.pm`) en ChatGPT (`gpt3.pm`) module geïmplementeerd als een back-end engine. Experimentele ondersteuning voor gpt-4 en gpt-4o zijn ook inbegrepen.

Als je normale tekstblokken wilt vertalen in een document dat geschreven is in de pod-stijl van Perl, gebruik dan het commando **greple** met de module `xlate::deepl` en `perl` als volgt:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

In deze opdracht betekent patroontekenreeks `^([\w\pP].*\n)+` opeenvolgende regels die beginnen met alfanumerieke letters en leestekens. Deze opdracht laat het te vertalen gebied gemarkeerd zien. Optie **--all** wordt gebruikt om de volledige tekst te produceren.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Voeg dan de optie `--xlate` toe om het geselecteerde gebied te vertalen. Vervolgens worden de gewenste secties gevonden en vervangen door de uitvoer van de opdracht **deepl**.

Standaard wordt originele en vertaalde tekst afgedrukt in het "conflict marker" formaat dat compatibel is met [git(1)](http://man.he.net/man1/git). Door `ifdef` formaat te gebruiken, kun je gemakkelijk het gewenste deel krijgen met [unifdef(1)](http://man.he.net/man1/unifdef) commando. Uitvoerformaat kan gespecificeerd worden met **--xlate-format** optie.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Als je de hele tekst wilt vertalen, gebruik dan de optie **--match-all**. Dit is een snelkoppeling om het patroon `(?s).+` op te geven dat overeenkomt met de hele tekst.

Gegevens in conflictmarkerformaat kunnen naast elkaar worden bekeken met het commando `sdif` met de optie `-V`. Aangezien het geen zin heeft om per string te vergelijken, wordt de optie `--no-cdif` aangeraden. Als je de tekst niet hoeft te kleuren, geef dan `--no-textcolor` (of `--no-tc`).

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

De verwerking wordt gedaan in gespecificeerde eenheden, maar in het geval van een opeenvolging van meerdere regels niet-lege tekst, worden ze samen omgezet in een enkele regel. Deze bewerking wordt als volgt uitgevoerd:

- Verwijder witruimte aan het begin en einde van elke regel.
- Als een regel eindigt met een leesteken over de hele breedte, aaneenschakelen met de volgende regel.
- Als een regel eindigt met een teken van volledige breedte en de volgende regel begint met een teken van volledige breedte, worden de regels aan elkaar gekoppeld.
- Als het einde of het begin van een regel geen teken voor de volledige breedte is, voeg ze dan samen door een spatieteken in te voegen.

Cachegegevens worden beheerd op basis van de genormaliseerde tekst, dus zelfs als er wijzigingen worden aangebracht die geen invloed hebben op de normalisatieresultaten, zullen de vertaalgegevens in de cache nog steeds effectief zijn.

Dit normalisatieproces wordt alleen uitgevoerd voor het eerste (0e) en even genummerde patroon. Dus als twee patronen als volgt worden gespecificeerd, wordt de tekst die overeenkomt met het eerste patroon verwerkt na normalisatie en wordt er geen normalisatieproces uitgevoerd op de tekst die overeenkomt met het tweede patroon.

    greple -Mxlate -E normalized -E not-normalized

Gebruik daarom het eerste patroon voor tekst die verwerkt moet worden door meerdere regels samen te voegen tot een enkele regel, en gebruik het tweede patroon voor voorgeformatteerde tekst. Als er geen tekst is om mee te matchen in het eerste patroon, gebruik dan een patroon dat nergens mee overeenkomt, zoals `(?!)`.

# MASKING

Soms zijn er delen van tekst die je niet vertaald wilt hebben. Bijvoorbeeld tags in markdown-bestanden. DeepL stelt voor dat in dergelijke gevallen het deel van de tekst dat moet worden uitgesloten, wordt geconverteerd naar XML-tags, wordt vertaald en vervolgens wordt hersteld nadat de vertaling is voltooid. Om dit te ondersteunen, is het mogelijk om de delen te specificeren die moeten worden gemaskeerd van vertaling.

    --xlate-setopt maskfile=MASKPATTERN

Dit zal elke lijn van het bestand \`MASKPATTERN\` interpreteren als een reguliere expressie, strings vertalen die hiermee overeenstemmen en na verwerking terugzetten. Regels die beginnen met `#` worden genegeerd.

Complexe patronen kunnen op meerdere regels worden geschreven met backslash escpaed newline.

Hoe de tekst door het maskeren wordt omgezet, kun je zien met de optie **--xlate-mask**.

Deze interface is experimenteel en kan in de toekomst veranderen.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Roep het vertaalproces op voor elk gematcht gebied.

    Zonder deze optie gedraagt **greple** zich als een normaal zoekcommando. U kunt dus controleren welk deel van het bestand zal worden vertaald voordat u het eigenlijke werk uitvoert.

    Commandoresultaat gaat naar standaard out, dus redirect naar bestand indien nodig, of overweeg [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) module te gebruiken.

    Optie **--xlate** roept **--xlate-kleur** aan met **--color=never** optie.

    Met de optie **--xlate-fold** wordt geconverteerde tekst gevouwen met de opgegeven breedte. De standaardbreedte is 70 en kan worden ingesteld met de optie **--xlate-fold-width**. Vier kolommen zijn gereserveerd voor inloopoperaties, zodat elke regel maximaal 74 tekens kan bevatten.

- **--xlate-engine**=_engine_

    Specificeert de te gebruiken vertaalmachine. Als u de engine module rechtstreeks specificeert, zoals `-Mxlate::deepl`, hoeft u deze optie niet te gebruiken.

    Op dit moment zijn de volgende engines beschikbaar

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4-turbo
    - **gpt4o**: gpt-4o-mini

        De interface van **gpt-4o** is instabiel en er kan op dit moment niet gegarandeerd worden dat deze correct werkt.

- **--xlate-labor**
- **--xlabor**

    In plaats van de vertaalmachine op te roepen, wordt er van je verwacht dat je zelf aan de slag gaat. Na het voorbereiden van tekst die vertaald moet worden, worden ze gekopieerd naar het klembord. Er wordt van je verwacht dat je ze op het formulier plakt, het resultaat naar het klembord kopieert en op return drukt.

- **--xlate-to** (Default: `EN-US`)

    Geef de doeltaal op. U kunt de beschikbare talen krijgen met het commando `deepl languages` wanneer u de engine **DeepL** gebruikt.

- **--xlate-format**=_format_ (Default: `conflict`)

    Specificeer het uitvoerformaat voor originele en vertaalde tekst.

    De volgende indelingen anders dan `xtxt` gaan ervan uit dat het te vertalen deel een verzameling regels is. In feite is het mogelijk om slechts een deel van een regel te vertalen, en het specificeren van een ander formaat dan `xtxt` zal geen zinvolle resultaten opleveren.

    - **conflict**, **cm**

        Originele en geconverteerde tekst worden afgedrukt in [git(1)](http://man.he.net/man1/git) conflictmarkeerder formaat.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        U kunt het originele bestand herstellen met de volgende [sed(1)](http://man.he.net/man1/sed) opdracht.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        De originele en vertaalde tekst worden uitgevoerd in de aangepaste containerstijl van markdown.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Bovenstaande tekst wordt vertaald naar het volgende in HTML.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Het aantal dubbele punten is standaard 7. Als je een dubbele punt reeks specificeert zoals `:::::`, wordt deze gebruikt in plaats van 7 dubbele punten.

    - **ifdef**

        Originele en geconverteerde tekst worden afgedrukt in [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` formaat.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        U kunt alleen Japanse tekst terughalen met het commando **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Originele en geconverteerde tekst worden gescheiden afgedrukt door een enkele lege regel. Voor `space+` wordt ook een nieuwe regel na de geconverteerde tekst afgedrukt.

    - **xtxt**

        Als het formaat `xtxt` (vertaalde tekst) of onbekend is, wordt alleen vertaalde tekst afgedrukt.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Geef de maximale lengte van de tekst op die in één keer naar de API moet worden gestuurd. De standaardwaarde is ingesteld zoals voor de gratis DeepL account service: 128K voor de API (**--xlate**) en 5000 voor de klembordinterface (**--xlate-labor**). U kunt deze waarden wijzigen als u Pro-service gebruikt.

- **--xlate-maxline**=_n_ (Default: 0)

    Geef het maximum aantal regels tekst op dat in één keer naar de API moet worden gestuurd.

    Stel deze waarde in op 1 als je één regel per keer wilt vertalen. Deze optie heeft voorrang op de `--xlate-maxlen` optie.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Zie het resultaat van de vertaling in real time in de STDERR uitvoer.

- **--xlate-stripe**

    Gebruik de module [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) om het gematchte deel weer te geven met zebrastrepen. Dit is nuttig wanneer de gematchte delen rug-aan-rug verbonden zijn.

    Het kleurenpalet wordt omgeschakeld volgens de achtergrondkleur van de terminal. Als je dit expliciet wilt specificeren, kun je **--xlate-stripe-light** of **--xlate-stripe-dark** gebruiken.

- **--xlate-mask**

    Voer de maskeerfunctie uit en geef de geconverteerde tekst weer zoals hij is, zonder restauratie.

- **--match-all**

    Stel de hele tekst van het bestand in als doelgebied.

# CACHE OPTIONS

De module **xlate** kan de tekst van de vertaling voor elk bestand in de cache opslaan en lezen vóór de uitvoering om de overhead van het vragen aan de server te elimineren. Met de standaard cache strategie `auto`, onderhoudt het alleen cache gegevens wanneer het cache bestand bestaat voor het doelbestand.

Gebruik **--xlate-cache=clear** om cachebeheer te starten of om alle bestaande cachegegevens op te ruimen. Eenmaal uitgevoerd met deze optie, zal een nieuw cachebestand worden aangemaakt als er geen bestaat en daarna automatisch worden onderhouden.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Onderhoud het cachebestand als het bestaat.

    - `create`

        Maak een leeg cache bestand en sluit af.

    - `always`, `yes`, `1`

        Cache-bestand toch behouden voor zover het doelbestand een normaal bestand is.

    - `clear`

        Wis eerst de cachegegevens.

    - `never`, `no`, `0`

        Cache-bestand nooit gebruiken, zelfs niet als het bestaat.

    - `accumulate`

        Standaard worden ongebruikte gegevens uit het cachebestand verwijderd. Als u ze niet wilt verwijderen en in het bestand wilt houden, gebruik dan `accumuleren`.
- **--xlate-update**

    Deze optie dwingt om het cachebestand bij te werken, zelfs als dat niet nodig is.

# COMMAND LINE INTERFACE

Je kunt deze module eenvoudig vanaf de commandoregel gebruiken met het `xlate` commando dat bij de distributie zit. Zie de `xlate` man pagina voor het gebruik.

Het `xlate` commando werkt samen met de Docker omgeving, dus zelfs als je niets geïnstalleerd hebt, kun je het gebruiken zolang Docker beschikbaar is. Gebruik de optie `-D` of `-C`.

Omdat er makefiles voor verschillende documentstijlen worden meegeleverd, is vertaling naar andere talen mogelijk zonder speciale specificaties. Gebruik de optie `-M`.

Je kunt ook de Docker en make opties combineren zodat je make in een Docker omgeving kunt draaien.

Door te draaien als `xlate -GC` wordt een shell gestart met de huidige werkende git repository aangekoppeld.

Lees het Japanse artikel in de ["SEE ALSO"](#see-also) sectie voor meer informatie.

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

Laad het `xlate.el` bestand in het archief om het `xlate` commando te gebruiken vanuit de Emacs editor. `xlate-region` functie vertaalt de gegeven regio. De standaardtaal is `EN-US` en u kunt de taal specificeren met het prefix argument.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Stel uw authenticatiesleutel in voor DeepL service.

- OPENAI\_API\_KEY

    OpenAI authenticatiesleutel.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Je moet commandoregeltools installeren voor DeepL en ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Docker containerafbeelding.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python bibliotheek en CLI commando.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python Bibliotheek

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI opdrachtregelinterface

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Zie de **greple** handleiding voor de details over het doeltekstpatroon. Gebruik **--inside**, **--outside**, **--include**, **--exclude** opties om het overeenkomende gebied te beperken.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    U kunt de module `-Mupdate` gebruiken om bestanden te wijzigen door het resultaat van het commando **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Gebruik **sdif** om het formaat van de conflictmarkering naast de optie **-V** te tonen.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe** module gebruik door **--xlate-stripe** optie.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Greple module om alleen de benodigde onderdelen te vertalen en te vervangen met DeepL API (in het Japans)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Documenten genereren in 15 talen met DeepL API-module (in het Japans)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Automatisch vertaalde Docker-omgeving met DeepL API (in het Japans)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
