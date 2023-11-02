=encoding utf-8

=head1 NAME

App::Greple::xlate - módulo de traducción para greple

=head1 SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

=head1 VERSION

Version 0.25

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

=head1 COMMAND LINE INTERFACE

Puede utilizar fácilmente este módulo desde la línea de comandos utilizando el comando C<xlate> incluido en el repositorio. Vea la información de ayuda de C<xlate> para su uso.

=head1 EMACS

Cargue el fichero F<xlate.el> incluido en el repositorio para usar el comando C<xlate> desde el editor Emacs. La función C<xlate-region> traduce la región dada. El idioma por defecto es C<EN-US> y puede especificar el idioma invocándolo con el argumento prefijo.

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
