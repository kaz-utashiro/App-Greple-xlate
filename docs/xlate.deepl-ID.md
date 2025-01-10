# NAME

App::Greple::xlate - modul dukungan penerjemahan untuk greple

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.9903

# DESCRIPTION

Modul **Greple** **xlate** menemukan blok teks yang diinginkan dan menggantinya dengan teks yang telah diterjemahkan. Saat ini modul DeepL (`deepl.pm`) dan ChatGPT (`gpt3.pm`) diimplementasikan sebagai mesin back-end. Dukungan eksperimental untuk gpt-4 dan gpt-4o juga disertakan.

Jika Anda ingin menerjemahkan blok teks normal dalam dokumen yang ditulis dengan gaya pod Perl, gunakan perintah **greple** dengan modul `xlate::deepl` dan `perl` seperti ini:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

Dalam perintah ini, string pola `^([\w\pP].*\n)+` berarti baris berurutan yang dimulai dengan alfanumerik dan tanda baca. Perintah ini menunjukkan area yang akan diterjemahkan dengan disorot. Opsi **--all** digunakan untuk menghasilkan seluruh teks.

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

Data format penanda konflik dapat dilihat dalam gaya berdampingan dengan perintah `sdif` dengan opsi `-V`. Karena tidak masuk akal untuk membandingkan per string, opsi `--no-cdif` direkomendasikan. Jika Anda tidak perlu mewarnai teks, tentukan `--no-textcolor` (atau `--no-tc`).

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Pemrosesan dilakukan dalam unit yang ditentukan, tetapi dalam kasus urutan beberapa baris teks yang tidak kosong, teks-teks tersebut dikonversi bersama menjadi satu baris. Operasi ini dilakukan sebagai berikut:

- Menghilangkan spasi pada awal dan akhir setiap baris.
- Jika sebuah baris diakhiri dengan karakter tanda baca dengan lebar penuh, gabungkan dengan baris berikutnya.
- Jika sebuah baris diakhiri dengan karakter dengan lebar penuh dan baris berikutnya dimulai dengan karakter dengan lebar penuh, gabungkan kedua baris tersebut.
- Jika akhir atau awal baris bukan merupakan karakter dengan lebar penuh, gabungkan keduanya dengan menyisipkan karakter spasi.

Data cache dikelola berdasarkan teks yang dinormalisasi, sehingga meskipun ada modifikasi yang dilakukan yang tidak memengaruhi hasil normalisasi, data terjemahan yang ditembolok akan tetap efektif.

Proses normalisasi ini dilakukan hanya untuk pola pertama (ke-0) dan pola bernomor genap. Dengan demikian, jika dua pola ditentukan sebagai berikut, teks yang cocok dengan pola pertama akan diproses setelah normalisasi, dan tidak ada proses normalisasi yang dilakukan pada teks yang cocok dengan pola kedua.

    greple -Mxlate -E normalized -E not-normalized

Oleh karena itu, gunakan pola pertama untuk teks yang akan diproses dengan menggabungkan beberapa baris menjadi satu baris, dan gunakan pola kedua untuk teks yang telah diformat sebelumnya. Jika tidak ada teks yang cocok dengan pola pertama, gunakan pola yang tidak cocok dengan apa pun, seperti `(?!)`.

# MASKING

Terkadang, ada bagian teks yang tidak ingin diterjemahkan. Misalnya, tag dalam file penurunan harga. DeepL menyarankan agar dalam kasus seperti itu, bagian teks yang akan dikecualikan dikonversi ke tag XML, diterjemahkan, dan kemudian dikembalikan setelah terjemahan selesai. Untuk mendukung hal ini, dimungkinkan untuk menentukan bagian yang akan disembunyikan dari terjemahan.

    --xlate-setopt maskfile=MASKPATTERN

Ini akan menginterpretasikan setiap baris dari file \`MASKPATTERN\` sebagai ekspresi reguler, menerjemahkan string yang cocok dengan itu, dan mengembalikannya setelah diproses. Baris yang dimulai dengan `#` akan diabaikan.

Pola kompleks dapat ditulis pada beberapa baris dengan garis miring diakhiri dengan baris baru.

Bagaimana teks diubah dengan masking dapat dilihat dengan opsi **--xlate-mask**.

Antarmuka ini bersifat eksperimental dan dapat berubah di masa depan.

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

    Pada saat ini, mesin berikut ini tersedia

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4-turbo
    - **gpt4o**: gpt-4o-mini

        Antarmuka **gpt-4o** tidak stabil dan tidak dapat dijamin untuk bekerja dengan benar saat ini.

- **--xlate-labor**
- **--xlabor**

    Alih-alih memanggil mesin penerjemah, Anda diharapkan untuk bekerja. Setelah menyiapkan teks yang akan diterjemahkan, teks tersebut disalin ke clipboard. Anda diharapkan untuk menempelkannya ke formulir, menyalin hasilnya ke clipboard, dan menekan return.

- **--xlate-to** (Default: `EN-US`)

    Tentukan bahasa target. Anda bisa mendapatkan bahasa yang tersedia dengan perintah `deepl languages` ketika menggunakan mesin **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Tentukan format output untuk teks asli dan terjemahan.

    Format berikut ini selain `xtxt` mengasumsikan bahwa bagian yang akan diterjemahkan adalah kumpulan baris. Pada kenyataannya, dimungkinkan untuk menerjemahkan hanya sebagian dari sebuah baris, dan menentukan format selain `xtxt` tidak akan menghasilkan hasil yang berarti.

    - **conflict**, **cm**

        Teks asli dan teks yang dikonversi dicetak dalam format penanda konflik [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Anda dapat memulihkan file asli dengan perintah [sed(1)](http://man.he.net/man1/sed) berikutnya.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Teks asli dan terjemahan ditampilkan dalam gaya wadah khusus penurunan harga.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Teks di atas akan diterjemahkan ke dalam HTML berikut ini.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Jumlah titik dua adalah 7 secara default. Jika Anda menentukan urutan titik dua seperti `:::::`, ini digunakan sebagai pengganti 7 titik dua.

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
    - **space+**

        Teks asli dan teks yang dikonversi dicetak dipisahkan oleh satu baris kosong. Untuk `spasi+`, ini juga menghasilkan baris baru setelah teks yang dikonversi.

    - **xtxt**

        Jika formatnya adalah `xtxt` (teks terjemahan) atau tidak diketahui, hanya teks terjemahan yang dicetak.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Tentukan panjang maksimum teks yang akan dikirim ke API sekaligus. Nilai default ditetapkan untuk layanan akun DeepL gratis: 128K untuk API (**--xlate**) dan 5000 untuk antarmuka clipboard (**--xlate-labor**). Anda mungkin dapat mengubah nilai ini jika Anda menggunakan layanan Pro.

- **--xlate-maxline**=_n_ (Default: 0)

    Tentukan jumlah maksimum baris teks yang akan dikirim ke API sekaligus.

    Tetapkan nilai ini ke 1 jika Anda ingin menerjemahkan satu baris dalam satu waktu. Opsi ini lebih diutamakan daripada opsi `--xlate-maxlen`.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Lihat hasil terjemahan secara real time dalam output STDERR.

- **--xlate-stripe**

    Gunakan modul [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) untuk menampilkan bagian yang cocok dengan mode garis zebra. Hal ini berguna ketika bagian yang dicocokkan dihubungkan secara berurutan.

    Palet warna dialihkan menurut warna latar belakang terminal. Jika Anda ingin menentukan secara eksplisit, Anda dapat menggunakan **--xlate-stripe-light** atau **--xlate-stripe-dark**.

- **--xlate-mask**

    Lakukan fungsi masking dan tampilkan teks yang dikonversi apa adanya tanpa pemulihan.

- **--match-all**

    Mengatur seluruh teks file sebagai area target.

# CACHE OPTIONS

Modul **xlate** dapat menyimpan teks terjemahan dalam cache untuk setiap file dan membacanya sebelum eksekusi untuk menghilangkan overhead dari permintaan ke server. Dengan strategi cache default `auto`, modul ini mempertahankan data cache hanya ketika file cache ada untuk file target.

Gunakan **--xlate-cache=clear** untuk memulai manajemen cache atau untuk membersihkan semua data cache yang ada. Setelah dieksekusi dengan opsi ini, file cache baru akan dibuat jika belum ada dan kemudian secara otomatis dipelihara setelahnya.

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
- **--xlate-update**

    Opsi ini memaksa untuk memperbarui file cache meskipun tidak diperlukan.

# COMMAND LINE INTERFACE

Anda dapat dengan mudah menggunakan modul ini dari baris perintah dengan menggunakan perintah `xlate` yang disertakan dalam distribusi. Lihat halaman manifes `xlate` untuk penggunaan.

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

Muat file `xlate.el` yang disertakan dalam repositori untuk menggunakan perintah `xlate` dari editor Emacs. Fungsi `xlate-region` menerjemahkan wilayah tertentu. Bahasa default adalah `EN-US` dan Anda dapat menentukan bahasa yang digunakan dengan argumen awalan.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

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

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Gambar kontainer Docker.

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

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Modul Greple **stripe** yang digunakan oleh opsi **--xlate-stripe**.

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

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
