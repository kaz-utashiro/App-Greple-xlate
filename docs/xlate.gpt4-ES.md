# NAME

App::Greple::xlate - módulo de soporte de traducción para greple

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

    greple -Mxlate::gpt4 --xlate pattern target-file

    greple -Mxlate::gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

# VERSION

Version 0.9921

# DESCRIPTION

**Greple** **xlate** el módulo encuentra los bloques de texto deseados y los reemplaza por el texto traducido. Actualmente, los módulos DeepL (`deepl.pm`), ChatGPT 4.1 (`gpt4.pm`) y GPT-5 (`gpt5.pm`) están implementados como motores de back-end.

Si desea traducir bloques de texto normales en un documento escrito en el estilo pod de Perl, utilice el comando **greple** con los módulos `xlate::deepl` y `perl` de la siguiente manera:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

En este comando, la cadena de patrón `^([\w\pP].*\n)+` significa líneas consecutivas que comienzan con letras alfanuméricas y de puntuación. Este comando muestra el área a traducir resaltada. La opción **--all** se utiliza para producir el texto completo.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Luego agregue la opción `--xlate` para traducir el área seleccionada. Así, encontrará las secciones deseadas y las reemplazará por la salida del comando **deepl**.

Por defecto, el texto original y el traducido se imprimen en el formato de "marcador de conflicto" compatible con [git(1)](http://man.he.net/man1/git). Usando el formato `ifdef`, puede obtener la parte deseada fácilmente con el comando [unifdef(1)](http://man.he.net/man1/unifdef). El formato de salida se puede especificar con la opción **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Si desea traducir todo el texto, utilice la opción **--match-all**. Esto es un atajo para especificar el patrón `(?s).+` que coincide con todo el texto.

Los datos en formato de marcador de conflicto pueden visualizarse en estilo lado a lado mediante el comando [sdif](https://metacpan.org/pod/App%3A%3Asdif) con la opción `-V`. Dado que no tiene sentido comparar por cada cadena, se recomienda la opción `--no-cdif`. Si no necesitas colorear el texto, especifica `--no-textcolor` (o `--no-tc`).

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

El procesamiento se realiza en las unidades especificadas, pero en el caso de una secuencia de varias líneas de texto no vacío, se convierten juntas en una sola línea. Esta operación se realiza de la siguiente manera:

- Eliminar los espacios en blanco al principio y al final de cada línea.
- Si una línea termina con un carácter de puntuación de ancho completo, concatenar con la siguiente línea.
- Si una línea termina con un carácter de ancho completo y la siguiente línea comienza con un carácter de ancho completo, concatenar las líneas.
- Si el final o el principio de una línea no es un carácter de ancho completo, concatenarlas insertando un carácter de espacio.

Los datos de caché se gestionan en función del texto normalizado, por lo que incluso si se realizan modificaciones que no afectan los resultados de la normalización, los datos de traducción en caché seguirán siendo efectivos.

Este proceso de normalización se realiza solo para el primer (0º) y los patrones de número par. Así, si se especifican dos patrones como sigue, el texto que coincida con el primer patrón se procesará después de la normalización, y no se realizará ningún proceso de normalización en el texto que coincida con el segundo patrón.

    greple -Mxlate -E normalized -E not-normalized

Por lo tanto, utilice el primer patrón para el texto que deba procesarse combinando varias líneas en una sola línea, y utilice el segundo patrón para el texto preformateado. Si no hay texto que coincida con el primer patrón, utilice un patrón que no coincida con nada, como `(?!)`.

# MASKING

Ocasionalmente, hay partes del texto que no deseas traducir. Por ejemplo, las etiquetas en archivos markdown. DeepL sugiere que en tales casos, la parte del texto que se debe excluir se convierta en etiquetas XML, se traduzca y luego se restaure después de completar la traducción. Para admitir esto, es posible especificar las partes que se deben enmascarar de la traducción.

    --xlate-setopt maskfile=MASKPATTERN

Esto interpretará cada línea del archivo \`MASKPATTERN\` como una expresión regular, traducirá las cadenas que coincidan y las revertirá después del procesamiento. Las líneas que comienzan con `#` se ignoran.

Un patrón complejo puede escribirse en varias líneas con una nueva línea escapada con barra invertida.

Cómo se transforma el texto mediante el enmascaramiento puede verse con la opción **--xlate-mask**.

Esta interfaz es experimental y está sujeta a cambios en el futuro.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Invoca el proceso de traducción para cada área coincidente.

    Sin esta opción, **greple** se comporta como un comando de búsqueda normal. Así puedes comprobar qué parte del archivo será objeto de la traducción antes de invocar el trabajo real.

    El resultado del comando va a la salida estándar, así que redirígelo a un archivo si es necesario, o considera usar el módulo [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    La opción **--xlate** llama a la opción **--xlate-color** con la opción **--color=never**.

    Con la opción **--xlate-fold**, el texto convertido se pliega por el ancho especificado. El ancho predeterminado es 70 y se puede establecer con la opción **--xlate-fold-width**. Se reservan cuatro columnas para la operación run-in, por lo que cada línea puede contener como máximo 74 caracteres.

- **--xlate-engine**=_engine_

    Especifica el motor de traducción que se va a utilizar. Si especificas el módulo del motor directamente, como `-Mxlate::deepl`, no necesitas usar esta opción.

    En este momento, los siguientes motores están disponibles

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4.1
    - **gpt4o**: gpt-4o-mini

        La interfaz de **gpt-4o** es inestable y no se puede garantizar que funcione correctamente en este momento.

    - **gpt5**: gpt-5

- **--xlate-labor**
- **--xlabor**

    En lugar de llamar al motor de traducción, se espera que trabajes manualmente. Después de preparar el texto a traducir, se copia al portapapeles. Se espera que lo pegues en el formulario, copies el resultado al portapapeles y presiones return.

- **--xlate-to** (Default: `EN-US`)

    Especifica el idioma de destino. Puedes obtener los idiomas disponibles con el comando `deepl languages` al usar el motor **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Especifica el formato de salida para el texto original y traducido.

    Los siguientes formatos, aparte de `xtxt`, asumen que la parte a traducir es una colección de líneas. De hecho, es posible traducir solo una parte de una línea, pero especificar un formato distinto de `xtxt` no producirá resultados significativos.

    - **conflict**, **cm**

        El texto original y el convertido se imprimen en formato de marcador de conflicto [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Puedes recuperar el archivo original con el siguiente comando [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        El texto original y el traducido se muestran en el estilo de contenedor personalizado de markdown.

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

        El número de dos puntos es 7 por defecto. Si especificas una secuencia de dos puntos como `:::::`, se utiliza en lugar de 7 dos puntos.

    - **ifdef**

        El texto original y el convertido se imprimen en formato [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Puedes recuperar solo el texto en japonés con el comando **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        El texto original y el texto convertido se imprimen separados por una sola línea en blanco.

    - **xtxt**

        Para `space+`, también se imprime una nueva línea después del texto convertido.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Si el formato es `xtxt` (texto traducido) o desconocido, solo se imprime el texto traducido.

- **--xlate-maxline**=_n_ (Default: 0)

    Especifique la longitud máxima del texto que se enviará a la API de una vez. El valor predeterminado se establece como para el servicio de cuenta gratuita de DeepL: 128K para la API (**--xlate**) y 5000 para la interfaz del portapapeles (**--xlate-labor**). Puede cambiar estos valores si utiliza el servicio Pro.

    Especifique el número máximo de líneas de texto que se enviarán a la API de una vez.

- **--xlate-prompt**=_text_

    Especifique un mensaje personalizado para enviar al motor de traducción. Esta opción solo está disponible cuando se utilizan motores ChatGPT (gpt3, gpt4, gpt4o). Puede personalizar el comportamiento de la traducción proporcionando instrucciones específicas al modelo de IA. Si el mensaje contiene `%s`, será reemplazado por el nombre del idioma de destino.

- **--xlate-context**=_text_

    Especifique información de contexto adicional para enviar al motor de traducción. Esta opción se puede usar varias veces para proporcionar múltiples cadenas de contexto. La información de contexto ayuda al motor de traducción a comprender el trasfondo y producir traducciones más precisas.

- **--xlate-glossary**=_glossary_

    Especifique un ID de glosario para usar en la traducción. Esta opción solo está disponible cuando se utiliza el motor DeepL. El ID de glosario debe obtenerse de su cuenta de DeepL y garantiza la traducción coherente de términos específicos.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Establezca este valor en 1 si desea traducir una línea a la vez. Esta opción tiene prioridad sobre la opción `--xlate-maxlen`.

- **--xlate-stripe**

    Vea el resultado de la traducción en tiempo real en la salida STDERR.

    Utilice el módulo [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) para mostrar la parte coincidente con un patrón de rayas tipo cebra. Esto es útil cuando las partes coincidentes están conectadas una tras otra.

- **--xlate-mask**

    La paleta de colores se cambia según el color de fondo del terminal. Si desea especificarlo explícitamente, puede usar **--xlate-stripe-light** o **--xlate-stripe-dark**.

- **--match-all**

    Realice la función de enmascaramiento y muestre el texto convertido tal cual sin restauración.

- **--lineify-cm**
- **--lineify-colon**

    En el caso de los formatos `cm` y `colon`, la salida se divide y se formatea línea por línea. Por lo tanto, si solo se traduce una parte de una línea, no se puede obtener el resultado esperado. Estos filtros corrigen la salida que se corrompe al traducir parte de una línea en una salida normal línea por línea.

    En la implementación actual, si se traducen varias partes de una línea, se muestran como líneas independientes.

# CACHE OPTIONS

Establezca todo el texto del archivo como área objetivo.

El módulo **xlate** puede almacenar texto traducido en caché para cada archivo y leerlo antes de la ejecución para eliminar la sobrecarga de solicitar al servidor. Con la estrategia de caché predeterminada `auto`, mantiene los datos en caché solo cuando existe el archivo de caché para el archivo objetivo.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Utilice **--xlate-cache=clear** para iniciar la gestión de caché o limpiar todos los datos de caché existentes. Una vez ejecutado con esta opción, se creará un nuevo archivo de caché si no existe y luego se mantendrá automáticamente.

    - `create`

        Mantenga el archivo de caché si existe.

    - `always`, `yes`, `1`

        Cree un archivo de caché vacío y salga.

    - `clear`

        Mantenga la caché de todos modos siempre que el objetivo sea un archivo normal.

    - `never`, `no`, `0`

        Borre primero los datos de la caché.

    - `accumulate`

        Nunca use el archivo de caché aunque exista.
- **--xlate-update**

    Por comportamiento predeterminado, los datos no utilizados se eliminan del archivo de caché. Si no desea eliminarlos y mantenerlos en el archivo, use `accumulate`.

# COMMAND LINE INTERFACE

Esta opción fuerza la actualización del archivo de caché aunque no sea necesario.

El comando `xlate` admite opciones largas al estilo GNU como `--to-lang`, `--from-lang`, `--engine` y `--file`. Utilice `xlate -h` para ver todas las opciones disponibles.

Puede utilizar fácilmente este módulo desde la línea de comandos usando el comando `xlate` incluido en la distribución. Consulte la página del manual `xlate` para su uso.

Las operaciones de Docker son gestionadas por el script `dozo`, que también puede usarse como un comando independiente. El script `dozo` admite el archivo de configuración `.dozorc` para ajustes persistentes del contenedor.

El comando `xlate` funciona en conjunto con el entorno Docker, por lo que incluso si no tiene nada instalado, puede usarlo siempre que Docker esté disponible. Use la opción `-D` o `-C`.

Además, dado que se proporcionan makefiles para varios estilos de documentos, la traducción a otros idiomas es posible sin especificaciones especiales. Use la opción `-M`.

También puede combinar las opciones Docker y `make` para que pueda ejecutar `make` en un entorno Docker.

Ejecutar como `xlate -C` iniciará una shell con el repositorio git de trabajo actual montado.

# EMACS

Carga el archivo `xlate.el` incluido en el repositorio para usar el comando `xlate` desde el editor Emacs. 

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    La función `xlate-region` traduce la región dada. El idioma predeterminado es `EN-US` y puedes especificar el idioma invocándolo con un argumento prefijo.

- OPENAI\_API\_KEY

    Configura tu clave de autenticación para el servicio DeepL.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Clave de autenticación de OpenAI.

Debes instalar las herramientas de línea de comandos para DeepL y ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

# SEE ALSO

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::gpt4](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt4)

[App::Greple::xlate::gpt5](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt5)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    [App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    La biblioteca `getoptlong.sh` se utiliza para el análisis de opciones en los scripts `xlate` y `dozo`.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    Imagen de contenedor Docker.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Biblioteca Python de DeepL y comando CLI.

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Biblioteca Python de OpenAI

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Interfaz de línea de comandos de OpenAI

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Consulta el manual **greple** para más detalles sobre el patrón de texto objetivo. Usa las opciones **--inside**, **--outside**, **--include**, **--exclude** para limitar el área de coincidencia.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Puedes usar el módulo `-Mupdate` para modificar archivos según el resultado del comando **greple**.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Usa **sdif** para mostrar el formato del marcador de conflicto lado a lado con la opción **-V**.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    El módulo Greple **stripe** se usa con la opción **--xlate-stripe**.

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Módulo Greple para traducir y reemplazar solo las partes necesarias con la API de DeepL (en japonés)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Generación de documentos en 15 idiomas con el módulo de la API de DeepL (en japonés)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
