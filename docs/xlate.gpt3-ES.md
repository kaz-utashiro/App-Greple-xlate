# NAME

App::Greple::xlate - módulo de soporte de traducción para greple

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.3401

# DESCRIPTION

El módulo **Greple** **xlate** encuentra bloques de texto deseados y los reemplaza por el texto traducido. Actualmente, los módulos DeepL (`deepl.pm`) y ChatGPT (`gpt3.pm`) están implementados como motores de backend. También se incluye soporte experimental para gpt-4 y gpt-4o.

Si quieres traducir bloques de texto normales en un documento escrito en el estilo pod de Perl, utiliza el comando **greple** con los módulos `xlate::deepl` y `perl` de la siguiente manera:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

En este comando, la cadena de patrón `^(\w.*\n)+` significa líneas consecutivas que comienzan con una letra alfanumérica. Este comando muestra el área que se va a traducir resaltada. La opción **--all** se utiliza para producir todo el texto.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Luego agregue la opción `--xlate` para traducir el área seleccionada. Luego, encontrará las secciones deseadas y las reemplazará por la salida del comando **deepl**.

Por defecto, el texto original y traducido se imprime en el formato de "marcador de conflicto" compatible con [git(1)](http://man.he.net/man1/git). Utilizando el formato `ifdef`, puedes obtener la parte deseada fácilmente con el comando [unifdef(1)](http://man.he.net/man1/unifdef). El formato de salida se puede especificar con la opción **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Si deseas traducir todo el texto, utiliza la opción **--match-all**. Esto es un atajo para especificar el patrón `(?s).+` que coincide con todo el texto.

El formato de datos de marcador de conflicto se puede ver en estilo lado a lado con el comando `sdif` con la opción `-V`. Dado que no tiene sentido comparar en base a cada cadena, se recomienda la opción `--no-cdif`. Si no necesita colorear el texto, especifique `--no-textcolor` (o `--no-tc`).

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

El procesamiento se realiza en unidades especificadas, pero en el caso de una secuencia de múltiples líneas de texto no vacías, se convierten juntas en una sola línea. Esta operación se realiza de la siguiente manera:

- Eliminar los espacios en blanco al principio y al final de cada línea.
- Si una línea termina con un carácter de puntuación de ancho completo, concaténala con la siguiente línea.
- Si una línea termina con un carácter de ancho completo y la siguiente línea comienza con un carácter de ancho completo, concatenar las líneas.
- Si el final o el principio de una línea no es un carácter de ancho completo, concatenarlos insertando un carácter de espacio.

Los datos en caché se gestionan en base al texto normalizado, por lo que incluso si se realizan modificaciones que no afectan los resultados de normalización, los datos de traducción en caché seguirán siendo efectivos.

Este proceso de normalización se realiza solo para el primer (0º) y el patrón de número par. Por lo tanto, si se especifican dos patrones de la siguiente manera, el texto que coincide con el primer patrón se procesará después de la normalización, y no se realizará ningún proceso de normalización en el texto que coincida con el segundo patrón.

    greple -Mxlate -E normalized -E not-normalized

Por lo tanto, use el primer patrón para el texto que se va a procesar combinando varias líneas en una sola línea, y use el segundo patrón para texto preformateado. Si no hay texto que coincida con el primer patrón, entonces use un patrón que no coincida con nada, como `(?!)`.

# MASKING

Ocasionalmente, hay partes de texto que no deseas traducir. Por ejemplo, etiquetas en archivos markdown. DeepL sugiere que en tales casos, la parte del texto a excluir se convierta en etiquetas XML, se traduzca y luego se restaure después de que la traducción esté completa. Para admitir esto, es posible especificar las partes a enmascarar en la traducción.

    --xlate-setopt maskfile=MASKPATTERN

Esto interpretará cada línea del archivo \`MASKPATTERN\` como una expresión regular, traducirá las cadenas que coincidan con ella y las revertirá después del procesamiento. Las líneas que comienzan con `#` son ignoradas.

Esta interfaz es experimental y está sujeta a cambios en el futuro.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Invoque el proceso de traducción para cada área coincidente.

    Sin esta opción, **greple** se comporta como un comando de búsqueda normal. Por lo tanto, puede verificar qué parte del archivo será objeto de la traducción antes de invocar el trabajo real.

    El resultado del comando se envía a la salida estándar, así que rediríjalo a un archivo si es necesario, o considere usar el módulo [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    La opción **--xlate** llama a la opción **--xlate-color** con la opción **--color=never**.

    Con la opción **--xlate-fold**, el texto convertido se pliega según el ancho especificado. El ancho predeterminado es 70 y se puede establecer mediante la opción **--xlate-fold-width**. Cuatro columnas están reservadas para la operación de ejecución, por lo que cada línea puede contener como máximo 74 caracteres.

- **--xlate-engine**=_engine_

    Especifica el motor de traducción que se utilizará. Si especificas directamente el módulo del motor, como `-Mxlate::deepl`, no necesitas usar esta opción.

    En este momento, están disponibles los siguientes motores:

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4-turbo
    - **gpt4o**: gpt-4o-mini

        La interfaz de **gpt-4o** es inestable y no se puede garantizar que funcione correctamente en este momento.

- **--xlate-labor**
- **--xlabor**

    En lugar de llamar al motor de traducción, se espera que trabajes tú. Después de preparar el texto para ser traducido, se copian al portapapeles. Se espera que los pegues en el formulario, copies el resultado al portapapeles y presiones Enter.

- **--xlate-to** (Default: `EN-US`)

    Especifique el idioma de destino. Puede obtener los idiomas disponibles mediante el comando `deepl languages` cuando se utiliza el motor **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Especifique el formato de salida para el texto original y traducido.

    Los siguientes formatos distintos a `xtxt` asumen que la parte a traducir es una colección de líneas. De hecho, es posible traducir solo una parte de una línea, y especificar un formato distinto a `xtxt` no producirá resultados significativos.

    - **conflict**, **cm**

        Original and converted text are printed in [git(1)](http://man.he.net/man1/git) conflict marker format.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Puede recuperar el archivo original con el siguiente comando [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        <<<<<<< HEAD

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Puede recuperar solo el texto en japonés con el comando **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        Original and converted text are printed in [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` format.

    - **xtxt**

        Si el formato es `xtxt` (texto traducido) o desconocido, solo se imprime el texto traducido.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Especifique la longitud máxima del texto a enviar a la API de DeepL. El valor predeterminado es el establecido para la cuenta gratuita de DeepL: 128K para la API (**--xlate**) y 5000 para la interfaz del portapapeles (**--xlate-labor**). Es posible que pueda cambiar estos valores si está utilizando el servicio Pro.

- **--xlate-maxline**=_n_ (Default: 0)

    Especifica el máximo de líneas de texto a enviar a la API a la vez.

    Establece este valor en 1 si deseas traducir una línea a la vez. Esta opción tiene prioridad sobre la opción `--xlate-maxlen`.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Vea el resultado de la traducción en tiempo real en la salida STDERR.

- **--match-all**

    Establezca todo el texto del archivo como un área objetivo.

# CACHE OPTIONS

El módulo **xlate** puede almacenar el texto traducido en caché para cada archivo y leerlo antes de la ejecución para eliminar la sobrecarga de preguntar al servidor. Con la estrategia de caché predeterminada `auto`, mantiene los datos en caché solo cuando el archivo de caché existe para el archivo objetivo.

- --cache-clear

    La opción **--cache-clear** se puede utilizar para iniciar la gestión de la caché o para actualizar todos los datos de caché existentes. Una vez ejecutado con esta opción, se creará un nuevo archivo de caché si no existe y luego se mantendrá automáticamente.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Mantenga el archivo de caché si existe.

    - `create`

        Cree un archivo de caché vacío y salga.

    - `always`, `yes`, `1`

        Mantenga la caché de todos modos siempre que el objetivo sea un archivo normal.

    - `clear`

        Borre primero los datos de la caché.

    - `never`, `no`, `0`

        Nunca use el archivo de caché incluso si existe.

    - `accumulate`

        Por defecto, los datos no utilizados se eliminan del archivo de caché. Si no desea eliminarlos y mantenerlos en el archivo, use `accumulate`.

# COMMAND LINE INTERFACE

Puedes usar fácilmente este módulo desde la línea de comandos utilizando el comando `xlate` incluido en la distribución. Consulta la información de ayuda de `xlate` para ver cómo se utiliza.

El comando `xlate` funciona en conjunto con el entorno Docker, por lo que incluso si no tienes nada instalado, puedes usarlo siempre que Docker esté disponible. Utiliza la opción `-D` o `-C`.

Además, dado que se proporcionan makefiles para varios estilos de documentos, es posible realizar traducciones a otros idiomas sin especificaciones especiales. Utiliza la opción `-M`.

También puedes combinar las opciones de Docker y make para ejecutar make en un entorno Docker.

Ejecutar algo como `xlate -GC` abrirá una terminal con el repositorio git de trabajo actual montado.

Lea el artículo en japonés en la sección "VER TAMBIÉN" para más detalles.

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

Carga el archivo `xlate.el` incluido en el repositorio para usar el comando `xlate` desde el editor Emacs. La función `xlate-region` traduce la región dada. El idioma predeterminado es `EN-US` y puedes especificar el idioma invocándolo con un argumento de prefijo.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Configura tu clave de autenticación para el servicio DeepL.

- OPENAI\_API\_KEY

    Clave de autenticación de OpenAI.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Debes instalar las herramientas de línea de comandos para DeepL y ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

[https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    Biblioteca de Python y comando CLI de DeepL.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Biblioteca de Python de OpenAI

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Interfaz de línea de comandos de OpenAI

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Consulta el manual de **greple** para obtener detalles sobre el patrón de texto objetivo. Utiliza las opciones **--inside**, **--outside**, **--include** y **--exclude** para limitar el área de coincidencia.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Puedes usar el módulo `-Mupdate` para modificar archivos según el resultado del comando **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Utiliza **sdif** para mostrar el formato de marcador de conflicto junto con la opción **-V**.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Módulo Greple para traducir y reemplazar solo las partes necesarias con la API de DeepL (en japonés)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Generando documentos en 15 idiomas con el módulo de API de DeepL (en japonés)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Entorno Docker de traducción automática con la API de DeepL (en japonés)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
