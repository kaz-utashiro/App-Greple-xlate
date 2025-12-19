# NAME

App::Greple::xlate - modul dukungan terjemahan untuk greple

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

    greple -Mxlate::gpt4 --xlate pattern target-file

    greple -Mxlate::gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

# VERSION

Version 0.9923

# DESCRIPTION

**Greple** **xlate** modul menemukan blok teks yang diinginkan dan menggantinya dengan teks terjemahan. Saat ini modul DeepL (`deepl.pm`), ChatGPT 4.1 (`gpt4.pm`), dan GPT-5 (`gpt5.pm`) diimplementasikan sebagai mesin back-end.

Jika Anda ingin menerjemahkan blok teks normal dalam sebuah dokumen yang ditulis dalam gaya pod Perl, gunakan perintah **greple** dengan modul `xlate::deepl` dan `perl` seperti ini:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

Dalam perintah ini, string pola `^([\w\pP].*\n)+` berarti baris-baris berurutan yang dimulai dengan huruf angka dan tanda baca. Perintah ini menampilkan area yang akan diterjemahkan dengan sorotan. Opsi **--all** digunakan untuk menghasilkan seluruh teks.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Lalu tambahkan opsi `--xlate` untuk menerjemahkan area yang dipilih. Kemudian, ini akan menemukan bagian yang diinginkan dan menggantinya dengan keluaran perintah **deepl**.

Secara bawaan, teks asli dan terjemahan dicetak dalam format "penanda konflik" yang kompatibel dengan [git(1)](http://man.he.net/man1/git). Dengan menggunakan format `ifdef`, Anda dapat mengambil bagian yang diinginkan dengan perintah [unifdef(1)](http://man.he.net/man1/unifdef) dengan mudah. Format keluaran dapat ditentukan dengan opsi **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Jika Anda ingin menerjemahkan seluruh teks, gunakan opsi **--match-all**. Ini adalah jalan pintas untuk menentukan pola `(?s).+` yang mencocokkan seluruh teks.

Data format penanda konflik dapat dilihat dalam gaya berdampingan dengan perintah [sdif](https://metacpan.org/pod/App%3A%3Asdif) bersama opsi `-V`. Karena tidak masuk akal untuk membandingkan per string, opsi `--no-cdif` direkomendasikan. Jika Anda tidak perlu mewarnai teks, tentukan `--no-textcolor` (atau `--no-tc`).

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Pemrosesan dilakukan dalam unit yang ditentukan, tetapi dalam kasus rangkaian beberapa baris teks yang tidak kosong, teks tersebut digabungkan menjadi satu baris. Operasi ini dilakukan sebagai berikut:

- Hapus spasi putih di awal dan akhir setiap baris.
- Jika sebuah baris diakhiri dengan karakter tanda baca lebar penuh, gabungkan dengan baris berikutnya.
- Jika sebuah baris diakhiri dengan karakter lebar penuh dan baris berikutnya dimulai dengan karakter lebar penuh, gabungkan baris-baris tersebut.
- Jika salah satu dari akhir atau awal baris bukan karakter lebar penuh, gabungkan dengan menyisipkan satu karakter spasi.

Data cache dikelola berdasarkan teks yang dinormalisasi, sehingga meskipun dilakukan modifikasi yang tidak mempengaruhi hasil normalisasi, data terjemahan yang di-cache tetap efektif.

Proses normalisasi ini dilakukan hanya untuk pola pertama (ke-0) dan bernomor genap. Dengan demikian, jika dua pola ditentukan seperti berikut, teks yang cocok dengan pola pertama akan diproses setelah normalisasi, dan tidak ada proses normalisasi yang dilakukan pada teks yang cocok dengan pola kedua.

    greple -Mxlate -E normalized -E not-normalized

Oleh karena itu, gunakan pola pertama untuk teks yang akan diproses dengan menggabungkan beberapa baris menjadi satu baris, dan gunakan pola kedua untuk teks pra-format. Jika tidak ada teks yang cocok pada pola pertama, gunakan pola yang tidak mencocokkan apa pun, seperti `(?!)`.

# MASKING

Terkadang, ada bagian teks yang tidak ingin Anda terjemahkan. Misalnya, tag dalam berkas markdown. DeepL menyarankan bahwa dalam kasus seperti itu, bagian teks yang dikecualikan diubah menjadi tag XML, diterjemahkan, lalu dipulihkan setelah terjemahan selesai. Untuk mendukung ini, dimungkinkan untuk menentukan bagian yang akan dimask dari terjemahan.

    --xlate-setopt maskfile=MASKPATTERN

Ini akan menafsirkan setiap baris dari berkas \`MASKPATTERN\` sebagai ekspresi reguler, menerjemahkan string yang cocok dengannya, dan mengembalikan setelah pemrosesan. Baris yang dimulai dengan `#` diabaikan.

Pola kompleks dapat ditulis dalam beberapa baris dengan baris baru yang di-escape dengan backslash.

Bagaimana teks diubah oleh masking dapat dilihat dengan opsi **--xlate-mask**.

Antarmuka ini bersifat eksperimental dan dapat berubah di masa mendatang.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Panggil proses terjemahan untuk setiap area yang cocok.

    Tanpa opsi ini, **greple** berperilaku sebagai perintah pencarian normal. Jadi Anda dapat memeriksa bagian mana dari berkas yang akan menjadi subjek terjemahan sebelum menjalankan pekerjaan yang sebenarnya.

    Hasil perintah masuk ke standar keluaran, jadi arahkan ke berkas jika perlu, atau pertimbangkan untuk menggunakan modul [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    Opsi **--xlate** memanggil opsi **--xlate-color** dengan opsi **--color=never**.

    Dengan opsi **--xlate-fold**, teks yang dikonversi dilipat berdasarkan lebar yang ditentukan. Lebar default adalah 70 dan dapat diatur oleh opsi **--xlate-fold-width**. Empat kolom dicadangkan untuk operasi run-in, jadi setiap baris dapat memuat paling banyak 74 karakter.

- **--xlate-engine**=_engine_

    Menentukan mesin terjemahan yang akan digunakan. Jika Anda menentukan modul mesin secara langsung, seperti `-Mxlate::deepl`, Anda tidak perlu menggunakan opsi ini.

    Saat ini, mesin berikut tersedia

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4.1
    - **gpt4o**: gpt-4o-mini

        Antarmuka **gpt-4o** tidak stabil dan tidak dapat dijamin berfungsi dengan benar saat ini.

    - **gpt5**: gpt-5

- **--xlate-labor**
- **--xlabor**

    Alih-alih memanggil mesin terjemahan, Anda diharapkan bekerja secara manual. Setelah menyiapkan teks yang akan diterjemahkan, teks tersebut disalin ke papan klip. Anda diharapkan menempelkannya ke formulir, menyalin hasilnya ke papan klip, dan menekan return.

- **--xlate-to** (Default: `EN-US`)

    Tentukan bahasa target. Anda bisa mendapatkan bahasa yang tersedia dengan perintah `deepl languages` saat menggunakan mesin **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Tentukan format keluaran untuk teks asli dan terjemahan.

    Format berikut selain `xtxt` mengasumsikan bahwa bagian yang akan diterjemahkan adalah kumpulan baris. Sebenarnya, memungkinkan untuk menerjemahkan hanya sebagian dari sebuah baris, tetapi menentukan format selain `xtxt` tidak akan menghasilkan hasil yang bermakna.

    - **conflict**, **cm**

        Teks asli dan yang telah dikonversi dicetak dalam format penanda konflik [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Anda dapat memulihkan berkas asli dengan perintah [sed(1)](http://man.he.net/man1/sed) berikutnya.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Teks asli dan terjemahan dikeluarkan dalam gaya container kustom markdown.

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

        Jumlah tanda titik dua adalah 7 secara default. Jika Anda menentukan urutan tanda titik dua seperti `:::::`, itu digunakan sebagai pengganti 7 tanda titik dua.

    - **ifdef**

        Teks asli dan yang telah dikonversi dicetak dalam format [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Anda dapat mengambil hanya teks bahasa Jepang dengan perintah **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Teks asli dan teks yang dikonversi dicetak dipisahkan oleh satu baris kosong. Untuk `space+`, juga mengeluarkan baris baru setelah teks yang dikonversi.

    - **xtxt**

        Jika formatnya `xtxt` (teks terjemahan) atau tidak dikenal, hanya teks terjemahan yang dicetak.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Tentukan panjang maksimum teks yang akan dikirim ke API sekaligus. Nilai default ditetapkan seperti untuk layanan akun DeepL gratis: 128K untuk API (**--xlate**) dan 5000 untuk antarmuka papan klip (**--xlate-labor**). Anda mungkin dapat mengubah nilai-nilai ini jika menggunakan layanan Pro.

- **--xlate-maxline**=_n_ (Default: 0)

    Tentukan jumlah maksimum baris teks yang akan dikirim ke API sekaligus.

    Setel nilai ini ke 1 jika Anda ingin menerjemahkan satu baris setiap kali. Opsi ini memiliki prioritas lebih tinggi daripada opsi `--xlate-maxlen`.

- **--xlate-prompt**=_text_

    Tentukan prompt kustom yang akan dikirim ke mesin terjemahan. Opsi ini hanya tersedia saat menggunakan mesin ChatGPT (gpt3, gpt4, gpt4o). Anda dapat menyesuaikan perilaku terjemahan dengan memberikan instruksi khusus kepada model AI. Jika prompt berisi `%s`, itu akan diganti dengan nama bahasa target.

- **--xlate-context**=_text_

    Tentukan informasi konteks tambahan yang akan dikirim ke mesin terjemahan. Opsi ini dapat digunakan beberapa kali untuk menyediakan beberapa string konteks. Informasi konteks membantu mesin terjemahan memahami latar belakang dan menghasilkan terjemahan yang lebih akurat.

- **--xlate-glossary**=_glossary_

    Tentukan ID glosarium yang akan digunakan untuk terjemahan. Opsi ini hanya tersedia saat menggunakan mesin DeepL. ID glosarium harus diperoleh dari akun DeepL Anda dan memastikan terjemahan yang konsisten untuk istilah-istilah tertentu.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Lihat hasil terjemahan secara waktu nyata di keluaran STDERR.

- **--xlate-stripe**

    Gunakan modul [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) untuk menampilkan bagian yang cocok dengan pola strip zebra. Ini berguna ketika bagian yang cocok tersambung berurutan.

    Palet warna dialihkan sesuai dengan warna latar belakang terminal. Jika Anda ingin menentukan secara eksplisit, Anda dapat menggunakan **--xlate-stripe-light** atau **--xlate-stripe-dark**.

- **--xlate-mask**

    Lakukan fungsi masking dan tampilkan teks yang dikonversi apa adanya tanpa pemulihan.

- **--match-all**

    Tetapkan seluruh teks file sebagai area target.

- **--lineify-cm**
- **--lineify-colon**

    Dalam kasus format `cm` dan `colon`, keluaran dipecah dan diformat baris demi baris. Oleh karena itu, jika hanya sebagian dari suatu baris yang akan diterjemahkan, hasil yang diharapkan tidak dapat diperoleh. Filter ini memperbaiki keluaran yang rusak karena menerjemahkan sebagian baris menjadi keluaran normal baris demi baris.

    Dalam implementasi saat ini, jika beberapa bagian dari suatu baris diterjemahkan, bagian-bagian tersebut dikeluarkan sebagai baris independen.

# CACHE OPTIONS

Modul **xlate** dapat menyimpan teks terjemahan yang di-cache untuk setiap file dan membacanya sebelum eksekusi untuk menghilangkan overhead permintaan ke server. Dengan strategi cache default `auto`, ia mempertahankan data cache hanya ketika file cache ada untuk file target.

Gunakan **--xlate-cache=clear** untuk memulai manajemen cache atau membersihkan semua data cache yang ada. Setelah dijalankan dengan opsi ini, file cache baru akan dibuat jika belum ada dan kemudian secara otomatis dipelihara setelahnya.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Pertahankan file cache jika ada.

    - `create`

        Buat file cache kosong dan keluar.

    - `always`, `yes`, `1`

        Pertahankan cache bagaimanapun juga selama target adalah file normal.

    - `clear`

        Bersihkan data cache terlebih dahulu.

    - `never`, `no`, `0`

        Jangan pernah gunakan file cache meskipun ada.

    - `accumulate`

        Secara default, data yang tidak digunakan dihapus dari file cache. Jika Anda tidak ingin menghapusnya dan tetap menyimpannya di file, gunakan `accumulate`.
- **--xlate-update**

    Opsi ini memaksa pembaruan file cache meskipun tidak diperlukan.

# COMMAND LINE INTERFACE

Anda dapat dengan mudah menggunakan modul ini dari baris perintah dengan menggunakan perintah `xlate` yang disertakan dalam distribusi. Lihat halaman manual `xlate` untuk penggunaan.

Perintah `xlate` mendukung opsi panjang gaya GNU seperti `--to-lang`, `--from-lang`, `--engine`, dan `--file`. Gunakan `xlate -h` untuk melihat semua opsi yang tersedia.

Perintah `xlate` bekerja selaras dengan lingkungan Docker, jadi meskipun Anda tidak memasang apa pun secara lokal, Anda dapat menggunakannya selama Docker tersedia. Gunakan opsi `-D` atau `-C`.

Operasi Docker ditangani oleh [App::dozo](https://metacpan.org/pod/App%3A%3Adozo), yang juga dapat digunakan sebagai perintah mandiri. Perintah `dozo` mendukung berkas konfigurasi `.dozorc` untuk pengaturan kontainer yang persisten.

Selain itu, karena makefile untuk berbagai gaya dokumen disediakan, penerjemahan ke bahasa lain dimungkinkan tanpa spesifikasi khusus. Gunakan opsi `-M`.

Anda juga dapat menggabungkan opsi Docker dan `make` sehingga Anda dapat menjalankan `make` di lingkungan Docker.

Menjalankan seperti `xlate -C` akan meluncurkan shell dengan repositori git working directory saat ini di-mount.

Baca artikel berbahasa Jepang di bagian ["SEE ALSO"](#see-also) untuk detailnya.

# EMACS

Muat file `xlate.el` yang disertakan dalam repositori untuk menggunakan perintah `xlate` dari editor Emacs. Fungsi `xlate-region` menerjemahkan region yang diberikan. Bahasa default adalah `EN-US` dan Anda dapat menentukan bahasa dengan memanggilnya menggunakan argumen prefix.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Atur kunci autentikasi Anda untuk layanan DeepL.

- OPENAI\_API\_KEY

    Kunci autentikasi OpenAI.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Anda harus memasang alat baris perintah untuk DeepL dan ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt4](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt4)

[App::Greple::xlate::gpt5](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt5)

[App::dozo](https://metacpan.org/pod/App%3A%3Adozo) - Runner Docker generik yang digunakan oleh xlate untuk operasi kontainer

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Citra kontainer Docker.

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    Pustaka `getoptlong.sh` digunakan untuk penguraian opsi dalam skrip `xlate` dan [App::dozo](https://metacpan.org/pod/App%3A%3Adozo).

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    Pustaka Python dan perintah CLI DeepL.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Pustaka Python OpenAI

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Antarmuka baris perintah OpenAI

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Lihat manual **greple** untuk detail tentang pola teks target. Gunakan opsi **--inside**, **--outside**, **--include**, **--exclude** untuk membatasi area pencocokan.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Anda dapat menggunakan modul `-Mupdate` untuk memodifikasi file berdasarkan hasil perintah **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Gunakan **sdif** untuk menampilkan format penanda konflik berdampingan dengan opsi **-V**.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Modul Greple **stripe** digunakan oleh opsi **--xlate-stripe**.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Modul Greple untuk menerjemahkan dan mengganti hanya bagian yang diperlukan dengan DeepL API (dalam bahasa Jepang)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Menghasilkan dokumen dalam 15 bahasa dengan modul DeepL API (dalam bahasa Jepang)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Lingkungan Docker terjemahan otomatis dengan DeepL API (dalam bahasa Jepang)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
