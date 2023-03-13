package App::Greple::xlate;

our $VERSION = "0.15";

=encoding utf-8

=head1 NAME

App::Greple::xlate - ενότητα υποστήριξης μετάφρασης για το greple

=head1 SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

=head1 VERSION

Version 0.15

=head1 DESCRIPTION

Η ενότητα B<Greple> B<xlate> βρίσκει μπλοκ κειμένου και τα αντικαθιστά με το μεταφρασμένο κείμενο. Επί του παρόντος, μόνο η υπηρεσία DeepL υποστηρίζεται από την ενότητα B<xlate::deepl>.

Αν θέλετε να μεταφράσετε κανονικό μπλοκ κειμένου σε έγγραφο στυλ L<pod>, χρησιμοποιήστε την εντολή B<greple> με την ενότητα C<xlate::deepl> και C<perl> ως εξής:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Το πρότυπο C<^(\w.*\n)+> σημαίνει διαδοχικές γραμμές που αρχίζουν με αλφαριθμητικό γράμμα. Αυτή η εντολή δείχνει την περιοχή που πρέπει να μεταφραστεί. Η επιλογή B<--all> χρησιμοποιείται για την παραγωγή ολόκληρου του κειμένου.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
</p>

Στη συνέχεια, προσθέστε την επιλογή C<--xlate> για να μεταφράσετε την επιλεγμένη περιοχή. Θα τα βρει και θα τα αντικαταστήσει με την έξοδο της εντολής B<deepl>.

Από προεπιλογή, το πρωτότυπο και το μεταφρασμένο κείμενο εκτυπώνονται σε μορφή "δείκτη σύγκρουσης" συμβατή με το L<git(1)>. Χρησιμοποιώντας τη μορφή C<ifdef>, μπορείτε να λάβετε εύκολα το επιθυμητό τμήμα με την εντολή L<unifdef(1)>. Η μορφή μπορεί να καθοριστεί με την επιλογή B<--xlate-format>.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
</p>

Αν θέλετε να μεταφράσετε ολόκληρο το κείμενο, χρησιμοποιήστε την επιλογή B<--match-entire>. Αυτή είναι μια σύντομη διαδρομή για να καθορίσετε το μοτίβο που ταιριάζει με ολόκληρο το κείμενο C<(?s).*>.

=head1 OPTIONS

=over 7

=item B<--xlate>

=item B<--xlate-color>

=item B<--xlate-fold>

=item B<--xlate-fold-width>=I<n> (Default: 70)

Προκαλέστε τη διαδικασία μετάφρασης για κάθε περιοχή που ταιριάζει.

Χωρίς αυτή την επιλογή, η B<greple> συμπεριφέρεται ως κανονική εντολή αναζήτησης. Έτσι, μπορείτε να ελέγξετε ποιο τμήμα του αρχείου θα αποτελέσει αντικείμενο της μετάφρασης πριν από την επίκληση της πραγματικής εργασίας.

Το αποτέλεσμα της εντολής πηγαίνει στην τυπική έξοδο, οπότε ανακατευθύνετε σε αρχείο αν είναι απαραίτητο, ή σκεφτείτε να χρησιμοποιήσετε την ενότητα L<App::Greple::update>.

Η επιλογή B<--xlate> καλεί την επιλογή B<--xlate-color> με την επιλογή B<--color=never>.

Με την επιλογή B<--xlate-fold>, το μετατρεπόμενο κείμενο διπλώνεται κατά το καθορισμένο πλάτος. Το προεπιλεγμένο πλάτος είναι 70 και μπορεί να οριστεί με την επιλογή B<--xlate-fold-width>. Τέσσερις στήλες είναι δεσμευμένες για τη λειτουργία run-in, οπότε κάθε γραμμή μπορεί να περιέχει 74 χαρακτήρες το πολύ.

=item B<--xlate-engine>=I<engine>

Καθορίστε τη μηχανή μετάφρασης που θα χρησιμοποιηθεί. Δεν χρειάζεται να χρησιμοποιήσετε αυτή την επιλογή επειδή η ενότητα C<xlate::deepl> τη δηλώνει ως C<--xlate-engine=deepl>.

=item B<--xlate-labor>

=item B<--xlabor>

Αντί να καλείτε μηχανή μετάφρασης, αναμένεται να εργαστείτε για. Μετά την προετοιμασία του προς μετάφραση κειμένου, αντιγράφονται στο πρόχειρο. Αναμένεται να τα επικολλήσετε στη φόρμα, να αντιγράψετε το αποτέλεσμα στο πρόχειρο και να πατήσετε return.

=item B<--xlate-to> (Default: C<EN-US>)

Καθορίστε τη γλώσσα-στόχο. Μπορείτε να λάβετε τις διαθέσιμες γλώσσες με την εντολή C<deepl languages> όταν χρησιμοποιείτε τη μηχανή B<DeepL>.

=item B<--xlate-format>=I<format> (Default: C<conflict>)

Καθορίστε τη μορφή εξόδου για το αρχικό και το μεταφρασμένο κείμενο.

=over 4

=item B<conflict>, B<cm>

Εκτυπώστε το πρωτότυπο και το μεταφρασμένο κείμενο σε μορφή δείκτη σύγκρουσης L<git(1)>.

    <<<<<<< ORIGINAL
    original text
    =======
    translated Japanese text
    >>>>>>> JA

Μπορείτε να ανακτήσετε το αρχικό αρχείο με την επόμενη εντολή L<sed(1)>.

    sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

=item B<ifdef>

Εκτύπωση πρωτότυπου και μεταφρασμένου κειμένου σε μορφή L<cpp(1)> C<#ifdef>.

    #ifdef ORIGINAL
    original text
    #endif
    #ifdef JA
    translated Japanese text
    #endif

Μπορείτε να ανακτήσετε μόνο το ιαπωνικό κείμενο με την εντολή B<unifdef>:

    unifdef -UORIGINAL -DJA foo.ja.pm

=item B<space>

Εκτύπωση του πρωτότυπου και του μεταφρασμένου κειμένου χωρισμένα με μία μόνο κενή γραμμή.

=item B<xtxt>

Εάν η μορφή είναι C<xtxt> (μεταφρασμένο κείμενο) ή άγνωστη, εκτυπώνεται μόνο το μεταφρασμένο κείμενο.

=back

=item B<--xlate-maxlen>=I<chars> (Default: 0)

Καθορίστε το μέγιστο μήκος του κειμένου που θα αποστέλλεται στο API ταυτόχρονα. Η προεπιλεγμένη τιμή ορίζεται όπως για την υπηρεσία δωρεάν λογαριασμού: 128K για το API (B<--xlate>) και 5000 για τη διεπαφή πρόχειρου (B<--xlate-labor>). Μπορεί να μπορείτε να αλλάξετε αυτές τις τιμές αν χρησιμοποιείτε την υπηρεσία Pro.

=item B<-->[B<no->]B<xlate-progress> (Default: True)

Δείτε το αποτέλεσμα της μετάφρασης σε πραγματικό χρόνο στην έξοδο STDERR.

=item B<--match-entire>

Ορίστε ολόκληρο το κείμενο του αρχείου ως περιοχή-στόχο.

=back

=head1 CACHE OPTIONS

Η ενότητα B<xlate> μπορεί να αποθηκεύσει το αποθηκευμένο κείμενο της μετάφρασης για κάθε αρχείο και να το διαβάσει πριν από την εκτέλεση, ώστε να εξαλειφθεί η επιβάρυνση από την ερώτηση στον διακομιστή. Με την προεπιλεγμένη στρατηγική κρυφής μνήμης C<auto>, διατηρεί τα δεδομένα της κρυφής μνήμης μόνο όταν το αρχείο κρυφής μνήμης υπάρχει για το αρχείο-στόχο.

=over 7

=item --cache-clear

Η επιλογή B<--cache-clear> μπορεί να χρησιμοποιηθεί για να ξεκινήσει η διαχείριση της κρυφής μνήμης ή για να ανανεωθούν όλα τα υπάρχοντα δεδομένα της κρυφής μνήμης. Μόλις εκτελεστεί με αυτή την επιλογή, θα δημιουργηθεί ένα νέο αρχείο cache αν δεν υπάρχει και στη συνέχεια θα διατηρηθεί αυτόματα.

=item --xlate-cache=I<strategy>

=over 4

=item C<auto> (Default)

Διατήρηση του αρχείου κρυφής μνήμης εάν υπάρχει.

=item C<create>

Δημιουργεί κενό αρχείο κρυφής μνήμης και τερματίζει.

=item C<always>, C<yes>, C<1>

Διατηρεί την κρυφή μνήμη ούτως ή άλλως εφόσον ο στόχος είναι κανονικό αρχείο.

=item C<clear>

Καθαρίστε πρώτα τα δεδομένα της κρυφής μνήμης.

=item C<never>, C<no>, C<0>

Δεν χρησιμοποιεί ποτέ το αρχείο κρυφής μνήμης ακόμη και αν υπάρχει.

=item C<accumulate>

Σύμφωνα με την προεπιλεγμένη συμπεριφορά, τα αχρησιμοποίητα δεδομένα αφαιρούνται από το αρχείο προσωρινής αποθήκευσης. Αν δεν θέλετε να τα αφαιρέσετε και να τα διατηρήσετε στο αρχείο, χρησιμοποιήστε το C<accumulate>.

=back

=back

=head1 ENVIRONMENT

=over 7

=item DEEPL_AUTH_KEY

Ορίστε το κλειδί ελέγχου ταυτότητας για την υπηρεσία DeepL.

=back

=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::xlate

=head1 SEE ALSO

L<App::Greple::xlate>

=over 7

=item L<https://github.com/DeepLcom/deepl-python>

DeepL βιβλιοθήκη Python και εντολή CLI.

=item L<App::Greple>

Ανατρέξτε στο εγχειρίδιο B<greple> για λεπτομέρειες σχετικά με το μοτίβο κειμένου-στόχου. Χρησιμοποιήστε τις επιλογές B<--inside>, B<--outside>, B<--include>, B<--exclude> για να περιορίσετε την περιοχή αντιστοίχισης.

=item L<App::Greple::update>

Μπορείτε να χρησιμοποιήσετε την ενότητα C<-Mupdate> για να τροποποιήσετε αρχεία με βάση το αποτέλεσμα της εντολής B<greple>.

=item L<App::sdif>

Χρησιμοποιήστε την εντολή B<sdif> για να εμφανίσετε τη μορφή του δείκτη σύγκρουσης δίπλα-δίπλα με την επιλογή B<-V>.

=back

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use v5.14;
use warnings;

use Data::Dumper;

use JSON;
use Text::ANSI::Fold ':constants';
use App::cdif::Command;
use Hash::Util qw(lock_keys);
use Unicode::EastAsianWidth;

our %opt = (
    engine   => \(our $xlate_engine),
    progress => \(our $show_progress = 1),
    format   => \(our $output_format = 'conflict'),
    collapse => \(our $collapse_spaces = 1),
    from     => \(our $lang_from = 'ORIGINAL'),
    to       => \(our $lang_to = 'EN-US'),
    fold     => \(our $fold_line = 0),
    width    => \(our $fold_width = 70),
    auth_key => \(our $auth_key),
    method   => \(our $cache_method //= $ENV{GREPLE_XLATE_CACHE} || 'auto'),
    dryrun   => \(our $dryrun = 0),
    maxlen   => \(our $max_length = 0),
    );
lock_keys %opt;
sub opt :lvalue { ${$opt{+shift}} }

my $current_file;

our %formatter = (
    xtxt => undef,
    none => undef,
    conflict => sub {
	join '',
	    "<<<<<<< $lang_from\n",
	    $_[0],
	    "=======\n",
	    $_[1],
	    ">>>>>>> $lang_to\n";
    },
    cm => 'conflict',
    ifdef => sub {
	join '',
	    "#ifdef $lang_from\n",
	    $_[0],
	    "#endif\n",
	    "#ifdef $lang_to\n",
	    $_[1],
	    "#endif\n";
    },
    space   => sub { join "\n", @_ },
    discard => sub { '' },
    );

# aliases
for (keys %formatter) {
    next if ! $formatter{$_} or ref $formatter{$_};
    $formatter{$_} = $formatter{$formatter{$_}} // die;
}

my $old_cache = {};
my $new_cache = {};
my $xlate_cache_update;

sub setup {
    return if state $once_called++;
    if (defined $cache_method) {
	if ($cache_method eq '') {
	    $cache_method = 'auto';
	}
	if (lc $cache_method eq 'accumulate') {
	    $new_cache = $old_cache;
	}
	if ($cache_method =~ /^(no|never)/i) {
	    $cache_method = '';
	}
    }
    if ($xlate_engine) {
	my $mod = __PACKAGE__ . "::$xlate_engine";
	if (eval "require $mod") {
	    $mod->import;
	} else {
	    die "Engine $xlate_engine is not available.\n";
	}
	no strict 'refs';
	${"$mod\::lang_from"} = $lang_from;
	${"$mod\::lang_to"} = $lang_to;
	*XLATE = \&{"$mod\::xlate"};
	if (not defined &XLATE) {
	    die "No \"xlate\" function in $mod.\n";
	}
    }
}

sub normalize {
    $_[0] =~ s{^.+(?:\n.+)*}{
	${^MATCH}
	    =~ s/\A\s+|\s+\z//gr
	    =~ s/(?<=\p{InFullwidth})\n(?=\p{InFullwidth})//gr
	    =~ s/\s+/ /gr
    }pmger;
}

sub postgrep {
    my $grep = shift;
    my @miss;
    for my $r ($grep->result) {
	my($b, @match) = @$r;
	for my $m (@match) {
	    my $key = normalize $grep->cut(@$m);
	    $new_cache->{$key} //= delete $old_cache->{$key} // do {
		push @miss, $key;
		"NOT TRANSLATED YET\n";
	    };
	}
    }
    cache_update(@miss) if @miss;
}

sub cache_update {
    binmode STDERR, ':encoding(utf8)';

    my @from = @_;
    print STDERR "From:\n", map s/^/\t< /mgr, @from if $show_progress;
    return @from if $dryrun;

    my @to = &XLATE(@from);

    print STDERR "To:\n", map s/^/\t> /mgr, @to if $show_progress;
    die "Unmatched response:\n@to" if @from != @to;
    $xlate_cache_update += @from;
    @{$new_cache}{@from} = @to;
}

sub fold_lines {
    state $fold = Text::ANSI::Fold->new(
	width     => $fold_width,
	boundary  => 'word',
	linebreak => LINEBREAK_ALL,
	runin     => 4,
	runout    => 4,
	);
    local $_ = shift;
    s/(.+)/join "\n", $fold->text($1)->chops/ge;
    $_;
}

sub xlate {
    my $text = shift;
    my $key = normalize $text;
    my $s = $new_cache->{$key} // "!!! TRANSLATION ERROR !!!\n";
    $s = fold_lines $s if $fold_line;
    if (state $formatter = $formatter{$output_format}) {
	return $formatter->($text, $s);
    } else {
	return $s;
    }
}
sub colormap { xlate $_ }
sub callback { xlate { @_ }->{match} }

sub cache_file {
    my $file = sprintf("%s.xlate-%s-%s.json",
		       $current_file, $xlate_engine, $lang_to);
    if ($cache_method eq 'auto') {
	-f $file ? $file : undef;
    } else {
	if ($cache_method and -f $current_file) {
	    $file;
	} else {
	    undef;
	}
    }
}

sub read_cache {
    my $file = shift;
    %$new_cache = %$old_cache = ();
    if (open my $fh, $file) {
	my $json = do { local $/; <$fh> };
	my $hash = $json eq '' ? {} : decode_json $json;
	%$old_cache = %$hash;
	warn "read cache from $file\n";
    }
}

sub write_cache {
    return if $dryrun;
    my $file = shift;
    if (open my $fh, '>', $file) {
	my $json = encode_json $new_cache;
	print $fh $json;
	warn "write cache to $file\n";
    }
}

sub begin {
    setup if not (state $done++);
    my %args = @_;
    $current_file = delete $args{&::FILELABEL} or die;
    s/\z/\n/ if /.\z/;
    $xlate_cache_update = 0;
    if (not defined $xlate_engine) {
	die "Select translation engine.\n";
    }
    if (my $cache = cache_file) {
	if ($cache_method =~ /^(create|clear)/) {
	    warn "created $cache\n" unless -f $cache;
	    open my $fh, '>', $cache or die "$cache: $!\n";
	    print $fh "{}\n";
	    die "skip $current_file" if $cache_method eq 'create';
	}
	read_cache $cache;
    }
}

sub end {
    if (my $cache = cache_file) {
	if ($xlate_cache_update or %$old_cache) {
	    write_cache $cache;
	}
    }
}

sub setopt {
    while (my($key, $val) = splice @_, 0, 2) {
	next if $key eq &::FILELABEL;
	die "$key: Invalid option.\n" if not exists $opt{$key};
	opt($key) = $val;
    }
}

1;

__DATA__

builtin xlate-progress!    $show_progress
builtin xlate-format=s     $output_format
builtin xlate-fold-line!   $fold_line
builtin xlate-fold-width=i $fold_width
builtin xlate-from=s       $lang_from
builtin xlate-to=s         $lang_to
builtin xlate-cache:s      $cache_method
builtin xlate-engine=s     $xlate_engine
builtin xlate-dryrun       $dryrun
builtin xlate-maxlen=i     $max_length

builtin deepl-auth-key=s   $App::Greple::xlate::deepl::auth_key
builtin deepl-method=s     $App::Greple::xlate::deepl::method

option default --face +E --ci=A

option --xlate-setopt --prologue &__PACKAGE__::setopt($<shift>)

option --xlate-color \
	--postgrep &__PACKAGE__::postgrep \
	--callback &__PACKAGE__::callback \
	--begin    &__PACKAGE__::begin \
	--end      &__PACKAGE__::end
option --xlate --xlate-color --color=never
option --xlate-fold --xlate --xlate-fold-line
option --xlate-labor --xlate --deepl-method=clipboard
option --xlabor --xlate-labor

option --cache-clear --xlate-cache=clear

option --match-entire    --re '\A(?s).+\z'
option --match-paragraph --re '^(.+\n)+'
option --match-podtext   -Mperl --pod --re '^(\w.*\n)(\S.*\n)*'

option --ifdef-color --re '^#ifdef(?s:.*?)^#endif.*\n'

#  LocalWords:  deepl ifdef unifdef Greple greple perl
