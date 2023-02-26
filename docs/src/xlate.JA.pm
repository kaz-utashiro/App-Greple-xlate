package App::Greple::xlate;

our $VERSION = "0.08";

=encoding utf-8

=head1 NAME

App::Greple::xlate - greple 用の翻訳サポートモジュール

=head1 SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

=head1 DESCRIPTION

B<Greple> B<xlate> モジュールは、テキストブロックを見つけ、翻訳されたテキストに置き換える。現在、B<xlate::deepl>モジュールが対応しているのはDeepLサービスのみである。

L<pod>形式の文書中の通常のテキストブロックを翻訳したい場合は、B<greple>コマンドとC<xlate::deepl>モジュール、C<perl>モジュールを使って、以下のようにする。

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

パターン C<^(\w.*n)+> は、英数字で始まる連続した行を意味する。このコマンドは、翻訳される領域を表示する。オプションB<--all>は、テキスト全体を翻訳するために使用する。

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
</p>

次に、C<--xlate>オプションを追加して、選択された領域を翻訳する。これは、B<deepl>コマンドの出力でそれらを見つけて置き換える。

デフォルトでは、原文と訳文が L<git(1)> と互換性のある "conflict marker" フォーマットで出力される。C<ifdef> 形式を用いると、L<unifdef(1)> コマンドで簡単に目的の部分を得ることができる。B<--xlate-format>オプションでフォーマットを指定することができる。

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
</p>

テキスト全体を翻訳したい場合は、B<--match-entire>オプションを使用する。これは、C<(?s).*>というテキスト全体にマッチするパターンを指定するためのショートカットである。

=head1 OPTIONS

=over 7

=item B<--xlate>

=item B<--xlate-color>

=item B<--xlate-fold>

=item B<--xlate-fold-width>=I<n> (Default: 70)

マッチした部分ごとに翻訳処理を起動する。

このオプションがない場合、B<greple>は通常の検索コマンドとして動作する。したがって、ファイルのどの部分が翻訳の対象となるかを、実際の作業を始める前に確認することができる。

コマンドの結果は標準出力されますので、必要に応じてファイルにリダイレクトするか、L<App::Greple::update>モジュールの使用を検討してください。

B<--xlate>オプションは、B<--xlate-color>オプションをB<--color=never>オプションで呼び出する。

B<--xlate-fold>オプションでは、変換されたテキストを指定した幅で折り返す。デフォルトの幅は70で、B<--xlate-fold-width>オプションで設定することができる。ランイン動作のために4列が確保されているので、1行には最大で74文字が格納できる。

=item B<--xlate-engine>=I<engine>

使用する翻訳エンジンを指定する。モジュールC<xlate::deepl>でC<--xlate-engine=deepl>として宣言されているので、このオプションを使う必要はない。

=item B<--xlate-to> (Default: C<JA>)

ターゲット言語を指定する。B<DeepL>エンジン使用時は、C<deepl languages>コマンドで利用可能な言語を取得できる。

=item B<--xlate-format>=I<format> (Default: conflict)

原文と訳文の出力形式を指定する。

=over 4

=item B<conflict>

原文と訳文をL<git(1)>コンフリクトマーカー形式で出力する。

    <<<<<<< ORIGINAL
    original text
    =======
    translated Japanese text
    >>>>>>> JA

次のL<sed(1)>コマンドで元のファイルを復元することができる。

    sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

=item B<ifdef>

原文と訳文をL<cpp(1)> C<#ifdef>形式で出力する。

    #ifdef ORIGINAL
    original text
    #endif
    #ifdef JA
    translated Japanese text
    #endif

B<unifdef>コマンドで日本語テキストのみを取り出すことができる。

    unifdef -UORIGINAL -DJA foo.ja.pm

=item B<space>

原文と訳文を1行の空白で区切って表示する。

=item B<none>

C<none>またはunknownの場合、翻訳されたテキストのみが表示される。

=back

=item B<-->[B<no->]B<xlate-progress> (Default: True)

翻訳結果はSTDERR出力にリアルタイムで表示される。

=item B<--match-entire>

ファイルの全テキストを対象範囲に設定する。

=back

=head1 CACHE OPTIONS

B<xlate>モジュールは、各ファイルの翻訳テキストをキャッシュしておき、実行前にそれを読むことで、サーバーへの問い合わせのオーバーヘッドをなくすことができる。デフォルトのキャッシュ戦略C<auto>では、対象ファイルに対してキャッシュファイルが存在する場合のみ、キャッシュデータを保持する。対応するキャッシュファイルが存在しない場合は、作成しない。

=over 7

=item --xlate-cache=I<strategy>

=over 4

=item C<auto> (Default)

キャッシュファイルが存在する場合は、それを保持する。

=item C<create>

空のキャッシュ・ファイルを作成して終了する。

=item C<always>, C<yes>, C<1>

対象が通常ファイルである限り、とにかくキャッシュを維持する。

=item C<never>, C<no>, C<0>

キャッシュ・ファイルが存在しても、決して使用しない。

=item C<accumulate>

デフォルトの動作では、未使用のデータはキャッシュファイルから削除される。削除せずに保持する場合は、C<蓄積>を使用してください。

=back

=back

=head1 ENVIRONMENT

=over 7

=item DEEPL_AUTH_KEY

DeepLサービス用の認証キーを設定する。

=back

=head1 SEE ALSO

=over 7

=item L<https://github.com/DeepLcom/deepl-python>

DeepL PythonライブラリとCLIコマンドを使用する。

=item L<App::Greple>

対象テキストパターンの詳細については、B<greple>のマニュアルを参照してください。B<--inside>, B<--outside>, B<--include>, B<--exclude>オプションでマッチング範囲を限定してください。

=item L<App::Greple::update>

C<-Mupdate>モジュールを用いると、B<greple>コマンドの結果をもとにファイルを修正することができる。

=item L<App::sdif>

B<sdif>を使用すると、B<-V>オプションと並べてコンフリクトマーカのフォーマットを表示することができる。

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