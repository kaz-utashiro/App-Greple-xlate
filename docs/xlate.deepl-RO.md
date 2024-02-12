# NAME

App::Greple::xlate - modul de suport pentru traducere pentru Greple

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.30

# DESCRIPTION

Modulul **Greple** **xlate** găsește blocurile de text dorite și le înlocuiește cu textul tradus. În prezent, modulele DeepL (`deepl.pm`) și ChatGPT (`gpt3.pm`) sunt implementate ca motor back-end. De asemenea, este inclus suportul experimental pentru gpt-4.

Dacă doriți să traduceți blocuri de text normale într-un document scris în stilul Perl's pod, utilizați comanda **greple** cu modulul `xlate::deepl` și `perl` astfel:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

În această comandă, șirul de modele `^(\w.*\n)+` înseamnă linii consecutive care încep cu o literă alfanumerică. Această comandă arată zona care urmează să fie tradusă evidențiată. Opțiunea **--all** este utilizată pentru a produce întregul text.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Apoi se adaugă opțiunea `--xlate` pentru a traduce zona selectată. Apoi, se vor găsi secțiunile dorite și se vor înlocui cu ieșirea comenzii **deepl**.

În mod implicit, textul original și cel tradus sunt tipărite în formatul "conflict marker" compatibil cu [git(1)](http://man.he.net/man1/git). Utilizând formatul `ifdef`, puteți obține cu ușurință partea dorită prin comanda [unifdef(1)](http://man.he.net/man1/unifdef). Formatul de ieșire poate fi specificat prin opțiunea **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Dacă doriți să traduceți întregul text, utilizați opțiunea **--match-all**. Aceasta este o scurtătură pentru a specifica modelul `(?s).+` care se potrivește cu întregul text.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Invocați procesul de traducere pentru fiecare zonă corespunzătoare.

    Fără această opțiune, **greple** se comportă ca o comandă de căutare normală. Astfel, puteți verifica ce parte a fișierului va face obiectul traducerii înainte de a invoca lucrul efectiv.

    Rezultatul comenzii merge la ieșire standard, deci redirecționați-l către fișier dacă este necesar sau luați în considerare utilizarea modulului [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    Opțiunea **--xlate** apelează opțiunea **--xlate-color** cu opțiunea **--color=never**.

    Cu opțiunea **--xlate-fold**, textul convertit este pliat cu lățimea specificată. Lățimea implicită este 70 și poate fi stabilită prin opțiunea **--xlate-fold-width**. Patru coloane sunt rezervate pentru operațiunea de rulare, astfel încât fiecare linie poate conține cel mult 74 de caractere.

- **--xlate-engine**=_engine_

    Specifică motorul de traducere care urmează să fie utilizat. Dacă specificați direct modulul motorului, cum ar fi `-Mxlate::deepl`, nu este necesar să utilizați această opțiune.

- **--xlate-labor**
- **--xlabor**

    În loc să apelați motorul de traducere, se așteaptă să lucrați pentru. După pregătirea textului care urmează să fie tradus, acestea sunt copiate în clipboard. Se așteaptă să le lipiți în formular, să copiați rezultatul în clipboard și să apăsați return.

- **--xlate-to** (Default: `EN-US`)

    Specificați limba țintă. Puteți obține limbile disponibile prin comanda `deepl languages` atunci când se utilizează motorul **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Specificați formatul de ieșire pentru textul original și cel tradus.

    - **conflict**, **cm**

        Textul original și cel convertit sunt tipărite în formatul de marker de conflict [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Puteți recupera fișierul original prin următoarea comandă [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        Textul original și cel convertit sunt tipărite în formatul [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Puteți recupera doar textul japonez prin comanda **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        Textul original și textul convertit sunt tipărite separate de o singură linie albă.

    - **xtxt**

        Dacă formatul este `xtxt` (text tradus) sau necunoscut, se tipărește numai textul tradus.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Specificați lungimea maximă a textului care urmează să fie trimis la API deodată. Valoarea implicită este setată ca pentru serviciul de cont gratuit DeepL: 128K pentru API (**--xlate**) și 5000 pentru interfața clipboard (**--xlate-labor**). Este posibil să puteți modifica aceste valori dacă utilizați serviciul Pro.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Vedeți rezultatul traducerii în timp real în ieșirea STDERR.

- **--match-all**

    Setați întregul text al fișierului ca zonă țintă.

# CACHE OPTIONS

Modulul **xlate** poate stoca în memoria cache textul traducerii pentru fiecare fișier și îl poate citi înainte de execuție, pentru a elimina costurile suplimentare de solicitare a serverului. Cu strategia implicită de cache `auto`, acesta păstrează datele din cache numai atunci când fișierul cache există pentru fișierul țintă.

- --cache-clear

    Opțiunea **--cache-clear** poate fi utilizată pentru a iniția gestionarea memoriei cache sau pentru a reîmprospăta toate datele existente în memoria cache. Odată executat cu această opțiune, un nou fișier cache va fi creat dacă nu există unul și apoi va fi menținut automat.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Menține fișierul cache dacă acesta există.

    - `create`

        Creează un fișier cache gol și iese.

    - `always`, `yes`, `1`

        Menține oricum memoria cache în măsura în care fișierul țintă este un fișier normal.

    - `clear`

        Ștergeți mai întâi datele din memoria cache.

    - `never`, `no`, `0`

        Nu utilizează niciodată fișierul cache, chiar dacă există.

    - `accumulate`

        Prin comportament implicit, datele neutilizate sunt eliminate din fișierul cache. Dacă nu doriți să le eliminați și să le păstrați în fișier, utilizați `acumulare`.

# COMMAND LINE INTERFACE

Puteți utiliza cu ușurință acest modul din linia de comandă, folosind comanda `xlate` inclusă în distribuție. Consultați informațiile din ajutorul `xlate` pentru utilizare.

Comanda `xlate` funcționează de comun acord cu mediul Docker, astfel încât, chiar dacă nu aveți nimic instalat la îndemână, îl puteți utiliza atâta timp cât Docker este disponibil. Utilizați opțiunea `-D` sau `-C`.

De asemenea, deoarece sunt furnizate makefile-uri pentru diferite stiluri de documente, traducerea în alte limbi este posibilă fără specificații speciale. Utilizați opțiunea `-M`.

De asemenea, puteți combina opțiunile Docker și make, astfel încât să puteți rula make într-un mediu Docker.

Rularea ca `xlate -GC` va lansa un shell cu depozitul git de lucru curent montat.

Citiți articolul japonez din secțiunea ["SEE ALSO"](#see-also) pentru detalii.

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

Încărcați fișierul `xlate.el` inclus în depozit pentru a utiliza comanda `xlate` din editorul Emacs. Funcția `xlate-region` traduce regiunea dată. Limba implicită este `EN-US` și puteți specifica limba invocând-o cu argumentul prefix.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Setați cheia de autentificare pentru serviciul DeepL.

- OPENAI\_API\_KEY

    Cheia de autentificare OpenAI.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Trebuie să instalați instrumentele de linie de comandă pentru DeepL și ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl).

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

[https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Biblioteca Python și comanda CLI.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Biblioteca OpenAI Python

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Interfață de linie de comandă OpenAI

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Consultați manualul **greple** pentru detalii despre modelul de text țintă. Utilizați opțiunile **--inside**, **--outside**, **--include**, **--exclude** pentru a limita zona de potrivire.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Puteți utiliza modulul `-Mupdate` pentru a modifica fișierele în funcție de rezultatul comenzii **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Folosiți **sdif** pentru a afișa formatul markerilor de conflict unul lângă altul cu opțiunea **-V**.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Modul Greple pentru a traduce și a înlocui doar părțile necesare cu DeepL API (în japoneză)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Generarea de documente în 15 limbi cu modulul DeepL API (în japoneză)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Traducerea automată a mediului Docker cu DeepL API (în japoneză)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
