package App::Greple::xlate;

our $VERSION = "0.09";

=encoding utf-8

=head1 NAME

App::Greple::xlate - модуль підтримки перекладу для greple

=head1 SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

=head1 DESCRIPTION

Модуль B<Greple> B<xlate> знаходить текстові блоки і замінює їх перекладеним текстом. Наразі модулем B<xlate::deepl> підтримується лише сервіс DeepL.

Якщо ви хочете перекласти звичайний текстовий блок у документі в стилі L<pod>, використовуйте команду B<greple> з модулем C<xlate::deepl> і C<perl> таким чином:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Шаблон C<^(\w.*\n)+> означає послідовні рядки, що починаються з буквено-цифрової літери. Ця команда показує область, яку потрібно перекласти. Параметр B<--all> використовується для перекладу всього тексту.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
</p>

Потім додайте опцію C<--xlate> для перекладу виділеної області. Вона знайде і замінить їх на виведені командою B<deepl>.

За замовчуванням оригінальний і перекладений текст виводиться у форматі "конфліктний маркер", сумісному з L<git(1)>. Використовуючи формат C<ifdef>, ви можете легко отримати потрібну частину командою L<unifdef(1)>. Формат можна вказати за допомогою опції B<--xlate-format>.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
</p>

Якщо ви хочете перекласти весь текст, використовуйте опцію B<--match-entire>. Це швидкий спосіб вказати, що шаблон збігається з усім текстом C<(?s).*>.

=head1 OPTIONS

=over 7

=item B<--xlate>

=item B<--xlate-color>

=item B<--xlate-fold>

=item B<--xlate-fold-width>=I<n> (Default: 70)

Виклик процесу перекладу для кожної знайденої області.

Без цього параметра B<greple> поводиться як звичайна команда пошуку. Таким чином, ви можете перевірити, яку частину файлу буде перекладено, перш ніж викликати процес перекладу.

Результат команди буде виведено у стандартний вивід, тому за потреби переспрямуйте його на файл або скористайтеся модулем L<App::Greple::update>.

Опція B<--xlate> викликає опцію B<--xlate-color> з опцією B<--color=never>.

За допомогою опції B<--xlate-fold> перетворений текст буде згорнуто за вказаною шириною. За замовчуванням ширина складає 70 і може бути встановлена за допомогою параметра B<--xlate-fold-width>. Чотири стовпчики зарезервовано для обкатки, тому кожен рядок може містити не більше 74 символів.

=item B<--xlate-engine>=I<engine>

Вкажіть рушій перекладу, який буде використано. Вам не потрібно використовувати цей параметр, оскільки модуль C<xlate::deepl> оголошує його як C<--xlate-engine=deepl>.

=item B<--xlate-labor>

Замість того, щоб викликати рушій перекладу, ви маєте працювати з ним. Після підготовки тексту для перекладу він копіюється в буфер обміну. Ви маєте вставити його у форму, скопіювати результат у буфер обміну і натиснути клавішу return.

=item B<--xlate-to> (Default: C<JA>)

Вкажіть цільову мову. Доступні мови можна отримати за допомогою команди C<deepl languages> у разі використання рушія B<DeepL>.

=item B<--xlate-format>=I<format> (Default: conflict)

Вкажіть формат виведення оригінального та перекладеного тексту.

=over 4

=item B<conflict>

Вивести оригінальний і перекладений текст у форматі конфліктних маркерів L<git(1)>.

    <<<<<<< ORIGINAL
    original text
    =======
    translated Japanese text
    >>>>>>> JA

Відновити вихідний файл можна наступною командою L<sed(1)>.

    sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

=item B<ifdef>

Вивести оригінальний та перекладений текст у форматі L<cpp(1)> C<#ifdef>.

    #ifdef ORIGINAL
    original text
    #endif
    #ifdef JA
    translated Japanese text
    #endif

За допомогою команди B<unifdef> можна отримати лише японський текст:

    unifdef -UORIGINAL -DJA foo.ja.pm

=item B<space>

Вивести текст оригіналу та перекладу, розділені одним порожнім рядком.

=item B<none>

Якщо формат C<none> або невідомий, буде надруковано лише перекладений текст.

=back

=item B<-->[B<no->]B<xlate-progress> (Default: True)

Результат перекладу у реальному часі можна побачити у виводі STDERR.

=item B<--match-entire>

Встановити весь текст файлу як цільову область.

=back

=head1 CACHE OPTIONS

Модуль B<xlate> може зберігати кешований текст перекладу для кожного файлу і зчитувати його перед виконанням, щоб усунути накладні витрати на запити до сервера. За замовчуванням стратегія кешування C<auto> зберігає кешовані дані лише тоді, коли для цільового файлу існує файл кешу.

=over 7

=item --refresh

За допомогою команди <--refresh> можна ініціювати керування кешем або оновити всі наявні дані кешу. Після виконання цієї опції буде створено новий файл кешу, якщо його не існує, а потім він буде автоматично підтримуватися.

=item --xlate-cache=I<strategy>

=over 4

=item C<auto> (Default)

Зберігати файл кешу, якщо він існує.

=item C<create>

Створити порожній файл кешу і вийти.

=item C<always>, C<yes>, C<1>

Зберігати кеш у будь-якому випадку, якщо цільовий файл є нормальним.

=item C<refresh>

Обслуговувати кеш, але не читати наявний.

=item C<never>, C<no>, C<0>

Ніколи не використовувати файл кешу, навіть якщо він існує.

=item C<accumulate>

За замовчуванням, невикористані дані видаляються з кеш-файлу. Якщо ви не хочете видаляти їх і зберігати у файлі, використовуйте C<accumulate>.

=back

=back

=head1 ENVIRONMENT

=over 7

=item DEEPL_AUTH_KEY

Встановіть свій ключ автентифікації для сервісу DeepL.

=back

=head1 SEE ALSO

=over 7

=item L<https://github.com/DeepLcom/deepl-python>

DeepL Бібліотека Python і команда CLI.

=item L<App::Greple>

Детальніше про шаблон цільового тексту див. у посібнику B<greple>. Використовуйте опції B<--inside>, B<--outside>, B<--include>, B<--exclude> для обмеження області пошуку.

=item L<App::Greple::update>

Ви можете скористатися модулем C<-Mupdate> для модифікації файлів за результатами виконання команди B<greple>.

=item L<App::sdif>

Використовуйте B<sdif> для відображення формату конфліктних маркерів поряд з опцією B<-V>.

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
	if ($cache_method ne 'refresh') {
	    read_cache $cache;
	}
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

option --refresh --xlate-cache=refresh

option --match-entire    --re '\A(?s).+\z'
option --match-paragraph --re '^(.+\n)+'
option --match-podtext   -Mperl --pod --re '^(\w.*\n)(\S.*\n)*'

option --ifdef-color --re '^#ifdef(?s:.*?)^#endif.*\n'

#  LocalWords:  deepl ifdef unifdef Greple greple perl
