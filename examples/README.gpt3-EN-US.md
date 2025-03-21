# Greple -Mxlate Module Sample File

This directory contains examples of automatically translating files using the Greple -Mxlate module.

If you are reading this text in a language other than Japanese, it has been automatically translated using this mechanism. Please bear with any oddities. If you notice any oddities even when reading in Japanese, it's because the author is a bit strange, so please either bear with it or kindly point it out.

Simply place the document file you want to translate and execute the make command to generate the necessary files. Currently, the following types of files are targeted:

- `*.docx`
- `*.pptx`
- `*.txt`
- `*.md`
- `*.pm`

## Generated Files

### For a single ENGINE

If not specified otherwise, three types of files will be created for each target language: `xtxt`, `cm`, and `ifdef`.

For example, if you want to translate a file named `Document.txt` into Japanese, the following three files will be generated:

    Document.txt.EN.xtxt
    Document.txt.EN.cm
    Document.txt.EN.ifdef

Three files will be generated: the `xtxt` file will contain only the translated text, while both the original text and the translated text will be included in the `cm` and `ifdef` files.

### Multiple ENGINES

If two ENGINEs, `deepl` and `gpt3`, are specified, the following files will be generated with the engine name included:

    Document.txt.deepl-JA.xtxt
    Document.txt.deepl-JA.cm
    Document.txt.deepl-JA.ifdef
    Document.txt.gpt3-EN.xtxt
    Document.txt.gpt3-EN.cm
    Document.txt.gpt3-EN.ifdef

## Line Wrapping

By adding `-fold` at the end of the format specification, such as `cm-fold`, the output will be wrapped at 80 columns.

## Control Files

If there is a file with a specific extension accompanying the target file, you can control the translation process based on its contents. For example, if there is a file named `Document.txt.LANG` along with the file `Document.txt`, it will be translated into the language specified in that file.

### .ENGINE

Specify the translation engine. The default options are `deepl` and `gpt3`. The default is `deepl`.

### .LANG

Specifies the target language for translation.

### .FORMAT

Specifies the translation format. Usually chosen from `xtxt`, `cm`, and `ifdef`.

Other formats, such as `md`, can also be used, but in that case, it will have the same content as `xtxt`. However, be careful when generating files that end with `.md`, as they will also be included in the translation target next time.

## Translation Process

By default, the prompt to initiate the translation process will be displayed with the translated text copied to the clipboard. Use the DeepL application or web interface to translate it, copy the result back to the clipboard, and then press Enter.

### Character Limit

If you are using a free account, you can only process up to 5000 characters at a time, so repeat this process until all the text is processed.

If you are using a paid account and there is no limit on the number of characters to process, set the upper limit in the `MAXLEN` variable and execute it.

    make MAXLEN=100000

### Using the DeepL API

To translate using the API, the `deepl` command must be installed. Set the `USEAPI` variable and execute make. However, the `deepl` command is not necessary when running in a Docker container.

    make USEAPI=yes

When using the API, the maximum number of characters is set to 128K. Set the authentication key in the `DEEPL_AUTH_KEY` environment variable. Set other environment variables such as `DEEPL_SERVER_URL` as needed.

### Using the Docker Container

Enable the `DOCKER` variable and execute make.

    make DOCKER=yes

### `XLATE_OPT` Variable

You can also specify options to be passed to the `xlate` command.

    make XLATE_OPT=-Dam100000

make XLATE_OPT=-Dam100000

## xlate Script

Initially, these files were designed to be processed by a Makefile, but now the settings used there have been made more generic and automated using a script called `xlate`. Therefore, the current Makefile simply calls the `xlate` command. The Makefile used by `xlate` is located in `../share/XLATE.mk`.

To view the help, please execute `xlate -h`.

### `xlate -M`

Execute the command "make".

### `xlate -D`

Run the `xlate` command in a Docker environment.

### `xlate -C`

Execute the command in a Docker environment.

Specify a command after `-C` to execute that command. If no command is specified, the shell will start up.

By default, the current directory is mounted to the `/work` directory. If you want to use a git environment, use the `-G` option.

If you want to mount read-only, specify the `-R` option.

#### `xlate -G`

When setting up the Docker environment, mount the current top directory of the git repository.

#### `xlate -GM`

Mount the current git repository and execute "make" in a Docker environment.

If you want to check what commands to execute, you can specify the `-n` option like `xlate -GMn`.

#### `xlate -GC`

Mount the Git repository and launch a shell in the Docker environment.

Git and other tools are already installed, so you can proceed with the work as is. Please note that modifications made in the working directory will be reflected in the original files as it is mounted there.
