# NAME

App::Greple::xlate - modul de suport pentru traducere pentru greple

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

    greple -Mxlate::gpt4 --xlate pattern target-file

    greple -Mxlate::gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

# VERSION

Version 0.9915

# DESCRIPTION

**Greple** **xlate** modulul găsește blocurile de text dorite și le înlocuiește cu textul tradus. În prezent, modulele DeepL (`deepl.pm`), ChatGPT 4.1 (`gpt4.pm`) și GPT-5 (`gpt5.pm`) sunt implementate ca motoare back-end.

Dacă doriți să traduceți blocuri de text normale într-un document scris în stilul pod al Perl, folosiți comanda **greple** cu modulele `xlate::deepl` și `perl` astfel:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

În această comandă, șirul de tipar `^([\w\pP].*\n)+` înseamnă linii consecutive care încep cu litere și cifre și semne de punctuație. Această comandă arată zona ce urmează a fi tradusă evidențiată. Opțiunea **--all** este folosită pentru a produce textul integral.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Apoi adăugați opțiunea `--xlate` pentru a traduce zona selectată. Atunci va găsi secțiunile dorite și le va înlocui cu ieșirea comenzii **deepl**.

Implicit, textul original și cel tradus sunt tipărite în formatul „conflict marker” compatibil cu [git(1)](http://man.he.net/man1/git). Folosind formatul `ifdef`, puteți obține partea dorită cu comanda [unifdef(1)](http://man.he.net/man1/unifdef) ușor. Formatul ieșirii poate fi specificat prin opțiunea **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Dacă doriți să traduceți întregul text, folosiți opțiunea **--match-all**. Aceasta este o scurtătură pentru a specifica tiparul `(?s).+` care se potrivește întregului text.

Datele în format conflict marker pot fi vizualizate în stil side-by-side cu comanda [sdif](https://metacpan.org/pod/App%3A%3Asdif) și opțiunea `-V`. Deoarece nu are sens să comparați pe bază de șir, se recomandă opțiunea `--no-cdif`. Dacă nu aveți nevoie să colorați textul, specificați `--no-textcolor` (sau `--no-tc`).

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Procesarea se face în unitățile specificate, dar în cazul unei secvențe de mai multe linii de text ne-gol, acestea sunt convertite împreună într-o singură linie. Această operație se efectuează după cum urmează:

- Eliminați spațiile albe de la începutul și sfârșitul fiecărei linii.
- Dacă o linie se termină cu un caracter de punctuație full-width, concatenați cu linia următoare.
- Dacă o linie se termină cu un caracter full-width și linia următoare începe cu un caracter full-width, concatenați liniile.
- Dacă fie sfârșitul, fie începutul unei linii nu este un caracter full-width, concatenați-le inserând un caracter spațiu.

Datele din cache sunt gestionate pe baza textului normalizat, astfel încât, chiar dacă se fac modificări care nu afectează rezultatele normalizării, datele de traducere din cache vor rămâne valabile.

Acest proces de normalizare se efectuează numai pentru modelul (tiparul) primul (al 0-lea) și pentru cele cu număr par. Astfel, dacă sunt specificate două tipare ca mai jos, textul care se potrivește primului tipar va fi procesat după normalizare, iar pe textul care se potrivește celui de-al doilea tipar nu se va efectua niciun proces de normalizare.

    greple -Mxlate -E normalized -E not-normalized

Prin urmare, folosiți primul tipar pentru textul care urmează să fie procesat prin combinarea mai multor linii într-o singură linie și folosiți al doilea tipar pentru text preformatat. Dacă nu există text care să se potrivească primului tipar, folosiți un tipar care nu se potrivește cu nimic, cum ar fi `(?!)`.

# MASKING

Ocazional, există părți din text pe care nu doriți să le traduceți. De exemplu, etichete în fișiere markdown. DeepL sugerează ca, în astfel de cazuri, partea de text care trebuie exclusă să fie convertită în etichete XML, tradusă, apoi restaurată după finalizarea traducerii. Pentru a susține acest lucru, este posibil să specificați părțile care vor fi mascate de la traducere.

    --xlate-setopt maskfile=MASKPATTERN

Aceasta va interpreta fiecare linie din fișierul \`MASKPATTERN\` ca o expresie regulată, va traduce șirurile care se potrivesc și va reveni după procesare. Liniile care încep cu `#` sunt ignorate.

Un tipar complex poate fi scris pe mai multe linii cu newline scăpat prin backslash.

Modul în care textul este transformat prin mascarea poate fi văzut prin opțiunea **--xlate-mask**.

Această interfață este experimentală și poate suferi modificări în viitor.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Pornește procesul de traducere pentru fiecare zonă potrivită.

    Fără această opțiune, **greple** se comportă ca o comandă de căutare normală. Astfel puteți verifica ce parte a fișierului va face obiectul traducerii înainte de a porni munca efectivă.

    Rezultatul comenzii merge la ieșirea standard, deci redirecționați către fișier dacă este necesar sau luați în considerare folosirea modulului [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    Opțiunea **--xlate** apelează opțiunea **--xlate-color** cu opțiunea **--color=never**.

    Cu opțiunea **--xlate-fold**, textul convertit este împărțit la lățimea specificată. Lățimea implicită este 70 și poate fi setată prin opțiunea **--xlate-fold-width**. Patru coloane sunt rezervate pentru operația run-in, astfel încât fiecare linie poate conține cel mult 74 de caractere.

- **--xlate-engine**=_engine_

    Specifică motorul de traducere care va fi folosit. Dacă specificați direct modulul motor, cum ar fi `-Mxlate::deepl`, nu este necesar să folosiți această opțiune.

    În acest moment, sunt disponibile următoarele motoare

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4.1
    - **gpt4o**: gpt-4o-mini

        Interfața lui **gpt-4o** este instabilă și nu poate fi garantat că va funcționa corect în acest moment.

    - **gpt5**: gpt-5

- **--xlate-labor**
- **--xlabor**

    În loc să apelați motorul de traducere, se așteaptă să lucrați manual. După pregătirea textului de tradus, acesta este copiat în clipboard. Se așteaptă să îl lipiți în formular, să copiați rezultatul în clipboard și să apăsați Enter.

- **--xlate-to** (Default: `EN-US`)

    Specificați limba țintă. Puteți obține limbile disponibile cu comanda `deepl languages` când folosiți motorul **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Specificați formatul de ieșire pentru textul original și tradus.

    Următoarele formate, altele decât `xtxt`, presupun că partea de tradus este o colecție de linii. De fapt, este posibil să traduceți doar o porțiune a unei linii, dar specificarea unui format diferit de `xtxt` nu va produce rezultate semnificative.

    - **conflict**, **cm**

        Textul original și cel convertit sunt tipărite în formatul marcatorilor de conflict [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Puteți recupera fișierul original cu următoarea comandă [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Textul original și cel tradus sunt afișate într-un stil de container personalizat pentru markdown.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Textul de mai sus va fi tradus în următorul format HTML.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Numărul de două puncte este 7 în mod implicit. Dacă specificați o secvență de două puncte precum `:::::`, aceasta este folosită în locul celor 7 două puncte.

    - **ifdef**

        Textul original și cel convertit sunt tipărite în formatul [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Puteți prelua doar textul japonez cu comanda **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Textul original și cel convertit sunt tipărite separate de o linie goală. Pentru `space+`, se afișează și un rând nou după textul convertit.

    - **xtxt**

        Dacă formatul este `xtxt` (text tradus) sau necunoscut, se tipărește doar textul tradus.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Specificați lungimea maximă a textului care va fi trimis la API dintr-o singură dată. Valoarea implicită este setată pentru serviciul contului DeepL gratuit: 128K pentru API (**--xlate**) și 5000 pentru interfața clipboard (**--xlate-labor**). Este posibil să puteți schimba aceste valori dacă utilizați serviciul Pro.

- **--xlate-maxline**=_n_ (Default: 0)

    Specificați numărul maxim de linii de text care vor fi trimise la API dintr-o singură dată.

    Setați această valoare la 1 dacă doriți să traduceți câte o linie pe rând. Această opțiune are prioritate față de opțiunea `--xlate-maxlen`.

- **--xlate-prompt**=_text_

    Specificați un prompt personalizat care să fie trimis motorului de traducere. Această opțiune este disponibilă doar atunci când folosiți motoarele ChatGPT (gpt3, gpt4, gpt4o). Puteți personaliza comportamentul traducerii oferind instrucțiuni specifice modelului AI. Dacă promptul conține `%s`, acesta va fi înlocuit cu numele limbii țintă.

- **--xlate-context**=_text_

    Specificați informații contextuale suplimentare care să fie trimise motorului de traducere. Această opțiune poate fi utilizată de mai multe ori pentru a furniza multiple șiruri de context. Informațiile de context ajută motorul de traducere să înțeleagă fundalul și să producă traduceri mai precise.

- **--xlate-glossary**=_glossary_

    Specificați un ID de glosar care să fie utilizat pentru traducere. Această opțiune este disponibilă doar atunci când se folosește motorul DeepL. ID-ul glosarului trebuie obținut din contul dvs. DeepL și asigură traducerea consecventă a termenilor specifici.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Vedeți rezultatul traducerii în timp real în ieșirea STDERR.

- **--xlate-stripe**

    Folosiți modulul [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) pentru a afișa partea potrivită în stil zebra striping. Acest lucru este util atunci când părțile potrivite sunt conectate consecutiv.

    Paleta de culori este comutată în funcție de culoarea fundalului terminalului. Dacă doriți să specificați explicit, puteți folosi **--xlate-stripe-light** sau **--xlate-stripe-dark**.

- **--xlate-mask**

    Efectuați funcția de mascarea și afișați textul convertit așa cum este, fără restaurare.

- **--match-all**

    Setați întregul text al fișierului ca zonă țintă.

- **--lineify-cm**
- **--lineify-colon**

    În cazul formatelor `cm` și `colon`, ieșirea este împărțită și formatată linie cu linie. Prin urmare, dacă doar o porțiune dintr-o linie trebuie tradusă, nu se poate obține rezultatul așteptat. Aceste filtre repară ieșirea care este coruptă prin traducerea unei părți a unei linii într-o ieșire normală linie cu linie.

    În implementarea curentă, dacă sunt traduse mai multe părți ale unei linii, acestea sunt afișate ca linii independente.

# CACHE OPTIONS

Modulul **xlate** poate stoca textul de traducere în cache pentru fiecare fișier și îl poate citi înainte de execuție pentru a elimina costul interogării serverului. Cu strategia de cache implicită `auto`, menține datele din cache numai atunci când fișierul de cache există pentru fișierul țintă.

Folosiți **--xlate-cache=clear** pentru a iniția gestionarea cache-ului sau pentru a curăța toate datele de cache existente. Odată executată cu această opțiune, va fi creat un fișier de cache nou dacă nu există unul și apoi va fi menținut automat ulterior.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Mențineți fișierul de cache dacă există.

    - `create`

        Creați fișier de cache gol și ieșiți.

    - `always`, `yes`, `1`

        Menține memoria cache oricum, atât timp cât ținta este un fișier normal.

    - `clear`

        Golește mai întâi datele din cache.

    - `never`, `no`, `0`

        Nu folosi niciodată fișierul cache chiar dacă există.

    - `accumulate`

        În mod implicit, datele neutilizate sunt eliminate din fișierul cache. Dacă nu dorești să le elimini și să le păstrezi în fișier, folosește `accumulate`.
- **--xlate-update**

    Această opțiune forțează actualizarea fișierului cache chiar dacă nu este necesar.

# COMMAND LINE INTERFACE

Poți folosi ușor acest modul din linia de comandă folosind comanda `xlate` inclusă în distribuție. Vezi pagina de manual `xlate` pentru utilizare.

Comanda `xlate` funcționează în concert cu mediul Docker, deci chiar dacă nu ai nimic instalat local, o poți folosi atâta timp cât Docker este disponibil. Folosește opțiunea `-D` sau `-C`.

De asemenea, deoarece sunt furnizate makefile-uri pentru diverse stiluri de documente, traducerea în alte limbi este posibilă fără specificații speciale. Folosește opțiunea `-M`.

Poți combina și opțiunile Docker și `make` astfel încât să poți rula `make` într-un mediu Docker.

Rularea ca `xlate -C` va lansa un shell cu depozitul git de lucru curent montat.

Citește articolul în japoneză din secțiunea ["SEE ALSO"](#see-also) pentru detalii.

# EMACS

Încarcă fișierul `xlate.el` inclus în depozit pentru a folosi comanda `xlate` din editorul Emacs. Funcția `xlate-region` traduce regiunea dată. Limba implicită este `EN-US` și poți specifica limba apelând-o cu un argument prefix.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Setează cheia ta de autentificare pentru serviciul DeepL.

- OPENAI\_API\_KEY

    Cheie de autentificare OpenAI.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Trebuie să instalezi instrumentele de linie de comandă pentru DeepL și ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt4](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt4)

[App::Greple::xlate::gpt5](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt5)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Imagine de container Docker.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    Biblioteca Python DeepL și comanda CLI.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Biblioteca Python OpenAI

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Interfața de linie de comandă OpenAI

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Vezi manualul **greple** pentru detalii despre modelul de text țintă. Folosește opțiunile **--inside**, **--outside**, **--include**, **--exclude** pentru a limita zona de potrivire.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Poți folosi modulul `-Mupdate` pentru a modifica fișierele în funcție de rezultatul comenzii **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Folosește **sdif** pentru a afișa formatul marcatorilor de conflict alăturat cu opțiunea **-V**.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Modulul Greple **stripe** este folosit prin opțiunea **--xlate-stripe**.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Modul Greple pentru a traduce și înlocui doar părțile necesare cu API-ul DeepL (în japoneză)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Generarea documentelor în 15 limbi cu modulul API DeepL (în japoneză)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Mediu Docker pentru traducere automată cu API-ul DeepL (în japoneză)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
