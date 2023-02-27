package App::Greple::xlate;

our $VERSION = "0.09";

=encoding utf-8

=head1 NAME

App::Greple::xlate - Greple tõlkimise tugimoodul

=head1 SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

=head1 DESCRIPTION

B<Greple> B<xlate> moodul leiab tekstiplokid ja asendab need tõlgitud tekstiga. Praegu toetab B<xlate::deepl> moodul ainult DeepL teenust.

Kui soovite L<pod> stiilis dokumendis tavalist tekstiplokki tõlkida, kasutage B<greple> käsku koos C<xlate::deepl> ja C<perl> mooduliga niimoodi:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Muster C<^(\w.*\n)+> tähendab järjestikuseid ridu, mis algavad tähtnumbrilise tähega. See käsk näitab tõlgitavat ala. Valikut B<--all> kasutatakse kogu teksti koostamiseks.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
</p>

Seejärel lisage valik C<--xlate>, et tõlkida valitud ala. See leiab ja asendab need käsu B<deepl> väljundiga.

Vaikimisi trükitakse originaal- ja tõlgitud tekst "konfliktimärkide" formaadis, mis on ühilduv L<git(1)>. Kasutades C<ifdef> formaati, saate soovitud osa hõlpsasti kätte käsuga L<unifdef(1)>. Formaat saab määrata B<--xlate-format> valikuga.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
</p>

Kui soovite tõlkida kogu teksti, kasutage B<--match-entire> valikut. See on lühike valik, et määrata muster vastab kogu tekstile C<(?s).*>.

=head1 OPTIONS

=over 7

=item B<--xlate>

=item B<--xlate-color>

=item B<--xlate-fold>

=item B<--xlate-fold-width>=I<n> (Default: 70)

Käivitage tõlkimisprotsess iga sobitatud ala jaoks.

Ilma selle valikuta käitub B<greple> nagu tavaline otsingukäsklus. Seega saate enne tegeliku töö käivitamist kontrollida, millise faili osa kohta tehakse tõlge.

Käsu tulemus läheb standardväljundisse, nii et vajadusel suunake see faili ümber või kaaluge mooduli L<App::Greple::update> kasutamist.

Valik B<--xlate> kutsub B<--xlate-color> valiku B<--color=never> valikul.

Valikuga B<--xlate-fold> volditakse konverteeritud tekst määratud laiusega. Vaikimisi laius on 70 ja seda saab määrata valikuga B<--xlate-fold-width>. Neli veergu on reserveeritud sisselülitamiseks, nii et iga rida võib sisaldada maksimaalselt 74 märki.

=item B<--xlate-engine>=I<engine>

Määrake kasutatav tõlkemootor. Seda valikut ei pea kasutama, sest moodul C<xlate::deepl> deklareerib seda kui C<--xlate-engine=deepl>.

=item B<--xlate-labor>

Insted kutsudes tõlkemootor, siis oodatakse tööd. Pärast tõlgitava teksti ettevalmistamist kopeeritakse need lõikelauale. Eeldatakse, et kleebite need vormi, kopeerite tulemuse lõikelauale ja vajutate return.

=item B<--xlate-to> (Default: C<JA>)

Määrake sihtkeel. B<DeepL> mootori kasutamisel saate saadaval olevad keeled kätte käsuga C<deepl languages>.

=item B<--xlate-format>=I<format> (Default: conflict)

Määrake originaal- ja tõlgitud teksti väljundformaat.

=over 4

=item B<conflict>

Trükib originaal- ja tõlgitud teksti L<git(1)> konfliktimärgistuse formaadis.

    <<<<<<< ORIGINAL
    original text
    =======
    translated Japanese text
    >>>>>>> JA

Originaalfaili saate taastada järgmise käsuga L<sed(1)>.

    sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

=item B<ifdef>

Prindi originaal- ja tõlgitud tekst L<cpp(1)> C<#ifdef>-vormingus.

    #ifdef ORIGINAL
    original text
    #endif
    #ifdef JA
    translated Japanese text
    #endif

Saate ainult jaapani teksti taastada käsuga B<unifdef>:

    unifdef -UORIGINAL -DJA foo.ja.pm

=item B<space>

Prindi originaal- ja tõlgitud tekst ühe tühja reaga eraldatud.

=item B<none>

Kui formaat on C<none> või tundmatu, trükitakse ainult tõlgitud tekst.

=back

=item B<-->[B<no->]B<xlate-progress> (Default: True)

Näete tõlkimise tulemust reaalajas STDERR-väljundist.

=item B<--match-entire>

Määrake kogu faili tekst sihtkohaks.

=back

=head1 CACHE OPTIONS

B<xlate> moodul võib salvestada iga faili tõlketeksti vahemällu ja lugeda seda enne täitmist, et kõrvaldada serveri küsimisega kaasnev koormus. Vaikimisi vahemälustrateegia C<auto> puhul säilitab ta vahemälu andmeid ainult siis, kui vahemälufail on sihtfaili jaoks olemas.

=over 7

=item --refresh

Valikut <--refresh> saab kasutada vahemälu haldamise algatamiseks või kõigi olemasolevate vahemälu andmete värskendamiseks. Selle valikuga käivitamisel luuakse uus vahemälufail, kui seda ei ole olemas, ja seejärel hooldatakse seda automaatselt.

=item --xlate-cache=I<strategy>

=over 4

=item C<auto> (Default)

Säilitab vahemälufaili, kui see on olemas.

=item C<create>

Loob tühja vahemälufaili ja väljub.

=item C<always>, C<yes>, C<1>

Säilitab vahemälu andmed niikuinii, kui sihtfail on tavaline fail.

=item C<refresh>

Säilitada vahemälu, kuid mitte lugeda olemasolevat.

=item C<never>, C<no>, C<0>

Ei kasuta kunagi vahemälufaili, isegi kui see on olemas.

=item C<accumulate>

Vaikimisi käitumine, kasutamata andmed eemaldatakse vahemälufailist. Kui te ei soovi neid eemaldada ja failis hoida, kasutage C<accumulate>.

=back

=back

=head1 ENVIRONMENT

=over 7

=item DEEPL_AUTH_KEY

Määrake oma autentimisvõti DeepL teenuse jaoks.

=back

=head1 SEE ALSO

=over 7

=item L<https://github.com/DeepLcom/deepl-python>

DeepL Pythoni raamatukogu ja CLI käsk.

=item L<App::Greple>

Vt B<greple> käsiraamatust üksikasjalikult sihttekstimustri kohta. Kasutage B<--inside>, B<--outside>, B<--include>, B<--exclude> valikuid, et piirata sobitusala.

=item L<App::Greple::update>

Saate kasutada C<-Mupdate> moodulit, et muuta faile B<greple> käsu tulemuse järgi.

=item L<App::sdif>

Kasutage B<sdif>, et näidata konfliktimärkide formaati kõrvuti valikuga B<-V>.

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
	if ($cache_method ne 'refresh') {
	    read_cache $cache;
	}
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

option --refresh --xlate-cache=refresh

option --match-entire    --re '\A(?s).+\z'
option --match-paragraph --re '^(.+\n)+'
option --match-podtext   -Mperl --pod --re '^(\w.*\n)(\S.*\n)*'

option --ifdef-color --re '^#ifdef(?s:.*?)^#endif.*\n'

#  LocalWords:  deepl ifdef unifdef Greple greple perl
