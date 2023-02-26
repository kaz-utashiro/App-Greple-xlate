package App::Greple::xlate;

our $VERSION = "0.08";

=encoding utf-8

=head1 NAME

App::Greple::xlate - vertaalondersteuningsmodule voor greple

=head1 SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

=head1 DESCRIPTION

B<Greple> B<xlate> module vindt tekstblokken en vervangt ze door de vertaalde tekst. Momenteel wordt alleen DeepL service ondersteund door de B<xlate::deepl> module.

Als je normale tekstblokken in L<pod> style document wilt vertalen, gebruik dan B<greple> commando met C<xlate::deepl> en C<perl> module zoals dit:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Patroon C<^(\w.*\n)+> betekent opeenvolgende regels die beginnen met een alfa-numerieke letter. Dit commando toont het te vertalen gebied. Optie B<--all> wordt gebruikt om de hele tekst te produceren.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
</p>

Voeg dan de optie C<--xlate> toe om het geselecteerde gebied te vertalen. Het zal ze vinden en vervangen door de uitvoer van het B<deepl> commando.

Standaard worden originele en vertaalde tekst afgedrukt in het "conflict marker" formaat dat compatibel is met L<git(1)>. Door C<ifdef> formaat te gebruiken, kunt u gemakkelijk het gewenste deel krijgen met het L<unifdef(1)> commando. Het formaat kan gespecificeerd worden met de optie B<--xlate-format>.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
</p>

Als u de hele tekst wilt vertalen, gebruik dan de optie B<--match-entire>. Dit is een short-cut om aan te geven dat het patroon overeenkomt met de hele tekst C<(?s).*>.

=head1 OPTIONS

=over 7

=item B<--xlate>

=item B<--xlate-color>

=item B<--xlate-fold>

=item B<--xlate-fold-width>=I<n> (Default: 70)

Roep het vertaalproces op voor elk gematcht gebied.

Zonder deze optie gedraagt B<greple> zich als een normaal zoekcommando. U kunt dus controleren welk deel van het bestand zal worden vertaald voordat u het eigenlijke werk uitvoert.

Commandoresultaat gaat naar standaard out, dus redirect naar bestand indien nodig, of overweeg L<App::Greple::update> module te gebruiken.

Optie B<--xlate> roept B<--xlate-kleur> aan met B<--color=never> optie.

Met de optie B<--xlate-fold> wordt geconverteerde tekst gevouwen met de opgegeven breedte. De standaardbreedte is 70 en kan worden ingesteld met de optie B<--xlate-fold-width>. Vier kolommen zijn gereserveerd voor inloopoperaties, zodat elke regel maximaal 74 tekens kan bevatten.

=item B<--xlate-engine>=I<engine>

Specificeer de te gebruiken vertaalmachine. U hoeft deze optie niet te gebruiken omdat module C<xlate::deepl> deze verklaart als C<--xlate-engine=deepl>.

=item B<--xlate-to> (Default: C<JA>)

Geef de doeltaal op. U kunt de beschikbare talen krijgen met het commando C<deepl languages> wanneer u de engine B<DeepL> gebruikt.

=item B<--xlate-format>=I<format> (Default: conflict)

Specificeer het uitvoerformaat voor originele en vertaalde tekst.

=over 4

=item B<conflict>

Print originele en vertaalde tekst in L<git(1)> conflictmarker formaat.

    <<<<<<< ORIGINAL
    original text
    =======
    translated Japanese text
    >>>>>>> JA

U kunt het originele bestand herstellen met de volgende L<sed(1)> opdracht.

    sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

=item B<ifdef>

Originele en vertaalde tekst afdrukken in L<cpp(1)> C<#ifdef> formaat.

    #ifdef ORIGINAL
    original text
    #endif
    #ifdef JA
    translated Japanese text
    #endif

U kunt alleen Japanse tekst terughalen met het commando B<unifdef>:

    unifdef -UORIGINAL -DJA foo.ja.pm

=item B<space>

Originele en vertaalde tekst afdrukken, gescheiden door een enkele lege regel.

=item B<none>

Als het formaat C<none> of onbekend is, wordt alleen de vertaalde tekst afgedrukt.

=back

=item B<-->[B<no->]B<xlate-progress> (Default: True)

Zie het resultaat van de vertaling in real time in de STDERR uitvoer.

=item B<--match-entire>

Stel de hele tekst van het bestand in als doelgebied.

=back

=head1 CACHE OPTIONS

De module B<xlate> kan de tekst van de vertaling voor elk bestand in de cache opslaan en lezen vóór de uitvoering om de overhead van het vragen aan de server te elimineren. Met de standaard cachestrategie C<auto> worden cachegegevens alleen onderhouden als het cachebestand voor het doelbestand bestaat. Als het corresponderende cachebestand niet bestaat, wordt het niet aangemaakt.

=over 7

=item --xlate-cache=I<strategy>

=over 4

=item C<auto> (Default)

Onderhoudt het cache bestand als het bestaat.

=item C<create>

Maak een leeg cache bestand en sluit af.

=item C<always>, C<yes>, C<1>

Cache-bestand toch behouden voor zover het doelbestand een normaal bestand is.

=item C<never>, C<no>, C<0>

Cache-bestand nooit gebruiken, zelfs niet als het bestaat.

=item C<accumulate>

Standaard gedrag, ongebruikte gegevens worden verwijderd uit cache bestand. Als u ze niet wilt verwijderen en in het bestand wilt houden, gebruik dan C<accumuleren>.

=back

=back

=head1 ENVIRONMENT

=over 7

=item DEEPL_AUTH_KEY

Stel uw authenticatiesleutel in voor DeepL service.

=back

=head1 SEE ALSO

=over 7

=item L<https://github.com/DeepLcom/deepl-python>

DeepL Python bibliotheek en CLI commando.

=item L<App::Greple>

Zie de B<greple> handleiding voor de details over het doeltekstpatroon. Gebruik B<--inside>, B<--outside>, B<--include>, B<--exclude> opties om het overeenkomende gebied te beperken.

=item L<App::Greple::update>

U kunt de module C<-Mupdate> gebruiken om bestanden te wijzigen door het resultaat van het commando B<greple>.

=item L<App::sdif>

Gebruik B<sdif> om het formaat van de conflictmarkering naast de optie B<-V> te tonen.

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

my %opt = (
    engine   => \(our $xlate_engine),
    progress => \(our $show_progress = 1),
    format   => \(our $output_format = 'conflict'),
    collapse => \(our $collapse_spaces = 1),
    from     => \(our $lang_from = 'ORIGINAL'),
    to       => \(our $lang_to = 'JA'),
    fold     => \(our $fold_line = 0),
    width    => \(our $fold_width = 70),
    auth_key => \(our $auth_key),
    method   => \(our $cache_method //= $ENV{GREPLE_XLATE_CACHE} || 'auto'),
    dryrun   => \(our $dryrun = 0),
    );
lock_keys %opt;
sub opt :lvalue { ${$opt{+shift}} }

my $current_file;

our %formatter = (
    none => undef,
    conflict => sub {
	join '',
	    "<<<<<<< $lang_from\n",
	    $_[0],
	    "=======\n",
	    $_[1],
	    ">>>>>>> $lang_to\n";
    },
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
	if ($cache_method eq 'create') {
	    unless (-f $cache) {
		open my $fh, '>', $cache or die "$cache: $!\n";
		warn "created $cache\n";
		print $fh "{}\n";
	    }
	    die "skip $current_file";
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

builtin deepl-auth-key=s   $__PACKAGE__::deepl::auth_key

option default --face +E --ci=A

option --xlate-setopt --prologue &__PACKAGE__::setopt($<shift>)

option --xlate-color \
	--postgrep &__PACKAGE__::postgrep \
	--callback &__PACKAGE__::callback \
	--begin    &__PACKAGE__::begin \
	--end      &__PACKAGE__::end
option --xlate --xlate-color --color=never
option --xlate-fold --xlate --xlate-fold-line

option --match-entire    --re '\A(?s).+\z'
option --match-paragraph --re '^(.+\n)+'
option --match-podtext   -Mperl --pod --re '^(\w.*\n)(\S.*\n)*'

option --ifdef-color --re '^#ifdef(?s:.*?)^#endif.*\n'

#  LocalWords:  deepl ifdef unifdef Greple greple perl
