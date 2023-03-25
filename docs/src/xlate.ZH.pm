package App::Greple::xlate;

our $VERSION = "0.21";

=encoding utf-8

=head1 NAME

App::Greple::xlate - greple的翻译支持模块

=head1 SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

=head1 VERSION

Version 0.21

=head1 DESCRIPTION

B<Greple> B<xlate>模块找到文本块，并用翻译后的文本替换它们。目前B<xlate::deepl>模块只支持DeepL 服务。

如果你想翻译L<pod>风格文档中的普通文本块，可以像这样使用B<greple>命令与C<xlate::deepl>和C<perl>模块。

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

模式C<^(\w.*\n)+>表示以字母-数字开头的连续行。这个命令显示要翻译的区域。选项B<--all>用于生成整个文本。

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
</p>

然后添加C<--xlate>选项来翻译选定的区域。它将找到并替换为B<-deepl>命令的输出。

默认情况下，原始文本和翻译文本是以与L<git(1)>兼容的 "冲突标记 "格式打印的。使用 C<ifdef> 格式，你可以通过 L<unifdef(1)> 命令轻松获得所需的部分。格式可以由B<--xlate-format>选项指定。

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
</p>

如果你想翻译整个文本，使用B<--match-all>选项。这是指定模式匹配整个文本的捷径，C<(?s).+>。

=head1 OPTIONS

=over 7

=item B<--xlate>

=item B<--xlate-color>

=item B<--xlate-fold>

=item B<--xlate-fold-width>=I<n> (Default: 70)

对每个匹配的区域调用翻译过程。

如果没有这个选项，B<greple>的行为就像一个普通的搜索命令。所以你可以在调用实际工作之前检查文件的哪一部分将成为翻译的对象。

命令的结果会进入标准输出，所以如果需要的话，可以重定向到文件，或者考虑使用L<App::Greple::update>模块。

选项B<--xlate>调用B<--xlate-color>选项与B<--color=never>选项。

使用B<--xlate-fold>选项，转换后的文本将按指定的宽度进行折叠。默认宽度为70，可以通过B<--xlate-fold-width>选项设置。四列是为磨合操作保留的，所以每行最多可以容纳74个字符。

=item B<--xlate-engine>=I<engine>

指定要使用的翻译引擎。你不必使用这个选项，因为模块C<xlate::deepl>将它声明为C<--xlate-engine=deepl>。

=item B<--xlate-labor>

=item B<--xlabor>

与其说是调用翻译引擎，不如说是希望你能为之工作。在准备好要翻译的文本后，它们被复制到剪贴板上。你应该把它们粘贴到表格中，把结果复制到剪贴板上，然后点击返回。

=item B<--xlate-to> (Default: C<EN-US>)

指定目标语言。当使用B<DeepL>引擎时，你可以通过C<deepl languages>命令获得可用语言。

=item B<--xlate-format>=I<format> (Default: C<conflict>)

指定原始和翻译文本的输出格式。

=over 4

=item B<conflict>, B<cm>

以L<git(1)>冲突标记格式打印原始和翻译文本。

    <<<<<<< ORIGINAL
    original text
    =======
    translated Japanese text
    >>>>>>> JA

你可以通过下一个L<sed(1)>命令恢复原始文件。

    sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

=item B<ifdef>

以 L<cpp(1)> C<#ifdef> 格式打印原始和翻译文本。

    #ifdef ORIGINAL
    original text
    #endif
    #ifdef JA
    translated Japanese text
    #endif

你可以通过B<unifdef>命令只检索日文文本。

    unifdef -UORIGINAL -DJA foo.ja.pm

=item B<space>

打印原始文本和翻译文本，用单个空行分开。

=item B<xtxt>

如果格式是C<xtxt>（翻译文本）或不知道，则只打印翻译文本。

=back

=item B<--xlate-maxlen>=I<chars> (Default: 0)

指定一次性发送至API的最大文本长度。默认值设置为免费账户服务：API（B<--xlate>）为128K，剪贴板界面（B<--xlate-labor>）为5000。如果你使用专业服务，你可以改变这些值。

=item B<-->[B<no->]B<xlate-progress> (Default: True)

在STDERR输出中可以看到实时的翻译结果。

=item B<--match-all>

将文件的整个文本设置为目标区域。

=back

=head1 CACHE OPTIONS

B<xlate>模块可以存储每个文件的翻译缓存文本，并在执行前读取它，以消除向服务器请求的开销。在默认的缓存策略C<auto>下，它只在目标文件的缓存文件存在时才维护缓存数据。

=over 7

=item --cache-clear

B<--cache-clear>选项可以用来启动缓冲区管理或刷新所有现有的缓冲区数据。一旦用这个选项执行，如果不存在一个新的缓存文件，就会创建一个新的缓存文件，然后自动维护。

=item --xlate-cache=I<strategy>

=over 4

=item C<auto> (Default)

如果缓存文件存在，则维护该文件。

=item C<create>

创建空缓存文件并退出。

=item C<always>, C<yes>, C<1>

只要目标文件是正常文件，就维持缓存。

=item C<clear>

先清除缓存数据。

=item C<never>, C<no>, C<0>

即使缓存文件存在，也不使用它。

=item C<accumulate>

根据默认行为，未使用的数据会从缓存文件中删除。如果你不想删除它们并保留在文件中，使用C<accumulate>。

=back

=back

=head1 COMMAND LINE INTERFACE

你可以通过使用版本库中的C<xlate>命令从命令行轻松使用这个模块。请参阅 C<xlate> 的帮助信息了解用法。

=head1 EMACS

加载存储库中的F<xlate.el>文件，从Emacs编辑器中使用C<xlate>命令。C<xlate-region>函数翻译给定的区域。默认的语言是C<EN-US>，你可以用前缀参数指定调用语言。

=head1 ENVIRONMENT

=over 7

=item DEEPL_AUTH_KEY

为DeepL 服务设置你的认证密钥。

=back

=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::xlate

=head1 SEE ALSO

L<App::Greple::xlate>

=over 7

=item L<https://github.com/DeepLcom/deepl-python>

DeepL Python库和CLI命令。

=item L<App::Greple>

关于目标文本模式的细节，请参见B<greple>手册。使用B<--inside>, B<--outside>, B<--include>, B<--exclude>选项来限制匹配区域。

=item L<App::Greple::update>

你可以使用C<-Mupdate>模块通过B<greple>命令的结果来修改文件。

=item L<App::sdif>

使用B<sdif>与B<-V>选项并列显示冲突标记格式。

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
