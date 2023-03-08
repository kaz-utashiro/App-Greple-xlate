# Greple -Mxlate module sample files

This directory contains examples of automatic file translation using Greple's -Mxlate module.

Simply place the document file to be translated and execute the make command to generate the necessary file. The following types of files are currently covered.

- `*.docx`, `*.pptx`, and `*.pptx`.
- `*.pptx`, `*.pptx`, and `*.txt`.
- `*.txt`
- `*.md`
- `*.pm`

## Generated files

If not specified, three types of files, `xtxt`, `cm`, and `ifdef`, will be generated for each target language.

For example, if you want to translate the file `Document.txt` into Japanese, three files named

    Document.txt.JA.xtxt
    Document.txt.JA.cm
    Document.txt.JA.ifdef

For example, to translate the file `Document.txt` into Japanese, three files named The `xtxt` file contains only the translated text, while the `cm` and `ifdef` files contain both the original and translated text.

## Control files

If the target file has a file with a specific extension, the translation process can be controlled by its contents. For example, if there is a file called `Document.txt.LANG` along with a file called `Document.txt`, the translation will be done in the language written in the file.

### *.LANG

Specify the language to be translated.

### *.FORMAT

Specify the format of translation. Specify the translation format from `xtxt`, `cm`, or `ifdef`.

## translation process

The default behavior is to copy the text to be translated to the clipboard, prompt for the translation process, translate it using the application or web interface at DeepL, copy the result back to the clipboard, and hit enter.

### character limit

If you are running with a free account, you can only process up to 5000 characters at a time, so repeat this process until all text has been processed.

If you are using a paid account and there is no limit to the number of characters to process, set the variable `MAXLEN` to the upper limit and run.

    make MAXLEN=100000

### Use API

To translate using the API, the `deepl` command must be installed. Set the variable `USEAPI` and run make.

    make USEAPI=yes

## Variables used in make

### DEBUG

Turns on debug mode.

### MAXLEN

Set the maximum number of characters to process at one time.

### USEAPI

Translate using the DeepL API.
