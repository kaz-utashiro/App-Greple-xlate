# NAME

App::Greple::xlate - modul de suport pentru traducere pentru Greple

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.9909

# DESCRIPTION

Modulul **Greple** **xlate** găsește blocurile de text dorite și le înlocuiește cu textul tradus. În prezent, modulul DeepL (`deepl.pm`) și ChatGPT (`gpt3.pm`) sunt implementate ca un motor back-end. Suportul experimental pentru gpt-4 și gpt-4o este, de asemenea, inclus.

Dacă doriți să traduceți blocuri de text normale într-un document scris în stilul Perl's pod, utilizați comanda **greple** cu modulul `xlate::deepl` și `perl` astfel:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

În această comandă, șirul de modele `^([\w\pP].*\n)+` înseamnă linii consecutive care încep cu litere alfanumerice și de punctuație. Această comandă afișează evidențiată zona care urmează să fie tradusă. Opțiunea **--all** este utilizată pentru a produce întregul text.

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

Datele din formatul markerilor de conflict pot fi vizualizate în stil paralel prin comanda `sdif` cu opțiunea `-V`. Deoarece nu are sens să comparați fiecare șir de caractere, este recomandată opțiunea `--no-cdif`. Dacă nu trebuie să colorați textul, specificați `--no-textcolor` (sau `--no-tc`).

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Prelucrarea se face în unități specificate, dar în cazul unei secvențe de linii multiple de text nevid, acestea sunt convertite împreună într-o singură linie. Această operațiune se efectuează după cum urmează:

- Se elimină spațiul alb de la începutul și sfârșitul fiecărei linii.
- Dacă o linie se termină cu un caracter de punctuație de lățime maximă, concatenarea se face cu linia următoare.
- Dacă o linie se termină cu un caracter de lățime întreagă și următoarea linie începe cu un caracter de lățime întreagă, se concatenează liniile.
- Dacă sfârșitul sau începutul unei linii nu este un caracter de lățime maximă, concatenați-le prin inserarea unui caracter de spațiu.

Datele din cache sunt gestionate pe baza textului normalizat, astfel încât, chiar dacă sunt efectuate modificări care nu afectează rezultatele normalizării, datele de traducere din cache vor fi în continuare eficiente.

Acest proces de normalizare se efectuează numai pentru primul model (al 0-lea) și pentru cel cu număr par. Astfel, dacă sunt specificate două modele după cum urmează, textul care corespunde primului model va fi prelucrat după normalizare și nu va fi efectuat niciun proces de normalizare pentru textul care corespunde celui de-al doilea model.

    greple -Mxlate -E normalized -E not-normalized

Prin urmare, utilizați primul model pentru textul care urmează să fie prelucrat prin combinarea mai multor linii într-o singură linie și utilizați al doilea model pentru textul preformattat. Dacă nu există niciun text care să se potrivească în primul model, utilizați un model care nu se potrivește cu nimic, cum ar fi `(?!)`.

# MASKING

Ocazional, există părți de text pe care nu le doriți traduse. De exemplu, etichetele din fișierele markdown. DeepL sugerează ca, în astfel de cazuri, partea de text care trebuie exclusă să fie convertită în etichete XML, tradusă și apoi restaurată după finalizarea traducerii. Pentru a sprijini acest lucru, este posibil să se specifice părțile care urmează să fie mascate de la traducere.

    --xlate-setopt maskfile=MASKPATTERN

Aceasta va interpreta fiecare linie din fișierul \`MASKPATTERN\` ca o expresie regulată, va traduce șirurile care corespund acesteia și va reveni după procesare. Liniile care încep cu `#` sunt ignorate.

Modelul complex poate fi scris pe mai multe linii cu backslash escpaed newline.

Modul în care textul este transformat prin mascare poate fi văzut prin opțiunea **--xlate-mask**.

Această interfață este experimentală și poate fi modificată în viitor.

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

    În acest moment, sunt disponibile următoarele motoare

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4.1
    - **gpt4o**: gpt-4o-mini

        Interfața lui **gpt-4o** este instabilă și nu se poate garanta că funcționează corect în acest moment.

- **--xlate-labor**
- **--xlabor**

    În loc să apelați motorul de traducere, se așteaptă să lucrați pentru. După pregătirea textului care urmează să fie tradus, acestea sunt copiate în clipboard. Se așteaptă să le lipiți în formular, să copiați rezultatul în clipboard și să apăsați return.

- **--xlate-to** (Default: `EN-US`)

    Specificați limba țintă. Puteți obține limbile disponibile prin comanda `deepl languages` atunci când se utilizează motorul **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Specificați formatul de ieșire pentru textul original și cel tradus.

    Următoarele formate, altele decât `xtxt`, presupun că partea care urmează să fie tradusă este o colecție de linii. De fapt, este posibil să se traducă doar o parte a unei linii, dar specificarea unui alt format decât `xtxt` nu va produce rezultate semnificative.

    - **conflict**, **cm**

        Textul original și cel convertit sunt tipărite în formatul de marker de conflict [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Puteți recupera fișierul original prin următoarea comandă [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Textul original și cel tradus sunt editate într-un stil de container personalizat markdown.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Textul de mai sus va fi tradus în următoarele în HTML.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Numărul de două puncte este de 7 în mod implicit. Dacă specificați o secvență de două puncte precum `:::::`, aceasta este utilizată în locul celor 7 două puncte.

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
    - **space+**

        Textul original și cel convertit sunt tipărite separate de o singură linie albă. Pentru `space+`, se tipărește și o linie nouă după textul convertit.

    - **xtxt**

        Dacă formatul este `xtxt` (text tradus) sau necunoscut, se tipărește numai textul tradus.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Specificați lungimea maximă a textului care urmează să fie trimis la API deodată. Valoarea implicită este setată ca pentru serviciul de cont gratuit DeepL: 128K pentru API (**--xlate**) și 5000 pentru interfața clipboard (**--xlate-labor**). Este posibil să puteți modifica aceste valori dacă utilizați serviciul Pro.

- **--xlate-maxline**=_n_ (Default: 0)

    Specificați numărul maxim de linii de text care urmează să fie trimise simultan către API.

    Setați această valoare la 1 dacă doriți să traduceți un rând pe rând. Această opțiune are prioritate față de opțiunea `--xlate-maxlen`.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Vedeți rezultatul traducerii în timp real în ieșirea STDERR.

- **--xlate-stripe**

    Utilizați modulul [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) pentru a afișa partea corespunzătoare prin metoda zebrei. Acest lucru este util atunci când părțile potrivite sunt conectate spate în spate.

    Paleta de culori este comutată în funcție de culoarea de fundal a terminalului. Dacă doriți să specificați explicit, puteți utiliza **--xlate-stripe-light** sau **--xlate-stripe-dark**.

- **--xlate-mask**

    Efectuați funcția de mascare și afișați textul convertit ca atare, fără restaurare.

- **--match-all**

    Setați întregul text al fișierului ca zonă țintă.

- **--lineify-cm**
- **--lineify-colon**

    În cazul formatelor `cm` și `colon`, rezultatul este împărțit și formatat linie cu linie. Prin urmare, dacă trebuie tradusă doar o parte a unei linii, rezultatul așteptat nu poate fi obținut. Aceste filtre fixează ieșirea care este coruptă prin traducerea unei părți a unei linii în ieșire normală linie cu linie.

    În implementarea actuală, dacă mai multe părți ale unei linii sunt traduse, acestea sunt emise ca linii independente.

# CACHE OPTIONS

Modulul **xlate** poate stoca în memoria cache textul traducerii pentru fiecare fișier și îl poate citi înainte de execuție, pentru a elimina costurile suplimentare de solicitare a serverului. Cu strategia implicită de cache `auto`, acesta păstrează datele din cache numai atunci când fișierul cache există pentru fișierul țintă.

Utilizați **--xlate-cache=clear** pentru a iniția gestionarea cache-ului sau pentru a curăța toate datele cache existente. Odată executat cu această opțiune, se va crea un nou fișier cache dacă nu există unul și apoi se va actualiza automat.

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
- **--xlate-update**

    Această opțiune forțează actualizarea fișierului cache chiar dacă nu este necesar.

# COMMAND LINE INTERFACE

Puteți utiliza cu ușurință acest modul din linia de comandă folosind comanda `xlate` inclusă în distribuție. Consultați pagina de manual `xlate` pentru utilizare.

Comanda `xlate` funcționează de comun acord cu mediul Docker, astfel încât, chiar dacă nu aveți nimic instalat la îndemână, îl puteți utiliza atâta timp cât Docker este disponibil. Utilizați opțiunea `-D` sau `-C`.

De asemenea, deoarece sunt furnizate makefile-uri pentru diferite stiluri de documente, traducerea în alte limbi este posibilă fără specificații speciale. Utilizați opțiunea `-M`.

De asemenea, puteți combina opțiunile Docker și `make` astfel încât să puteți rula `make` într-un mediu Docker.

Executarea ca `xlate -C` va lansa un shell cu depozitul git de lucru curent montat.

Citiți articolul japonez din secțiunea ["SEE ALSO"](#see-also) pentru detalii.

# EMACS

Încărcați fișierul `xlate.el` inclus în depozit pentru a utiliza comanda `xlate` din editorul Emacs. Funcția `xlate-region` traduce regiunea dată. Limba implicită este `EN-US` și puteți specifica limba invocând-o cu argumentul prefix.

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

Trebuie să instalați instrumentele de linie de comandă pentru DeepL și ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl).

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Imagine container Docker.

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

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Utilizarea modulului Greple **stripe** prin opțiunea **--xlate-stripe**.

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

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
