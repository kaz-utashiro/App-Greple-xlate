# NAME

App::Greple::xlate - modul dukungan penerjemahan untuk greple

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.3101

# DESCRIPTION

Modul **Greple** **xlate** menemukan blok teks yang diinginkan dan menggantinya dengan teks yang telah diterjemahkan. Saat ini modul DeepL (`deepl.pm`) dan ChatGPT (`gpt3.pm`) diimplementasikan sebagai mesin back-end. Dukungan eksperimental untuk gpt-4 juga disertakan.

Jika Anda ingin menerjemahkan blok teks normal dalam dokumen yang ditulis dengan gaya pod Perl, gunakan perintah **greple** dengan modul `xlate::deepl` dan `perl` seperti ini:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Dalam perintah ini, string pola `^(\w.*\n)+` berarti baris berurutan yang dimulai dengan huruf alfanumerik. Perintah ini menunjukkan area yang akan diterjemahkan disorot. Opsi **--all** digunakan untuk menghasilkan seluruh teks.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Kemudian tambahkan opsi `--xlate` untuk menerjemahkan area yang dipilih. Kemudian, ia akan menemukan bagian yang diinginkan dan menggantinya dengan keluaran perintah **deepl**.

Secara default, teks asli dan terjemahan dicetak dalam format "penanda konflik" yang kompatibel dengan [git(1)](http://man.he.net/man1/git). Dengan menggunakan format `ifdef`, Anda dapat memperoleh bagian yang diinginkan dengan perintah [unifdef(1)](http://man.he.net/man1/unifdef) dengan mudah. Format keluaran dapat ditentukan dengan opsi **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Jika Anda ingin menerjemahkan seluruh teks, gunakan opsi **--match-all**. Ini adalah jalan pintas untuk menentukan pola `(?s).+` yang cocok dengan seluruh teks.

Data format penanda konflik dapat dilihat dalam gaya berdampingan dengan perintah `sdif` dengan opsi `-V`. Karena tidak masuk akal untuk membandingkan per string, opsi `--no-cdif` direkomendasikan. Jika Anda tidak perlu mewarnai teks, tentukan `--no-color` atau `--cm 'TEXT*='`.

    sdif -V --cm '*TEXT=' --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Memanggil proses penerjemahan untuk setiap area yang cocok.

    Tanpa opsi ini, **greple** berperilaku sebagai perintah pencarian biasa. Jadi, Anda dapat memeriksa bagian mana dari file yang akan menjadi subjek terjemahan sebelum memanggil pekerjaan yang sebenarnya.

    Hasil perintah akan keluar ke standar, jadi alihkan ke file jika perlu, atau pertimbangkan untuk menggunakan modul [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    Opsi **--xlate** memanggil opsi **--xlate-color** dengan opsi **--color=never**.

    Dengan opsi **--xlate-fold**, teks yang dikonversi akan dilipat dengan lebar yang ditentukan. Lebar default adalah 70 dan dapat diatur dengan opsi **--xlate-fold-width**. Empat kolom dicadangkan untuk operasi run-in, sehingga setiap baris dapat menampung paling banyak 74 karakter.

- **--xlate-engine**=_engine_

    Menentukan mesin penerjemahan yang akan digunakan. Jika Anda menentukan modul mesin secara langsung, seperti `-Mxlate::deepl`, Anda tidak perlu menggunakan opsi ini.

- **--xlate-labor**
- **--xlabor**

    Alih-alih memanggil mesin penerjemah, Anda diharapkan untuk bekerja. Setelah menyiapkan teks yang akan diterjemahkan, teks tersebut disalin ke clipboard. Anda diharapkan untuk menempelkannya ke formulir, menyalin hasilnya ke clipboard, dan menekan return.

- **--xlate-to** (Default: `EN-US`)

    Tentukan bahasa target. Anda bisa mendapatkan bahasa yang tersedia dengan perintah `deepl languages` ketika menggunakan mesin **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Tentukan format output untuk teks asli dan terjemahan.

    - **conflict**, **cm**

        Teks asli dan teks yang dikonversi dicetak dalam format penanda konflik [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Anda dapat memulihkan file asli dengan perintah [sed(1)](http://man.he.net/man1/sed) berikutnya.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        Teks asli dan teks yang dikonversi dicetak dalam format [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Anda hanya dapat mengambil teks bahasa Jepang dengan perintah **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        Teks asli dan teks yang dikonversi dicetak dengan dipisahkan oleh satu baris kosong.

    - **xtxt**

        Jika formatnya adalah `xtxt` (teks terjemahan) atau tidak diketahui, hanya teks terjemahan yang dicetak.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Tentukan panjang maksimum teks yang akan dikirim ke API sekaligus. Nilai default ditetapkan untuk layanan akun DeepL gratis: 128K untuk API (**--xlate**) dan 5000 untuk antarmuka clipboard (**--xlate-labor**). Anda mungkin dapat mengubah nilai ini jika Anda menggunakan layanan Pro.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Lihat hasil terjemahan secara real time dalam output STDERR.

- **--match-all**

    Mengatur seluruh teks file sebagai area target.

# CACHE OPTIONS

Modul **xlate** dapat menyimpan teks terjemahan dalam cache untuk setiap file dan membacanya sebelum eksekusi untuk menghilangkan overhead dari permintaan ke server. Dengan strategi cache default `auto`, modul ini mempertahankan data cache hanya ketika file cache ada untuk file target.

- --cache-clear

    Opsi **--cache-clear** dapat digunakan untuk memulai manajemen cache atau untuk menyegarkan semua data cache yang ada. Setelah dieksekusi dengan opsi ini, file cache baru akan dibuat jika belum ada dan kemudian secara otomatis dipelihara setelahnya.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Mempertahankan file cache jika sudah ada.

    - `create`

        Buat file cache kosong dan keluar.

    - `always`, `yes`, `1`

        Pertahankan cache sejauh targetnya adalah file normal.

    - `clear`

        Hapus data cache terlebih dahulu.

    - `never`, `no`, `0`

        Jangan pernah menggunakan file cache meskipun ada.

    - `accumulate`

        Secara default, data yang tidak digunakan akan dihapus dari file cache. Jika Anda tidak ingin menghapusnya dan menyimpannya di dalam file, gunakan `accumulate`.

# COMMAND LINE INTERFACE

Anda dapat dengan mudah menggunakan modul ini dari baris perintah dengan menggunakan perintah `xlate` yang disertakan dalam distribusi. Lihat informasi bantuan `xlate` untuk informasi penggunaan.

Perintah `xlate` bekerja bersama dengan lingkungan Docker, jadi meskipun Anda tidak memiliki apa pun yang terinstal, Anda dapat menggunakannya selama Docker tersedia. Gunakan opsi `-D` atau `-C`.

Selain itu, karena tersedia makefile untuk berbagai gaya dokumen, penerjemahan ke dalam bahasa lain dapat dilakukan tanpa spesifikasi khusus. Gunakan opsi `-M`.

Anda juga dapat menggabungkan opsi Docker dan make sehingga Anda dapat menjalankan make di lingkungan Docker.

Menjalankan seperti `xlate -GC` akan meluncurkan sebuah shell dengan repositori git yang sedang berjalan.

Baca artikel bahasa Jepang di bagian ["LIHAT JUGA"](#lihat-juga) untuk detailnya.

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

Muat file `xlate.el` yang disertakan dalam repositori untuk menggunakan perintah `xlate` dari editor Emacs. Fungsi `xlate-region` menerjemahkan wilayah tertentu. Bahasa default adalah `EN-US` dan Anda dapat menentukan bahasa yang digunakan dengan argumen awalan.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Tetapkan kunci autentikasi Anda untuk layanan DeepL.

- OPENAI\_API\_KEY

    Kunci autentikasi OpenAI.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Anda harus menginstal alat baris perintah untuk DeepL dan ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

L <App::Greple::xlate>

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

[https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL pustaka Python dan perintah CLI.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Perpustakaan Python OpenAI

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Antarmuka baris perintah OpenAI

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Lihat manual **greple** untuk detail tentang pola teks target. Gunakan opsi **--inside**, **--outside**, **--include**, **--exclude** untuk membatasi area pencocokan.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Anda dapat menggunakan modul `-Mupdate` untuk memodifikasi file berdasarkan hasil perintah **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Gunakan **sdif** untuk menampilkan format penanda konflik berdampingan dengan opsi **-V**.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Modul Greple untuk menerjemahkan dan mengganti bagian yang diperlukan saja dengan DeepL API (dalam bahasa Jepang)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Menghasilkan dokumen dalam 15 bahasa dengan modul API DeepL (dalam bahasa Jepang)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Lingkungan Docker terjemahan otomatis dengan DeepL API (dalam bahasa Jepang)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
