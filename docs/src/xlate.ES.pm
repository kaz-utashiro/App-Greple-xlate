package App::Greple::xlate;

our $VERSION = "0.19";

=encoding utf-8

=head1 NAME

App::Greple::xlate - módulo de traducción para greple

=head1 SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

=head1 VERSION

Version 0.19

=head1 DESCRIPTION

El módulo B<Greple> B<xlate> encuentra bloques de texto y los reemplaza por el texto traducido. Actualmente sólo DeepL servicio es compatible con el módulo B<xlate::deepl>.

Si desea traducir un bloque de texto normal en un documento de estilo L<pod>, utilice el comando B<greple> con el módulo C<xlate::deepl> y C<perl> de la siguiente manera:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

El patrón C<^(\w.*\n)+> significa líneas consecutivas que comienzan con una letra alfanumérica. Este comando muestra el área a traducir. La opción B<--all> se utiliza para producir el texto completo.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
</p>

A continuación, añada la opción C<--xlate> para traducir el área seleccionada. Las encontrará y reemplazará por la salida del comando B<deepl>.

Por defecto, el texto original y traducido se imprime en el formato "marcador de conflicto" compatible con L<git(1)>. Usando el formato C<ifdef>, puede obtener fácilmente la parte deseada mediante el comando L<unifdef(1)>. El formato puede especificarse mediante la opción B<--xlate-format>.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
</p>

Si desea traducir todo el texto, utilice la opción B<--match-all>. Es un atajo para especificar que el patrón coincide con todo el texto C<(?s).+>.

=head1 OPTIONS

=over 7

=item B<--xlate>

=item B<--xlate-color>

=item B<--xlate-fold>

=item B<--xlate-fold-width>=I<n> (Default: 70)

Invoca el proceso de traducción para cada área coincidente.

Sin esta opción, B<greple> se comporta como un comando de búsqueda normal. Por lo tanto, puede comprobar qué parte del archivo será objeto de la traducción antes de invocar el trabajo real.

El resultado del comando va a la salida estándar, así que rediríjalo al archivo si es necesario, o considere usar el módulo L<App::Greple::update>.

La opción B<--xlate> llama a la opción B<--xlate-color> con la opción B<--color=nunca>.

Con la opción B<--xlate-fold>, el texto convertido se dobla por el ancho especificado. La anchura por defecto es 70 y puede ajustarse con la opción B<--xlate-fold-width>. Se reservan cuatro columnas para la operación de repliegue, por lo que cada línea puede contener 74 caracteres como máximo.

=item B<--xlate-engine>=I<engine>

Especifique el motor de traducción que se utilizará. No es necesario utilizar esta opción porque el módulo C<xlate::deepl> lo declara como C<--xlate-engine=deepl>.

=item B<--xlate-labor>

=item B<--xlabor>

En lugar de llamar al motor de traducción, se espera que trabaje para. Después de preparar el texto a traducir, se copian en el portapapeles. Se espera que los pegue en el formulario, copie el resultado en el portapapeles y pulse Retorno.

=item B<--xlate-to> (Default: C<EN-US>)

Especifique el idioma de destino. Puede obtener los idiomas disponibles mediante el comando C<deepl languages> si utiliza el motor B<DeepL>.

=item B<--xlate-format>=I<format> (Default: C<conflict>)

Especifique el formato de salida del texto original y traducido.

=over 4

=item B<conflict>, B<cm>

Imprima el texto original y traducido en formato de marcador de conflicto L<git(1)>.

    <<<<<<< ORIGINAL
    original text
    =======
    translated Japanese text
    >>>>>>> JA

Puede recuperar el archivo original con el siguiente comando L<sed(1)>.

    sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

=item B<ifdef>

Imprime el texto original y traducido en formato L<cpp(1)> C<#ifdef>.

    #ifdef ORIGINAL
    original text
    #endif
    #ifdef JA
    translated Japanese text
    #endif

Puede recuperar sólo el texto japonés mediante el comando B<unifdef>:

    unifdef -UORIGINAL -DJA foo.ja.pm

=item B<space>

Imprime el texto original y el traducido separados por una sola línea en blanco.

=item B<xtxt>

Si el formato es C<xtxt> (texto traducido) o desconocido, sólo se imprime el texto traducido.

=back

=item B<--xlate-maxlen>=I<chars> (Default: 0)

Especifique la longitud máxima del texto que se enviará a la API de una sola vez. El valor predeterminado es el mismo que para el servicio de cuenta gratuita: 128K para la API (B<--xlate>) y 5000 para la interfaz del portapapeles (B<--xlate-labor>). Puede cambiar estos valores si utiliza el servicio Pro.

=item B<-->[B<no->]B<xlate-progress> (Default: True)

Ver el resultado de la traducción en tiempo real en la salida STDERR.

=item B<--match-all>

Establece todo el texto del fichero como área de destino.

=back

=head1 CACHE OPTIONS

El módulo B<xlate> puede almacenar en caché el texto traducido de cada fichero y leerlo antes de la ejecución para eliminar la sobrecarga de preguntar al servidor. Con la estrategia de caché por defecto C<auto>, mantiene los datos de caché sólo cuando el archivo de caché existe para el archivo de destino.

=over 7

=item --cache-clear

La opción B<--cache-clear> puede utilizarse para iniciar la gestión de la caché o para refrescar todos los datos de caché existentes. Una vez ejecutada esta opción, se creará un nuevo archivo de caché si no existe y se mantendrá automáticamente después.

=item --xlate-cache=I<strategy>

=over 4

=item C<auto> (Default)

Mantener el archivo de caché si existe.

=item C<create>

Crear un archivo de caché vacío y salir.

=item C<always>, C<yes>, C<1>

Mantener caché de todos modos hasta que el destino sea un archivo normal.

=item C<clear>

Borrar primero los datos de la caché.

=item C<never>, C<no>, C<0>

No utilizar nunca el archivo de caché aunque exista.

=item C<accumulate>

Por defecto, los datos no utilizados se eliminan del archivo de caché. Si no desea eliminarlos y mantenerlos en el archivo, utilice C<acumular>.

=back

=back

=head1 ENVIRONMENT

=over 7

=item DEEPL_AUTH_KEY

Establezca su clave de autenticación para el servicio DeepL.

=back

=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::xlate

=head1 SEE ALSO

L<App::Greple::xlate>

=over 7

=item L<https://github.com/DeepLcom/deepl-python>

DeepL Librería Python y comando CLI.

=item L<App::Greple>

Vea el manual B<greple> para los detalles sobre el patrón de texto objetivo. Utilice las opciones B<--inside>, B<--outside>, B<--include>, B<--exclude> para limitar el área de coincidencia.

=item L<App::Greple::update>

Puede utilizar el módulo C<-Mupdate> para modificar archivos según el resultado del comando B<greple>.

=item L<App::sdif>

Utilice B<sdif> para mostrar el formato del marcador de conflicto junto con la opción B<-V>.

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
