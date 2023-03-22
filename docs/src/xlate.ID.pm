package App::Greple::xlate;

our $VERSION = "0.19";

=encoding utf-8

=head1 NAME

App::Greple::xlate - modul dukungan penerjemahan untuk greple

=head1 SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

=head1 VERSION

Version 0.19

=head1 DESCRIPTION

Modul B<Greple> B<xlate> menemukan blok teks dan menggantinya dengan teks yang telah diterjemahkan. Saat ini hanya layanan DeepL yang didukung oleh modul B<xlate::deepl>.

Jika Anda ingin menerjemahkan blok teks normal dalam dokumen gaya L<pod>, gunakan perintah B<greple> dengan modul C<xlate::deepl> dan C<perl> seperti ini:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Pola C<^(\w.*\n)+> berarti baris berurutan yang dimulai dengan huruf alfanumerik. Perintah ini menunjukkan area yang akan diterjemahkan. Opsi B<--all> digunakan untuk menghasilkan seluruh teks.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
</p>

Kemudian tambahkan opsi C<--xlate> untuk menerjemahkan area yang dipilih. Ini akan menemukan dan menggantinya dengan keluaran perintah B<deepl>.

Secara default, teks asli dan terjemahan dicetak dalam format "penanda konflik" yang kompatibel dengan L<git(1)>. Dengan menggunakan format C<ifdef>, Anda dapat memperoleh bagian yang diinginkan dengan perintah L<unifdef(1)> dengan mudah. Format dapat ditentukan dengan opsi B<--xlate-format>.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
</p>

Jika Anda ingin menerjemahkan seluruh teks, gunakan opsi B<--match-all>. Ini adalah jalan pintas untuk menentukan pola yang cocok dengan seluruh teks C<(?).+>.

=head1 OPTIONS

=over 7

=item B<--xlate>

=item B<--xlate-color>

=item B<--xlate-fold>

=item B<--xlate-fold-width>=I<n> (Default: 70)

Memanggil proses penerjemahan untuk setiap area yang cocok.

Tanpa opsi ini, B<greple> berperilaku sebagai perintah pencarian biasa. Jadi, Anda dapat memeriksa bagian mana dari file yang akan menjadi subjek terjemahan sebelum memanggil pekerjaan yang sebenarnya.

Hasil perintah akan keluar ke standar, jadi alihkan ke file jika perlu, atau pertimbangkan untuk menggunakan modul L<App::Greple::update>.

Opsi B<--xlate> memanggil opsi B<--xlate-color> dengan opsi B<--color=never>.

Dengan opsi B<--xlate-fold>, teks yang dikonversi akan dilipat dengan lebar yang ditentukan. Lebar default adalah 70 dan dapat diatur dengan opsi B<--xlate-fold-width>. Empat kolom dicadangkan untuk operasi run-in, sehingga setiap baris dapat menampung paling banyak 74 karakter.

=item B<--xlate-engine>=I<engine>

Tentukan mesin penerjemahan yang akan digunakan. Anda tidak perlu menggunakan opsi ini karena modul C<xlate::deepl> mendeklarasikannya sebagai C<--xlate-engine=deepl>.

=item B<--xlate-labor>

=item B<--xlabor>

Setelah memanggil mesin penerjemahan, Anda diharapkan untuk bekerja. Setelah menyiapkan teks yang akan diterjemahkan, teks tersebut disalin ke clipboard. Anda diharapkan untuk menempelkannya ke formulir, menyalin hasilnya ke clipboard, dan menekan return.

=item B<--xlate-to> (Default: C<EN-US>)

Tentukan bahasa target. Anda bisa mendapatkan bahasa yang tersedia dengan perintah C<deepl languages> ketika menggunakan mesin B<DeepL>.

=item B<--xlate-format>=I<format> (Default: C<conflict>)

Tentukan format output untuk teks asli dan terjemahan.

=over 4

=item B<conflict>, B<cm>

Mencetak teks asli dan teks terjemahan dalam format penanda konflik L<git(1)>.

    <<<<<<< ORIGINAL
    original text
    =======
    translated Japanese text
    >>>>>>> JA

Anda dapat memulihkan file asli dengan perintah L<sed(1)> berikutnya.

    sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

=item B<ifdef>

Mencetak teks asli dan teks terjemahan dalam format L<cpp(1)> C<#ifdef>.

    #ifdef ORIGINAL
    original text
    #endif
    #ifdef JA
    translated Japanese text
    #endif

Anda hanya dapat mengambil teks bahasa Jepang dengan perintah B<unifdef>:

    unifdef -UORIGINAL -DJA foo.ja.pm

=item B<space>

Mencetak teks asli dan teks terjemahan yang dipisahkan oleh satu baris kosong.

=item B<xtxt>

Jika formatnya adalah C<xtxt> (teks terjemahan) atau tidak diketahui, hanya teks terjemahan yang dicetak.

=back

=item B<--xlate-maxlen>=I<chars> (Default: 0)

Tentukan panjang maksimum teks yang akan dikirim ke API sekaligus. Nilai default ditetapkan untuk layanan akun gratis: 128K untuk API (B<--xlate>) dan 5000 untuk antarmuka clipboard (B<--xlate-labor>). Anda mungkin dapat mengubah nilai ini jika Anda menggunakan layanan Pro.

=item B<-->[B<no->]B<xlate-progress> (Default: True)

Lihat hasil terjemahan secara real time dalam output STDERR.

=item B<--match-all>

Mengatur seluruh teks file sebagai area target.

=back

=head1 CACHE OPTIONS

Modul B<xlate> dapat menyimpan teks terjemahan dalam cache untuk setiap file dan membacanya sebelum eksekusi untuk menghilangkan overhead dari permintaan ke server. Dengan strategi cache default C<auto>, modul ini mempertahankan data cache hanya ketika file cache ada untuk file target.

=over 7

=item --cache-clear

Opsi B<--cache-clear> dapat digunakan untuk memulai manajemen cache atau untuk menyegarkan semua data cache yang ada. Setelah dieksekusi dengan opsi ini, file cache baru akan dibuat jika belum ada dan kemudian secara otomatis dipelihara setelahnya.

=item --xlate-cache=I<strategy>

=over 4

=item C<auto> (Default)

Mempertahankan file cache jika sudah ada.

=item C<create>

Buat file cache kosong dan keluar.

=item C<always>, C<yes>, C<1>

Pertahankan cache sejauh targetnya adalah file normal.

=item C<clear>

Hapus data cache terlebih dahulu.

=item C<never>, C<no>, C<0>

Jangan pernah menggunakan file cache meskipun ada.

=item C<accumulate>

Secara default, data yang tidak digunakan akan dihapus dari file cache. Jika Anda tidak ingin menghapusnya dan menyimpannya di dalam file, gunakan C<accumulate>.

=back

=back

=head1 ENVIRONMENT

=over 7

=item DEEPL_AUTH_KEY

Tetapkan kunci autentikasi Anda untuk layanan DeepL.

=back

=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::xlate

=head1 SEE ALSO

L <App::Greple::xlate>

=over 7

=item L<https://github.com/DeepLcom/deepl-python>

DeepL pustaka Python dan perintah CLI.

=item L<App::Greple>

Lihat manual B<greple> untuk detail tentang pola teks target. Gunakan opsi B<--inside>, B<--outside>, B<--include>, B<--exclude> untuk membatasi area pencocokan.

=item L<App::Greple::update>

Anda dapat menggunakan modul C<-Mupdate> untuk memodifikasi file berdasarkan hasil perintah B<greple>.

=item L<App::sdif>

Gunakan B<sdif> untuk menampilkan format penanda konflik berdampingan dengan opsi B<-V>.

=back

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use v5.14;
use warnings;

use Data::Dumper;

use JSON;
use Text::ANSI::Fold ':constants';
use App::cdif::Command;
use Hash::Util qw(lock_keys);
use Unicode::EastAsianWidth;

our %opt = (
    engine   => \(our $xlate_engine),
    progress => \(our $show_progress = 1),
    format   => \(our $output_format = 'conflict'),
    collapse => \(our $collapse_spaces = 1),
    from     => \(our $lang_from = 'ORIGINAL'),
    to       => \(our $lang_to = 'EN-US'),
    fold     => \(our $fold_line = 0),
    width    => \(our $fold_width = 70),
    auth_key => \(our $auth_key),
    method   => \(our $cache_method //= $ENV{GREPLE_XLATE_CACHE} || 'auto'),
    dryrun   => \(our $dryrun = 0),
    maxlen   => \(our $max_length = 0),
    );
lock_keys %opt;
sub opt :lvalue { ${$opt{+shift}} }

my $current_file;

our %formatter = (
    xtxt => undef,
    none => undef,
    conflict => sub {
	join '',
	    "<<<<<<< $lang_from\n",
	    $_[0],
	    "=======\n",
	    $_[1],
	    ">>>>>>> $lang_to\n";
    },
    cm => 'conflict',
    ifdef => sub {
	join '',
	    "#ifdef $lang_from\n",
	    $_[0],
	    "#endif\n",
	    "#ifdef $lang_to\n",
	    $_[1],
	    "#endif\n";
    },
    space   => sub { join "\n", @_ },
    discard => sub { '' },
    );

# aliases
for (keys %formatter) {
    next if ! $formatter{$_} or ref $formatter{$_};
    $formatter{$_} = $formatter{$formatter{$_}} // die;
}

my $old_cache = {};
my $new_cache = {};
my $xlate_cache_update;

sub setup {
    return if state $once_called++;
    if (defined $cache_method) {
	if ($cache_method eq '') {
	    $cache_method = 'auto';
	}
	if (lc $cache_method eq 'accumulate') {
	    $new_cache = $old_cache;
	}
	if ($cache_method =~ /^(no|never)/i) {
	    $cache_method = '';
	}
    }
    if ($xlate_engine) {
	my $mod = __PACKAGE__ . "::$xlate_engine";
	if (eval "require $mod") {
	    $mod->import;
	} else {
	    die "Engine $xlate_engine is not available.\n";
	}
	no strict 'refs';
	${"$mod\::lang_from"} = $lang_from;
	${"$mod\::lang_to"} = $lang_to;
	*XLATE = \&{"$mod\::xlate"};
	if (not defined &XLATE) {
	    die "No \"xlate\" function in $mod.\n";
	}
    }
}

sub normalize {
    $_[0] =~ s{^.+(?:\n.+)*}{
	${^MATCH}
	    =~ s/\A\s+|\s+\z//gr
	    =~ s/(?<=\p{InFullwidth})\n(?=\p{InFullwidth})//gr
	    =~ s/\s+/ /gr
    }pmger;
}

sub postgrep {
    my $grep = shift;
    my @miss;
    for my $r ($grep->result) {
	my($b, @match) = @$r;
	for my $m (@match) {
	    my $key = normalize $grep->cut(@$m);
	    $new_cache->{$key} //= delete $old_cache->{$key} // do {
		push @miss, $key;
		"NOT TRANSLATED YET\n";
	    };
	}
    }
    cache_update(@miss) if @miss;
}

sub cache_update {
    binmode STDERR, ':encoding(utf8)';

    my @from = @_;
    print STDERR "From:\n", map s/^/\t< /mgr, @from if $show_progress;
    return @from if $dryrun;

    my @to = &XLATE(@from);

    print STDERR "To:\n", map s/^/\t> /mgr, @to if $show_progress;
    die "Unmatched response:\n@to" if @from != @to;
    $xlate_cache_update += @from;
    @{$new_cache}{@from} = @to;
}

sub fold_lines {
    state $fold = Text::ANSI::Fold->new(
	width     => $fold_width,
	boundary  => 'word',
	linebreak => LINEBREAK_ALL,
	runin     => 4,
	runout    => 4,
	);
    local $_ = shift;
    s/(.+)/join "\n", $fold->text($1)->chops/ge;
    $_;
}

sub xlate {
    my $text = shift;
    my $key = normalize $text;
    my $s = $new_cache->{$key} // "!!! TRANSLATION ERROR !!!\n";
    $s = fold_lines $s if $fold_line;
    if (state $formatter = $formatter{$output_format}) {
	return $formatter->($text, $s);
    } else {
	return $s;
    }
}
sub colormap { xlate $_ }
sub callback { xlate { @_ }->{match} }

sub cache_file {
    my $file = sprintf("%s.xlate-%s-%s.json",
		       $current_file, $xlate_engine, $lang_to);
    if ($cache_method eq 'auto') {
	-f $file ? $file : undef;
    } else {
	if ($cache_method and -f $current_file) {
	    $file;
	} else {
	    undef;
	}
    }
}

sub read_cache {
    my $file = shift;
    %$new_cache = %$old_cache = ();
    if (open my $fh, $file) {
	my $json = do { local $/; <$fh> };
	my $hash = $json eq '' ? {} : decode_json $json;
	%$old_cache = %$hash;
	warn "read cache from $file\n";
    }
}

sub write_cache {
    return if $dryrun;
    my $file = shift;
    if (open my $fh, '>', $file) {
	my $json = encode_json $new_cache;
	print $fh $json;
	warn "write cache to $file\n";
    }
}

sub begin {
    setup if not (state $done++);
    my %args = @_;
    $current_file = delete $args{&::FILELABEL} or die;
    s/\z/\n/ if /.\z/;
    $xlate_cache_update = 0;
    if (not defined $xlate_engine) {
	die "Select translation engine.\n";
    }
    if (my $cache = cache_file) {
	if ($cache_method =~ /^(create|clear)/) {
	    warn "created $cache\n" unless -f $cache;
	    open my $fh, '>', $cache or die "$cache: $!\n";
	    print $fh "{}\n";
	    die "skip $current_file" if $cache_method eq 'create';
	}
	read_cache $cache;
    }
}

sub end {
    if (my $cache = cache_file) {
	if ($xlate_cache_update or %$old_cache) {
	    write_cache $cache;
	}
    }
}

sub setopt {
    while (my($key, $val) = splice @_, 0, 2) {
	next if $key eq &::FILELABEL;
	die "$key: Invalid option.\n" if not exists $opt{$key};
	opt($key) = $val;
    }
}

1;

__DATA__

builtin xlate-progress!    $show_progress
builtin xlate-format=s     $output_format
builtin xlate-fold-line!   $fold_line
builtin xlate-fold-width=i $fold_width
builtin xlate-from=s       $lang_from
builtin xlate-to=s         $lang_to
builtin xlate-cache:s      $cache_method
builtin xlate-engine=s     $xlate_engine
builtin xlate-dryrun       $dryrun
builtin xlate-maxlen=i     $max_length

builtin deepl-auth-key=s   $App::Greple::xlate::deepl::auth_key
builtin deepl-method=s     $App::Greple::xlate::deepl::method

option default --face +E --ci=A

option --xlate-setopt --prologue &__PACKAGE__::setopt($<shift>)

option --xlate-color \
	--postgrep &__PACKAGE__::postgrep \
	--callback &__PACKAGE__::callback \
	--begin    &__PACKAGE__::begin \
	--end      &__PACKAGE__::end
option --xlate --xlate-color --color=never
option --xlate-fold --xlate --xlate-fold-line
option --xlate-labor --xlate --deepl-method=clipboard
option --xlabor --xlate-labor

option --cache-clear --xlate-cache=clear

option --match-all       --re '\A(?s).+\z'
option --match-entire    --match-all
option --match-paragraph --re '^(.+\n)+'
option --match-podtext   -Mperl --pod --re '^(\w.*\n)(\S.*\n)*'

option --ifdef-color --re '^#ifdef(?s:.*?)^#endif.*\n'

#  LocalWords:  deepl ifdef unifdef Greple greple perl
