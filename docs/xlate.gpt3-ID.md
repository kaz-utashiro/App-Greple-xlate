# NAME

App::Greple::xlate - modul dukungan terjemahan untuk greple

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.39

# DESCRIPTION

Modul **Greple** **xlate** mencari blok teks yang diinginkan dan menggantinya dengan teks yang diterjemahkan. Saat ini modul DeepL (`deepl.pm`) dan ChatGPT (`gpt3.pm`) diimplementasikan sebagai mesin backend. Dukungan eksperimental untuk gpt-4 dan gpt-4o juga disertakan.

Jika Anda ingin menerjemahkan blok teks normal dalam dokumen yang ditulis dalam gaya pod Perl, gunakan perintah **greple** dengan modul `xlate::deepl` dan `perl` seperti ini:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

Dalam perintah ini, pola string `^([\w\pP].*\n)+` berarti baris-baris berturut-turut yang dimulai dengan huruf alfanumerik dan tanda baca. Perintah ini menunjukkan area yang akan diterjemahkan yang disorot. Opsi **--all** digunakan untuk menghasilkan seluruh teks.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Kemudian tambahkan opsi `--xlate` untuk menerjemahkan area yang dipilih. Kemudian, akan mencari bagian yang diinginkan dan menggantinya dengan output perintah **deepl**.

Secara default, teks asli dan diterjemahkan dicetak dalam format "conflict marker" yang kompatibel dengan [git(1)](http://man.he.net/man1/git). Dengan menggunakan format `ifdef`, Anda dapat mendapatkan bagian yang diinginkan dengan mudah menggunakan perintah [unifdef(1)](http://man.he.net/man1/unifdef). Format output dapat ditentukan dengan opsi **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Jika Anda ingin menerjemahkan seluruh teks, gunakan opsi **--match-all**. Ini adalah pintasan untuk menentukan pola `(?s).+` yang cocok dengan seluruh teks.

Format penanda konflik data dapat dilihat dalam gaya samping-samping dengan perintah `sdif` dengan opsi `-V`. Karena tidak masuk akal untuk membandingkan berdasarkan string, opsi `--no-cdif` direkomendasikan. Jika Anda tidak perlu mewarnai teks, tentukan `--no-textcolor` (atau `--no-tc`).

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Pemrosesan dilakukan dalam unit yang ditentukan, tetapi dalam kasus urutan beberapa baris teks non-kosong, mereka dikonversi bersama menjadi satu baris. Operasi ini dilakukan sebagai berikut:

- Hapus spasi putih di awal dan akhir setiap baris.
- Jika sebuah baris diakhiri dengan karakter tanda baca lebar penuh, gabungkan dengan baris berikutnya.
- Jika sebuah baris diakhiri dengan karakter lebar penuh dan baris berikutnya dimulai dengan karakter lebar penuh, gabungkan baris tersebut.
- Jika baik di akhir maupun di awal baris tidak ada karakter lebar penuh, gabungkan mereka dengan menyisipkan karakter spasi.

Data cache dikelola berdasarkan teks yang dinormalisasi, sehingga bahkan jika modifikasi dilakukan yang tidak memengaruhi hasil normalisasi, data terjemahan yang di-cache akan tetap efektif.

Proses normalisasi ini dilakukan hanya untuk pola pertama (0) dan pola dengan nomor genap. Oleh karena itu, jika dua pola ditentukan seperti berikut, teks yang cocok dengan pola pertama akan diproses setelah normalisasi, dan tidak akan dilakukan proses normalisasi pada teks yang cocok dengan pola kedua.

    greple -Mxlate -E normalized -E not-normalized

Oleh karena itu, gunakan pola pertama untuk teks yang akan diproses dengan menggabungkan beberapa baris menjadi satu baris, dan gunakan pola kedua untuk teks yang sudah diformat sebelumnya. Jika tidak ada teks yang cocok dengan pola pertama, maka gunakan pola yang tidak cocok dengan apa pun, seperti `(?!)`.

# MASKING

Kadang-kadang, ada bagian teks yang tidak ingin Anda terjemahkan. Misalnya, tag dalam file markdown. DeepL menyarankan bahwa dalam kasus seperti itu, bagian teks yang akan dikecualikan dikonversi menjadi tag XML, diterjemahkan, dan kemudian dikembalikan setelah terjemahan selesai. Untuk mendukung hal ini, memungkinkan untuk menentukan bagian yang akan disembunyikan dari terjemahan.

    --xlate-setopt maskfile=MASKPATTERN

Ini akan menginterpretasikan setiap baris dari file \`MASKPATTERN\` sebagai ekspresi reguler, menerjemahkan string yang cocok dengannya, dan mengembalikannya setelah pemrosesan. Baris yang dimulai dengan `#` diabaikan.

Antarmuka ini bersifat eksperimental dan dapat berubah di masa depan.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Menggunakan proses terjemahan untuk setiap area yang cocok.

    Tanpa opsi ini, **greple** berperilaku sebagai perintah pencarian normal. Jadi Anda dapat memeriksa bagian mana dari file yang akan menjadi subjek terjemahan sebelum memanggil pekerjaan sebenarnya.

    Hasil perintah ditampilkan di stdout, jadi alihkan ke file jika perlu, atau pertimbangkan untuk menggunakan modul [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    Opsi **--xlate** memanggil opsi **--xlate-color** dengan opsi **--color=never**.

    Dengan opsi **--xlate-fold**, teks yang dikonversi dilipat dengan lebar yang ditentukan. Lebar default adalah 70 dan dapat diatur dengan opsi **--xlate-fold-width**. Empat kolom dipesan untuk operasi run-in, sehingga setiap baris dapat menampung paling banyak 74 karakter.

- **--xlate-engine**=_engine_

    Menentukan mesin terjemahan yang akan digunakan. Jika Anda menentukan modul mesin secara langsung, seperti `-Mxlate::deepl`, Anda tidak perlu menggunakan opsi ini.

    Pada saat ini, mesin berikut tersedia

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4-turbo
    - **gpt4o**: gpt-4o-mini

        Antarmuka **gpt-4o** tidak stabil dan tidak dapat dijamin akan berfungsi dengan benar saat ini.

- **--xlate-labor**
- **--xlabor**

    Alih-alih memanggil mesin terjemahan, Anda diharapkan untuk bekerja sendiri. Setelah menyiapkan teks yang akan diterjemahkan, teks tersebut akan disalin ke clipboard. Anda diharapkan untuk menempelkannya ke formulir, menyalin hasilnya ke clipboard, dan menekan tombol enter.

- **--xlate-to** (Default: `EN-US`)

    Tentukan bahasa target. Anda dapat mendapatkan bahasa yang tersedia dengan perintah `deepl languages` saat menggunakan mesin **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Tentukan format output untuk teks asli dan terjemahan.

    Format-format berikut selain `xtxt` mengasumsikan bahwa bagian yang akan diterjemahkan adalah kumpulan baris. Sebenarnya, memungkinkan untuk menerjemahkan hanya sebagian dari sebuah baris, dan menentukan format selain `xtxt` tidak akan menghasilkan hasil yang bermakna.

    - **conflict**, **cm**

        Teks asli dan terjemahan dicetak dalam format penanda konflik [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Anda dapat memulihkan file asli dengan perintah [sed(1)](http://man.he.net/man1/sed) berikutnya.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        \`\`\`html

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Ini berarti:

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Jumlah titik dua adalah 7 secara default. Jika Anda menentukan urutan titik dua seperti `:::::`, itu digunakan sebagai pengganti 7 titik dua.

    - **ifdef**

        Teks asli dan terjemahan dicetak dalam format [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Anda dapat mengambil hanya teks Jepang dengan perintah **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Original: 

    - **xtxt**

        Jika formatnya adalah `xtxt` (teks terjemahan) atau tidak diketahui, hanya teks terjemahan yang dicetak.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Terjemahkan teks berikut ke dalam bahasa Indonesia, baris per baris.

- **--xlate-maxline**=_n_ (Default: 0)

    Tentukan jumlah maksimum baris teks yang akan dikirim ke API sekaligus.

    Atur nilai ini menjadi 1 jika Anda ingin menerjemahkan satu baris setiap kali. Pilihan ini lebih diutamakan daripada opsi `--xlate-maxlen`.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Lihat hasil terjemahan secara real time dalam output STDERR.

- **--xlate-stripe**

    Gunakan modul [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) untuk menampilkan bagian yang cocok dengan gaya zebra striping. Ini berguna ketika bagian yang cocok terhubung satu sama lain.

    Palet warna akan berubah sesuai dengan warna latar belakang terminal. Jika Anda ingin menentukannya secara eksplisit, Anda dapat menggunakan **--xlate-stripe-light** atau **--xlate-stripe-dark**.

- **--match-all**

    Atur seluruh teks file sebagai area target.

# CACHE OPTIONS

Modul **xlate** dapat menyimpan teks terjemahan yang di-cache untuk setiap file dan membacanya sebelum eksekusi untuk menghilangkan overhead meminta ke server. Dengan strategi cache default `auto`, ia hanya mempertahankan data cache ketika file cache ada untuk file target.

Gunakan **--xlate-cache=clear** untuk memulai manajemen cache atau membersihkan semua data cache yang ada. Setelah dieksekusi dengan opsi ini, file cache baru akan dibuat jika belum ada dan kemudian secara otomatis dipelihara setelahnya.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Pertahankan file cache jika ada.

    - `create`

        Buat file cache kosong dan keluar.

    - `always`, `yes`, `1`

        Pertahankan cache apa pun selama target adalah file normal.

    - `clear`

        Hapus data cache terlebih dahulu.

    - `never`, `no`, `0`

        Jangan pernah menggunakan file cache bahkan jika ada.

    - `accumulate`

        Dengan perilaku default, data yang tidak digunakan dihapus dari file cache. Jika Anda tidak ingin menghapusnya dan tetap di file, gunakan `accumulate`.
- **--xlate-update**

    Opsi ini memaksa untuk memperbarui file cache bahkan jika tidak diperlukan.

# COMMAND LINE INTERFACE

Anda dapat dengan mudah menggunakan modul ini dari baris perintah dengan menggunakan perintah `xlate` yang disertakan dalam distribusi. Lihat informasi bantuan `xlate` untuk penggunaan.

Perintah `xlate` bekerja bersama dengan lingkungan Docker, jadi meskipun Anda tidak memiliki apa pun yang terinstal, Anda dapat menggunakannya selama Docker tersedia. Gunakan opsi `-D` atau `-C`.

Selain itu, karena makefile untuk berbagai gaya dokumen disediakan, terjemahan ke bahasa lain memungkinkan tanpa spesifikasi khusus. Gunakan opsi `-M`.

Anda juga dapat menggabungkan opsi Docker dan make sehingga Anda dapat menjalankan make di lingkungan Docker.

Menjalankan seperti `xlate -GC` akan meluncurkan shell dengan repositori git kerja saat ini dipasang.

Baca artikel Jepang di bagian ["LIHAT JUGA"](#lihat-juga) untuk detailnya.

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

Muat file `xlate.el` yang disertakan dalam repositori untuk menggunakan perintah `xlate` dari editor Emacs. Fungsi `xlate-region` menerjemahkan wilayah yang diberikan. Bahasa default adalah `EN-US` dan Anda dapat menentukan bahasa dengan memanggilnya dengan argumen awalan.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Atur kunci otentikasi Anda untuk layanan DeepL.

- OPENAI\_API\_KEY

    Kunci otentikasi OpenAI.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Anda harus menginstal alat baris perintah untuk DeepL dan ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

[https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    Pustaka DeepL Python dan perintah CLI.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Pustaka Python OpenAI

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Antarmuka baris perintah OpenAI

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Lihat panduan **greple** untuk detail tentang pola teks target. Gunakan opsi **--inside**, **--outside**, **--include**, **--exclude** untuk membatasi area pencocokan.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Anda dapat menggunakan modul `-Mupdate` untuk memodifikasi file berdasarkan hasil perintah **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Gunakan **sdif** untuk menampilkan format penanda konflik berdampingan dengan opsi **-V**.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Modul Greple untuk menerjemahkan dan mengganti hanya bagian yang diperlukan dengan API DeepL (dalam bahasa Jepang)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Menghasilkan dokumen dalam 15 bahasa dengan modul API DeepL (dalam bahasa Jepang)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Lingkungan Docker terjemahan otomatis dengan API DeepL (dalam bahasa Jepang)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
