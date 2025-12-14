# NAME

App::Greple::xlate - módulo de traducción para greple

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

    greple -Mxlate::gpt4 --xlate pattern target-file

    greple -Mxlate::gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

# VERSION

Version 0.9918

# DESCRIPTION

El módulo **Greple** **xlate** encuentra los bloques de texto deseados y los sustituye por el texto traducido. Actualmente DeepL (`deepl.pm`), ChatGPT 4.1 (`gpt4.pm`), y GPT-5 (`gpt5.pm`) módulo se implementan como un motor de back-end.

Si desea traducir bloques de texto normal en un documento escrito en el estilo vaina de Perl, utilice el comando **greple** con el módulo `xlate::deepl` y `perl` de la siguiente manera:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

En este comando, la cadena de patrones `^([\w\pP].*\n)+` significa líneas consecutivas que comienzan con letras alfanuméricas y de puntuación. Este comando muestra resaltada el área a traducir. La opción **--all** se utiliza para producir el texto completo.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

A continuación, añada la opción `--xlate` para traducir el área seleccionada. Entonces, encontrará las secciones deseadas y las reemplazará por la salida del comando **deepl**.

Por defecto, el texto original y traducido se imprime en el formato "marcador de conflicto" compatible con [git(1)](http://man.he.net/man1/git). Usando el formato `ifdef`, puede obtener la parte deseada mediante el comando [unifdef(1)](http://man.he.net/man1/unifdef) fácilmente. El formato de salida puede especificarse mediante la opción **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Si desea traducir todo el texto, utilice la opción **--match-all**. Es un atajo para especificar el patrón `(?s).+` que coincide con todo el texto.

Los datos en formato de marcador de conflicto pueden visualizarse en estilo lado a lado mediante el comando [sdif](https://metacpan.org/pod/App%3A%3Asdif) con la opción `-V`. Dado que no tiene sentido comparar cadena por cadena, se recomienda la opción `--no-cdif`. Si no necesita colorear el texto, especifique `--no-textcolor` (o `--no-tc`).

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

El procesamiento se realiza en unidades especificadas, pero en el caso de una secuencia de varias líneas de texto no vacías, se convierten juntas en una sola línea. Esta operación se realiza del siguiente modo:

- Se eliminan los espacios en blanco al principio y al final de cada línea.
- Si una línea termina con un carácter de puntuación de ancho completo, concaténela con la línea siguiente.
- Si una línea termina con un carácter de ancho completo y la línea siguiente comienza con un carácter de ancho completo, concatene las líneas.
- Si el final o el principio de una línea no es un carácter de ancho completo, concaténelas insertando un carácter de espacio.

Los datos de la caché se gestionan en función del texto normalizado, por lo que aunque se realicen modificaciones que no afecten a los resultados de la normalización, los datos de traducción almacenados en la caché seguirán siendo efectivos.

Este proceso de normalización sólo se realiza para el primer patrón (0) y los patrones pares. Por lo tanto, si se especifican dos patrones como los siguientes, el texto que coincida con el primer patrón se procesará después de la normalización, y no se realizará ningún proceso de normalización en el texto que coincida con el segundo patrón.

    greple -Mxlate -E normalized -E not-normalized

Por lo tanto, utilice el primer patrón para texto que deba procesarse combinando varias líneas en una sola, y utilice el segundo patrón para texto preformateado. Si no hay texto que coincidir en el primer patrón, utilice un patrón que no coincida con nada, como `(?!)`.

# MASKING

En ocasiones, hay partes del texto que no desea traducir. Por ejemplo, las etiquetas de los archivos markdown. DeepL sugiere que, en tales casos, la parte del texto que debe excluirse se convierta en etiquetas XML, se traduzca y, una vez finalizada la traducción, se restaure. Para ello, es posible especificar las partes que no deben traducirse.

    --xlate-setopt maskfile=MASKPATTERN

Esto interpretará cada línea del fichero \`MASKPATTERN\` como una expresión regular, traducirá las cadenas que coincidan con ella, y revertirá tras el proceso. Las líneas que empiezan por `#` se ignoran.

Un patrón complejo puede escribirse en varias líneas con una barra invertida y una nueva línea.

Cómo se transforma el texto mediante el enmascaramiento puede verse con la opción **--xlate-mask**.

Esta interfaz es experimental y está sujeta a cambios en el futuro.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Invoca el proceso de traducción para cada área coincidente.

    Sin esta opción, **greple** se comporta como un comando de búsqueda normal. Por lo tanto, puede comprobar qué parte del archivo será objeto de la traducción antes de invocar el trabajo real.

    El resultado del comando va a la salida estándar, así que rediríjalo al archivo si es necesario, o considere usar el módulo [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    La opción **--xlate** llama a la opción **--xlate-color** con la opción **--color=nunca**.

    Con la opción **--xlate-fold**, el texto convertido se dobla por el ancho especificado. La anchura por defecto es 70 y puede ajustarse con la opción **--xlate-fold-width**. Se reservan cuatro columnas para la operación de repliegue, por lo que cada línea puede contener 74 caracteres como máximo.

- **--xlate-engine**=_engine_

    Especifica el motor de traducción que se utilizará. Si especifica el módulo del motor directamente, como `-Mxlate::deepl`, no necesita utilizar esta opción.

    En este momento, están disponibles los siguientes motores

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4.1
    - **gpt4o**: gpt-4o-mini

        La interfaz de **gpt-4o** es inestable y no se puede garantizar que funcione correctamente por el momento.

    - **gpt5**: gpt-5

- **--xlate-labor**
- **--xlabor**

    En lugar de llamar al motor de traducción, se espera que trabajen para. Después de preparar el texto a traducir, se copia en el portapapeles. Se espera que los pegue en el formulario, copie el resultado en el portapapeles y pulse Retorno.

- **--xlate-to** (Default: `EN-US`)

    Especifique el idioma de destino. Puede obtener los idiomas disponibles mediante el comando `deepl languages` si utiliza el motor **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Especifique el formato de salida del texto original y traducido.

    Los siguientes formatos distintos de `xtxt` asumen que la parte a traducir es una colección de líneas. De hecho, es posible traducir sólo una parte de una línea, pero especificar un formato distinto de `xtxt` no producirá resultados significativos.

    - **conflict**, **cm**

        El texto original y el convertido se imprimen en formato de marcador de conflicto [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Puede recuperar el archivo original con el siguiente comando [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        El texto original y el traducido salen en un estilo contenedor personalizado de markdown.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        El texto anterior se traducirá a lo siguiente en HTML.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        El número de dos puntos es 7 por defecto. Si especifica una secuencia de dos puntos como `:::::`, se utiliza en lugar de 7 dos puntos.

    - **ifdef**

        El texto original y el convertido se imprimen en formato [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Puede recuperar sólo el texto japonés mediante el comando **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        El texto original y el convertido se imprimen separados por una sola línea en blanco. Para `espacio+`, también se imprime una nueva línea después del texto convertido.

    - **xtxt**

        Si el formato es `xtxt` (texto traducido) o desconocido, sólo se imprime el texto traducido.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Especifique la longitud máxima del texto que se enviará a la API de una sola vez. El valor predeterminado es el mismo que para el servicio gratuito de cuenta DeepL: 128K para la API (**--xlate**) y 5000 para la interfaz del portapapeles (**--xlate-labor**). Puede cambiar estos valores si utiliza el servicio Pro.

- **--xlate-maxline**=_n_ (Default: 0)

    Especifique el número máximo de líneas de texto que se enviarán a la API de una sola vez.

    Establezca este valor en 1 si desea traducir una línea cada vez. Esta opción tiene prioridad sobre la opción `--xlate-maxlen`.

- **--xlate-prompt**=_text_

    Especifique un mensaje personalizado que se enviará al motor de traducción. Esta opción sólo está disponible cuando se utilizan motores ChatGPT (gpt3, gpt4, gpt4o). Puede personalizar el comportamiento de la traducción proporcionando instrucciones específicas al modelo de IA. Si la instrucción contiene `%s`, se sustituirá por el nombre del idioma de destino.

- **--xlate-context**=_text_

    Especifique la información de contexto adicional que se enviará al motor de traducción. Esta opción puede utilizarse varias veces para proporcionar varias cadenas de contexto. La información de contexto ayuda al motor de traducción a comprender el contexto y producir traducciones más precisas.

- **--xlate-glossary**=_glossary_

    Especifique un ID de glosario que se utilizará para la traducción. Esta opción sólo está disponible cuando se utiliza el motor DeepL. El ID del glosario debe obtenerse de su cuenta de DeepL y garantiza la traducción coherente de términos específicos.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Ver el resultado de la traducción en tiempo real en la salida STDERR.

- **--xlate-stripe**

    Utilice el módulo [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) para mostrar las partes coincidentes en forma de rayas de cebra. Esto es útil cuando las partes coincidentes están conectadas espalda con espalda.

    La paleta de colores cambia según el color de fondo del terminal. Si desea especificarlo explícitamente, puede utilizar **--xlate-stripe-light** o **--xlate-stripe-dark**.

- **--xlate-mask**

    Realiza la función de enmascaramiento y muestra el texto convertido tal cual sin restaurar.

- **--match-all**

    Establece todo el texto del fichero como área de destino.

- **--lineify-cm**
- **--lineify-colon**

    En el caso de los formatos `cm` y `colon`, la salida se divide y formatea línea por línea. Por lo tanto, si sólo se quiere traducir una parte de una línea, no se puede obtener el resultado esperado. Estos filtros corrigen la salida que se corrompe al traducir parte de una línea a la salida normal línea por línea.

    En la implementación actual, si se traducen varias partes de una línea, se emiten como líneas independientes.

# CACHE OPTIONS

El módulo **xlate** puede almacenar en caché el texto traducido de cada fichero y leerlo antes de la ejecución para eliminar la sobrecarga de preguntar al servidor. Con la estrategia de caché por defecto `auto`, mantiene los datos de caché sólo cuando el archivo de caché existe para el archivo de destino.

Utilice **--xlate-cache=clear** para iniciar la gestión de la caché o para limpiar todos los datos de caché existentes. Una vez ejecutado con esta opción, se creará un nuevo archivo de caché si no existe y se mantendrá automáticamente después.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Mantener el archivo de caché si existe.

    - `create`

        Crear un archivo de caché vacío y salir.

    - `always`, `yes`, `1`

        Mantener caché de todos modos hasta que el destino sea un archivo normal.

    - `clear`

        Borrar primero los datos de la caché.

    - `never`, `no`, `0`

        No utilizar nunca el archivo de caché aunque exista.

    - `accumulate`

        Por defecto, los datos no utilizados se eliminan del archivo de caché. Si no desea eliminarlos y mantenerlos en el archivo, utilice `acumular`.
- **--xlate-update**

    Esta opción obliga a actualizar el archivo de caché aunque no sea necesario.

# COMMAND LINE INTERFACE

Puede utilizar fácilmente este módulo desde la línea de comandos mediante el comando `xlate` incluido en la distribución. Consulte la página del manual `xlate` para más información.

El comando `xlate` admite opciones largas al estilo GNU como `--to-lang`, `--from-lang`, `--engine` y `--file`. Utilice `xlate -h` para ver todas las opciones disponibles.

El comando `xlate` funciona conjuntamente con el entorno Docker, por lo que incluso si no tiene nada instalado a mano, puede utilizarlo siempre que Docker esté disponible. Utilice la opción `-D` o `-C`.

Las operaciones Docker son manejadas por el script `xrun`, que también puede ser utilizado como un comando independiente. El script `xrun` soporta el archivo de configuración `.xrunrc` para la configuración persistente del contenedor.

Además, como se proporcionan makefiles para varios estilos de documento, la traducción a otros idiomas es posible sin especificación especial. Utilice la opción `-M`.

También puedes combinar las opciones Docker y `make` para poder ejecutar `make` en un entorno Docker.

Ejecutar como `xlate -C` lanzará un shell con el repositorio git de trabajo actual montado.

Lea el artículo japonés en la sección ["SEE TAMBIÉN"](#see-también) para más detalles.

# EMACS

Cargue el fichero `xlate.el` incluido en el repositorio para usar el comando `xlate` desde el editor Emacs. La función `xlate-region` traduce la región dada. El idioma por defecto es `EN-US` y puede especificar el idioma invocándolo con el argumento prefijo.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Establezca su clave de autenticación para el servicio DeepL.

- OPENAI\_API\_KEY

    Clave de autenticación OpenAI.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Debe instalar las herramientas de línea de comandos para DeepL y ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt4](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt4)

[App::Greple::xlate::gpt5](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt5)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Imagen de contenedor Docker.

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    La biblioteca `getoptlong.sh` se utiliza para el análisis sintáctico de opciones en los scripts `xlate` y `xrun`.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Librería Python y comando CLI.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Biblioteca OpenAI Python

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Interfaz de línea de comandos de OpenAI

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Vea el manual **greple** para los detalles sobre el patrón de texto objetivo. Utilice las opciones **--inside**, **--outside**, **--include**, **--exclude** para limitar el área de coincidencia.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Puede utilizar el módulo `-Mupdate` para modificar archivos según el resultado del comando **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Utilice **sdif** para mostrar el formato del marcador de conflicto junto con la opción **-V**.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Uso del módulo Greple **stripe** mediante la opción **--xlate-stripe**.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Módulo Greple para traducir y sustituir sólo las partes necesarias con DeepL API (en japonés)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Generación de documentos en 15 idiomas con el módulo API DeepL (en japonés)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Entorno Docker de traducción automática con DeepL API (en japonés)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
