# Greple -Mxlate Module Sample File

This directory contains examples of automatically translating files using Greple's -Mxlate module.

If you are reading this text in a language other than Japanese, it was automatically translated and generated using this system. Please bear with any oddities. If you are reading it in Japanese and still find something strange, it's because the author's head is a bit off, so please either bear with it or kindly point it out.

Just place the document file you want to translate and run the make command to generate the necessary files. Currently, the following types of files are supported:

- `*.docx`
- `*.pptx`
- `*.txt`
- `*.md`
- `*.pm`

## Generated Files

### For a Single ENGINE

If nothing is specified, three types of files—`xtxt`, `cm`, and `ifdef`—are created for each target language.

For example, if you translate a file called `Document.txt` into Japanese,

    Document.txt.JA.xtxt
    Document.txt.JA.cm
    Document.txt.JA.ifdef

these three files will be generated. The `xtxt` file contains only the translated text, while `cm` and `ifdef` contain both the original and translated text.

### For Multiple ENGINES

If both `deepl` and `gpt4` are specified in ENGINE, files including the engine name will be generated as follows.

    Document.txt.deepl-JA.xtxt
    Document.txt.deepl-JA.cm
    Document.txt.deepl-JA.ifdef
    Document.txt.gpt4-EN.xtxt
    Document.txt.gpt4-EN.cm
    Document.txt.gpt4-EN.ifdef

## Line Wrapping

If you add `-fold` at the end of the format specification, such as `cm-fold`, the output will be wrapped at 80 columns.

## Control Files

If a file with a specific extension exists for the target file, you can control the translation process based on its contents. For example, if there is a file called `Document.txt.LANG` along with `Document.txt`, it will be translated into the language written in that file.

### .ENGINE

Translation engine specification. The default `deepl` and `gpt4` can be specified. The default is `deepl`.

### .LANG

Specifies the target language for translation.

### .FORMAT

Specifies the translation format. Normally, choose from `xtxt`, `cm`, or `ifdef`.

You can also specify other formats, such as `md`, but in that case, the content will be the same as `xtxt`. However, if you generate a file ending with `.md`, it will also be targeted for translation next time, so use it with caution.

## Translation Process

By default, when the text to be translated is copied to the clipboard, a prompt will appear to start the translation process. Use the DeepL application or web interface to translate it, copy the result back to the clipboard, and then press the Enter key.

### Character Limit

If you are using a free account, you can only process up to 5,000 characters at a time, so repeat this process until all the text is processed.

If you are using a paid account and there is no character limit, set the upper limit in the `MAXLEN` variable when running.

    make MAXLEN=100000

### Using the DeepL API

To use the API for translation, the `deepl` command must be installed. Set the `USEAPI` variable and run make. However, if you are running in a Docker container, the `deepl` command is not required.

    make USEAPI=yes

When using the API, the maximum number of characters is set to 128K. Set the authentication key in the environment variable `DEEPL_AUTH_KEY`. Set other environment variables such as `DEEPL_SERVER_URL` as needed.

### Using a Docker Container

Enable the `DOCKER` variable and run make.

    make DOCKER=yes

### `XLATE_OPT` Variable

You can also specify options to pass to the `xlate` command.

    For example, if you run

make XLATE_OPT=-Dam100000

you can use the API, set the character limit to 100,000, and run it on Docker.

## xlate Script

Initially, these files were processed by the Makefile, but now the settings used there have been made more general, and processing is automatically handled by a script called `xlate`. Therefore, the current Makefile simply calls the `xlate` command. The Makefile used by `xlate` is located at `../share/XLATE.mk`.

To see help, run `xlate -h`.

### `xlate -M`

Runs make.

### `xlate -D`

Runs the xlate command in a Docker environment.

### `xlate -C`

Runs a command in a Docker environment.

If you specify a command after `-C`, that command will be executed. If nothing is specified, a shell will start.

By default, the current directory is mounted to the `/work` directory. If you want to use a git environment, use the `-G` option below.

If you want to mount as read-only, specify the `-R` option.

#### `xlate -G`

When building a Docker environment, mounts the top directory of the current git repository.

#### `xlate -GM`

Mounts the current git repository and runs make in the Docker environment.

If you want to check what command will be executed, you can specify the `-n` option as in `xlate -GMn`.

#### `xlate -GC`

Since Git and other tools are already installed, you can start working right away. Please note that because the working directory is mounted, any changes you make there will be reflected in the original files.
