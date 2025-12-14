# NAME

App::Greple::xlate - modul de suport pentru traducere pentru greple

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

    greple -Mxlate::gpt4 --xlate pattern target-file

    greple -Mxlate::gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

# VERSION

Version 0.9920

# DESCRIPTION

**Greple** **xlate** modulul găsește blocurile de text dorite și le înlocuiește cu textul tradus. În prezent, modulele DeepL (`deepl.pm`), ChatGPT 4.1 (`gpt4.pm`) și GPT-5 (`gpt5.pm`) sunt implementate ca motoare back-end.

Dacă doriți să traduceți blocuri normale de text într-un document scris în stilul pod al Perl, folosiți comanda **greple** cu `xlate::deepl` și modulul `perl` astfel:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

În această comandă, șirul de pattern `^([\w\pP].*\n)+` înseamnă linii consecutive care încep cu litere alfanumerice sau semne de punctuație. Această comandă evidențiază zona care urmează să fie tradusă. Opțiunea **--all** este folosită pentru a produce întregul text.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Apoi adăugați opțiunea `--xlate` pentru a traduce zona selectată. Astfel, va găsi secțiunile dorite și le va înlocui cu rezultatul comenzii **deepl**.

În mod implicit, textul original și cel tradus sunt tipărite în formatul „conflict marker” compatibil cu [git(1)](http://man.he.net/man1/git). Folosind formatul `ifdef`, puteți obține partea dorită cu comanda [unifdef(1)](http://man.he.net/man1/unifdef) cu ușurință. Formatul de ieșire poate fi specificat cu opțiunea **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Dacă doriți să traduceți întregul text, folosiți opțiunea **--match-all**. Aceasta este o scurtătură pentru a specifica pattern-ul `(?s).+` care se potrivește cu întregul text.

Datele în format de marcator de conflict pot fi vizualizate în stil side-by-side prin comanda [sdif](https://metacpan.org/pod/App%3A%3Asdif) cu opțiunea `-V`. Deoarece nu are sens să comparați pe bază de șir, se recomandă opțiunea `--no-cdif`. Dacă nu aveți nevoie să colorați textul, specificați `--no-textcolor` (sau `--no-tc`).

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Procesarea se face în unități specificate, dar în cazul unei secvențe de mai multe linii de text ne-goale, acestea sunt convertite împreună într-o singură linie. Această operațiune se realizează astfel:

- Se elimină spațiile albe de la începutul și sfârșitul fiecărei linii.
- Dacă o linie se termină cu un caracter de punctuație de lățime completă, se concatenează cu linia următoare.
- Dacă o linie se termină cu un caracter de lățime completă și linia următoare începe cu un caracter de lățime completă, liniile se concatenează.
- Dacă fie sfârșitul, fie începutul unei linii nu este un caracter de lățime completă, se concatenează prin inserarea unui spațiu.

Datele din cache sunt gestionate pe baza textului normalizat, astfel încât chiar dacă se fac modificări care nu afectează rezultatele normalizării, datele de traducere din cache vor rămâne valabile.

Acest proces de normalizare se efectuează doar pentru primul (al 0-lea) și pentru pattern-urile cu număr par. Astfel, dacă sunt specificate două pattern-uri ca mai jos, textul care se potrivește cu primul pattern va fi procesat după normalizare, iar pe textul care se potrivește cu al doilea pattern nu se va efectua nicio normalizare.

    greple -Mxlate -E normalized -E not-normalized

Prin urmare, folosiți primul pattern pentru textul care trebuie procesat prin combinarea mai multor linii într-una singură și folosiți al doilea pattern pentru textul pre-formatat. Dacă nu există text care să se potrivească cu primul pattern, folosiți un pattern care nu se potrivește cu nimic, cum ar fi `(?!)`.

# MASKING

Ocazional, există părți din text pe care nu doriți să le traduceți. De exemplu, etichetele din fișierele markdown. DeepL sugerează ca, în astfel de cazuri, partea de text care trebuie exclusă să fie convertită în etichete XML, tradusă, apoi restaurată după finalizarea traducerii. Pentru a susține acest lucru, este posibil să specificați părțile care trebuie mascate de la traducere.

    --xlate-setopt maskfile=MASKPATTERN

Acest lucru va interpreta fiecare linie din fișierul \`MASKPATTERN\` ca o expresie regulată, va traduce șirurile care se potrivesc și va reveni după procesare. Liniile care încep cu `#` sunt ignorate.

Un model complex poate fi scris pe mai multe linii cu newline scăpat cu backslash.

Modul în care textul este transformat prin mascarea poate fi văzut cu opțiunea **--xlate-mask**.

Această interfață este experimentală și poate suferi modificări în viitor.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Invocați procesul de traducere pentru fiecare zonă potrivită.

    Fără această opțiune, **greple** se comportă ca o comandă de căutare normală. Astfel, puteți verifica ce parte a fișierului va fi supusă traducerii înainte de a lansa efectiv procesul.

    Rezultatul comenzii este trimis la ieșirea standard, deci redirecționați către un fișier dacă este necesar sau luați în considerare utilizarea modulului [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    Opțiunea **--xlate** apelează opțiunea **--xlate-color** cu opțiunea **--color=never**.

    Cu opțiunea **--xlate-fold**, textul convertit este împărțit pe lățimea specificată. Lățimea implicită este 70 și poate fi setată cu opțiunea **--xlate-fold-width**. Patru coloane sunt rezervate pentru operațiunea run-in, astfel încât fiecare linie poate conține cel mult 74 de caractere.

- **--xlate-engine**=_engine_

    Specifică motorul de traducere care va fi folosit. Dacă specificați direct modulul motorului, cum ar fi `-Mxlate::deepl`, nu este necesar să folosiți această opțiune.

    În acest moment, următoarele motoare sunt disponibile

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4.1
    - **gpt4o**: gpt-4o-mini

        Interfața **gpt-4o** este instabilă și nu se poate garanta că funcționează corect în acest moment.

    - **gpt5**: gpt-5

- **--xlate-labor**
- **--xlabor**

    În loc să apelați motorul de traducere, se așteaptă să lucrați manual. După pregătirea textului de tradus, acesta este copiat în clipboard. Se așteaptă să îl lipiți în formular, să copiați rezultatul în clipboard și să apăsați return.

- **--xlate-to** (Default: `EN-US`)

    Specificați limba țintă. Puteți obține limbile disponibile cu comanda `deepl languages` atunci când folosiți motorul **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Specificați formatul de ieșire pentru textul original și cel tradus.

    Următoarele formate, altele decât `xtxt`, presupun că partea de tradus este o colecție de linii. De fapt, este posibil să traduceți doar o porțiune dintr-o linie, dar specificarea unui format diferit de `xtxt` nu va produce rezultate semnificative.

    - **conflict**, **cm**

        Textul original și cel convertit sunt tipărite în formatul marker de conflict [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Puteți recupera fișierul original cu următoarea comandă [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Textul original și cel tradus sunt afișate în stilul container personalizat al markdown-ului.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Textul de mai sus va fi tradus astfel în HTML.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Numărul de două puncte este 7 în mod implicit. Dacă specificați o secvență de două puncte ca `:::::`, aceasta va fi folosită în loc de 7 două puncte.

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

        Textul original și cel convertit sunt tipărite separate printr-un singur rând gol.

    - **xtxt**

        Pentru `space+`, de asemenea, se afișează un rând nou după textul convertit.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Dacă formatul este `xtxt` (text tradus) sau necunoscut, se afișează doar textul tradus.

- **--xlate-maxline**=_n_ (Default: 0)

    Specificați lungimea maximă a textului care poate fi trimis la API odată. Valoarea implicită este setată ca pentru serviciul gratuit DeepL: 128K pentru API (**--xlate**) și 5000 pentru interfața clipboard (**--xlate-labor**). Este posibil să puteți schimba aceste valori dacă folosiți serviciul Pro.

    Specificați numărul maxim de linii de text care pot fi trimise la API odată.

- **--xlate-prompt**=_text_

    Specificați un prompt personalizat care va fi trimis motorului de traducere. Această opțiune este disponibilă doar atunci când utilizați motoarele ChatGPT (gpt3, gpt4, gpt4o). Puteți personaliza comportamentul traducerii oferind instrucțiuni specifice modelului AI. Dacă promptul conține `%s`, acesta va fi înlocuit cu numele limbii țintă.

- **--xlate-context**=_text_

    Specificați informații suplimentare de context care vor fi trimise motorului de traducere. Această opțiune poate fi folosită de mai multe ori pentru a furniza mai multe șiruri de context. Informațiile de context ajută motorul de traducere să înțeleagă fundalul și să producă traduceri mai precise.

- **--xlate-glossary**=_glossary_

    Specificați un ID de glosar care va fi folosit pentru traducere. Această opțiune este disponibilă doar atunci când utilizați motorul DeepL. ID-ul de glosar trebuie obținut din contul dumneavoastră DeepL și asigură traducerea consecventă a anumitor termeni.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Setați această valoare la 1 dacă doriți să traduceți o linie odată. Această opțiune are prioritate față de opțiunea `--xlate-maxlen`.

- **--xlate-stripe**

    Vedeți rezultatul traducerii în timp real în ieșirea STDERR.

    Folosiți modulul [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) pentru a evidenția partea potrivită în stil zebra striping. Acest lucru este util când părțile potrivite sunt conectate una după alta.

- **--xlate-mask**

    Paleta de culori este comutată în funcție de culoarea de fundal a terminalului. Dacă doriți să specificați explicit, puteți folosi **--xlate-stripe-light** sau **--xlate-stripe-dark**.

- **--match-all**

    Efectuați funcția de mascarea și afișați textul convertit așa cum este, fără restaurare.

- **--lineify-cm**
- **--lineify-colon**

    În cazul formatelor `cm` și `colon`, ieșirea este împărțită și formatată linie cu linie. Prin urmare, dacă doar o parte a unei linii trebuie tradusă, rezultatul așteptat nu poate fi obținut. Aceste filtre corectează ieșirea care este coruptă prin traducerea unei părți dintr-o linie într-o ieșire normală, linie cu linie.

    În implementarea actuală, dacă mai multe părți ale unei linii sunt traduse, acestea sunt afișate ca linii independente.

# CACHE OPTIONS

Setați întregul text al fișierului ca zonă țintă.

Modulul **xlate** poate stoca textul tradus în cache pentru fiecare fișier și îl poate citi înainte de execuție pentru a elimina timpul de așteptare la server. Cu strategia implicită de cache `auto`, menține datele în cache doar când există un fișier cache pentru fișierul țintă.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Folosiți **--xlate-cache=clear** pentru a iniția gestionarea cache-ului sau pentru a curăța toate datele cache existente. Odată executat cu această opțiune, va fi creat un fișier cache nou dacă nu există deja și apoi va fi menținut automat ulterior.

    - `create`

        Menține fișierul cache dacă există.

    - `always`, `yes`, `1`

        Creează un fișier cache gol și iese.

    - `clear`

        Menține cache-ul oricum, atâta timp cât ținta este un fișier normal.

    - `never`, `no`, `0`

        Șterge mai întâi datele din cache.

    - `accumulate`

        Nu folosi niciodată fișierul cache, chiar dacă există.
- **--xlate-update**

    Prin comportamentul implicit, datele neutilizate sunt eliminate din fișierul cache. Dacă nu doriți să le eliminați și să le păstrați în fișier, folosiți `accumulate`.

# COMMAND LINE INTERFACE

Această opțiune forțează actualizarea fișierului cache chiar dacă nu este necesar.

Comanda `xlate` suportă opțiuni lungi în stil GNU, cum ar fi `--to-lang`, `--from-lang`, `--engine` și `--file`. Folosiți `xlate -h` pentru a vedea toate opțiunile disponibile.

Puteți folosi cu ușurință acest modul din linia de comandă folosind comanda `xlate` inclusă în distribuție. Consultați pagina de manual `xlate` pentru utilizare.

Operațiunile Docker sunt gestionate de scriptul `dozo`, care poate fi folosit și ca o comandă de sine stătătoare. Scriptul `dozo` suportă fișierul de configurare `.dozorc` pentru setările persistente ale containerului.

Comanda `xlate` funcționează în colaborare cu mediul Docker, astfel încât chiar dacă nu aveți nimic instalat local, o puteți folosi atâta timp cât Docker este disponibil. Folosiți opțiunea `-D` sau `-C`.

De asemenea, deoarece sunt furnizate makefile-uri pentru diverse stiluri de documente, traducerea în alte limbi este posibilă fără specificații speciale. Folosiți opțiunea `-M`.

Puteți combina și opțiunile Docker și `make` astfel încât să puteți rula `make` într-un mediu Docker.

Rularea ca `xlate -C` va lansa un shell cu depozitul git curent montat.

# EMACS

Încarcă fișierul `xlate.el` inclus în depozit pentru a folosi comanda `xlate` din editorul Emacs. 

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Funcția `xlate-region` traduce regiunea dată. Limba implicită este `EN-US` și poți specifica limba invocând-o cu argument prefix.

- OPENAI\_API\_KEY

    Setează cheia ta de autentificare pentru serviciul DeepL.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Cheie de autentificare OpenAI.

Trebuie să instalezi unelte de linie de comandă pentru DeepL și ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

# SEE ALSO

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::gpt4](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt4)

[App::Greple::xlate::gpt5](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt5)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    [App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    Biblioteca `getoptlong.sh` este folosită pentru analiza opțiunilor în scripturile `xlate` și `dozo`.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    Imagine container Docker.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Bibliotecă Python DeepL și comandă CLI.

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Bibliotecă Python OpenAI

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Interfață de linie de comandă OpenAI

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Vezi manualul **greple** pentru detalii despre modelul textului țintă. Folosește opțiunile **--inside**, **--outside**, **--include**, **--exclude** pentru a limita zona de potrivire.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Poți folosi modulul `-Mupdate` pentru a modifica fișierele în funcție de rezultatul comenzii **greple**.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Folosește **sdif** pentru a afișa formatul markerului de conflict alăturat cu opțiunea **-V**.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Modulul Greple **stripe** se folosește cu opțiunea **--xlate-stripe**.

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Modul Greple pentru a traduce și înlocui doar părțile necesare cu API-ul DeepL (în japoneză)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Generarea documentelor în 15 limbi cu modulul API DeepL (în japoneză)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
