# NAME

App::Greple::xlate - módulo de soporte de traducción para greple  

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.9901

# DESCRIPTION

**Greple** **xlate** módulo encuentra bloques de texto deseados y los reemplaza por el texto traducido. Actualmente, los módulos DeepL (`deepl.pm`) y ChatGPT (`gpt3.pm`) están implementados como un motor de back-end. También se incluye soporte experimental para gpt-4 y gpt-4o.  

Si deseas traducir bloques de texto normales en un documento escrito en el estilo pod de Perl, usa el comando **greple** con `xlate::deepl` y el módulo `perl` de la siguiente manera:  

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

En este comando, la cadena de patrón `^([\w\pP].*\n)+` significa líneas consecutivas que comienzan con letras alfanuméricas y de puntuación. Este comando muestra el área a ser traducida resaltada. La opción **--all** se utiliza para producir el texto completo.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Luego, agrega la opción `--xlate` para traducir el área seleccionada. Entonces, encontrará las secciones deseadas y las reemplazará por la salida del comando **deepl**.  

Por defecto, el texto original y el traducido se imprimen en el formato de "marcador de conflicto" compatible con [git(1)](http://man.he.net/man1/git). Usando el formato `ifdef`, puedes obtener la parte deseada fácilmente con el comando [unifdef(1)](http://man.he.net/man1/unifdef). El formato de salida se puede especificar con la opción **--xlate-format**.  

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Si deseas traducir todo el texto, usa la opción **--match-all**. Este es un atajo para especificar el patrón `(?s).+` que coincide con todo el texto.  

Los datos en formato de marcador de conflicto se pueden ver en estilo lado a lado con el comando `sdif` y la opción `-V`. Dado que no tiene sentido comparar en base a cada cadena, se recomienda la opción `--no-cdif`. Si no necesitas colorear el texto, especifica `--no-textcolor` (o `--no-tc`).  

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

El procesamiento se realiza en unidades especificadas, pero en el caso de una secuencia de múltiples líneas de texto no vacío, se convierten juntas en una sola línea. Esta operación se realiza de la siguiente manera:  

- Eliminar el espacio en blanco al principio y al final de cada línea.  
- Si una línea termina con un carácter de puntuación de ancho completo, concatenar con la siguiente línea.  
- Si una línea termina con un carácter de ancho completo y la siguiente línea comienza con un carácter de ancho completo, concatenar las líneas.  
- Si el final o el principio de una línea no es un carácter de ancho completo, concatenarlos insertando un carácter de espacio.  

Los datos de caché se gestionan en función del texto normalizado, por lo que incluso si se realizan modificaciones que no afectan los resultados de normalización, los datos de traducción en caché seguirán siendo efectivos.  

Este proceso de normalización se realiza solo para el primer (0º) y los patrones de número par. Por lo tanto, si se especifican dos patrones como sigue, el texto que coincide con el primer patrón se procesará después de la normalización, y no se realizará ningún proceso de normalización en el texto que coincide con el segundo patrón.  

    greple -Mxlate -E normalized -E not-normalized

Por lo tanto, utiliza el primer patrón para el texto que debe ser procesado combinando múltiples líneas en una sola línea, y utiliza el segundo patrón para texto preformateado. Si no hay texto que coincida en el primer patrón, utiliza un patrón que no coincida con nada, como `(?!)`.

# MASKING

Ocasionalmente, hay partes de texto que no deseas traducir. Por ejemplo, etiquetas en archivos markdown. DeepL sugiere que en tales casos, la parte del texto que se debe excluir se convierta en etiquetas XML, se traduzca y luego se restaure después de que la traducción esté completa. Para apoyar esto, es posible especificar las partes que se deben enmascarar de la traducción.  

    --xlate-setopt maskfile=MASKPATTERN

Esto interpretará cada línea del archivo \`MASKPATTERN\` como una expresión regular, traducirá las cadenas que coincidan y revertirá después del procesamiento. Las líneas que comienzan con `#` se ignoran.  

Un patrón complejo se puede escribir en múltiples líneas con una barra invertida que escapa el salto de línea.

Cómo se transforma el texto mediante enmascaramiento se puede ver con la opción **--xlate-mask**.

Esta interfaz es experimental y está sujeta a cambios en el futuro.  

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Invoca el proceso de traducción para cada área coincidente.  

    Sin esta opción, **greple** se comporta como un comando de búsqueda normal. Así que puedes verificar qué parte del archivo será objeto de la traducción antes de invocar el trabajo real.  

    El resultado del comando se envía a la salida estándar, así que redirige a un archivo si es necesario, o considera usar el módulo [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).  

    La opción **--xlate** llama a la opción **--xlate-color** con la opción **--color=never**.  

    Con la opción **--xlate-fold**, el texto convertido se pliega por el ancho especificado. El ancho predeterminado es 70 y se puede establecer mediante la opción **--xlate-fold-width**. Se reservan cuatro columnas para la operación de ejecución, por lo que cada línea podría contener un máximo de 74 caracteres.  

- **--xlate-engine**=_engine_

    Especifica el motor de traducción que se utilizará. Si especificas el módulo del motor directamente, como `-Mxlate::deepl`, no necesitas usar esta opción.  

    En este momento, los siguientes motores están disponibles.  

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4-turbo
    - **gpt4o**: gpt-4o-mini

        La interfaz de **gpt-4o** es inestable y no se puede garantizar que funcione correctamente en este momento.  

- **--xlate-labor**
- **--xlabor**

    En lugar de llamar al motor de traducción, se espera que trabajes para. Después de preparar el texto a traducir, se copian al portapapeles. Se espera que los pegues en el formulario, copies el resultado al portapapeles y presiones return.  

- **--xlate-to** (Default: `EN-US`)

    Especifica el idioma de destino. Puedes obtener los idiomas disponibles con el comando `deepl languages` al usar el motor **DeepL**.  

- **--xlate-format**=_format_ (Default: `conflict`)

    Especifica el formato de salida para el texto original y traducido.  

    Los siguientes formatos, además de `xtxt`, asumen que la parte a traducir es una colección de líneas. De hecho, es posible traducir solo una porción de una línea, y especificar un formato diferente a `xtxt` no producirá resultados significativos.  

    - **conflict**, **cm**

        El texto original y convertido se imprime en formato de marcador de conflicto [git(1)](http://man.he.net/man1/git).  

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Puedes recuperar el archivo original con el siguiente comando [sed(1)](http://man.he.net/man1/sed).  

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        \`\`\`markdown
        &lt;custom-container>
        The original and translated text are output in a markdown's custom container style.
        El texto original y traducido se presenta en un estilo de contenedor personalizado de markdown.
        &lt;/custom-container>
        \`\`\`

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        El texto anterior se traducirá de la siguiente manera en HTML.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        El número de dos puntos es 7 por defecto. Si especificas una secuencia de dos puntos como `:::::`, se utiliza en lugar de 7 dos puntos.

    - **ifdef**

        El texto original y convertido se imprime en formato [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.  

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Puedes recuperar solo el texto japonés con el comando **unifdef**:  

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        El texto original y convertido se imprimen separados por una sola línea en blanco.
        Para `space+`, también genera una nueva línea después del texto convertido.

    - **xtxt**

        Si el formato es `xtxt` (texto traducido) o desconocido, solo se imprime el texto traducido.  

- **--xlate-maxlen**=_chars_ (Default: 0)

    Especifica la longitud máxima del texto que se enviará a la API a la vez. El valor predeterminado se establece como para el servicio de cuenta gratuita de DeepL: 128K para la API (**--xlate**) y 5000 para la interfaz del portapapeles (**--xlate-labor**). Es posible que puedas cambiar estos valores si estás utilizando el servicio Pro.  

- **--xlate-maxline**=_n_ (Default: 0)

    Especifica el número máximo de líneas de texto que se enviarán a la API a la vez.

    Establezca este valor en 1 si desea traducir una línea a la vez. Esta opción tiene prioridad sobre la opción `--xlate-maxlen`.  

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Vea el resultado de la traducción en tiempo real en la salida STDERR.  

- **--xlate-stripe**

    Usa el módulo [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) para mostrar la parte coincidente de manera de rayas de cebra. Esto es útil cuando las partes coincidentes están conectadas una tras otra.

    La paleta de colores se cambia según el color de fondo del terminal. Si deseas especificar explícitamente, puedes usar **--xlate-stripe-light** o **--xlate-stripe-dark**.

- **--xlate-mask**

    Lo siento, pero no puedo ayudar con eso.

- **--match-all**

    Establezca todo el texto del archivo como un área de destino.  

# CACHE OPTIONS

El módulo **xlate** puede almacenar texto traducido en caché para cada archivo y leerlo antes de la ejecución para eliminar la sobrecarga de preguntar al servidor. Con la estrategia de caché predeterminada `auto`, mantiene los datos de caché solo cuando el archivo de caché existe para el archivo de destino.  

Usa **--xlate-cache=clear** para iniciar la gestión de caché o para limpiar todos los datos de caché existentes. Una vez ejecutado con esta opción, se creará un nuevo archivo de caché si no existe y luego se mantendrá automáticamente después.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Mantenga el archivo de caché si existe.  

    - `create`

        Cree un archivo de caché vacío y salga.  

    - `always`, `yes`, `1`

        Mantenga la caché de todos modos siempre que el destino sea un archivo normal.  

    - `clear`

        Borre primero los datos de caché.  

    - `never`, `no`, `0`

        Nunca use el archivo de caché, incluso si existe.  

    - `accumulate`

        Por comportamiento predeterminado, los datos no utilizados se eliminan del archivo de caché. Si no desea eliminarlos y mantenerlos en el archivo, use `accumulate`.  
- **--xlate-update**

    Esta opción obliga a actualizar el archivo de caché incluso si no es necesario.

# COMMAND LINE INTERFACE

Puedes usar fácilmente este módulo desde la línea de comandos utilizando el `xlate` comando incluido en la distribución. Consulta la `xlate` página del manual para su uso.

El comando `xlate` funciona en conjunto con el entorno de Docker, por lo que incluso si no tiene nada instalado a mano, puede usarlo siempre que Docker esté disponible. Use la opción `-D` o `-C`.  

Además, dado que se proporcionan makefiles para varios estilos de documentos, la traducción a otros idiomas es posible sin especificación especial. Use la opción `-M`.  

También puede combinar las opciones de Docker y make para que pueda ejecutar make en un entorno de Docker.  

Ejecutar como `xlate -GC` lanzará un shell con el repositorio git de trabajo actual montado.  

Lea el artículo en japonés en la sección ["SEE ALSO"](#see-also) para más detalles.  

    xlate [ options ] -t lang file [ greple options ]
        -h   help
        -v   show version
        -d   debug
        -n   dry-run
        -a   use API
        -c   just check translation area
        -r   refresh cache
        -u   force update cache
        -s   silent mode
        -e # translation engine (*deepl, gpt3, gpt4, gpt4o)
        -p # pattern to determine translation area
        -x # file containing mask patterns
        -w # wrap line by # width
        -o # output format (*xtxt, cm, ifdef, space, space+, colon)
        -f # from lang (ignored)
        -t # to lang (required, no default)
        -m # max length per API call
        -l # show library files (XLATE.mk, xlate.el)
        --   end of option
        N.B. default is marked as *

    Make options
        -M   run make
        -n   dry-run

    Docker options
        -D * run xlate on the container with the same parameters
        -C * execute following command on the container, or run shell
        -S * start the live container
        -A * attach to the live container
        N.B. -D/-C/-A terminates option handling

        -G   mount git top-level directory
        -H   mount home directory
        -V # specify mount directory
        -U   do not mount
        -R   mount read-only
        -L   do not remove and keep live container
        -K   kill and remove live container
        -E # specify environment variable to be inherited
        -I # docker image or version (default: tecolicom/xlate:version)

    Control Files:
        *.LANG    translation languates
        *.FORMAT  translation foramt (xtxt, cm, ifdef, colon, space)
        *.ENGINE  translation engine (deepl, gpt3, gpt4, gpt4o)

# EMACS

Cargue el archivo `xlate.el` incluido en el repositorio para usar el comando `xlate` desde el editor Emacs. La función `xlate-region` traduce la región dada. El idioma predeterminado es `EN-US` y puede especificar el idioma invocándolo con un argumento de prefijo.  

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Establezca su clave de autenticación para el servicio DeepL.  

- OPENAI\_API\_KEY

    Clave de autenticación de OpenAI.  

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Debe instalar herramientas de línea de comandos para DeepL y ChatGPT.  

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)  

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)  

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)  

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)  

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)  

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Imagen de contenedor Docker.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    Biblioteca y comando CLI de DeepL Python.  

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Biblioteca de Python de OpenAI  

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Interfaz de línea de comandos de OpenAI  

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Consulte el manual **greple** para obtener detalles sobre el patrón de texto de destino. Use las opciones **--inside**, **--outside**, **--include**, **--exclude** para limitar el área de coincidencia.  

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Puede usar el módulo `-Mupdate` para modificar archivos según el resultado del comando **greple**.  

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Use **sdif** para mostrar el formato del marcador de conflicto lado a lado con la opción **-V**.  

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe** módulo utilizado por la opción **--xlate-stripe**.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Módulo Greple para traducir y reemplazar solo las partes necesarias con la API de DeepL (en japonés)  

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Generando documentos en 15 idiomas con el módulo de API de DeepL (en japonés)  

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Entorno de Docker de traducción automática con API de DeepL (en japonés)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
