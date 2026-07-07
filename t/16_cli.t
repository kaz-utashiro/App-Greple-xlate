use v5.14;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use Cwd qw(abs_path);

my $script = abs_path('script/xlate');
my $dir    = tempdir(CLEANUP => 1);

# スタブ llm(-nn ケースで使用)と getoptlong.sh を PATH で解決
$ENV{PATH} = abs_path('t/bin') . ":$ENV{PATH}";
$ENV{PERL5LIB} = abs_path('lib') . ($ENV{PERL5LIB} ? ":$ENV{PERL5LIB}" : '');
$ENV{NO_COLOR} = 1;

sub write_file {
    my($path, $text) = @_;
    open my $fh, '>:encoding(utf8)', $path or die "$path: $!";
    print $fh $text;
    close $fh;
}

sub run_cli {
    my @cmd = ('bash', $script, @_);
    my $stderr = "$dir/stderr.$$";
    my $pid = open my $fh, '-|';
    defined $pid or die "fork: $!";
    if (!$pid) {
        open STDERR, '>', $stderr or die;
        exec @cmd or exit 127;
    }
    my $out = do { local $/; <$fh> };
    close $fh;
    my $status = $? >> 8;
    my $err = '';
    if (open my $e, '<', $stderr) { local $/; $err = <$e>; close $e }
    unlink $stderr;
    return { out => $out // '', err => $err, status => $status };
}

my $doc = "$dir/f.txt";
write_file($doc, "hello world\n");

subtest 'defaults: gpt5 engine, API mode' => sub {
    my $r = run_cli(qw(-n -t JA), $doc);
    is($r->{status}, 0, 'exit 0');
    like($r->{out}, qr/--xlate-engine=gpt5/, 'default engine is gpt5');
    like($r->{out}, qr/--xlate(?:\s|$)/m, 'API mode (--xlate)');
    unlike($r->{out}, qr/--xlate-labor/, 'not labor mode');
};

subtest '--no-api selects labor mode' => sub {
    my $r = run_cli(qw(-n --no-api -t JA), $doc);
    like($r->{out}, qr/--xlate-labor/, 'labor mode');
};

subtest '-a is a valid explicit default' => sub {
    my $base = run_cli(qw(-n -t JA), $doc);
    my $api  = run_cli(qw(-n -a -t JA), $doc);
    is($api->{out}, $base->{out}, 'same command as default');
    is($api->{status}, 0, 'exit 0');
};

subtest '-e deepl still works' => sub {
    my $r = run_cli(qw(-n -e deepl -t JA), $doc);
    like($r->{out}, qr/--xlate-engine=deepl/, 'deepl engine');
};

subtest '-nn runs greple with --xlate-dryrun' => sub {
    my $body = "hello dryrun world\n";
    my $d2 = "$dir/dry.txt";
    write_file($d2, $body);
    write_file("$d2.xlate-gpt5-EN-US.json", '');
    my $r = run_cli(qw(-nn -t EN-US), $d2);
    is($r->{status}, 0, 'exit 0');
    like($r->{out}, qr/\Qhello dryrun world\E/, 'original text passes through');
    like($r->{err}, qr/From/, 'transmission preview shown on stderr');
    unlike($r->{out}, qr/^greple /m, 'not an echoed command line');
};

done_testing;
