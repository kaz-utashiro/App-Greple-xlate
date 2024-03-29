# NAME

App::Greple::xlate - μονάδα υποστήριξης μετάφρασης για το greple

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.3101

# DESCRIPTION

Το **Greple** **xlate** module εντοπίζει τα επιθυμητά τμήματα κειμένου και τα αντικαθιστά με το μεταφρασμένο κείμενο. Αυτή τη στιγμή, τα DeepL (`deepl.pm`) και ChatGPT (`gpt3.pm`) module υλοποιούνται ως μηχανή πίσω από το σύστημα. Περιλαμβάνεται επίσης πειραματική υποστήριξη για το gpt-4.

Εάν θέλετε να μεταφράσετε κανονικά τμήματα κειμένου σε ένα έγγραφο που έχει γραφεί στο στυλ pod της Perl, χρησιμοποιήστε την εντολή **greple** με το `xlate::deepl` και το πρόσθετο `perl` όπως εξής:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Σε αυτήν την εντολή, η συμβολοσειρά προτύπου `^(\w.*\n)+` σημαίνει συνεχόμενες γραμμές που ξεκινούν με αλφαριθμητικό γράμμα. Αυτή η εντολή εμφανίζει την περιοχή που πρόκειται να μεταφραστεί με επισήμανση. Η επιλογή **--all** χρησιμοποιείται για να παράγει ολόκληρο το κείμενο.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Στη συνέχεια, προσθέστε την επιλογή `--xlate` για να μεταφράσετε την επιλεγμένη περιοχή. Στη συνέχεια, θα εντοπίσει τα επιθυμητά τμήματα και θα τα αντικαταστήσει με την έξοδο της εντολής **deepl**.

Από προεπιλογή, το αρχικό και το μεταφρασμένο κείμενο εκτυπώνονται στη μορφή "conflict marker" που είναι συμβατή με το [git(1)](http://man.he.net/man1/git). Χρησιμοποιώντας τη μορφή `ifdef`, μπορείτε να πάρετε το επιθυμητό τμήμα με την εντολή [unifdef(1)](http://man.he.net/man1/unifdef) εύκολα. Η μορφή εξόδου μπορεί να καθοριστεί με την επιλογή **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Εάν θέλετε να μεταφράσετε ολόκληρο το κείμενο, χρησιμοποιήστε την επιλογή **--match-all**. Αυτό είναι ένας συντομευμένος τρόπος για να καθορίσετε το πρότυπο `(?s).+` που ταιριάζει με ολόκληρο το κείμενο.

Τα δεδομένα μορφής δείκτη σύγκρουσης μπορούν να προβληθούν σε στυλ δίπλα-δίπλα με την εντολή `sdif` με την επιλογή `-V`. Δεδομένου ότι δεν έχει νόημα να συγκρίνουμε βάσει κάθε συμβολοσειράς, συνιστάται η επιλογή `--no-cdif`. Αν δεν χρειάζεστε να χρωματίσετε το κείμενο, καθορίστε το `--no-color` ή το `--cm 'ΚΕΙΜΕΝΟ*='`.

    sdif -V --cm '*TEXT=' --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Καλέστε τη διαδικασία μετάφρασης για κάθε ταιριαστή περιοχή.

    Χωρίς αυτήν την επιλογή, το **greple** συμπεριφέρεται ως ένα κανονικό πρόγραμμα αναζήτησης. Έτσι μπορείτε να ελέγξετε ποιο μέρος του αρχείου θα υπόκειται στη μετάφραση πριν καλέσετε την πραγματική εργασία.

    Το αποτέλεσμα της εντολής πηγαίνει στην τυπική έξοδο, οπότε αν χρειάζεται ανακατεύθυνση σε αρχείο, ή σκεφτείτε να χρησιμοποιήσετε το πρόσθετο [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    Η επιλογή **--xlate** καλεί την επιλογή **--xlate-color** με την επιλογή **--color=never**.

    Με την επιλογή **--xlate-fold**, το μεταφρασμένο κείμενο διπλώνεται με το καθορισμένο πλάτος. Το προεπιλεγμένο πλάτος είναι 70 και μπορεί να οριστεί με την επιλογή **--xlate-fold-width**. Τέσσερεις στήλες είναι καταλεγμένες για τη λειτουργία run-in, οπότε κάθε γραμμή μπορεί να περιέχει το πολύ 74 χαρακτήρες.

- **--xlate-engine**=_engine_

    Καθορίζει τη μηχανή μετάφρασης που θα χρησιμοποιηθεί. Εάν καθορίσετε απευθείας το μοντούλο της μηχανής, όπως `-Mxlate::deepl`, δεν χρειάζεται να χρησιμοποιήσετε αυτήν την επιλογή.

- **--xlate-labor**
- **--xlabor**

    Αντί να καλείτε τη μηχανή μετάφρασης, αναμένεται να εργαστείτε εσείς. Αφού προετοιμάσετε το κείμενο που πρόκειται να μεταφραστεί, αντιγράφετε το στο πρόχειρο. Αναμένεται να το επικολλήσετε στη φόρμα, να αντιγράψετε το αποτέλεσμα στο πρόχειρο και να πατήσετε Enter.

- **--xlate-to** (Default: `EN-US`)

    Καθορίστε τη γλώσσα προορισμού. Μπορείτε να λάβετε τις διαθέσιμες γλώσσες με την εντολή `deepl languages` όταν χρησιμοποιείτε τη μηχανή **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Καθορίστε τη μορφή εξόδου για το αρχικό και μεταφρασμένο κείμενο.

    - **conflict**, **cm**

        Ο αρχικός και μετατραπέντας κείμενος εκτυπώνονται σε μορφή δείκτη σύγκρουσης [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Μπορείτε να ανακτήσετε το αρχικό αρχείο με την επόμενη εντολή [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        Ο αρχικός και μετατραπέντας κείμενος εκτυπώνονται σε μορφή [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Μπορείτε να ανακτήσετε μόνο το ιαπωνικό κείμενο με την εντολή **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        Ο αρχικός και μετατραπέντας κείμενος εκτυπώνονται χωρισμένοι από μια μόνο κενή γραμμή.

    - **xtxt**

        Εάν η μορφή είναι `xtxt` (μεταφρασμένο κείμενο) ή άγνωστη, εκτυπώνεται μόνο το μεταφρασμένο κείμενο.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Μεταφράστε το παρακάτω κείμενο στα ελληνικά, γραμμή-προς-γραμμή.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Δείτε το αποτέλεσμα της μετάφρασης σε πραγματικό χρόνο στην έξοδο STDERR.

- **--match-all**

    Ορίστε ολόκληρο το κείμενο του αρχείου ως περιοχή στόχο.

# CACHE OPTIONS

Το πρόσθετο **xlate** μπορεί να αποθηκεύει το μεταφρασμένο κείμενο για κάθε αρχείο και να το διαβάζει πριν από την εκτέλεση για να εξαλείψει τον χρόνο που απαιτείται για την επικοινωνία με τον διακομιστή. Με την προεπιλεγμένη στρατηγική προσωρινής αποθήκευσης `auto`, διατηρεί τα δεδομένα προσωρινής αποθήκευσης μόνο όταν το αρχείο προσωρινής αποθήκευσης υπάρχει για το συγκεκριμένο αρχείο στόχο.

- --cache-clear

    Η επιλογή **--cache-clear** μπορεί να χρησιμοποιηθεί για την εκκίνηση της διαχείρισης της προσωρινής αποθήκευσης ή για την ανανέωση όλων των υπαρχόντων δεδομένων προσωρινής αποθήκευσης. Μόλις εκτελεστεί με αυτήν την επιλογή, θα δημιουργηθεί ένα νέο αρχείο προσωρινής αποθήκευσης αν δεν υπάρχει και στη συνέχεια θα διατηρείται αυτόματα.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Διατηρήστε το αρχείο προσωρινής αποθήκευσης αν υπάρχει.

    - `create`

        Δημιουργήστε ένα κενό αρχείο προσωρινής αποθήκευσης και τερματίστε.

    - `always`, `yes`, `1`

        Διατηρήστε την προσωρινή μνήμη ούτως ή άλλως, όσο το προορισμένο αρχείο είναι κανονικό αρχείο.

    - `clear`

        Καθαρίστε πρώτα τα δεδομένα της προσωρινής μνήμης.

    - `never`, `no`, `0`

        Ποτέ μην χρησιμοποιείτε το αρχείο της προσωρινής μνήμης, ακόμα κι αν υπάρχει.

    - `accumulate`

        Από προεπιλογή, τα αχρησιμοποίητα δεδομένα αφαιρούνται από το αρχείο της προσωρινής μνήμης. Εάν δεν θέλετε να τα αφαιρέσετε και να τα κρατήσετε στο αρχείο, χρησιμοποιήστε την επιλογή `accumulate`.

# COMMAND LINE INTERFACE

Μπορείτε εύκολα να χρησιμοποιήσετε αυτήν την ενότητα από τη γραμμή εντολών χρησιμοποιώντας την εντολή `xlate` που περιλαμβάνεται στη διανομή. Δείτε τις πληροφορίες βοήθειας της εντολής `xlate` για τη χρήση.

Η εντολή `xlate` λειτουργεί σε συνεργασία με το περιβάλλον Docker, οπότε ακόμα κι αν δεν έχετε κάτι εγκατεστημένο στο χέρι, μπορείτε να το χρησιμοποιήσετε όσον ο Docker είναι διαθέσιμος. Χρησιμοποιήστε την επιλογή `-D` ή `-C`.

Επίσης, εφόσον παρέχονται αρχεία makefiles για διάφορα στυλ εγγράφου, είναι δυνατή η μετάφραση σε άλλες γλώσσες χωρίς ειδική προδιαγραφή. Χρησιμοποιήστε την επιλογή `-M`.

Μπορείτε επίσης να συνδυάσετε τις επιλογές Docker και make έτσι ώστε να μπορείτε να εκτελέσετε την εντολή make σε ένα περιβάλλον Docker.

Η εκτέλεση όπως η `xlate -GC` θα εκκινήσει ένα κέλυφος με το τρέχον αποθετήριο git που έχει προσαρτηθεί.

Διαβάστε το ιαπωνικό άρθρο στην ενότητα ["ΔΕΙΤΕ ΕΠΙΣΗΣ"](#δειτε-επισησ) για λεπτομέρειες.

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

Φορτώστε το αρχείο `xlate.el` που περιλαμβάνεται στο αποθετήριο για να χρησιμοποιήσετε την εντολή `xlate` από τον επεξεργαστή Emacs. Η συνάρτηση `xlate-region` μεταφράζει την δοθείσα περιοχή. Η προεπιλεγμένη γλώσσα είναι η `EN-US` και μπορείτε να καθορίσετε τη γλώσσα καλώντας την με πρόθεμα.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Ορίστε το κλειδί πιστοποίησης σας για την υπηρεσία DeepL.

- OPENAI\_API\_KEY

    Κλειδί επαλήθευσης OpenAI.

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

    Βιβλιοθήκη DeepL Python και εντολή CLI.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Βιβλιοθήκη Python της OpenAI

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Διεπαφή γραμμής εντολών της OpenAI

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Δείτε το εγχειρίδιο **greple** για λεπτομέρειες σχετικά με το πρότυπο κειμένου προορισμού. Χρησιμοποιήστε τις επιλογές **--inside**, **--outside**, **--include**, **--exclude** για να περιορίσετε την περιοχή της αντιστοίχισης.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Μπορείτε να χρησιμοποιήσετε τον μονάδα `-Mupdate` για να τροποποιήσετε αρχεία με βάση το αποτέλεσμα της εντολής **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Χρησιμοποιήστε το **sdif** για να εμφανίσετε τη μορφή του δείκτη σύγκρουσης δίπλα-δίπλα με την επιλογή **-V**.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Μεταφράστε το παρακάτω κείμενο στα Ελληνικά, γραμμή προς γραμμή.

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Μονάδα Greple για μετάφραση και αντικατάσταση μόνο των απαραίτητων τμημάτων με το API του DeepL (στα Ιαπωνικά)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Δημιουργία εγγράφων σε 15 γλώσσες με τη μονάδα DeepL API (στα Ιαπωνικά)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
