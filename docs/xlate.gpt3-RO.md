# NAME

App::Greple::xlate - modul de suport pentru traducere pentru greple

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.9908

# DESCRIPTION

Modulul **Greple** **xlate** găsește blocurile de text dorite și le înlocuiește cu textul tradus. În prezent, modulul DeepL (`deepl.pm`) și ChatGPT (`gpt3.pm`) sunt implementate ca motoare de bază. Suportul experimental pentru gpt-4 și gpt-4o este, de asemenea, inclus.

Dacă doriți să traduceți blocurile de text normale dintr-un document scris în stilul pod al Perl, utilizați comanda **greple** cu modulul `xlate::deepl` și `perl` în felul următor:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

În această comandă, șirul de tipar `^([\w\pP].*\n)+` înseamnă linii consecutive care încep cu litere alfanumerice și de punctuație. Această comandă arată zona care trebuie tradusă evidențiată. Opțiunea **--all** este folosită pentru a produce întregul text.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Apoi adăugați opțiunea `--xlate` pentru a traduce zona selectată. Apoi, va găsi secțiunile dorite și le va înlocui cu rezultatul comenzii **deepl**.

În mod implicit, textul original și textul tradus sunt afișate în formatul "conflict marker", compatibil cu [git(1)](http://man.he.net/man1/git). Utilizând formatul `ifdef`, puteți obține partea dorită cu ușurință folosind comanda [unifdef(1)](http://man.he.net/man1/unifdef). Formatul de ieșire poate fi specificat prin opțiunea **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Dacă doriți să traduceți întregul text, utilizați opțiunea **--match-all**. Aceasta este o scurtătură pentru a specifica modelul `(?s).+` care se potrivește cu întregul text.

Formatul datelor pentru markerul de conflict poate fi vizualizat în stil side-by-side folosind comanda `sdif` cu opțiunea `-V`. Deoarece nu are sens să comparăm pe baza fiecărui șir de caractere, se recomandă opțiunea `--no-cdif`. Dacă nu aveți nevoie să colorați textul, specificați `--no-textcolor` (sau `--no-tc`).

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Procesarea se face în unități specificate, dar în cazul unei secvențe de mai multe linii de text ne-gol, acestea sunt convertite împreună într-o singură linie. Această operație se efectuează astfel:

- Se elimină spațiile albe de la început și sfârșitul fiecărei linii.
- Dacă o linie se încheie cu un caracter de punctuație de lățime completă, concatenează cu linia următoare.
- Dacă o linie se termină cu un caracter de lățime completă și linia următoare începe cu un caracter de lățime completă, se concatenează liniile.
- Dacă fie sfârșitul sau începutul unei linii nu este un caracter de lățime completă, acestea sunt concatenate prin inserarea unui caracter spațiu.

Datele cache sunt gestionate pe baza textului normalizat, astfel încât chiar dacă se fac modificări care nu afectează rezultatele normalizării, datele de traducere cache vor fi în continuare eficiente.

Acest proces de normalizare este efectuat doar pentru primul (0-lea) și pentru modelul cu număr par. Prin urmare, dacă sunt specificate două modele după cum urmează, textul care se potrivește cu primul model va fi procesat după normalizare, iar niciun proces de normalizare nu va fi efectuat pe textul care se potrivește cu al doilea model.

    greple -Mxlate -E normalized -E not-normalized

Prin urmare, folosiți primul model pentru textul care urmează să fie procesat prin combinarea mai multor linii într-o singură linie, și folosiți al doilea model pentru textul preformatat. Dacă nu există text de potrivit în primul model, folosiți un model care nu se potrivește cu nimic, cum ar fi `(?!)`.

# MASKING

Uneori, există părți ale textului pe care nu dorești să le traduci. De exemplu, tag-urile din fișierele markdown. DeepL sugerează că în astfel de cazuri, partea de text de exclus să fie convertită în tag-uri XML, tradusă, și apoi restaurată după ce traducerea este completă. Pentru a susține acest lucru, este posibil să specifici părțile care trebuie mascate de la traducere.

    --xlate-setopt maskfile=MASKPATTERN

Acesta va interpreta fiecare linie a fișierului \`MASKPATTERN\` ca o expresie regulată, va traduce șirurile care se potrivesc cu ea, și va reveni la forma inițială după procesare. Liniile care încep cu `#` sunt ignorate.

Un model complex poate fi scris pe mai multe linii cu o linie nouă scrisă cu backslash.

Cum este transformat textul prin mascare poate fi văzut prin opțiunea **--xlate-mask**.

Această interfață este experimentală și este supusă unor posibile schimbări în viitor.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Invocați procesul de traducere pentru fiecare zonă potrivită.

    Fără această opțiune, **greple** se comportă ca o comandă de căutare normală. Deci puteți verifica care parte a fișierului va fi supusă traducerii înainte de a invoca lucrul efectiv.

    Rezultatul comenzii este trimis la ieșirea standard, deci redirecționați-l într-un fișier dacă este necesar sau luați în considerare utilizarea modulului [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    Opțiunea **--xlate** apelează opțiunea **--xlate-color** cu opțiunea **--color=never**.

    Cu opțiunea **--xlate-fold**, textul convertit este pliat în funcție de lățimea specificată. Lățimea implicită este de 70 și poate fi setată prin opțiunea **--xlate-fold-width**. Patru coloane sunt rezervate pentru operația run-in, astfel încât fiecare linie poate conține cel mult 74 de caractere.

- **--xlate-engine**=_engine_

    Specifică motorul de traducere care trebuie utilizat. Dacă specifici direct modulul motorului, cum ar fi `-Mxlate::deepl`, nu este nevoie să folosești această opțiune.

    În acest moment, următoarele motoare sunt disponibile

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4-turbo
    - **gpt4o**: gpt-4o-mini

        Interfața lui **gpt-4o** este instabilă și nu poate fi garantată că funcționează corect în acest moment.

- **--xlate-labor**
- **--xlabor**

    În loc să apelați motorul de traducere, se așteaptă să lucrați pentru el. După ce ați pregătit textul pentru a fi tradus, acesta este copiat în clipboard. Se așteaptă să îl lipiți în formular, să copiați rezultatul în clipboard și să apăsați Enter.

- **--xlate-to** (Default: `EN-US`)

    Specificați limba țintă. Puteți obține limbile disponibile prin comanda `deepl languages` atunci când utilizați motorul **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Specificați formatul de ieșire pentru textul original și cel tradus.

    Formatele următoare, în afara `xtxt`, presupun că partea de tradus este o colecție de linii. De fapt, este posibil să traduci doar o porțiune dintr-o linie, iar specificarea unui format diferit de `xtxt` nu va produce rezultate semnificative.

    - **conflict**, **cm**

        Textul original și cel convertit sunt tipărite în formatul de marcare a conflictelor [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Puteți recupera fișierul original cu următoarea comandă [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        \`\`\`html

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        &lt;div class="original">

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Numărul de două puncte este 7 în mod implicit. Dacă specifici o secvență de două puncte ca `:::::`, aceasta este folosită în loc de 7 două puncte.

    - **ifdef**

        Textul original și cel convertit sunt tipărite în formatul [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Puteți recupera doar textul japonez cu comanda **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Original text:

    - **xtxt**

        Dacă formatul este `xtxt` (text tradus) sau necunoscut, se tipărește doar textul tradus.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Traduceți următorul text în limba română, linie cu linie.

- **--xlate-maxline**=_n_ (Default: 0)

    Specifică numărul maxim de linii de text care vor fi trimise la API odată.

    Setează această valoare la 1 dacă vrei să traduci câte o linie pe rând. Această opțiune primește prioritate față de opțiunea `--xlate-maxlen`.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Vedeți rezultatul traducerii în timp real în ieșirea STDERR.

- **--xlate-stripe**

    Folosiți modulul [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) pentru a arăta partea potrivită într-un mod cu dungi de zebra. Acest lucru este util atunci când părțile potrivite sunt conectate una după alta.

    Paleta de culori se schimbă în funcție de culoarea de fundal a terminalului. Dacă doriți să specificați explicit, puteți folosi **--xlate-stripe-light** sau **--xlate-stripe-dark**.

- **--xlate-mask**

    Efectuați funcția de mascare și afișați textul convertit așa cum este fără restaurare.

- **--match-all**

    Setați întregul text al fișierului ca zonă țintă.

# CACHE OPTIONS

Modulul **xlate** poate stoca textul tradus în cache pentru fiecare fișier și îl poate citi înainte de execuție pentru a elimina costurile de întrebare către server. Cu strategia implicită de cache `auto`, acesta menține datele cache doar atunci când fișierul cache există pentru fișierul țintă.

Folosește **--xlate-cache=clear** pentru a iniția gestionarea cache-ului sau pentru a curăța toate datele de cache existente. Odată ce este executat cu această opțiune, un nou fișier de cache va fi creat dacă nu există deja și apoi va fi întreținut automat ulterior.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Mențineți fișierul cache dacă există.

    - `create`

        Creați un fișier cache gol și ieșiți.

    - `always`, `yes`, `1`

        Mențineți cache-ul oricum, atâta timp cât ținta este un fișier normal.

    - `clear`

        Ștergeți mai întâi datele cache.

    - `never`, `no`, `0`

        Nu utilizați niciodată fișierul cache chiar dacă există.

    - `accumulate`

        În mod implicit, datele neutilizate sunt eliminate din fișierul cache. Dacă nu doriți să le eliminați și să le păstrați în fișier, utilizați `accumulate`.
- **--xlate-update**

    Această opțiune forțează actualizarea fișierului de cache chiar dacă nu este necesar.

# COMMAND LINE INTERFACE

Puteți folosi cu ușurință acest modul din linia de comandă folosind comanda `xlate` inclusă în distribuție. Consultați pagina de manual `xlate` pentru utilizare.

Comanda `xlate` funcționează în concordanță cu mediul Docker, deci chiar dacă nu aveți nimic instalat la îndemână, puteți să-l utilizați atâta timp cât Docker este disponibil. Utilizați opțiunea `-D` sau `-C`.

De asemenea, deoarece sunt furnizate fișiere make pentru diferite stiluri de documente, traducerea în alte limbi este posibilă fără specificații speciale. Utilizați opțiunea `-M`.

De asemenea, puteți combina opțiunile Docker și `make` astfel încât să puteți rula `make` într-un mediu Docker.

Rularea ca `xlate -C` va lansa un shell cu depozitul git de lucru curent montat.

Citiți articolul în limba japoneză din secțiunea "VEZI ȘI" pentru detalii.

# EMACS

Încărcați fișierul `xlate.el` inclus în depozit pentru a utiliza comanda `xlate` din editorul Emacs. Funcția `xlate-region` traduce regiunea dată. Limba implicită este `EN-US` și puteți specifica limba prin invocarea acesteia cu un argument de prefix.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Setați cheia de autentificare pentru serviciul DeepL.

- OPENAI\_API\_KEY

    Cheia de autentificare OpenAI.

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

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Imaginea containerului Docker.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    Bibliotecă Python DeepL și comandă CLI.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Biblioteca Python OpenAI

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Interfața de linie de comandă OpenAI

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Consultați manualul **greple** pentru detalii despre modelul de text țintă. Utilizați opțiunile **--inside**, **--outside**, **--include**, **--exclude** pentru a limita zona de potrivire.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Puteți utiliza modulul `-Mupdate` pentru a modifica fișierele în funcție de rezultatul comenzii **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Utilizați **sdif** pentru a afișa formatul markerului de conflict alături de opțiunea **-V**.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Modulul Greple **stripe** folosit de opțiunea **--xlate-stripe**.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Modulul Greple pentru a traduce și înlocui doar părțile necesare cu ajutorul API-ului DeepL (în japoneză)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Generarea documentelor în 15 limbi cu modulul DeepL API (în japoneză)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Mediu Docker de traducere automată cu ajutorul API-ului DeepL (în japoneză)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
