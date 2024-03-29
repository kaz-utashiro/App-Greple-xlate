# NAME

App::Greple::xlate - ενότητα υποστήριξης μετάφρασης για το greple

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.3101

# DESCRIPTION

Η ενότητα **Greple** **xlate** βρίσκει τα επιθυμητά τμήματα κειμένου και τα αντικαθιστά με το μεταφρασμένο κείμενο. Επί του παρόντος, η ενότητα DeepL (`deepl.pm`) και η ενότητα ChatGPT (`gpt3.pm`) υλοποιούνται ως μηχανή back-end. Περιλαμβάνεται επίσης πειραματική υποστήριξη για το gpt-4.

Αν θέλετε να μεταφράσετε κανονικά μπλοκ κειμένου σε ένα έγγραφο γραμμένο στο στυλ pod της Perl, χρησιμοποιήστε την εντολή **greple** με την ενότητα `xlate::deepl` και `perl` ως εξής:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Σε αυτή την εντολή, η συμβολοσειρά προτύπων `^(\w.*\n)+` σημαίνει διαδοχικές γραμμές που αρχίζουν με αλφαριθμητικό γράμμα. Αυτή η εντολή εμφανίζει την περιοχή που πρόκειται να μεταφραστεί επισημασμένη. Η επιλογή **--all** χρησιμοποιείται για την παραγωγή ολόκληρου του κειμένου.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Στη συνέχεια, προσθέστε την επιλογή `--xlate` για να μεταφράσετε την επιλεγμένη περιοχή. Στη συνέχεια, θα βρει τα επιθυμητά τμήματα και θα τα αντικαταστήσει με την έξοδο της εντολής **deepl**.

Από προεπιλογή, το πρωτότυπο και το μεταφρασμένο κείμενο εκτυπώνονται σε μορφή "conflict marker" συμβατή με το [git(1)](http://man.he.net/man1/git). Χρησιμοποιώντας τη μορφή `ifdef`, μπορείτε να πάρετε εύκολα το επιθυμητό μέρος με την εντολή [unifdef(1)](http://man.he.net/man1/unifdef). Η μορφή εξόδου μπορεί να καθοριστεί με την επιλογή **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Αν θέλετε να μεταφράσετε ολόκληρο το κείμενο, χρησιμοποιήστε την επιλογή **--match-all**. Αυτή είναι μια σύντομη διαδρομή για να καθορίσετε το μοτίβο `(?s).+` που ταιριάζει σε ολόκληρο το κείμενο.

Τα δεδομένα μορφής δείκτη σύγκρουσης μπορούν να προβληθούν σε στυλ side-by-side με την εντολή `sdif` με την επιλογή `-V`. Δεδομένου ότι δεν έχει νόημα η σύγκριση ανά συμβολοσειρά, συνιστάται η επιλογή `--no-cdif`. Εάν δεν χρειάζεται να χρωματίσετε το κείμενο, καθορίστε την εντολή `--no-color` ή `--cm 'TEXT*='`.

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

    Προκαλέστε τη διαδικασία μετάφρασης για κάθε περιοχή που ταιριάζει.

    Χωρίς αυτή την επιλογή, η **greple** συμπεριφέρεται ως κανονική εντολή αναζήτησης. Έτσι, μπορείτε να ελέγξετε ποιο τμήμα του αρχείου θα αποτελέσει αντικείμενο της μετάφρασης πριν από την επίκληση της πραγματικής εργασίας.

    Το αποτέλεσμα της εντολής πηγαίνει στην τυπική έξοδο, οπότε ανακατευθύνετε σε αρχείο αν είναι απαραίτητο, ή σκεφτείτε να χρησιμοποιήσετε την ενότητα [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    Η επιλογή **--xlate** καλεί την επιλογή **--xlate-color** με την επιλογή **--color=never**.

    Με την επιλογή **--xlate-fold**, το μετατρεπόμενο κείμενο διπλώνεται κατά το καθορισμένο πλάτος. Το προεπιλεγμένο πλάτος είναι 70 και μπορεί να οριστεί με την επιλογή **--xlate-fold-width**. Τέσσερις στήλες είναι δεσμευμένες για τη λειτουργία run-in, οπότε κάθε γραμμή μπορεί να περιέχει 74 χαρακτήρες το πολύ.

- **--xlate-engine**=_engine_

    Καθορίζει τη μηχανή μετάφρασης που θα χρησιμοποιηθεί. Αν καθορίσετε απευθείας τη μονάδα μηχανής, όπως `-Mxlate::deepl`, δεν χρειάζεται να χρησιμοποιήσετε αυτή την επιλογή.

- **--xlate-labor**
- **--xlabor**

    Αντί να καλείτε τη μηχανή μετάφρασης, αναμένεται να εργαστείτε για. Μετά την προετοιμασία του προς μετάφραση κειμένου, αντιγράφονται στο πρόχειρο. Αναμένεται να τα επικολλήσετε στη φόρμα, να αντιγράψετε το αποτέλεσμα στο πρόχειρο και να πατήσετε return.

- **--xlate-to** (Default: `EN-US`)

    Καθορίστε τη γλώσσα-στόχο. Μπορείτε να λάβετε τις διαθέσιμες γλώσσες με την εντολή `deepl languages` όταν χρησιμοποιείτε τη μηχανή **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Καθορίστε τη μορφή εξόδου για το αρχικό και το μεταφρασμένο κείμενο.

    - **conflict**, **cm**

        Το αρχικό και το μετατρεπόμενο κείμενο εκτυπώνονται σε μορφή δείκτη σύγκρουσης [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Μπορείτε να ανακτήσετε το αρχικό αρχείο με την επόμενη εντολή [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        Το αρχικό και το μετατρεπόμενο κείμενο εκτυπώνονται σε μορφή [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Μπορείτε να ανακτήσετε μόνο το ιαπωνικό κείμενο με την εντολή **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        Το αρχικό και το μετασχηματισμένο κείμενο εκτυπώνονται χωριστά με μία κενή γραμμή.

    - **xtxt**

        Εάν η μορφή είναι `xtxt` (μεταφρασμένο κείμενο) ή άγνωστη, εκτυπώνεται μόνο το μεταφρασμένο κείμενο.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Καθορίστε το μέγιστο μήκος του κειμένου που θα αποσταλεί στο API ταυτόχρονα. Η προεπιλεγμένη τιμή έχει οριστεί όπως για τη δωρεάν υπηρεσία λογαριασμού DeepL: 128K για το API (**--xlate**) και 5000 για τη διεπαφή πρόχειρου (**--xlate-labor**). Μπορεί να μπορείτε να αλλάξετε αυτές τις τιμές αν χρησιμοποιείτε την υπηρεσία Pro.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Δείτε το αποτέλεσμα της μετάφρασης σε πραγματικό χρόνο στην έξοδο STDERR.

- **--match-all**

    Ορίστε ολόκληρο το κείμενο του αρχείου ως περιοχή-στόχο.

# CACHE OPTIONS

Η ενότητα **xlate** μπορεί να αποθηκεύσει το αποθηκευμένο κείμενο της μετάφρασης για κάθε αρχείο και να το διαβάσει πριν από την εκτέλεση, ώστε να εξαλειφθεί η επιβάρυνση από την ερώτηση στον διακομιστή. Με την προεπιλεγμένη στρατηγική κρυφής μνήμης `auto`, διατηρεί τα δεδομένα της κρυφής μνήμης μόνο όταν το αρχείο κρυφής μνήμης υπάρχει για το αρχείο-στόχο.

- --cache-clear

    Η επιλογή **--cache-clear** μπορεί να χρησιμοποιηθεί για να ξεκινήσει η διαχείριση της κρυφής μνήμης ή για να ανανεωθούν όλα τα υπάρχοντα δεδομένα της κρυφής μνήμης. Μόλις εκτελεστεί με αυτή την επιλογή, θα δημιουργηθεί ένα νέο αρχείο cache αν δεν υπάρχει και στη συνέχεια θα διατηρηθεί αυτόματα.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Διατήρηση του αρχείου κρυφής μνήμης εάν υπάρχει.

    - `create`

        Δημιουργεί κενό αρχείο κρυφής μνήμης και τερματίζει.

    - `always`, `yes`, `1`

        Διατηρεί την κρυφή μνήμη ούτως ή άλλως εφόσον ο στόχος είναι κανονικό αρχείο.

    - `clear`

        Καθαρίστε πρώτα τα δεδομένα της κρυφής μνήμης.

    - `never`, `no`, `0`

        Δεν χρησιμοποιεί ποτέ το αρχείο κρυφής μνήμης ακόμη και αν υπάρχει.

    - `accumulate`

        Σύμφωνα με την προεπιλεγμένη συμπεριφορά, τα αχρησιμοποίητα δεδομένα αφαιρούνται από το αρχείο προσωρινής αποθήκευσης. Αν δεν θέλετε να τα αφαιρέσετε και να τα διατηρήσετε στο αρχείο, χρησιμοποιήστε το `accumulate`.

# COMMAND LINE INTERFACE

Μπορείτε εύκολα να χρησιμοποιήσετε αυτήν την ενότητα από τη γραμμή εντολών χρησιμοποιώντας την εντολή `xlate` που περιλαμβάνεται στη διανομή. Ανατρέξτε στις πληροφορίες βοήθειας της `xlate` για τη χρήση.

Η εντολή `xlate` λειτουργεί σε συνεργασία με το περιβάλλον Docker, οπότε ακόμα και αν δεν έχετε τίποτα εγκατεστημένο στο χέρι, μπορείτε να τη χρησιμοποιήσετε εφόσον το Docker είναι διαθέσιμο. Χρησιμοποιήστε την επιλογή `-D` ή `-C`.

Επίσης, δεδομένου ότι παρέχονται makefiles για διάφορα στυλ εγγράφων, η μετάφραση σε άλλες γλώσσες είναι δυνατή χωρίς ειδικές προδιαγραφές. Χρησιμοποιήστε την επιλογή `-M`.

Μπορείτε επίσης να συνδυάσετε τις επιλογές Docker και make, ώστε να μπορείτε να εκτελέσετε το make σε περιβάλλον Docker.

Εκτελώντας το όπως το `xlate -GC` θα ξεκινήσει ένα κέλυφος με το τρέχον αποθετήριο git που λειτουργεί συνδεδεμένο.

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

Φορτώστε το αρχείο `xlate.el` που περιλαμβάνεται στο αποθετήριο για να χρησιμοποιήσετε την εντολή `xlate` από τον επεξεργαστή Emacs. Η συνάρτηση `xlate-region` μεταφράζει τη δεδομένη περιοχή. Η προεπιλεγμένη γλώσσα είναι η `EN-US` και μπορείτε να καθορίσετε τη γλώσσα που θα την καλέσετε με το όρισμα prefix.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Ορίστε το κλειδί ελέγχου ταυτότητας για την υπηρεσία DeepL.

- OPENAI\_API\_KEY

    Κλειδί ελέγχου ταυτότητας OpenAI.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Πρέπει να εγκαταστήσετε τα εργαλεία γραμμής εντολών για τα DeepL και ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

[https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL βιβλιοθήκη Python και εντολή CLI.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Βιβλιοθήκη OpenAI Python

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Διεπαφή γραμμής εντολών OpenAI

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Ανατρέξτε στο εγχειρίδιο **greple** για λεπτομέρειες σχετικά με το μοτίβο κειμένου-στόχου. Χρησιμοποιήστε τις επιλογές **--inside**, **--outside**, **--include**, **--exclude** για να περιορίσετε την περιοχή αντιστοίχισης.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Μπορείτε να χρησιμοποιήσετε την ενότητα `-Mupdate` για να τροποποιήσετε αρχεία με βάση το αποτέλεσμα της εντολής **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Χρησιμοποιήστε την εντολή **sdif** για να εμφανίσετε τη μορφή του δείκτη σύγκρουσης δίπλα-δίπλα με την επιλογή **-V**.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Μονάδα Greple για τη μετάφραση και την αντικατάσταση μόνο των απαραίτητων τμημάτων με το DeepL API (στα ιαπωνικά)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Δημιουργία εγγράφων σε 15 γλώσσες με την ενότητα DeepL API (στα ιαπωνικά)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Αυτόματη μετάφραση περιβάλλοντος Docker με DeepL API (στα ιαπωνικά)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
