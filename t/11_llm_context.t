use v5.14;
use warnings;
use utf8;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP;

use lib '.';
use t::Util;

$ENV{NO_COLOR} = 1;
$ENV{PATH} = File::Spec->rel2abs('t/bin') . ":$ENV{PATH}";

my $dir = tempdir(CLEANUP => 1);

my $DOC = <<'END';
## SECTION ONE

alpha paragraph original text

beta paragraph original text

## SECTION TWO

gamma paragraph original text

delta paragraph original text
END

sub write_file {
    my($path, $text) = @_;
    open my $fh, '>', $path or die "$path: $!";
    print $fh $text;
    close $fh;
}

sub stub_calls {
    my($log) = @_;
    return () unless -f $log;
    open my $fh, '<', $log or die "$log: $!";
    map JSON::PP->new->decode($_), <$fh>;
}

sub sys_of {
    my($rec) = @_;
    my @a = @{$rec->{argv}};
    my($i) = grep { $a[$_] eq '-s' } 0 .. $#a;
    $a[$i + 1];
}

# 小文字始まりの段落だけを翻訳対象にする(見出し行は対象外)
my @XLATE = (qw(--xlate --xlate-engine=gpt5 --xlate-to=EN-US),
             qw(--xlate-format=xtxt --all --need=0),
             '--re', '^([a-z].*\n)+');

sub run_xlate {
    my($file, @extra) = @_;
    xlate(@XLATE, @extra, $file)->run;
}

# 準備: 全対訳入りのキャッシュを作る(スタブ llm は uc 変換)
my $doc = "$dir/doc.txt";
my $cache = "$doc.xlate-gpt5-EN-US.json";
write_file($doc, $DOC);
write_file($cache, '');
my $r0 = run_xlate($doc);
is($r0->status, 0, 'initial full translation succeeds');

subtest 'single changed paragraph goes through region path' => sub {
    (my $mod = $DOC) =~ s/beta paragraph original/beta paragraph revised/;
    write_file($doc, $mod);
    my $log = "$dir/single.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($doc);
    is($r->status, 0, 'run succeeds');
    my @calls = stub_calls($log);
    is(scalar @calls, 1, 'exactly one llm call for one gap');
    is_deeply(JSON::PP->new->decode($calls[0]{stdin}),
              [ "beta paragraph revised text\n" ],
              'only the changed paragraph is sent');
    like($r->stdout, qr/BETA PARAGRAPH REVISED TEXT/, 'translated output');
    like($r->stdout, qr/ALPHA PARAGRAPH ORIGINAL TEXT/, 'others from cache');
};

subtest 'duplicate paragraphs do not fake cache hits' => sub {
    my $dup = "$dir/dup.txt";
    write_file($dup, <<'END');
alpha duplicated text

alpha duplicated text

beta unique text
END
    write_file("$dup.xlate-gpt5-EN-US.json", '');
    my $log = "$dir/dup.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($dup);
    is($r->status, 0, 'run succeeds');
    my @calls = stub_calls($log);
    is(scalar @calls, 1, 'all-miss doc with duplicates: single flat call');
    is_deeply(JSON::PP->new->decode($calls[0]{stdin}),
              [ "alpha duplicated text\n", "beta unique text\n" ],
              'duplicates deduped, no false hit classification');
    like($r->stdout, qr/ALPHA DUPLICATED TEXT.*ALPHA DUPLICATED TEXT.*BETA UNIQUE TEXT/s,
         'both occurrences rendered from the single translation');
};

done_testing;
