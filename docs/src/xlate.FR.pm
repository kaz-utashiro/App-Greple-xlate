package App::Greple::xlate;

our $VERSION = "0.17";

=encoding utf-8

=head1 NAME

App::Greple::xlate - module d'aide à la traduction pour greple

=head1 SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

=head1 VERSION

Version 0.17

=head1 DESCRIPTION

Le module B<Greple> B<xlate> trouve des blocs de texte et les remplace par le texte traduit. Actuellement, seul le service DeepL est pris en charge par le module B<xlate::deepl>.

Si vous voulez traduire un bloc de texte normal dans un document de style L<pod>, utilisez la commande B<greple> avec le module C<xlate::deepl> et C<perl> comme ceci :

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Le motif C<^(\w.*\n)+> signifie des lignes consécutives commençant par une lettre alpha-numérique. Cette commande montre la zone à traduire. L'option B<--all> est utilisée pour produire le texte entier.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
</p>

Ensuite, ajoutez l'option C<--xlate> pour traduire la zone sélectionnée. Elle les trouvera et les remplacera par la sortie de la commande B<deepl>.

Par défaut, le texte original et traduit est imprimé dans le format "marqueur de conflit" compatible avec L<git(1)>. En utilisant le format C<ifdef>, vous pouvez obtenir facilement la partie souhaitée par la commande L<unifdef(1)>. Le format peut être spécifié par l'option B<--xlate-format>.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
</p>

Si vous voulez traduire un texte entier, utilisez l'option B<--match-entire>. Il s'agit d'un raccourci pour spécifier que le motif correspond au texte entier C<(?s).*>.

=head1 OPTIONS

=over 7

=item B<--xlate>

=item B<--xlate-color>

=item B<--xlate-fold>

=item B<--xlate-fold-width>=I<n> (Default: 70)

Invoquez le processus de traduction pour chaque zone appariée.

Sans cette option, B<greple> se comporte comme une commande de recherche normale. Vous pouvez donc vérifier quelle partie du fichier fera l'objet de la traduction avant d'invoquer le travail réel.

Le résultat de la commande va vers la sortie standard, donc redirigez vers le fichier si nécessaire, ou envisagez d'utiliser le module L<App::Greple::update>.

L'option B<--xlate> appelle l'option B<--xlate-color> avec l'option B<--color=never>.

Avec l'option B<--xlate-fold>, le texte converti est plié selon la largeur spécifiée. La largeur par défaut est de 70 et peut être définie par l'option B<--xlate-fold-width>. Quatre colonnes sont réservées à l'opération de rodage, de sorte que chaque ligne peut contenir 74 caractères au maximum.

=item B<--xlate-engine>=I<engine>

Spécifiez le moteur de traduction à utiliser. Vous n'avez pas à utiliser cette option car le module C<xlate::deepl> le déclare comme C<--xlate-engine=deepl>.

=item B<--xlate-labor>

=item B<--xlabor>

Au lieu d'appeler le moteur de traduction, vous êtes censé travailler pour. Après avoir préparé les textes à traduire, ils sont copiés dans le presse-papiers. Vous êtes censé les coller dans le formulaire, copier le résultat dans le presse-papiers et appuyer sur la touche retour.

=item B<--xlate-to> (Default: C<EN-US>)

Spécifiez la langue cible. Vous pouvez obtenir les langues disponibles par la commande C<deepl languages> lorsque vous utilisez le moteur B<DeepL>.

=item B<--xlate-format>=I<format> (Default: C<conflict>)

Spécifiez le format de sortie pour le texte original et le texte traduit.

=over 4

=item B<conflict>, B<cm>

Imprimez le texte original et traduit au format de marqueur de conflit L<git(1)>.

    <<<<<<< ORIGINAL
    original text
    =======
    translated Japanese text
    >>>>>>> JA

Vous pouvez récupérer le fichier original par la commande L<sed(1)> suivante.

    sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

=item B<ifdef>

Impression du texte original et du texte traduit au format C<#ifdef> de L<cpp(1)>.

    #ifdef ORIGINAL
    original text
    #endif
    #ifdef JA
    translated Japanese text
    #endif

Vous pouvez récupérer uniquement le texte japonais par la commande B<unifdef> :

    unifdef -UORIGINAL -DJA foo.ja.pm

=item B<space>

Imprimer le texte original et le texte traduit séparés par une seule ligne blanche.

=item B<xtxt>

Si le format est C<xtxt> (texte traduit) ou inconnu, seul le texte traduit est imprimé.

=back

=item B<--xlate-maxlen>=I<chars> (Default: 0)

Spécifie la longueur maximale du texte à envoyer à l'API en une seule fois. La valeur par défaut est la même que pour le service de compte gratuit : 128K pour l'API (B<--xlate>) et 5000 pour l'interface du presse-papiers (B<--xlate-labor>). Vous pouvez modifier ces valeurs si vous utilisez le service Pro.

=item B<-->[B<no->]B<xlate-progress> (Default: True)

Voir le résultat de la traduction en temps réel dans la sortie STDERR.

=item B<--match-entire>

Définissez l'ensemble du texte du fichier comme zone cible.

=back

=head1 CACHE OPTIONS

Le module B<xlate> peut stocker le texte de la traduction en cache pour chaque fichier et le lire avant l'exécution pour éliminer les frais généraux de demande au serveur. Avec la stratégie de cache par défaut C<auto>, il maintient les données de cache uniquement lorsque le fichier de cache existe pour le fichier cible.

=over 7

=item --cache-clear

L'option B<--cache-clear> peut être utilisée pour initier la gestion du cache ou pour rafraîchir toutes les données du cache existant. Une fois exécutée avec cette option, un nouveau fichier de cache sera créé s'il n'en existe pas, puis automatiquement maintenu par la suite.

=item --xlate-cache=I<strategy>

=over 4

=item C<auto> (Default)

Maintenir le fichier de cache s'il existe.

=item C<create>

Créer un fichier cache vide et quitter.

=item C<always>, C<yes>, C<1>

Maintenir le cache de toute façon tant que la cible est un fichier normal.

=item C<clear>

Effacer d'abord les données du cache.

=item C<never>, C<no>, C<0>

Ne jamais utiliser le fichier cache même s'il existe.

=item C<accumulate>

Par défaut, les données inutilisées sont supprimées du fichier cache. Si vous ne voulez pas les supprimer et les conserver dans le fichier, utilisez C<accumulate>.

=back

=back

=head1 ENVIRONMENT

=over 7

=item DEEPL_AUTH_KEY

Définissez votre clé d'authentification pour le service DeepL.

=back

=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::xlate

=head1 SEE ALSO

L<App::Greple::xlate>

=over 7

=item L<https://github.com/DeepLcom/deepl-python>

DeepL Bibliothèque Python et commande CLI.

=item L<App::Greple>

Voir le manuel B<greple> pour les détails sur le modèle de texte cible. Utilisez les options B<--inside>, B<--outside>, B<--include>, B<--exclude> pour limiter la zone de correspondance.

=item L<App::Greple::update>

Vous pouvez utiliser le module C<-Mupdate> pour modifier les fichiers par le résultat de la commande B<greple>.

=item L<App::sdif>

Utilisez B<sdif> pour afficher le format des marqueurs de conflit côte à côte avec l'option B<-V>.

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
