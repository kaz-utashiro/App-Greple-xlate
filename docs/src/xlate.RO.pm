package App::Greple::xlate;

our $VERSION = "0.20";

=encoding utf-8

=head1 NAME

App::Greple::xlate - modul de suport pentru traducere pentru Greple

=head1 SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

=head1 VERSION

Version 0.20

=head1 DESCRIPTION

Modulul B<Greple> B<xlate> găsește blocurile de text și le înlocuiește cu textul tradus. În prezent, numai serviciul DeepL este suportat de modulul B<xlate::deepl>.

Dacă doriți să traduceți un bloc de text normal într-un document în stil L<pod>, utilizați comanda B<greple> cu modulul C<xlate::deepl> și C<perl> astfel:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Modelul C<^(\w.*\n)+> înseamnă linii consecutive care încep cu o literă alfanumerică. Această comandă arată zona care urmează să fie tradusă. Opțiunea B<--all> este utilizată pentru a produce întregul text.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
</p>

Apoi se adaugă opțiunea C<--xlate> pentru a traduce zona selectată. Aceasta le va găsi și le va înlocui cu ieșirea comenzii B<deepl>.

În mod implicit, textul original și cel tradus sunt tipărite în formatul "conflict marker" compatibil cu L<git(1)>. Utilizând formatul C<ifdef>, puteți obține cu ușurință partea dorită prin comanda L<unifdef(1)>. Formatul poate fi specificat prin opțiunea B<--xlate-format>.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
</p>

Dacă doriți să traduceți întregul text, utilizați opțiunea B<--match-all>. Aceasta este o prescurtare pentru a specifica că modelul se potrivește cu întregul text C<(?s).+>.

=head1 OPTIONS

=over 7

=item B<--xlate>

=item B<--xlate-color>

=item B<--xlate-fold>

=item B<--xlate-fold-width>=I<n> (Default: 70)

Invocați procesul de traducere pentru fiecare zonă corespunzătoare.

Fără această opțiune, B<greple> se comportă ca o comandă de căutare normală. Astfel, puteți verifica ce parte a fișierului va face obiectul traducerii înainte de a invoca lucrul efectiv.

Rezultatul comenzii merge la ieșire standard, deci redirecționați-l către fișier dacă este necesar sau luați în considerare utilizarea modulului L<App::Greple::update>.

Opțiunea B<--xlate> apelează opțiunea B<--xlate-color> cu opțiunea B<--color=never>.

Cu opțiunea B<--xlate-fold>, textul convertit este pliat cu lățimea specificată. Lățimea implicită este 70 și poate fi stabilită prin opțiunea B<--xlate-fold-width>. Patru coloane sunt rezervate pentru operațiunea de rulare, astfel încât fiecare linie poate conține cel mult 74 de caractere.

=item B<--xlate-engine>=I<engine>

Specificați motorul de traducere care urmează să fie utilizat. Nu este necesar să utilizați această opțiune deoarece modulul C<xlate::deepl> o declară ca fiind C<--xlate-engine=deepl>.

=item B<--xlate-labor>

=item B<--xlabor>

În loc să apelați motorul de traducere, se așteaptă să lucrați pentru. După pregătirea textului care urmează să fie tradus, acestea sunt copiate în clipboard. Se așteaptă să le lipiți în formular, să copiați rezultatul în clipboard și să apăsați return.

=item B<--xlate-to> (Default: C<EN-US>)

Specificați limba țintă. Puteți obține limbile disponibile prin comanda C<deepl languages> atunci când se utilizează motorul B<DeepL>.

=item B<--xlate-format>=I<format> (Default: C<conflict>)

Specificați formatul de ieșire pentru textul original și cel tradus.

=over 4

=item B<conflict>, B<cm>

Tipăriți textul original și tradus în formatul de marcare a conflictului L<git(1)>.

    <<<<<<< ORIGINAL
    original text
    =======
    translated Japanese text
    >>>>>>> JA

Puteți recupera fișierul original prin următoarea comandă L<sed(1)>.

    sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

=item B<ifdef>

Tipăriți textul original și tradus în formatul L<cpp(1)> C<#ifdef>.

    #ifdef ORIGINAL
    original text
    #endif
    #ifdef JA
    translated Japanese text
    #endif

Puteți recupera doar textul japonez prin comanda B<unifdef>:

    unifdef -UORIGINAL -DJA foo.ja.pm

=item B<space>

Tipăriți textul original și tradus separate de o singură linie albă.

=item B<xtxt>

Dacă formatul este C<xtxt> (text tradus) sau necunoscut, se tipărește numai textul tradus.

=back

=item B<--xlate-maxlen>=I<chars> (Default: 0)

Specificați lungimea maximă a textului care urmează să fie trimis la API deodată. Valoarea implicită este setată ca pentru serviciul de cont gratuit: 128K pentru API (B<--xlate>) și 5000 pentru interfața clipboard (B<--xlate-labor>). Este posibil să puteți modifica aceste valori dacă utilizați serviciul Pro.

=item B<-->[B<no->]B<xlate-progress> (Default: True)

Vedeți rezultatul traducerii în timp real în ieșirea STDERR.

=item B<--match-all>

Setați întregul text al fișierului ca zonă țintă.

=back

=head1 CACHE OPTIONS

Modulul B<xlate> poate stoca în memoria cache textul traducerii pentru fiecare fișier și îl poate citi înainte de execuție, pentru a elimina costurile suplimentare de solicitare a serverului. Cu strategia implicită de cache C<auto>, acesta păstrează datele din cache numai atunci când fișierul cache există pentru fișierul țintă.

=over 7

=item --cache-clear

Opțiunea B<--cache-clear> poate fi utilizată pentru a iniția gestionarea memoriei cache sau pentru a reîmprospăta toate datele existente în memoria cache. Odată executat cu această opțiune, un nou fișier cache va fi creat dacă nu există unul și apoi va fi menținut automat.

=item --xlate-cache=I<strategy>

=over 4

=item C<auto> (Default)

Menține fișierul cache dacă acesta există.

=item C<create>

Creează un fișier cache gol și iese.

=item C<always>, C<yes>, C<1>

Menține oricum memoria cache în măsura în care fișierul țintă este un fișier normal.

=item C<clear>

Ștergeți mai întâi datele din memoria cache.

=item C<never>, C<no>, C<0>

Nu utilizează niciodată fișierul cache, chiar dacă există.

=item C<accumulate>

Prin comportament implicit, datele neutilizate sunt eliminate din fișierul cache. Dacă nu doriți să le eliminați și să le păstrați în fișier, utilizați C<acumulare>.

=back

=back

=head1 ENVIRONMENT

=over 7

=item DEEPL_AUTH_KEY

Setați cheia de autentificare pentru serviciul DeepL.

=back

=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::xlate

=head1 SEE ALSO

L<App::Greple::xlate>

=over 7

=item L<https://github.com/DeepLcom/deepl-python>

DeepL Biblioteca Python și comanda CLI.

=item L<App::Greple>

Consultați manualul B<greple> pentru detalii despre modelul de text țintă. Utilizați opțiunile B<--inside>, B<--outside>, B<--include>, B<--exclude> pentru a limita zona de potrivire.

=item L<App::Greple::update>

Puteți utiliza modulul C<-Mupdate> pentru a modifica fișierele în funcție de rezultatul comenzii B<greple>.

=item L<App::sdif>

Folosiți B<sdif> pentru a afișa formatul markerilor de conflict unul lângă altul cu opțiunea B<-V>.

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

option --match-all       --re '\A(?s).+\z'
option --match-entire    --match-all
option --match-paragraph --re '^(.+\n)+'
option --match-podtext   -Mperl --pod --re '^(\w.*\n)(\S.*\n)*'

option --ifdef-color --re '^#ifdef(?s:.*?)^#endif.*\n'

#  LocalWords:  deepl ifdef unifdef Greple greple perl
