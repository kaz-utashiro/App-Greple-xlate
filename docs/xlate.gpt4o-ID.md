# NAME

App::Greple::xlate - modul dukungan terjemahan untuk greple  

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.38

# DESCRIPTION

**Greple** **xlate** modul menemukan blok teks yang diinginkan dan menggantinya dengan teks yang diterjemahkan. Saat ini, modul DeepL (`deepl.pm`) dan ChatGPT (`gpt3.pm`) diimplementasikan sebagai mesin backend. Dukungan eksperimental untuk gpt-4 dan gpt-4o juga disertakan.  

Jika Anda ingin menerjemahkan blok teks normal dalam dokumen yang ditulis dalam gaya pod Perl, gunakan perintah **greple** dengan modul `xlate::deepl` dan `perl` seperti ini:  

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Dalam perintah ini, string pola `^(\w.*\n)+` berarti baris berturut-turut yang dimulai dengan huruf alfanumerik. Perintah ini menunjukkan area yang akan diterjemahkan dengan sorotan. Opsi **--all** digunakan untuk menghasilkan seluruh teks.  

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Kemudian tambahkan opsi `--xlate` untuk menerjemahkan area yang dipilih. Kemudian, itu akan menemukan bagian yang diinginkan dan menggantinya dengan output perintah **deepl**.  

Secara default, teks asli dan terjemahan dicetak dalam format "penanda konflik" yang kompatibel dengan [git(1)](http://man.he.net/man1/git). Menggunakan format `ifdef`, Anda dapat dengan mudah mendapatkan bagian yang diinginkan dengan perintah [unifdef(1)](http://man.he.net/man1/unifdef). Format output dapat ditentukan dengan opsi **--xlate-format**.  

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Jika Anda ingin menerjemahkan seluruh teks, gunakan opsi **--match-all**. Ini adalah pintasan untuk menentukan pola `(?s).+` yang mencocokkan seluruh teks.  

Data format penanda konflik dapat dilihat dalam gaya berdampingan dengan perintah `sdif` dengan opsi `-V`. Karena tidak ada gunanya membandingkan berdasarkan per-string, opsi `--no-cdif` disarankan. Jika Anda tidak perlu memberi warna pada teks, tentukan `--no-textcolor` (atau `--no-tc`).  

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Pemrosesan dilakukan dalam unit yang ditentukan, tetapi dalam kasus urutan beberapa baris teks yang tidak kosong, mereka dikonversi bersama menjadi satu baris. Operasi ini dilakukan sebagai berikut:  

- Hapus spasi putih di awal dan akhir setiap baris.  
- Jika sebuah baris diakhiri dengan karakter tanda baca lebar penuh, gabungkan dengan baris berikutnya.  
- Jika sebuah baris diakhiri dengan karakter lebar penuh dan baris berikutnya dimulai dengan karakter lebar penuh, gabungkan baris tersebut.  
- Jika baik akhir atau awal sebuah baris bukan karakter lebar penuh, gabungkan mereka dengan menyisipkan karakter spasi.  

Data cache dikelola berdasarkan teks yang dinormalisasi, jadi meskipun modifikasi dilakukan yang tidak mempengaruhi hasil normalisasi, data terjemahan yang di-cache tetap akan efektif.  

Proses normalisasi ini hanya dilakukan untuk pola pertama (0) dan pola bernomor genap. Jadi, jika dua pola ditentukan sebagai berikut, teks yang cocok dengan pola pertama akan diproses setelah normalisasi, dan tidak ada proses normalisasi yang akan dilakukan pada teks yang cocok dengan pola kedua.  

    greple -Mxlate -E normalized -E not-normalized

Oleh karena itu, gunakan pola pertama untuk teks yang akan diproses dengan menggabungkan beberapa baris menjadi satu baris, dan gunakan pola kedua untuk teks yang telah diformat sebelumnya. Jika tidak ada teks yang cocok dalam pola pertama, maka pola yang tidak cocok dengan apa pun, seperti `(?!)`.

# MASKING

Kadang-kadang, ada bagian dari teks yang tidak ingin Anda terjemahkan. Misalnya, tag dalam file markdown. DeepL menyarankan bahwa dalam kasus seperti itu, bagian teks yang akan dikecualikan diubah menjadi tag XML, diterjemahkan, dan kemudian dipulihkan setelah terjemahan selesai. Untuk mendukung ini, dimungkinkan untuk menentukan bagian yang akan disembunyikan dari terjemahan.  

    --xlate-setopt maskfile=MASKPATTERN

Ini akan menginterpretasikan setiap baris dari file \`MASKPATTERN\` sebagai ekspresi reguler, menerjemahkan string yang cocok, dan mengembalikannya setelah pemrosesan. Baris yang dimulai dengan `#` diabaikan.  

Antarmuka ini bersifat eksperimental dan dapat berubah di masa depan.  

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Panggil proses terjemahan untuk setiap area yang cocok.  

    Tanpa opsi ini, **greple** berfungsi sebagai perintah pencarian normal. Jadi Anda dapat memeriksa bagian mana dari file yang akan menjadi subjek terjemahan sebelum memanggil pekerjaan yang sebenarnya.  

    Hasil perintah dikirim ke standar keluar, jadi alihkan ke file jika perlu, atau pertimbangkan untuk menggunakan modul [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).  

    Opsi **--xlate** memanggil opsi **--xlate-color** dengan opsi **--color=never**.  

    Dengan opsi **--xlate-fold**, teks yang dikonversi dilipat berdasarkan lebar yang ditentukan. Lebar default adalah 70 dan dapat diatur dengan opsi **--xlate-fold-width**. Empat kolom dicadangkan untuk operasi run-in, sehingga setiap baris dapat menampung maksimal 74 karakter.  

- **--xlate-engine**=_engine_

    Menentukan mesin terjemahan yang akan digunakan. Jika Anda menentukan modul mesin secara langsung, seperti `-Mxlate::deepl`, Anda tidak perlu menggunakan opsi ini.  

    Saat ini, mesin berikut tersedia  

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4-turbo
    - **gpt4o**: gpt-4o-mini

        Antarmuka **gpt-4o** tidak stabil dan tidak dapat dijamin berfungsi dengan benar saat ini.  

- **--xlate-labor**
- **--xlabor**

    Alih-alih memanggil mesin terjemahan, Anda diharapkan untuk bekerja. Setelah menyiapkan teks yang akan diterjemahkan, mereka disalin ke clipboard. Anda diharapkan untuk menempelkannya ke formulir, menyalin hasilnya ke clipboard, dan menekan return.  

- **--xlate-to** (Default: `EN-US`)

    Tentukan bahasa target. Anda dapat mendapatkan bahasa yang tersedia dengan perintah `deepl languages` saat menggunakan mesin **DeepL**.  

- **--xlate-format**=_format_ (Default: `conflict`)

    Tentukan format keluaran untuk teks asli dan terjemahan.  

    Format berikut selain `xtxt` mengasumsikan bahwa bagian yang akan diterjemahkan adalah kumpulan baris. Sebenarnya, dimungkinkan untuk menerjemahkan hanya sebagian dari sebuah baris, dan menentukan format selain `xtxt` tidak akan menghasilkan hasil yang berarti.  

    - **conflict**, **cm**

        Teks asli dan yang dikonversi dicetak dalam format penanda konflik [git(1)](http://man.he.net/man1/git).  

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Anda dapat memulihkan file asli dengan perintah [sed(1)](http://man.he.net/man1/sed) berikutnya.  

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Original and converted text are printed in [git(1)](http://man.he.net/man1/git) markdown **div** block style notation.  
        Teks asli dan yang dikonversi dicetak dalam notasi gaya blok **div** markdown [git(1)](http://man.he.net/man1/git).

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

        Jumlah kolom adalah 7 secara default. Jika Anda menentukan urutan kolom seperti `:::::`, itu akan digunakan sebagai pengganti 7 kolom.

    - **ifdef**

        Teks asli dan yang dikonversi dicetak dalam format [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.  

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

        Original and converted text are printed separated by single blank line. 
        Teks asli dan teks yang dikonversi dicetak terpisah dengan satu baris kosong.
        For `space+`, it also outputs a newline after the converted text.
        Untuk `space+`, ini juga mengeluarkan baris baru setelah teks yang dikonversi.

    - **xtxt**

        Jika formatnya adalah `xtxt` (teks terjemahan) atau tidak dikenal, hanya teks terjemahan yang dicetak.  

- **--xlate-maxlen**=_chars_ (Default: 0)

    Tentukan panjang maksimum teks yang akan dikirim ke API sekaligus. Nilai default diatur seperti untuk layanan akun DeepL gratis: 128K untuk API (**--xlate**) dan 5000 untuk antarmuka clipboard (**--xlate-labor**). Anda mungkin dapat mengubah nilai ini jika Anda menggunakan layanan Pro.  

- **--xlate-maxline**=_n_ (Default: 0)

    Tentukan jumlah maksimum baris teks yang akan dikirim ke API sekaligus.

    Setel nilai ini ke 1 jika Anda ingin menerjemahkan satu baris pada satu waktu. Opsi ini memiliki prioritas lebih tinggi daripada opsi `--xlate-maxlen`.  

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Lihat hasil terjemahan secara real-time di output STDERR.  

- **--match-all**

    Setel seluruh teks file sebagai area target.  

# CACHE OPTIONS

Modul **xlate** dapat menyimpan teks terjemahan yang di-cache untuk setiap file dan membacanya sebelum eksekusi untuk menghilangkan overhead meminta ke server. Dengan strategi cache default `auto`, ia hanya mempertahankan data cache ketika file cache ada untuk file target.  

Gunakan **--xlate-cache=clear** untuk memulai manajemen cache atau untuk membersihkan semua data cache yang ada. Setelah dijalankan dengan opsi ini, file cache baru akan dibuat jika belum ada dan kemudian secara otomatis dikelola setelahnya.

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

        Jangan pernah menggunakan file cache meskipun ada.  

    - `accumulate`

        Dengan perilaku default, data yang tidak terpakai dihapus dari file cache. Jika Anda tidak ingin menghapusnya dan menyimpannya di file, gunakan `accumulate`.  
- **--xlate-update**

    Opsi ini memaksa untuk memperbarui file cache meskipun tidak diperlukan.

# COMMAND LINE INTERFACE

Anda dapat dengan mudah menggunakan modul ini dari baris perintah dengan menggunakan perintah `xlate` yang disertakan dalam distribusi. Lihat informasi bantuan `xlate` untuk penggunaan.  

Perintah `xlate` bekerja sama dengan lingkungan Docker, jadi bahkan jika Anda tidak memiliki apa pun yang terinstal, Anda dapat menggunakannya selama Docker tersedia. Gunakan opsi `-D` atau `-C`.  

Juga, karena makefile untuk berbagai gaya dokumen disediakan, terjemahan ke dalam bahasa lain dimungkinkan tanpa spesifikasi khusus. Gunakan opsi `-M`.  

Anda juga dapat menggabungkan opsi Docker dan make sehingga Anda dapat menjalankan make di lingkungan Docker.  

Menjalankan seperti `xlate -GC` akan meluncurkan shell dengan repositori git kerja saat ini yang dipasang.  

Baca artikel Jepang di bagian ["SEE ALSO"](#see-also) untuk detail.  

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

Muat file `xlate.el` yang disertakan dalam repositori untuk menggunakan perintah `xlate` dari editor Emacs. Fungsi `xlate-region` menerjemahkan wilayah yang diberikan. Bahasa default adalah `EN-US` dan Anda dapat menentukan bahasa dengan memanggilnya dengan argumen prefiks.  

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Setel kunci otentikasi Anda untuk layanan DeepL.  

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

    Perpustakaan Python DeepL dan perintah CLI.  

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Perpustakaan Python OpenAI  

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Antarmuka baris perintah OpenAI  

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Lihat manual **greple** untuk detail tentang pola teks target. Gunakan opsi **--inside**, **--outside**, **--include**, **--exclude** untuk membatasi area pencocokan.  

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Anda dapat menggunakan modul `-Mupdate` untuk memodifikasi file berdasarkan hasil perintah **greple**.  

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Gunakan **sdif** untuk menunjukkan format penanda konflik berdampingan dengan opsi **-V**.  

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
