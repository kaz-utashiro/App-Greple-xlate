package App::Greple::xlate;

our $VERSION = "0.17";

=encoding utf-8

=head1 NAME

App::Greple::xlate - Greple용 번역 지원 모듈

=head1 SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

=head1 VERSION

Version 0.17

=head1 DESCRIPTION

B<Greple> B<xlate> 모듈은 텍스트 블록을 찾아 번역된 텍스트로 대체합니다. 현재 B<xlate::deep> 모듈은 DeepL 서비스만 지원합니다.

L<pod> 스타일 문서에서 일반 텍스트 블록을 번역하려면 다음과 같이 B<greple> 명령어를 C<xlate::deepl> 및 C<perl> 모듈과 함께 사용합니다:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

패턴 C<^(\w.*\n)+>는 영숫자로 시작하는 연속된 줄을 의미합니다. 이 명령은 번역할 영역을 표시합니다. 옵션 B<--all>은 전체 텍스트를 생성하는 데 사용됩니다.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
</p>

그런 다음 C<--엑스레이트> 옵션을 추가하여 선택한 영역을 번역합니다. B<딥> 명령 출력으로 해당 영역을 찾아서 대체합니다.

기본적으로 원본 텍스트와 번역된 텍스트는 L<git(1)>과 호환되는 "충돌 마커" 형식으로 인쇄됩니다. C<ifdef> 형식을 사용하면 L<unifdef(1)> 명령으로 원하는 부분을 쉽게 얻을 수 있습니다. 형식은 B<--xlate-format> 옵션으로 지정할 수 있습니다.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
</p>

전체 텍스트를 번역하려면 B<--match-entire> 옵션을 사용합니다. 이것은 전체 텍스트 C<(?s).*>와 일치하는 패턴을 지정하는 단축키입니다.

=head1 OPTIONS

=over 7

=item B<--xlate>

=item B<--xlate-color>

=item B<--xlate-fold>

=item B<--xlate-fold-width>=I<n> (Default: 70)

일치하는 각 영역에 대해 번역 프로세스를 호출합니다.

이 옵션이 없으면 B<greple>은 일반 검색 명령처럼 작동합니다. 따라서 실제 작업을 호출하기 전에 파일에서 어느 부분이 번역 대상이 될지 확인할 수 있습니다.

명령 결과는 표준 아웃으로 이동하므로 필요한 경우 파일로 리디렉션하거나 L<App::Greple::update> 모듈을 사용하는 것을 고려할 수 있습니다.

옵션 B<--xlate>는 B<--color=never> 옵션과 함께 B<--xlate-color> 옵션을 호출합니다.

B<--xlate-fold> 옵션을 사용하면 변환된 텍스트가 지정된 너비만큼 접힙니다. 기본 너비는 70이며 B<--xlate-fold-width> 옵션으로 설정할 수 있습니다. 실행 작업을 위해 4개의 열이 예약되어 있으므로 각 줄에는 최대 74자가 들어갈 수 있습니다.

=item B<--xlate-engine>=I<engine>

사용할 번역 엔진을 지정합니다. 모듈 C<xlate::deep>은 C<--xlate-engine=deepl>로 선언하므로 이 옵션을 사용할 필요가 없습니다.

=item B<--xlate-labor>

=item B<--xlabor>

번역 엔진을 호출하는 대신 작업할 것으로 예상됩니다. 번역할 텍스트를 준비한 후 클립보드에 복사합니다. 양식에 붙여넣고 결과를 클립보드에 복사한 후 Return 키를 눌러야 합니다.

=item B<--xlate-to> (Default: C<EN-US>)

대상 언어를 지정합니다. B<DeepL> 엔진을 사용할 때 C<deepl languages> 명령으로 사용 가능한 언어를 가져올 수 있습니다.

=item B<--xlate-format>=I<format> (Default: C<conflict>)

원본 및 번역 텍스트의 출력 형식을 지정합니다.

=over 4

=item B<conflict>, B<cm>

원본 텍스트와 번역 텍스트를 L<git(1)> 충돌 마커 형식으로 인쇄합니다.

    <<<<<<< ORIGINAL
    original text
    =======
    translated Japanese text
    >>>>>>> JA

다음 L<sed(1)> 명령으로 원본 파일을 복구할 수 있습니다.

    sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

=item B<ifdef>

원본 텍스트와 번역 텍스트를 L<cpp(1)> C<#ifdef> 형식으로 인쇄합니다.

    #ifdef ORIGINAL
    original text
    #endif
    #ifdef JA
    translated Japanese text
    #endif

일본어 텍스트만 검색하려면 B<unifdef> 명령으로 검색할 수 있습니다:

    unifdef -UORIGINAL -DJA foo.ja.pm

=item B<space>

원본 텍스트와 번역 텍스트를 빈 줄로 구분하여 인쇄합니다.

=item B<xtxt>

형식이 C<xtxt>(번역된 텍스트) 또는 알 수 없는 경우 번역된 텍스트만 인쇄됩니다.

=back

=item B<--xlate-maxlen>=I<chars> (Default: 0)

한 번에 API로 전송할 텍스트의 최대 길이를 지정합니다. 기본값은 무료 계정 서비스의 경우 API(B<--xlate>)의 경우 128K, 클립보드 인터페이스(B<--xlate-labor>)의 경우 5000으로 설정되어 있습니다. Pro 서비스를 사용하는 경우 이 값을 변경할 수 있습니다.

=item B<-->[B<no->]B<xlate-progress> (Default: True)

번역 결과는 STDERR 출력에서 실시간으로 확인할 수 있습니다.

=item B<--match-entire>

파일의 전체 텍스트를 대상 영역으로 설정합니다.

=back

=head1 CACHE OPTIONS

B<엑스레이트> 모듈은 각 파일에 대한 번역 텍스트를 캐시하여 저장하고 실행 전에 읽어들여 서버에 요청하는 오버헤드를 없앨 수 있습니다. 기본 캐시 전략 C<auto>를 사용하면 대상 파일에 대한 캐시 파일이 존재할 때만 캐시 데이터를 유지합니다.

=over 7

=item --cache-clear

B<--cache-clear> 옵션은 캐시 관리를 시작하거나 기존의 모든 캐시 데이터를 새로 고치는 데 사용할 수 있습니다. 이 옵션을 실행하면 캐시 파일이 없는 경우 새 캐시 파일이 생성되고 이후에는 자동으로 유지 관리됩니다.

=item --xlate-cache=I<strategy>

=over 4

=item C<auto> (Default)

캐시 파일이 있는 경우 캐시 파일을 유지 관리합니다.

=item C<create>

빈 캐시 파일을 생성하고 종료합니다.

=item C<always>, C<yes>, C<1>

타겟이 정상 파일인 한 캐시를 유지합니다.

=item C<clear>

캐시 데이터를 먼저 지웁니다.

=item C<never>, C<no>, C<0>

캐시 파일이 존재하더라도 절대 사용하지 않습니다.

=item C<accumulate>

기본 동작에 따라 사용하지 않는 데이터는 캐시 파일에서 제거됩니다. 제거하지 않고 파일에 유지하려면 C<accumulate>를 사용하세요.

=back

=back

=head1 ENVIRONMENT

=over 7

=item DEEPL_AUTH_KEY

DeepL 서비스에 대한 인증 키를 설정합니다.

=back

=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::xlate

=head1 SEE ALSO

L<App::Greple::xlate>

=over 7

=item L<https://github.com/DeepLcom/deepl-python>

DeepL 파이썬 라이브러리 및 CLI 명령.

=item L<App::Greple>

대상 텍스트 패턴에 대한 자세한 내용은 B<greple> 매뉴얼을 참조하세요. B<--내부>, B<--외부>, B<--포함>, B<--제외> 옵션을 사용하여 일치하는 영역을 제한할 수 있습니다.

=item L<App::Greple::update>

C<-Mupdate> 모듈을 사용하여 B<greple> 명령의 결과에 따라 파일을 수정할 수 있습니다.

=item L<App::sdif>

충돌 마커 형식을 B<-V> 옵션과 함께 나란히 표시하려면 B<에스디프>를 사용합니다.

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

option --match-entire    --re '\A(?s).+\z'
option --match-paragraph --re '^(.+\n)+'
option --match-podtext   -Mperl --pod --re '^(\w.*\n)(\S.*\n)*'

option --ifdef-color --re '^#ifdef(?s:.*?)^#endif.*\n'

#  LocalWords:  deepl ifdef unifdef Greple greple perl
