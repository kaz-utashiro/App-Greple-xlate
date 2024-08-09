# NAME

App::Greple::xlate - vertaalondersteuningsmodule voor greple

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.3101

# DESCRIPTION

De module **Greple** **xlate** vindt de gewenste tekstblokken en vervangt ze door de vertaalde tekst. Momenteel zijn DeepL (`deepl.pm`) en ChatGPT (`gpt3.pm`) module geïmplementeerd als een back-end engine. Experimentele ondersteuning voor gpt-4 is ook inbegrepen.

Als je normale tekstblokken wilt vertalen in een document dat geschreven is in de pod-stijl van Perl, gebruik dan het commando **greple** met de module `xlate::deepl` en `perl` als volgt:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

In dit commando betekent pattern string `^(\w.*\n)+` opeenvolgende regels die beginnen met een alfa-numerieke letter. Deze opdracht toont het te vertalen gebied gemarkeerd. Optie **--all** wordt gebruikt om de hele tekst te produceren.

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
- Als een regel eindigt met een teken van volledige breedte en de volgende regel begint met een teken van volledige breedte, worden de regels aan elkaar gekoppeld.
- Als het einde of het begin van een regel geen teken voor de volledige breedte is, voeg ze dan samen door een spatieteken in te voegen.

Cachegegevens worden beheerd op basis van de genormaliseerde tekst, dus zelfs als er wijzigingen worden aangebracht die geen invloed hebben op de normalisatieresultaten, zullen de vertaalgegevens in de cache nog steeds effectief zijn.

Dit normalisatieproces wordt alleen uitgevoerd voor het eerste (0e) en even genummerde patroon. Dus als twee patronen als volgt worden gespecificeerd, wordt de tekst die overeenkomt met het eerste patroon verwerkt na normalisatie en wordt er geen normalisatieproces uitgevoerd op de tekst die overeenkomt met het tweede patroon.

    greple Mxlate -E normalized -E not-normalized

Gebruik daarom het eerste patroon voor tekst die verwerkt moet worden door meerdere regels samen te voegen tot een enkele regel, en gebruik het tweede patroon voor voorgeformatteerde tekst. Als er geen overeenkomende tekst is in het eerste patroon, gebruik dan een patroon dat nergens mee overeenkomt, zoals `(?!)`.

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

- **--xlate-labor**
- **--xlabor**

    In plaats van de vertaalmachine op te roepen, wordt er van je verwacht dat je zelf aan de slag gaat. Na het voorbereiden van tekst die vertaald moet worden, worden ze gekopieerd naar het klembord. Er wordt van je verwacht dat je ze op het formulier plakt, het resultaat naar het klembord kopieert en op return drukt.

- **--xlate-to** (Default: `EN-US`)

    Geef de doeltaal op. U kunt de beschikbare talen krijgen met het commando `deepl languages` wanneer u de engine **DeepL** gebruikt.

- **--xlate-format**=_format_ (Default: `conflict`)

    Specificeer het uitvoerformaat voor originele en vertaalde tekst.

    - **conflict**, **cm**

        Originele en geconverteerde tekst worden afgedrukt in [git(1)](http://man.he.net/man1/git) conflictmarkeerder formaat.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        U kunt het originele bestand herstellen met de volgende [sed(1)](http://man.he.net/man1/sed) opdracht.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

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

        Originele en geconverteerde tekst worden gescheiden door een enkele lege regel afgedrukt.

    - **xtxt**

        Als het formaat `xtxt` (vertaalde tekst) of onbekend is, wordt alleen vertaalde tekst afgedrukt.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Geef de maximale lengte van de tekst op die in één keer naar de API moet worden gestuurd. De standaardwaarde is ingesteld zoals voor de gratis DeepL account service: 128K voor de API (**--xlate**) en 5000 voor de klembordinterface (**--xlate-labor**). U kunt deze waarden wijzigen als u Pro-service gebruikt.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Zie het resultaat van de vertaling in real time in de STDERR uitvoer.

- **--match-all**

    Stel de hele tekst van het bestand in als doelgebied.

# CACHE OPTIONS

De module **xlate** kan de tekst van de vertaling voor elk bestand in de cache opslaan en lezen vóór de uitvoering om de overhead van het vragen aan de server te elimineren. Met de standaard cache strategie `auto`, onderhoudt het alleen cache gegevens wanneer het cache bestand bestaat voor het doelbestand.

- --cache-clear

    De optie **--cache-clear** kan worden gebruikt om het beheer van de cache te starten of om alle bestaande cache-gegevens te vernieuwen. Eenmaal uitgevoerd met deze optie, wordt een nieuw cachebestand aangemaakt als er geen bestaat en daarna automatisch onderhouden.

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

# COMMAND LINE INTERFACE

Je kunt deze module eenvoudig vanaf de commandoregel gebruiken met het commando `xlate` dat bij de distributie zit. Zie de `xlate` helpinformatie voor gebruik.

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
        -s   silent mode
        -e # translation engine (default "deepl")
        -p # pattern to determine translation area
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
        -I * specify altanative docker image (default: tecolicom/xlate:version)
        -D * run xlate on the container with the rest parameters
        -C * run following command on the container, or run shell

    Control Files:
        *.LANG    translation languates
        *.FORMAT  translation foramt (xtxt, cm, ifdef)
        *.ENGINE  translation engine (deepl or gpt3)

# EMACS

Laad het `xlate.el` bestand in het archief om het `xlate` commando te gebruiken vanuit de Emacs editor. `xlate-region` functie vertaalt de gegeven regio. De standaardtaal is `EN-US` en u kunt de taal specificeren met het prefix argument.

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

[https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

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
