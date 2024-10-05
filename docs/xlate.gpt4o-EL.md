# NAME

<App::Greple::xlate - υποστηρικτικό μοντέλο μετάφρασης για το greple>

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.37

# DESCRIPTION

<**Greple** **xlate** μοντέλο βρίσκει τα επιθυμητά μπλοκ κειμένου και τα αντικαθιστά με το μεταφρασμένο κείμενο. Αυτή τη στιγμή, τα μοντέλα DeepL (`deepl.pm`) και ChatGPT (`gpt3.pm`) έχουν υλοποιηθεί ως μηχανή back-end. Πειραματική υποστήριξη για gpt-4 και gpt-4o περιλαμβάνεται επίσης.>

<Αν θέλετε να μεταφράσετε κανονικά μπλοκ κειμένου σε ένα έγγραφο γραμμένο στο στυλ pod του Perl, χρησιμοποιήστε την εντολή **greple** με τα `xlate::deepl` και `perl` μοντέλα όπως αυτό:>

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

<Σε αυτή την εντολή, η συμβολοσειρά μοτίβου `^(\w.*\n)+` σημαίνει διαδοχικές γραμμές που ξεκινούν με αλφα-αριθμητικό γράμμα. Αυτή η εντολή δείχνει την περιοχή που πρέπει να μεταφραστεί επισημασμένη. Η επιλογή **--all** χρησιμοποιείται για να παραχθεί ολόκληρο το κείμενο.>

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

<Στη συνέχεια, προσθέστε την επιλογή `--xlate` για να μεταφράσετε την επιλεγμένη περιοχή. Έτσι, θα βρει τις επιθυμητές ενότητες και θα τις αντικαταστήσει με την έξοδο της εντολής **deepl**.>

<Από προεπιλογή, το πρωτότυπο και το μεταφρασμένο κείμενο εκτυπώνονται σε μορφή "σημείου σύγκρουσης" συμβατή με το [git(1)](http://man.he.net/man1/git). Χρησιμοποιώντας τη μορφή `ifdef`, μπορείτε να αποκτήσετε το επιθυμητό μέρος με την εντολή [unifdef(1)](http://man.he.net/man1/unifdef) εύκολα. Η μορφή εξόδου μπορεί να καθοριστεί με την επιλογή **--xlate-format**.>

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

<Αν θέλετε να μεταφράσετε ολόκληρο το κείμενο, χρησιμοποιήστε την επιλογή **--match-all**. Αυτό είναι μια συντόμευση για να καθορίσετε το μοτίβο `(?s).+` που ταιριάζει με ολόκληρο το κείμενο.>

<Δεδομένα μορφής σημείου σύγκρουσης μπορούν να προβληθούν σε στυλ παράλληλης προβολής με την εντολή `sdif` με την επιλογή `-V`. Δεδομένου ότι δεν έχει νόημα να συγκρίνουμε σε βάση ανά συμβολοσειρά, προτείνεται η επιλογή `--no-cdif`. Αν δεν χρειάζεστε να χρωματίσετε το κείμενο, καθορίστε `--no-textcolor` (ή `--no-tc`).>

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

<Η επεξεργασία γίνεται σε καθορισμένες μονάδες, αλλά στην περίπτωση μιας ακολουθίας πολλαπλών γραμμών μη κενών κειμένων, αυτές μετατρέπονται μαζί σε μία μόνο γραμμή. Αυτή η λειτουργία εκτελείται ως εξής:>

- <Αφαιρέστε τα κενά στην αρχή και στο τέλος κάθε γραμμής.>
- <Αν μια γραμμή τελειώνει με χαρακτήρα πλήρους πλάτους, συνδυάστε την με την επόμενη γραμμή.>
- <Αν μια γραμμή τελειώνει με χαρακτήρα πλήρους πλάτους και η επόμενη γραμμή ξεκινά με χαρακτήρα πλήρους πλάτους, συνδυάστε τις γραμμές.>
- <Αν είτε το τέλος είτε η αρχή μιας γραμμής δεν είναι χαρακτήρας πλήρους πλάτους, συνδυάστε τις εισάγοντας έναν χαρακτήρα κενών.>

<Δεδομένα cache διαχειρίζονται με βάση το κανονικοποιημένο κείμενο, οπότε ακόμη και αν γίνουν τροποποιήσεις που δεν επηρεάζουν τα αποτελέσματα κανονικοποίησης, τα δεδομένα μετάφρασης που έχουν αποθηκευτεί θα είναι ακόμα αποτελεσματικά.>

<Αυτή η διαδικασία κανονικοποίησης εκτελείται μόνο για το πρώτο (0ο) και τα ζυγά μοτίβα. Έτσι, αν δύο μοτίβα καθοριστούν ως εξής, το κείμενο που ταιριάζει με το πρώτο μοτίβο θα υποβληθεί σε επεξεργασία μετά την κανονικοποίηση, και καμία διαδικασία κανονικοποίησης δεν θα εκτελείται στο κείμενο που ταιριάζει με το δεύτερο μοτίβο.>

    greple -Mxlate -E normalized -E not-normalized

<Επομένως, χρησιμοποιήστε το πρώτο μοτίβο για κείμενο που πρόκειται να υποβληθεί σε επεξεργασία συνδυάζοντας πολλές γραμμές σε μία μόνο γραμμή, και χρησιμοποιήστε το δεύτερο μοτίβο για προ-μορφοποιημένο κείμενο. Αν δεν υπάρχει κείμενο για να ταιριάξει στο πρώτο μοτίβο, τότε ένα μοτίβο που δεν ταιριάζει με τίποτα, όπως το `(?!)`.>

# MASKING

Κατά καιρούς, υπάρχουν μέρη κειμένου που δεν θέλετε να μεταφραστούν. Για παράδειγμα, ετικέτες σε αρχεία markdown. Ο DeepL προτείνει ότι σε τέτοιες περιπτώσεις, το μέρος του κειμένου που πρέπει να εξαιρεθεί να μετατραπεί σε ετικέτες XML, να μεταφραστεί και στη συνέχεια να αποκατασταθεί μετά την ολοκλήρωση της μετάφρασης. Για να υποστηριχθεί αυτό, είναι δυνατόν να καθοριστούν τα μέρη που θα καλυφθούν από τη μετάφραση.

    --xlate-setopt maskfile=MASKPATTERN

Αυτό θα ερμηνεύσει κάθε γραμμή του αρχείου \`MASKPATTERN\` ως κανονική έκφραση, θα μεταφράσει τις συμβολοσειρές που ταιριάζουν σε αυτήν και θα επιστρέψει μετά την επεξεργασία. Οι γραμμές που αρχίζουν με `#` αγνοούνται.

Αυτή η διεπαφή είναι πειραματική και υπόκειται σε αλλαγές στο μέλλον.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Καλέστε τη διαδικασία μετάφρασης για κάθε ταιριαστή περιοχή.

    Χωρίς αυτή την επιλογή, **greple** συμπεριφέρεται ως κανονική εντολή αναζήτησης. Έτσι μπορείτε να ελέγξετε ποιο μέρος του αρχείου θα είναι αντικείμενο της μετάφρασης πριν καλέσετε την πραγματική εργασία.

    Το αποτέλεσμα της εντολής πηγαίνει στην τυπική έξοδο, οπότε ανακατευθύνετε σε αρχείο αν είναι απαραίτητο, ή σκεφτείτε να χρησιμοποιήσετε το [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) module.

    Η επιλογή **--xlate** καλεί την επιλογή **--xlate-color** με την επιλογή **--color=never**.

    Με την επιλογή **--xlate-fold**, το μετατραπέν κείμενο διπλώνεται με το καθορισμένο πλάτος. Το προεπιλεγμένο πλάτος είναι 70 και μπορεί να ρυθμιστεί με την επιλογή **--xlate-fold-width**. Τέσσερις στήλες διατηρούνται για τη λειτουργία run-in, έτσι ώστε κάθε γραμμή να μπορεί να περιέχει το πολύ 74 χαρακτήρες.

- **--xlate-engine**=_engine_

    Καθορίζει τη μηχανή μετάφρασης που θα χρησιμοποιηθεί. Εάν καθορίσετε απευθείας το module της μηχανής, όπως `-Mxlate::deepl`, δεν χρειάζεται να χρησιμοποιήσετε αυτή την επιλογή.

    Αυτή τη στιγμή, οι παρακάτω μηχανές είναι διαθέσιμες

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4-turbo
    - **gpt4o**: gpt-4o-mini

        Η διεπαφή του **gpt-4o** είναι ασταθής και δεν μπορεί να εγγυηθεί ότι θα λειτουργήσει σωστά αυτή τη στιγμή.

- **--xlate-labor**
- **--xlabor**

    Αντί να καλέσετε τη μηχανή μετάφρασης, αναμένεται να εργαστείτε για. Μετά την προετοιμασία του κειμένου που θα μεταφραστεί, αντιγράφονται στο πρόχειρο. Αναμένεται να τα επικολλήσετε στη φόρμα, να αντιγράψετε το αποτέλεσμα στο πρόχειρο και να πατήσετε επιστροφή.

- **--xlate-to** (Default: `EN-US`)

    Καθορίστε τη γλώσσα στόχο. Μπορείτε να αποκτήσετε διαθέσιμες γλώσσες με την εντολή `deepl languages` όταν χρησιμοποιείτε τη μηχανή **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Καθορίστε τη μορφή εξόδου για το πρωτότυπο και το μεταφρασμένο κείμενο.

    Οι παρακάτω μορφές εκτός από `xtxt` υποθέτουν ότι το μέρος που θα μεταφραστεί είναι μια συλλογή γραμμών. Στην πραγματικότητα, είναι δυνατόν να μεταφραστεί μόνο ένα μέρος μιας γραμμής, και η καθορισμένη μορφή εκτός από `xtxt` δεν θα παράγει ουσιαστικά αποτελέσματα.

    - **conflict**, **cm**

        Το πρωτότυπο και το μετατραπέν κείμενο εκτυπώνονται σε μορφή [git(1)](http://man.he.net/man1/git) conflict marker.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Μπορείτε να ανακτήσετε το πρωτότυπο αρχείο με την επόμενη εντολή [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Original and converted text are printed in [git(1)](http://man.he.net/man1/git) markdown **div** block style notation.
        Πρωτότυπο και μετατραπέν κείμενο εκτυπώνονται σε στυλ σημειώσεων **div** μπλοκ [git(1)](http://man.he.net/man1/git) markdown.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Αυτό σημαίνει:

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Ο αριθμός των κολονακίων είναι 7 από προεπιλογή. Αν καθορίσετε μια ακολουθία κολονακίων όπως `:::::`, χρησιμοποιείται αντί για 7 κολονακία.

    - **ifdef**

        Το πρωτότυπο και το μετατραπέν κείμενο εκτυπώνονται σε μορφή [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Μπορείτε να ανακτήσετε μόνο το ιαπωνικό κείμενο με την εντολή **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Original and converted text are printed separated by single blank line. 
        Το πρωτότυπο και το μετατραπέν κείμενο εκτυπώνονται χωρισμένα με μία κενή γραμμή.
        For `space+`, it also outputs a newline after the converted text.
        Για `space+`, εκτυπώνει επίσης μια νέα γραμμή μετά το μετατραπέν κείμενο.

    - **xtxt**

        Εάν η μορφή είναι `xtxt` (μεταφρασμένο κείμενο) ή άγνωστη, μόνο το μεταφρασμένο κείμενο εκτυπώνεται.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Καθορίστε το μέγιστο μήκος του κειμένου που θα σταλεί στην API ταυτόχρονα. Η προεπιλεγμένη τιμή είναι 128K για την υπηρεσία API (**--xlate**) και 5000 για τη διεπαφή πρόχειρου (**--xlate-labor**). Μπορεί να μπορείτε να αλλάξετε αυτές τις τιμές αν χρησιμοποιείτε την υπηρεσία Pro.

- **--xlate-maxline**=_n_ (Default: 0)

    Καθορίστε τον μέγιστο αριθμό γραμμών κειμένου που θα σταλεί στην API ταυτόχρονα.

    Ορίστε αυτή την τιμή σε 1 αν θέλετε να μεταφράσετε μία γραμμή τη φορά. Αυτή η επιλογή έχει προτεραιότητα σε σχέση με την επιλογή `--xlate-maxlen`.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Δείτε το αποτέλεσμα της μετάφρασης σε πραγματικό χρόνο στην έξοδο STDERR.

- **--match-all**

    Ορίστε ολόκληρο το κείμενο του αρχείου ως περιοχή στόχου.

# CACHE OPTIONS

Το **xlate** module μπορεί να αποθηκεύει κείμενο μετάφρασης σε cache για κάθε αρχείο και να το διαβάζει πριν από την εκτέλεση για να εξαλείψει την επιβάρυνση της αίτησης στον διακομιστή. Με την προεπιλεγμένη στρατηγική cache `auto`, διατηρεί δεδομένα cache μόνο όταν το αρχείο cache υπάρχει για το αρχείο στόχου.

- --cache-clear

    Η επιλογή **--cache-clear** μπορεί να χρησιμοποιηθεί για να ξεκινήσει η διαχείριση cache ή να ανανεώσει όλα τα υπάρχοντα δεδομένα cache. Μόλις εκτελεστεί με αυτή την επιλογή, θα δημιουργηθεί ένα νέο αρχείο cache αν δεν υπάρχει και στη συνέχεια θα διατηρείται αυτόματα.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Διατηρήστε το αρχείο cache αν υπάρχει.

    - `create`

        Δημιουργήστε κενό αρχείο cache και βγείτε.

    - `always`, `yes`, `1`

        Διατηρήστε την cache ούτως ή άλλως εφόσον ο στόχος είναι κανονικό αρχείο.

    - `clear`

        Καθαρίστε πρώτα τα δεδομένα cache.

    - `never`, `no`, `0`

        Ποτέ μην χρησιμοποιείτε το αρχείο cache ακόμα και αν υπάρχει.

    - `accumulate`

        Με τη συμπεριφορά προεπιλογής, τα αχρησιμοποίητα δεδομένα αφαιρούνται από το αρχείο cache. Αν δεν θέλετε να τα αφαιρέσετε και να τα διατηρήσετε στο αρχείο, χρησιμοποιήστε `accumulate`.

# COMMAND LINE INTERFACE

Μπορείτε εύκολα να χρησιμοποιήσετε αυτό το module από τη γραμμή εντολών χρησιμοποιώντας την εντολή `xlate` που περιλαμβάνεται στη διανομή. Δείτε τις πληροφορίες βοήθειας `xlate` για τη χρήση.

Η εντολή `xlate` λειτουργεί σε συνεργασία με το περιβάλλον Docker, οπότε ακόμα και αν δεν έχετε τίποτα εγκατεστημένο, μπορείτε να το χρησιμοποιήσετε όσο το Docker είναι διαθέσιμο. Χρησιμοποιήστε την επιλογή `-D` ή `-C`.

Επίσης, δεδομένου ότι παρέχονται makefiles για διάφορα στυλ εγγράφων, η μετάφραση σε άλλες γλώσσες είναι δυνατή χωρίς ειδική προδιαγραφή. Χρησιμοποιήστε την επιλογή `-M`.

Μπορείτε επίσης να συνδυάσετε τις επιλογές Docker και make ώστε να μπορείτε να εκτελέσετε make σε περιβάλλον Docker.

Η εκτέλεση όπως `xlate -GC` θα εκκινήσει ένα shell με το τρέχον αποθετήριο git να είναι προσαρτημένο.

Διαβάστε το ιαπωνικό άρθρο στην ενότητα ["SEE ALSO"](#see-also) για λεπτομέρειες.

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

Φορτώστε το αρχείο `xlate.el` που περιλαμβάνεται στο αποθετήριο για να χρησιμοποιήσετε την εντολή `xlate` από τον επεξεργαστή Emacs. Η συνάρτηση `xlate-region` μεταφράζει την καθορισμένη περιοχή. Η προεπιλεγμένη γλώσσα είναι `EN-US` και μπορείτε να καθορίσετε γλώσσα καλώντας την με προθετικό επιχείρημα.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Ορίστε το κλειδί αυθεντικοποίησής σας για την υπηρεσία DeepL.

- OPENAI\_API\_KEY

    Κλειδί αυθεντικοποίησης OpenAI.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Πρέπει να εγκαταστήσετε τα εργαλεία γραμμής εντολών για το DeepL και το ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

[https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    Βιβλιοθήκη Python DeepL και εντολή CLI.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Βιβλιοθήκη Python OpenAI

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Διεπαφή γραμμής εντολών OpenAI

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Δείτε το εγχειρίδιο **greple** για λεπτομέρειες σχετικά με το μοτίβο κειμένου στόχου. Χρησιμοποιήστε τις επιλογές **--inside**, **--outside**, **--include**, **--exclude** για να περιορίσετε την περιοχή αντιστοίχισης.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Μπορείτε να χρησιμοποιήσετε το module `-Mupdate` για να τροποποιήσετε αρχεία με βάση το αποτέλεσμα της εντολής **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Χρησιμοποιήστε το **sdif** για να δείξετε τη μορφή δείκτη σύγκρουσης δίπλα-δίπλα με την επιλογή **-V**.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Module Greple για να μεταφράσει και να αντικαταστήσει μόνο τα απαραίτητα μέρη με το API DeepL (στα ιαπωνικά)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Δημιουργία εγγράφων σε 15 γλώσσες με το module API DeepL (στα ιαπωνικά)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Αυτόματη μετάφραση περιβάλλοντος Docker με API DeepL (στα Ιαπωνικά)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.