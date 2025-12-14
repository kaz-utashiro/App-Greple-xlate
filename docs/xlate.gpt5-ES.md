# NAME

App::Greple::xlate - módulo de soporte de traducción para greple

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

    greple -Mxlate::gpt4 --xlate pattern target-file

    greple -Mxlate::gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

# VERSION

Version 0.9919

# DESCRIPTION

**Greple** **xlate** el módulo encuentra los bloques de texto deseados y los reemplaza por el texto traducido. Actualmente, los módulos DeepL (`deepl.pm`), ChatGPT 4.1 (`gpt4.pm`) y GPT-5 (`gpt5.pm`) están implementados como motor de back-end.

Si desea traducir bloques de texto normales en un documento escrito en el estilo pod de Perl, use el comando **greple** con los módulos `xlate::deepl` y `perl` de esta manera:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

En este comando, la cadena de patrón `^([\w\pP].*\n)+` significa líneas consecutivas que comienzan con letras alfanuméricas y signos de puntuación. Este comando muestra el área a traducir resaltada. La opción **--all** se utiliza para producir el texto completo.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Luego agregue la opción `--xlate` para traducir el área seleccionada. Entonces, encontrará las secciones deseadas y las reemplazará por la salida del comando **deepl**.

De forma predeterminada, el texto original y el traducido se imprimen en el formato de "marcador de conflicto" compatible con [git(1)](http://man.he.net/man1/git). Usando el formato `ifdef`, puede obtener la parte deseada fácilmente con el comando [unifdef(1)](http://man.he.net/man1/unifdef). El formato de salida puede especificarse con la opción **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Si desea traducir todo el texto, use la opción **--match-all**. Este es un atajo para especificar el patrón `(?s).+` que coincide con todo el texto.

Los datos en formato de marcador de conflicto pueden visualizarse en estilo lado a lado con el comando [sdif](https://metacpan.org/pod/App%3A%3Asdif) y la opción `-V`. Dado que no tiene sentido comparar por cadena, se recomienda la opción `--no-cdif`. Si no necesita colorear el texto, especifique `--no-textcolor` (o `--no-tc`).

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

El procesamiento se realiza en unidades especificadas, pero en el caso de una secuencia de múltiples líneas de texto no vacío, se convierten juntas en una sola línea. Esta operación se realiza de la siguiente manera:

- Eliminar los espacios en blanco al principio y al final de cada línea.
- Si una línea termina con un signo de puntuación de ancho completo, concatenar con la siguiente línea.
- Si una línea termina con un carácter de ancho completo y la siguiente línea comienza con un carácter de ancho completo, concatenar las líneas.
- Si el final o el comienzo de una línea no es un carácter de ancho completo, concatenarlas insertando un espacio.

Los datos de caché se gestionan en función del texto normalizado, por lo que incluso si se realizan modificaciones que no afecten los resultados de la normalización, los datos de traducción en caché seguirán siendo efectivos.

Este proceso de normalización se realiza solo para el primer (índice 0) y los patrones de número par. Por lo tanto, si se especifican dos patrones como se indica a continuación, el texto que coincida con el primer patrón se procesará después de la normalización, y no se realizará ningún proceso de normalización en el texto que coincida con el segundo patrón.

    greple -Mxlate -E normalized -E not-normalized

Por lo tanto, use el primer patrón para el texto que deba procesarse combinando múltiples líneas en una sola línea, y use el segundo patrón para texto preformateado. Si no hay texto que coincida en el primer patrón, use un patrón que no coincida con nada, como `(?!)`.

# MASKING

Ocasionalmente, hay partes del texto que no desea traducir. Por ejemplo, etiquetas en archivos markdown. DeepL sugiere que, en tales casos, la parte del texto a excluir se convierta en etiquetas XML, se traduzca y luego se restaure una vez completada la traducción. Para admitir esto, es posible especificar las partes que se deben enmascarar de la traducción.

    --xlate-setopt maskfile=MASKPATTERN

Esto interpretará cada línea del archivo \`MASKPATTERN\` como una expresión regular, traducirá las cadenas que coincidan con ella y revertirá después del procesamiento. Las líneas que comienzan con `#` se ignoran.

Un patrón complejo puede escribirse en múltiples líneas con salto de línea escapado con barra invertida.

Cómo se transforma el texto mediante el enmascaramiento puede verse con la opción **--xlate-mask**.

Esta interfaz es experimental y está sujeta a cambios en el futuro.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Invoque el proceso de traducción para cada área coincidente.

    Sin esta opción, **greple** se comporta como un comando de búsqueda normal. Así puede comprobar qué parte del archivo será objeto de la traducción antes de iniciar el trabajo real.

    El resultado del comando va a la salida estándar, así que rediríjalo a un archivo si es necesario, o considere usar el módulo [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    La opción **--xlate** llama a la opción **--xlate-color** con la opción **--color=never**.

    Con la opción **--xlate-fold**, el texto convertido se ajusta al ancho especificado. El ancho predeterminado es 70 y puede establecerse con la opción **--xlate-fold-width**. Se reservan cuatro columnas para la operación de run-in, por lo que cada línea puede contener como máximo 74 caracteres.

- **--xlate-engine**=_engine_

    Especifica el motor de traducción a utilizar. Si especifica directamente el módulo del motor, como `-Mxlate::deepl`, no necesita usar esta opción.

    En este momento, están disponibles los siguientes motores

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4.1
    - **gpt4o**: gpt-4o-mini

        La interfaz de **gpt-4o** es inestable y no se puede garantizar que funcione correctamente en este momento.

    - **gpt5**: gpt-5

- **--xlate-labor**
- **--xlabor**

    En lugar de llamar al motor de traducción, se espera que usted trabaje manualmente. Después de preparar el texto a traducir, se copia al portapapeles. Se espera que lo pegue en el formulario, copie el resultado al portapapeles y presione regresar.

- **--xlate-to** (Default: `EN-US`)

    Especifique el idioma de destino. Puede obtener los idiomas disponibles con el comando `deepl languages` cuando use el motor **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Especifique el formato de salida para el texto original y el traducido.

    Los siguientes formatos distintos de `xtxt` asumen que la parte a traducir es una colección de líneas. De hecho, es posible traducir solo una parte de una línea, pero especificar un formato distinto de `xtxt` no producirá resultados significativos.

    - **conflict**, **cm**

        El texto original y el convertido se imprimen en formato de marcadores de conflicto de [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Puede recuperar el archivo original con el siguiente comando [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        El texto original y el traducido se muestran en un estilo de contenedor personalizado de markdown.

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

        El número de dos puntos es 7 por defecto. Si especifica una secuencia de dos puntos como `:::::`, se usa en lugar de 7 dos puntos.

    - **ifdef**

        El texto original y el convertido se imprimen en formato [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Puede recuperar solo el texto japonés con el comando **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        El texto original y el convertido se imprimen separados por una sola línea en blanco. Para `space+`, también se imprime una nueva línea después del texto convertido.

    - **xtxt**

        Si el formato es `xtxt` (texto traducido) o desconocido, solo se imprime el texto traducido.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Especifique la longitud máxima del texto que se enviará a la API de una vez. El valor predeterminado se establece como para el servicio de cuenta gratuita de DeepL: 128K para la API (**--xlate**) y 5000 para la interfaz del portapapeles (**--xlate-labor**). Es posible que pueda cambiar estos valores si utiliza el servicio Pro.

- **--xlate-maxline**=_n_ (Default: 0)

    Especifique el número máximo de líneas de texto que se enviarán a la API de una vez.

    Establezca este valor en 1 si desea traducir una línea a la vez. Esta opción tiene prioridad sobre la opción `--xlate-maxlen`.

- **--xlate-prompt**=_text_

    Especifique un prompt personalizado que se enviará al motor de traducción. Esta opción solo está disponible al usar motores de ChatGPT (gpt3, gpt4, gpt4o). Puede personalizar el comportamiento de la traducción proporcionando instrucciones específicas al modelo de IA. Si el prompt contiene `%s`, se reemplazará con el nombre del idioma de destino.

- **--xlate-context**=_text_

    Especifique información de contexto adicional que se enviará al motor de traducción. Esta opción se puede usar varias veces para proporcionar múltiples cadenas de contexto. La información de contexto ayuda al motor de traducción a comprender el trasfondo y producir traducciones más precisas.

- **--xlate-glossary**=_glossary_

    Especifique un ID de glosario que se utilizará para la traducción. Esta opción solo está disponible al usar el motor de DeepL. El ID de glosario debe obtenerse de su cuenta de DeepL y garantiza una traducción coherente de términos específicos.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Vea el resultado de la traducción en tiempo real en la salida STDERR.

- **--xlate-stripe**

    Use el módulo [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) para mostrar la parte coincidente con un estilo de rayas tipo cebra. Esto es útil cuando las partes coincidentes están conectadas consecutivamente.

    La paleta de colores se cambia según el color de fondo de la terminal. Si desea especificarlo explícitamente, puede usar **--xlate-stripe-light** o **--xlate-stripe-dark**.

- **--xlate-mask**

    Realice la función de enmascaramiento y muestre el texto convertido tal cual sin restauración.

- **--match-all**

    Establezca todo el texto del archivo como área objetivo.

- **--lineify-cm**
- **--lineify-colon**

    En el caso de los formatos `cm` y `colon`, la salida se divide y se formatea línea por línea. Por lo tanto, si solo se traduce una parte de una línea, no se puede obtener el resultado esperado. Estos filtros corrigen la salida que se corrompe al traducir parte de una línea a una salida normal línea por línea.

    En la implementación actual, si se traducen múltiples partes de una línea, se generan como líneas independientes.

# CACHE OPTIONS

El módulo **xlate** puede almacenar en caché el texto de la traducción para cada archivo y leerlo antes de la ejecución para eliminar la sobrecarga de consultar al servidor. Con la estrategia de caché predeterminada `auto`, mantiene los datos de la caché solo cuando el archivo de caché existe para el archivo de destino.

Use **--xlate-cache=clear** para iniciar la gestión de la caché o para limpiar todos los datos de caché existentes. Una vez ejecutado con esta opción, se creará un nuevo archivo de caché si no existe y luego se mantendrá automáticamente.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Mantenga el archivo de caché si existe.

    - `create`

        Cree un archivo de caché vacío y salga.

    - `always`, `yes`, `1`

        Mantén la caché de todos modos siempre que el destino sea un archivo normal.

    - `clear`

        Borra primero los datos de la caché.

    - `never`, `no`, `0`

        Nunca uses el archivo de caché aunque exista.

    - `accumulate`

        Por defecto, los datos no utilizados se eliminan del archivo de caché. Si no quieres eliminarlos y prefieres mantenerlos en el archivo, usa `accumulate`.
- **--xlate-update**

    Esta opción fuerza la actualización del archivo de caché aunque no sea necesaria.

# COMMAND LINE INTERFACE

Puedes usar fácilmente este módulo desde la línea de comandos utilizando el comando `xlate` incluido en la distribución. Consulta la página del manual `xlate` para su uso.

El comando `xlate` admite opciones largas al estilo GNU como `--to-lang`, `--from-lang`, `--engine` y `--file`. Use `xlate -h` para ver todas las opciones disponibles.

El comando `xlate` funciona en conjunto con el entorno Docker, por lo que, incluso si no tienes nada instalado localmente, puedes usarlo siempre que Docker esté disponible. Usa la opción `-D` o `-C`.

Las operaciones de Docker son gestionadas por el script `dozo`, que también puede utilizarse como un comando independiente. El script `dozo` admite el archivo de configuración `.dozorc` para configuraciones persistentes del contenedor.

Además, dado que se proporcionan makefiles para varios estilos de documentos, es posible la traducción a otros idiomas sin especificaciones especiales. Usa la opción `-M`.

También puedes combinar las opciones Docker y `make` para poder ejecutar `make` en un entorno Docker.

Ejecutar como `xlate -C` iniciará una shell con el repositorio git de trabajo actual montado.

Lee el artículo en japonés en la sección ["SEE ALSO"](#see-also) para más detalles.

# EMACS

Carga el archivo `xlate.el` incluido en el repositorio para usar el comando `xlate` desde el editor Emacs. La función `xlate-region` traduce la región indicada. El idioma predeterminado es `EN-US` y puedes especificar el idioma invocándola con un argumento prefijo.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

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

[App::Greple::xlate::gpt4](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt4)

[App::Greple::xlate::gpt5](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt5)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Imagen de contenedor Docker.

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    La biblioteca `getoptlong.sh` se utiliza para el análisis de opciones en los scripts `xlate` y `dozo`.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    Biblioteca de Python y comando CLI de DeepL.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Biblioteca de Python de OpenAI

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Interfaz de línea de comandos de OpenAI

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Consulta el manual **greple** para más detalles sobre el patrón de texto objetivo. Usa las opciones **--inside**, **--outside**, **--include**, **--exclude** para limitar el área de coincidencia.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Puedes usar el módulo `-Mupdate` para modificar archivos con el resultado del comando **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Usa **sdif** para mostrar el formato de marcador de conflicto junto con la opción **-V**.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Módulo de Greple **stripe** usado con la opción **--xlate-stripe**.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Módulo de Greple para traducir y reemplazar solo las partes necesarias con la API de DeepL (en japonés)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Generación de documentos en 15 idiomas con el módulo de la API de DeepL (en japonés)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Entorno Docker de traducción automática con la API de DeepL (en japonés)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
