package App::Greple::xlate;

our $VERSION = "0.22";

=encoding utf-8

=head1 NAME

App::Greple::xlate - модуль поддержки перевода для greple

=head1 SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

=head1 VERSION

Version 0.22

=head1 DESCRIPTION

Модуль B<Greple> B<xlate> находит текстовые блоки и заменяет их переведенным текстом. В настоящее время модуль B<xlate::deepl> поддерживает только сервис DeepL.

Если вы хотите перевести обычный текстовый блок в документе стиля L<pod>, используйте команду B<greple> с модулем C<xlate::deepl> и C<perl> следующим образом:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Шаблон C<^(\w.*\n)+> означает последовательные строки, начинающиеся с буквенно-цифровой буквы. Эта команда показывает область, которая должна быть переведена. Опция B<--all> используется для создания всего текста.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
</p>

Затем добавьте опцию C<--xlate> для перевода выделенной области. Она найдет и заменит их на вывод команды B<deepl>.

По умолчанию оригинальный и переведенный текст печатается в формате "маркер конфликта", совместимом с L<git(1)>. Используя формат C<ifdef>, вы можете легко получить нужную часть командой L<unifdef(1)>. Формат может быть задан опцией B<--xlate-format>.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
</p>

Если вы хотите перевести весь текст, используйте опцию B<--match-all>. Это сокращение для указания соответствия шаблона всему тексту C<(?s).+>.

=head1 OPTIONS

=over 7

=item B<--xlate>

=item B<--xlate-color>

=item B<--xlate-fold>

=item B<--xlate-fold-width>=I<n> (Default: 70)

Запустите процесс перевода для каждой совпавшей области.

Без этой опции B<greple> ведет себя как обычная команда поиска. Таким образом, вы можете проверить, какая часть файла будет подвергнута переводу, прежде чем вызывать фактическую работу.

Результат команды выводится в стандартный аут, поэтому при необходимости перенаправьте его в файл или воспользуйтесь модулем L<App::Greple::update>.

Опция B<--xlate> вызывает опцию B<--xlate-color> с опцией B<--color=never>.

С опцией B<--xlate-fold> преобразованный текст сворачивается на указанную ширину. Ширина по умолчанию равна 70 и может быть задана опцией B<--xlate-fold-width>. Для обкатки зарезервировано четыре колонки, поэтому в каждой строке может содержаться не более 74 символов.

=item B<--xlate-engine>=I<engine>

Укажите используемый механизм перевода. Эту опцию можно не использовать, поскольку в модуле C<xlate::deepl> она объявлена как C<--xlate-engine=deepl>.

=item B<--xlate-labor>

=item B<--xlabor>

Вместо того чтобы вызывать систему перевода, вам предстоит работать. После подготовки текста для перевода он копируется в буфер обмена. Предполагается, что вы вставите их в форму, скопируете результат в буфер обмена и нажмете кнопку return.

=item B<--xlate-to> (Default: C<EN-US>)

Укажите целевой язык. Вы можете получить доступные языки с помощью команды C<deepl languages> при использовании движка B<DeepL>.

=item B<--xlate-format>=I<format> (Default: C<conflict>)

Укажите формат вывода оригинального и переведенного текста.

=over 4

=item B<conflict>, B<cm>

Выведите оригинальный и переведенный текст в формате маркера конфликта L<git(1)>.

    <<<<<<< ORIGINAL
    original text
    =======
    translated Japanese text
    >>>>>>> JA

Вы можете восстановить исходный файл следующей командой L<sed(1)>.

    sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

=item B<ifdef>

Печать оригинального и переведенного текста в формате L<cpp(1)> C<#ifdef>.

    #ifdef ORIGINAL
    original text
    #endif
    #ifdef JA
    translated Japanese text
    #endif

Вы можете восстановить только японский текст командой B<unifdef>:

    unifdef -UORIGINAL -DJA foo.ja.pm

=item B<space>

Вывести оригинальный и переведенный текст, разделенные одной пустой строкой.

=item B<xtxt>

Если формат C<xtxt> (переведенный текст) или неизвестен, печатается только переведенный текст.

=back

=item B<--xlate-maxlen>=I<chars> (Default: 0)

Укажите максимальную длину текста, который будет отправлен в API за один раз. Значение по умолчанию установлено как для бесплатного сервиса: 128K для API (B<--xlate>) и 5000 для интерфейса буфера обмена (B<--xlate-labor>). Вы можете изменить эти значения, если используете услугу Pro.

=item B<-->[B<no->]B<xlate-progress> (Default: True)

Результат перевода можно увидеть в реальном времени в выводе STDERR.

=item B<--match-all>

Установите весь текст файла в качестве целевой области.

=back

=head1 CACHE OPTIONS

Модуль B<xlate> может хранить кэшированный текст перевода для каждого файла и считывать его перед выполнением, чтобы исключить накладные расходы на запрос к серверу. При стратегии кэширования по умолчанию C<auto>, он сохраняет данные кэша только тогда, когда файл кэша существует для целевого файла.

=over 7

=item --cache-clear

Опция B<--cache-clear> может быть использована для инициирования управления кэшем или для обновления всех существующих данных кэша. После выполнения этой опции будет создан новый файл кэша, если он не существует, а затем автоматически сохранен.

=item --xlate-cache=I<strategy>

=over 4

=item C<auto> (Default)

Сохранять файл кэша, если он существует.

=item C<create>

Создать пустой файл кэша и выйти.

=item C<always>, C<yes>, C<1>

Сохранять кэш в любом случае, пока целевой файл является обычным файлом.

=item C<clear>

Сначала очистите данные кэша.

=item C<never>, C<no>, C<0>

Никогда не использовать файл кэша, даже если он существует.

=item C<accumulate>

По умолчанию неиспользуемые данные удаляются из файла кэша. Если вы не хотите удалять их и сохранять в файле, используйте C<accumulate>.

=back

=back

=head1 COMMAND LINE INTERFACE

Вы можете легко использовать этот модуль из командной строки с помощью команды C<xlate>, включенной в репозиторий. Информацию об использовании смотрите в справке C<xlate>.

=head1 EMACS

Загрузите файл F<xlate.el>, включенный в репозиторий, чтобы использовать команду C<xlate> из редактора Emacs. Функция C<xlate-region> переводит заданный регион. Язык по умолчанию - C<EN-US>, и вы можете указать язык, вызывая ее с помощью аргумента prefix.

=head1 ENVIRONMENT

=over 7

=item DEEPL_AUTH_KEY

Задайте ключ аутентификации для сервиса DeepL.

=back

=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::xlate

=head1 SEE ALSO

L<App::Greple::xlate>

=over 7

=item L<https://github.com/DeepLcom/deepl-python>

DeepL Библиотека Python и команда CLI.

=item L<App::Greple>

Подробную информацию о шаблоне целевого текста см. в руководстве B<greple>. Используйте опции B<--inside>, B<--outside>, B<--include>, B<--exclude> для ограничения области совпадения.

=item L<App::Greple::update>

Вы можете использовать модуль C<-Mupdate> для модификации файлов по результатам команды B<greple>.

=item L<App::sdif>

Используйте B<sdif>, чтобы показать формат маркера конфликта бок о бок с опцией B<-V>.

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

my $json_obj = JSON->new->utf8->canonical->pretty;

sub read_cache {
    my $file = shift;
    %$new_cache = %$old_cache = ();
    if (open my $fh, $file) {
	my $json = do { local $/; <$fh> };
	my $hash = $json eq '' ? {} : $json_obj->decode($json);
	%$old_cache = %$hash;
	warn "read cache from $file\n";
    }
}

sub write_cache {
    return if $dryrun;
    my $file = shift;
    if (open my $fh, '>', $file) {
	my $json = $json_obj->encode($new_cache);
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
