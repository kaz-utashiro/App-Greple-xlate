package App::Greple::xlate;

our $VERSION = "0.09";

=encoding utf-8

=head1 NAME

App::Greple::xlate - Übersetzungsunterstützungsmodul für Greple

=head1 SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

=head1 DESCRIPTION

B<Greple> B<xlate> Modul findet Textblöcke und ersetzt sie durch den übersetzten Text. Derzeit wird nur der DeepL Service vom B<xlate::deepl> Modul unterstützt.

Wenn Sie einen normalen Textblock in einem Dokument im Stil von L<pod> übersetzen wollen, verwenden Sie den Befehl B<greple> mit dem Modul C<xlate::deepl> und C<perl> wie folgt:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Pattern C<^(\w.*\n)+> bedeutet aufeinanderfolgende Zeilen, die mit einem alphanumerischen Buchstaben beginnen. Dieser Befehl zeigt den zu übersetzenden Bereich an. Die Option B<--all> wird verwendet, um den gesamten Text zu übersetzen.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
</p>

Fügen Sie dann die Option C<--xlate> hinzu, um den ausgewählten Bereich zu übersetzen. Sie werden gefunden und durch die Ausgabe des Befehls B<deepl> ersetzt.

Standardmäßig werden der ursprüngliche und der übersetzte Text im Format der "Konfliktmarkierung" ausgegeben, das mit L<git(1)> kompatibel ist. Wenn Sie das Format C<ifdef> verwenden, können Sie den gewünschten Teil mit dem Befehl L<unifdef(1)> leicht erhalten. Das Format kann mit der Option B<--xlate-format> angegeben werden.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
</p>

Wenn Sie den gesamten Text übersetzen wollen, verwenden Sie die Option B<--match-entire>. Dies ist eine Abkürzung, um das Muster für den gesamten Text C<(?s).*> anzugeben.

=head1 OPTIONS

=over 7

=item B<--xlate>

=item B<--xlate-color>

=item B<--xlate-fold>

=item B<--xlate-fold-width>=I<n> (Default: 70)

Rufen Sie den Übersetzungsprozess für jeden übereinstimmenden Bereich auf.

Ohne diese Option verhält sich B<greple> wie ein normaler Suchbefehl. Sie können also prüfen, welcher Teil der Datei Gegenstand der Übersetzung sein wird, bevor Sie die eigentliche Arbeit aufrufen.

Das Ergebnis des Befehls wird im Standard-Output ausgegeben, also leiten Sie es bei Bedarf in eine Datei um oder verwenden Sie das Modul L<App::Greple::update>.

Die Option B<--xlate> ruft die Option B<--xlate-color> mit der Option B<--color=never> auf.

Mit der Option B<--xlate-fold> wird der konvertierte Text um die angegebene Breite gefaltet. Die Standardbreite ist 70 und kann mit der Option B<--xlate-fold-width> eingestellt werden. Vier Spalten sind für den Einlaufvorgang reserviert, so dass jede Zeile maximal 74 Zeichen enthalten kann.

=item B<--xlate-engine>=I<engine>

Geben Sie die zu verwendende Übersetzungsmaschine an. Sie brauchen diese Option nicht zu verwenden, da das Modul C<xlate::deepl> sie als C<--xlate-engine=deepl> deklariert.

=item B<--xlate-labor>

Anstatt die Übersetzungsmaschine aufzurufen, wird von Ihnen erwartet, dass Sie für arbeiten. Nachdem der zu übersetzende Text vorbereitet wurde, wird er in die Zwischenablage kopiert. Es wird erwartet, dass Sie sie in das Formular einfügen, das Ergebnis in die Zwischenablage kopieren und die Eingabetaste drücken.

=item B<--xlate-to> (Default: C<JA>)

Geben Sie die Zielsprache an. Sie können die verfügbaren Sprachen mit dem Befehl C<deepl languages> abrufen, wenn Sie die Engine B<DeepL> verwenden.

=item B<--xlate-format>=I<format> (Default: conflict)

Geben Sie das Ausgabeformat für den Originaltext und den übersetzten Text an.

=over 4

=item B<conflict>

Drucken Sie den Originaltext und den übersetzten Text im Format L<git(1)> conflict marker.

    <<<<<<< ORIGINAL
    original text
    =======
    translated Japanese text
    >>>>>>> JA

Sie können die Originaldatei mit dem nächsten Befehl L<sed(1)> wiederherstellen.

    sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

=item B<ifdef>

Druckt den originalen und übersetzten Text im Format L<cpp(1)> C<#ifdef>.

    #ifdef ORIGINAL
    original text
    #endif
    #ifdef JA
    translated Japanese text
    #endif

Mit dem Befehl B<unifdef> können Sie nur den japanischen Text wiederherstellen:

    unifdef -UORIGINAL -DJA foo.ja.pm

=item B<space>

Original und übersetzten Text durch eine einzelne Leerzeile getrennt ausgeben.

=item B<none>

Wenn das Format C<none> oder unbekannt ist, wird nur der übersetzte Text gedruckt.

=back

=item B<-->[B<no->]B<xlate-progress> (Default: True)

Sehen Sie das Ergebnis der Übersetzung in Echtzeit in der STDERR-Ausgabe.

=item B<--match-entire>

Legen Sie den gesamten Text der Datei als Zielbereich fest.

=back

=head1 CACHE OPTIONS

Das Modul B<xlate> kann den übersetzten Text für jede Datei im Cache speichern und vor der Ausführung lesen, um den Overhead durch Anfragen an den Server zu vermeiden. Bei der Standard-Cache-Strategie C<auto> werden die Cache-Daten nur beibehalten, wenn die Cache-Datei für die Zieldatei existiert.

=over 7

=item --refresh

Die Option <--refresh> kann verwendet werden, um die Cache-Verwaltung zu starten oder um alle vorhandenen Cache-Daten zu aktualisieren. Nach der Ausführung dieser Option wird eine neue Cachedatei erstellt, falls noch keine vorhanden ist, und anschließend automatisch gepflegt.

=item --xlate-cache=I<strategy>

=over 4

=item C<auto> (Default)

Cache-Datei beibehalten, wenn sie vorhanden ist.

=item C<create>

Leere Cachedatei erstellen und beenden.

=item C<always>, C<yes>, C<1>

Cache trotzdem beibehalten, sofern das Ziel eine normale Datei ist.

=item C<refresh>

Cache beibehalten, aber vorhandene Datei nicht lesen.

=item C<never>, C<no>, C<0>

Cache-Datei nie verwenden, auch wenn sie vorhanden ist.

=item C<accumulate>

Standardmäßig werden ungenutzte Daten aus der Cache-Datei entfernt. Wenn Sie sie nicht entfernen und in der Datei behalten wollen, verwenden Sie C<accumulate>.

=back

=back

=head1 ENVIRONMENT

=over 7

=item DEEPL_AUTH_KEY

Legen Sie Ihren Authentifizierungsschlüssel für den Dienst DeepL fest.

=back

=head1 SEE ALSO

=over 7

=item L<https://github.com/DeepLcom/deepl-python>

DeepL Python-Bibliothek und CLI-Befehl.

=item L<App::Greple>

Lesen Sie das Handbuch B<greple> für Details über Zieltextmuster. Verwenden Sie die Optionen B<--inside>, B<--outside>, B<--include>, B<--exclude>, um den Suchbereich einzuschränken.

=item L<App::Greple::update>

Sie können das Modul C<-Mupdate> verwenden, um Dateien anhand des Ergebnisses des Befehls B<greple> zu ändern.

=item L<App::sdif>

Verwenden Sie B<sdif>, um das Format der Konfliktmarkierung zusammen mit der Option B<-V> anzuzeigen.

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
