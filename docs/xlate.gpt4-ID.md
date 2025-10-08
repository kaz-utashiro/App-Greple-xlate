# NAME

App::Greple::xlate - modul dukungan terjemahan untuk greple

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

    greple -Mxlate::gpt4 --xlate pattern target-file

    greple -Mxlate::gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

# VERSION

Version 0.9914

# DESCRIPTION

**Greple** **xlate** modul menemukan blok teks yang diinginkan dan menggantinya dengan teks terjemahan. Saat ini modul DeepL (`deepl.pm`), ChatGPT 4.1 (`gpt4.pm`), dan GPT-5 (`gpt5.pm`) telah diimplementasikan sebagai mesin back-end.

Jika Anda ingin menerjemahkan blok teks biasa dalam dokumen yang ditulis dengan gaya pod Perl, gunakan perintah **greple** dengan modul `xlate::deepl` dan `perl` seperti ini:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

Dalam perintah ini, string pola `^([\w\pP].*\n)+` berarti baris-baris berurutan yang dimulai dengan huruf alfanumerik dan tanda baca. Perintah ini menampilkan area yang akan diterjemahkan dengan sorotan. Opsi **--all** digunakan untuk menghasilkan seluruh teks.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Kemudian tambahkan opsi `--xlate` untuk menerjemahkan area yang dipilih. Maka, modul ini akan menemukan bagian yang diinginkan dan menggantinya dengan keluaran perintah **deepl**.

Secara default, teks asli dan terjemahan dicetak dalam format "conflict marker" yang kompatibel dengan [git(1)](http://man.he.net/man1/git). Dengan menggunakan format `ifdef`, Anda dapat mengambil bagian yang diinginkan dengan perintah [unifdef(1)](http://man.he.net/man1/unifdef) dengan mudah. Format keluaran dapat ditentukan dengan opsi **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Jika Anda ingin menerjemahkan seluruh teks, gunakan opsi **--match-all**. Ini adalah jalan pintas untuk menentukan pola `(?s).+` yang cocok dengan seluruh teks.

Format data penanda konflik dapat dilihat dalam gaya berdampingan dengan perintah [sdif](https://metacpan.org/pod/App%3A%3Asdif) menggunakan opsi `-V`. Karena tidak masuk akal untuk membandingkan berdasarkan per-string, opsi `--no-cdif` direkomendasikan. Jika Anda tidak perlu mewarnai teks, tentukan `--no-textcolor` (atau `--no-tc`).

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Pemrosesan dilakukan dalam satuan yang ditentukan, tetapi dalam kasus urutan beberapa baris teks yang tidak kosong, semuanya akan diubah bersama menjadi satu baris. Operasi ini dilakukan sebagai berikut:

- Hapus spasi di awal dan akhir setiap baris.
- Jika sebuah baris diakhiri dengan karakter tanda baca lebar penuh, gabungkan dengan baris berikutnya.
- Jika sebuah baris diakhiri dengan karakter lebar penuh dan baris berikutnya dimulai dengan karakter lebar penuh, gabungkan baris-baris tersebut.
- Jika baik akhir maupun awal baris bukan karakter lebar penuh, gabungkan dengan menyisipkan karakter spasi.

Data cache dikelola berdasarkan teks yang dinormalisasi, sehingga meskipun ada modifikasi yang tidak memengaruhi hasil normalisasi, data terjemahan yang di-cache tetap berlaku.

Proses normalisasi ini hanya dilakukan untuk pola pertama (ke-0) dan bernomor genap. Jadi, jika dua pola ditentukan seperti berikut, teks yang cocok dengan pola pertama akan diproses setelah normalisasi, dan tidak ada proses normalisasi pada teks yang cocok dengan pola kedua.

    greple -Mxlate -E normalized -E not-normalized

Oleh karena itu, gunakan pola pertama untuk teks yang akan diproses dengan menggabungkan beberapa baris menjadi satu baris, dan gunakan pola kedua untuk teks yang sudah diformat sebelumnya. Jika tidak ada teks yang cocok pada pola pertama, gunakan pola yang tidak cocok dengan apa pun, seperti `(?!)`.

# MASKING

Kadang-kadang, ada bagian dari teks yang tidak ingin Anda terjemahkan. Misalnya, tag dalam file markdown. DeepL menyarankan bahwa dalam kasus seperti itu, bagian teks yang ingin dikecualikan diubah menjadi tag XML, diterjemahkan, lalu dikembalikan setelah terjemahan selesai. Untuk mendukung ini, dimungkinkan untuk menentukan bagian-bagian yang akan dimask dari terjemahan.

    --xlate-setopt maskfile=MASKPATTERN

Ini akan menafsirkan setiap baris file \`MASKPATTERN\` sebagai ekspresi reguler, menerjemahkan string yang cocok dengannya, dan mengembalikannya setelah diproses. Baris yang diawali dengan `#` diabaikan.

Pola kompleks dapat ditulis dalam beberapa baris dengan newline yang di-escape dengan backslash.

Bagaimana teks diubah dengan masking dapat dilihat dengan opsi **--xlate-mask**.

Antarmuka ini bersifat eksperimental dan dapat berubah di masa depan.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Proses terjemahan dijalankan untuk setiap area yang cocok.

    Tanpa opsi ini, **greple** berperilaku sebagai perintah pencarian biasa. Jadi Anda dapat memeriksa bagian mana dari file yang akan menjadi subjek terjemahan sebelum menjalankan pekerjaan sebenarnya.

    Hasil perintah akan keluar ke standar, jadi arahkan ke file jika perlu, atau pertimbangkan untuk menggunakan modul [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    Opsi **--xlate** memanggil opsi **--xlate-color** dengan opsi **--color=never**.

    Dengan opsi **--xlate-fold**, teks yang telah dikonversi akan dilipat sesuai lebar yang ditentukan. Lebar default adalah 70 dan dapat diatur dengan opsi **--xlate-fold-width**. Empat kolom dicadangkan untuk operasi run-in, jadi setiap baris dapat menampung maksimal 74 karakter.

- **--xlate-engine**=_engine_

    Menentukan mesin terjemahan yang akan digunakan. Jika Anda menentukan modul mesin secara langsung, seperti `-Mxlate::deepl`, Anda tidak perlu menggunakan opsi ini.

    Saat ini, mesin-mesin berikut tersedia

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4.1
    - **gpt4o**: gpt-4o-mini

        Antarmuka **gpt-4o** tidak stabil dan tidak dapat dijamin berfungsi dengan benar saat ini.

    - **gpt5**: gpt-5

- **--xlate-labor**
- **--xlabor**

    Alih-alih memanggil mesin terjemahan, Anda diharapkan untuk bekerja secara manual. Setelah menyiapkan teks yang akan diterjemahkan, teks tersebut disalin ke clipboard. Anda diharapkan menempelkannya ke formulir, menyalin hasilnya ke clipboard, dan menekan return.

- **--xlate-to** (Default: `EN-US`)

    Tentukan bahasa target. Anda dapat melihat bahasa yang tersedia dengan perintah `deepl languages` saat menggunakan mesin **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Tentukan format keluaran untuk teks asli dan terjemahan.

    Format berikut selain `xtxt` mengasumsikan bahwa bagian yang akan diterjemahkan adalah kumpulan baris. Sebenarnya, dimungkinkan untuk menerjemahkan hanya sebagian dari satu baris, tetapi menentukan format selain `xtxt` tidak akan menghasilkan hasil yang bermakna.

    - **conflict**, **cm**

        Teks asli dan yang telah dikonversi dicetak dalam format penanda konflik [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Anda dapat memulihkan file asli dengan perintah [sed(1)](http://man.he.net/man1/sed) berikutnya.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Teks asli dan terjemahan dikeluarkan dalam gaya custom container markdown.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Teks di atas akan diterjemahkan menjadi berikut ini dalam HTML.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Jumlah titik dua adalah 7 secara default. Jika Anda menentukan urutan titik dua seperti `:::::`, itu akan digunakan sebagai pengganti 7 titik dua.

    - **ifdef**

        Teks asli dan yang telah dikonversi dicetak dalam format [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

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

        Teks asli dan teks yang telah dikonversi dicetak dipisahkan oleh satu baris kosong.

    - **xtxt**

        Untuk `space+`, juga akan menghasilkan baris baru setelah teks yang telah dikonversi.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Jika formatnya adalah `xtxt` (teks yang diterjemahkan) atau tidak dikenal, hanya teks yang diterjemahkan yang dicetak.

- **--xlate-maxline**=_n_ (Default: 0)

    Tentukan panjang maksimum teks yang akan dikirim ke API sekaligus. Nilai default diatur seperti untuk layanan akun gratis DeepL: 128K untuk API (**--xlate**) dan 5000 untuk antarmuka clipboard (**--xlate-labor**). Anda mungkin dapat mengubah nilai ini jika menggunakan layanan Pro.

    Tentukan jumlah baris maksimum teks yang akan dikirim ke API sekaligus.

- **--xlate-prompt**=_text_

    Tentukan prompt khusus yang akan dikirimkan ke mesin terjemahan. Opsi ini hanya tersedia saat menggunakan mesin ChatGPT (gpt3, gpt4, gpt4o). Anda dapat menyesuaikan perilaku terjemahan dengan memberikan instruksi spesifik kepada model AI. Jika prompt berisi `%s`, maka akan digantikan dengan nama bahasa target.

- **--xlate-context**=_text_

    Tentukan informasi konteks tambahan yang akan dikirimkan ke mesin terjemahan. Opsi ini dapat digunakan beberapa kali untuk memberikan beberapa string konteks. Informasi konteks membantu mesin terjemahan memahami latar belakang dan menghasilkan terjemahan yang lebih akurat.

- **--xlate-glossary**=_glossary_

    Tentukan ID glosarium yang akan digunakan untuk terjemahan. Opsi ini hanya tersedia saat menggunakan mesin DeepL. ID glosarium harus diperoleh dari akun DeepL Anda dan memastikan konsistensi terjemahan istilah tertentu.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Atur nilai ini ke 1 jika Anda ingin menerjemahkan satu baris pada satu waktu. Opsi ini memiliki prioritas lebih tinggi daripada opsi `--xlate-maxlen`.

- **--xlate-stripe**

    Lihat hasil terjemahan secara real time di output STDERR.

    Gunakan modul [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) untuk menampilkan bagian yang cocok dengan pola zebra striping. Ini berguna ketika bagian yang cocok terhubung secara berurutan.

- **--xlate-mask**

    Palet warna akan berganti sesuai dengan warna latar belakang terminal. Jika Anda ingin menentukan secara eksplisit, Anda dapat menggunakan **--xlate-stripe-light** atau **--xlate-stripe-dark**.

- **--match-all**

    Lakukan fungsi masking dan tampilkan teks yang telah dikonversi apa adanya tanpa pemulihan.

- **--lineify-cm**
- **--lineify-colon**

    Dalam kasus format `cm` dan `colon`, output dibagi dan diformat baris demi baris. Oleh karena itu, jika hanya sebagian dari sebuah baris yang diterjemahkan, hasil yang diharapkan tidak dapat diperoleh. Filter-filter ini memperbaiki output yang rusak akibat menerjemahkan sebagian baris menjadi output normal baris demi baris.

    Dalam implementasi saat ini, jika beberapa bagian dari sebuah baris diterjemahkan, bagian-bagian tersebut akan dikeluarkan sebagai baris yang berdiri sendiri.

# CACHE OPTIONS

Atur seluruh teks file sebagai area target.

Modul **xlate** dapat menyimpan teks terjemahan yang di-cache untuk setiap file dan membacanya sebelum eksekusi untuk menghilangkan overhead permintaan ke server. Dengan strategi cache default `auto`, data cache hanya dipertahankan jika file cache ada untuk file target.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Gunakan **--xlate-cache=clear** untuk memulai manajemen cache atau membersihkan semua data cache yang ada. Setelah dijalankan dengan opsi ini, file cache baru akan dibuat jika belum ada dan kemudian akan dipelihara secara otomatis setelahnya.

    - `create`

        Pertahankan file cache jika ada.

    - `always`, `yes`, `1`

        Buat file cache kosong dan keluar.

    - `clear`

        Tetap pertahankan cache selama target adalah file normal.

    - `never`, `no`, `0`

        Bersihkan data cache terlebih dahulu.

    - `accumulate`

        Jangan pernah menggunakan file cache meskipun sudah ada.
- **--xlate-update**

    Secara default, data yang tidak digunakan akan dihapus dari file cache. Jika Anda tidak ingin menghapusnya dan tetap menyimpannya di file, gunakan `accumulate`.

# COMMAND LINE INTERFACE

Opsi ini memaksa pembaruan file cache meskipun tidak diperlukan.

Anda dapat dengan mudah menggunakan modul ini dari baris perintah dengan menggunakan perintah `xlate` yang disertakan dalam distribusi. Lihat halaman manual `xlate` untuk penggunaannya.

Perintah `xlate` bekerja bersama dengan lingkungan Docker, jadi meskipun Anda tidak memiliki apa pun yang terinstal, Anda dapat menggunakannya selama Docker tersedia. Gunakan opsi `-D` atau `-C`.

Selain itu, karena makefile untuk berbagai gaya dokumen disediakan, terjemahan ke bahasa lain dimungkinkan tanpa spesifikasi khusus. Gunakan opsi `-M`.

Anda juga dapat menggabungkan opsi Docker dan `make` sehingga Anda dapat menjalankan `make` di lingkungan Docker.

Menjalankan seperti `xlate -C` akan meluncurkan shell dengan repositori git kerja saat ini yang terpasang.

# EMACS

Muat file `xlate.el` yang disertakan dalam repositori untuk menggunakan perintah `xlate` dari editor Emacs.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Fungsi `xlate-region` menerjemahkan region yang diberikan.

- OPENAI\_API\_KEY

    Bahasa default adalah `EN-US` dan Anda dapat menentukan bahasa dengan memanggilnya menggunakan argumen prefiks.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Atur kunci autentikasi Anda untuk layanan DeepL.

Kunci autentikasi OpenAI.

Anda harus menginstal alat baris perintah untuk DeepL dan ChatGPT.

# SEE ALSO

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

[App::Greple::xlate::gpt4](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt4)

[App::Greple::xlate::gpt5](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt5)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    [App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Gambar kontainer Docker.

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Pustaka Python DeepL dan perintah CLI.

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Pustaka Python OpenAI

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Antarmuka baris perintah OpenAI

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Lihat manual **greple** untuk detail tentang pola teks target. Gunakan opsi **--inside**, **--outside**, **--include**, **--exclude** untuk membatasi area pencocokan.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Anda dapat menggunakan modul `-Mupdate` untuk memodifikasi file berdasarkan hasil perintah **greple**.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Gunakan **sdif** untuk menampilkan format penanda konflik berdampingan dengan opsi **-V**.

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Modul Greple **stripe** digunakan dengan opsi **--xlate-stripe**.

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Modul Greple untuk menerjemahkan dan mengganti hanya bagian yang diperlukan dengan API DeepL (dalam bahasa Jepang)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
