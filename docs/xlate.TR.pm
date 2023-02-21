package App::Greple::xlate;

our $VERSION = "0.07";

=encoding utf-8

=head1 NAME

App::Greple::xlate - greple için çeviri destek modülü

=head1 SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

=head1 DESCRIPTION

B<Greple> B<xlate> modülü metin bloklarını bulur ve bunları çevrilmiş metinle değiştirir. Şu anda sadece DeepL servisi B<xlate::deepl> modülü tarafından desteklenmektedir.

L<pod> stili belgede normal metin bloğunu çevirmek istiyorsanız, B<greple> komutunu C<xlate::deepl> ve C<perl> modülü ile aşağıdaki gibi kullanın:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

C<^(\w.*\n)+> kalıbı alfa-nümerik harfle başlayan ardışık satırlar anlamına gelir. Bu komut çevrilecek alanı gösterir. B<--all> seçeneği tüm metni üretmek için kullanılır.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
</p>

Daha sonra seçilen alanı çevirmek için C<--xlate> seçeneğini ekleyin. B<deepl> komut çıktısı ile bunları bulacak ve değiştirecektir.

Varsayılan olarak, orijinal ve çevrilmiş metin L<git(1)> ile uyumlu "conflict marker" formatında yazdırılır. C<ifdef> formatını kullanarak, L<unifdef(1)> komutu ile istediğiniz kısmı kolayca elde edebilirsiniz. Biçim B<--xlate-format> seçeneği ile belirtilebilir.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
</p>

Eğer metnin tamamını çevirmek istiyorsanız, B<--match-entire> seçeneğini kullanın. Bu, C<(?s).*> metninin tamamıyla eşleşen kalıbı belirtmek için bir kısa yoldur.

=head1 OPTIONS

=over 7

=item B<--xlate>

=item B<--xlate-color>

=item B<--xlate-fold>

=item B<--xlate-fold-width>=I<n> (Default: 70)

Eşleşen her alan için çeviri işlemini çağırın.

Bu seçenek olmadan, B<greple> normal bir arama komutu gibi davranır. Böylece, asıl işi çağırmadan önce dosyanın hangi bölümünün çeviriye tabi olacağını kontrol edebilirsiniz.

Komut sonucu standart çıkışa gider, bu nedenle gerekirse dosyaya yönlendirin veya L<App::Greple::update> modülünü kullanmayı düşünün.

B<--xlate> seçeneği B<--color=never> seçeneği ile B<--xlate-color> seçeneğini çağırır.

B<--xlate-fold> seçeneği ile, dönüştürülen metin belirtilen genişlikte katlanır. Varsayılan genişlik 70'tir ve B<--xlate-fold-width> seçeneği ile ayarlanabilir. Çalıştırma işlemi için dört sütun ayrılmıştır, bu nedenle her satır en fazla 74 karakter alabilir.

=item B<--xlate-engine>=I<engine>

Kullanılacak çeviri motorunu belirtin. Bu seçeneği kullanmak zorunda değilsiniz çünkü C<xlate::deepl> modülü bunu C<--xlate-engine=deepl> olarak bildirir.

=item B<--xlate-to> (Default: C<JA>)

Hedef dili belirtin. B<DeepL> motorunu kullanırken C<deepl languages> komutu ile mevcut dilleri alabilirsiniz.

=item B<--xlate-format>=I<format> (Default: conflict)

Orijinal ve çevrilmiş metin için çıktı formatını belirtin.

=over 4

=item B<conflict>

Orijinal ve çevrilmiş metni L<git(1)> çakışma işaretleyici biçiminde yazdırın.

    <<<<<<< ORIGINAL
    original text
    =======
    translated Japanese text
    >>>>>>> JA

Bir sonraki L<sed(1)> komutu ile orijinal dosyayı kurtarabilirsiniz.

    sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

=item B<ifdef>

Orijinal ve çevrilmiş metni L<cpp(1)> C<#ifdef> biçiminde yazdırın.

    #ifdef ORIGINAL
    original text
    #endif
    #ifdef JA
    translated Japanese text
    #endif

B<unifdef> komutu ile sadece Japonca metni alabilirsiniz:

    unifdef -UORIGINAL -DJA foo.ja.pm

=item B<space>

Orijinal ve çevrilmiş metni tek bir boş satırla ayırarak yazdırın.

=item B<none>

Eğer format C<none> veya unkown ise, sadece çevrilmiş metin yazdırılır.

=back

=item B<-->[B<no->]B<xlate-progress> (Default: True)

Çeviri sonucunu STDERR çıktısında gerçek zamanlı olarak görün.

=item B<--match-entire>

Dosyanın tüm metnini hedef alan olarak ayarlayın.

=back

=head1 CACHE OPTIONS

B<xlate> modülü her dosya için önbelleğe alınmış çeviri metnini saklayabilir ve sunucuya sorma ek yükünü ortadan kaldırmak için yürütmeden önce okuyabilir. Varsayılan önbellek stratejisi C<auto> ile, önbellek verilerini yalnızca hedef dosya için önbellek dosyası mevcut olduğunda tutar. İlgili önbellek dosyası mevcut değilse, oluşturmaz.

=over 7

=item --xlate-cache=I<strategy>

=over 4

=item C<auto> (Default)

Eğer varsa önbellek dosyasını korur.

=item C<create>

Boş önbellek dosyası oluştur ve çık.

=item C<always>, C<yes>, C<1>

Hedef normal dosya olduğu sürece önbelleği yine de korur.

=item C<never>, C<no>, C<0>

Var olsa bile önbellek dosyasını asla kullanmayın.

=item C<accumulate>

Varsayılan davranış olarak, kullanılmayan veriler önbellek dosyasından kaldırılır. Bunları kaldırmak ve dosyada tutmak istemiyorsanız, C<accumulate> kullanın.

=back

=back

=head1 ENVIRONMENT

=over 7

=item DEEPL_AUTH_KEY

DeepL hizmeti için kimlik doğrulama anahtarınızı ayarlayın.

=back

=head1 SEE ALSO

=over 7

=item L<https://github.com/DeepLcom/deepl-python>

DeepL Python kütüphanesi ve CLI komutu.

=item L<App::Greple>

Hedef metin kalıbı hakkında ayrıntılı bilgi için B<greple> kılavuzuna bakın. Eşleşen alanı sınırlamak için B<--inside>, B<--outside>, B<--include>, B<--exclude> seçeneklerini kullanın.

=item L<App::Greple::update>

Dosyaları B<greple> komutunun sonucuna göre değiştirmek için C<-Mupdate> modülünü kullanabilirsiniz.

=item L<App::sdif>

B<-V> seçeneği ile çakışma işaretleyici formatını yan yana göstermek için B<sdif> kullanın.

=back

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Telif hakkı ©︎ 2023 Kazumasa Utashiro.

Bu kütüphane özgür yazılımdır; Perl'ün kendisi ile aynı koşullar altında yeniden dağıtabilir ve/veya değiştirebilirsiniz.

=cut

use v5.14;
use warnings;

use Data::Dumper;

use JSON;
use Text::ANSI::Fold ':constants';
use App::cdif::Command;
use Hash::Util qw(lock_keys);

my %opt = (
    engine   => \(our $xlate_engine),
    progress => \(our $show_progress = 1),
    format   => \(our $output_format = 'conflict'),
    collapse => \(our $collapse_spaces = 1),
    from     => \(our $lang_from = 'ORIGINAL'),
    to       => \(our $lang_to = 'JA'),
    fold     => \(our $fold_line = 0),
    width    => \(our $fold_width = 70),
    auth_key => \(our $auth_key),
    method   => \(our $cache_method //= $ENV{GREPLE_XLATE_CACHE} || 'auto'),
    dryrun   => \(our $dryrun = 0),
    );
lock_keys %opt;
sub opt :lvalue { ${$opt{+shift}} }

my $current_file;

our %formatter = (
    none => undef,
    conflict => sub {
	join '',
	    "<<<<<<< $lang_from\n",
	    $_[0],
	    "=======\n",
	    $_[1],
	    ">>>>>>> $lang_to\n";
    },
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
	${^MATCH} =~ s/\A\s+|\s+\z//gr =~ s/\s+/ /gr
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
	if ($cache_method eq 'create') {
	    unless (-f $cache) {
		open my $fh, '>', $cache or die "$cache: $!\n";
		warn "created $cache\n";
		print $fh "{}\n";
	    }
	    die "skip $current_file";
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

builtin deepl-auth-key=s   $__PACKAGE__::deepl::auth_key

option default --face +E --ci=A

option --xlate-setopt --prologue &__PACKAGE__::setopt($<shift>)

option --xlate-color \
	--postgrep &__PACKAGE__::postgrep \
	--callback &__PACKAGE__::callback \
	--begin    &__PACKAGE__::begin \
	--end      &__PACKAGE__::end
option --xlate --xlate-color --color=never
option --xlate-fold --xlate --xlate-fold-line

option --match-entire    --re '\A(?s).+\z'
option --match-paragraph --re '^(.+\n)+'
option --match-podtext   -Mperl --pod --re '^(\w.*\n)(\S.*\n)*'

option --ifdef-color --re '^#ifdef(?s:.*?)^#endif.*\n'

#  LocalWords:  deepl ifdef unifdef Greple greple perl
