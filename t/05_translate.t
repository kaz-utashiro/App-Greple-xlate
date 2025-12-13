use v5.14;
use warnings;
use utf8;
use Encode;

use Test::More;
use Data::Dumper;

use lib '.';
use t::Util;

$ENV{NO_COLOR} = 1;

# Test with null engine (no API key required)
subtest 'null engine' => sub {
    my $input = "Hello, World!\n";
    my $result = xlate(qw(--xlate --xlate-engine=null --xlate-to=JA .+))
        ->setstdin($input)->run;
    is($result->status, 0, 'null engine exits successfully');
    like($result->stdout, qr/Hello, World!/, 'null engine returns input unchanged');
};

# Test with DeepL (if API key available)
SKIP: {
    skip 'DEEPL_AUTH_KEY not set', 2 unless $ENV{DEEPL_AUTH_KEY};

    subtest 'deepl engine - English to Japanese' => sub {
        my $input = "Hello\n";
        my $result = xlate(qw(--xlate --xlate-engine=deepl --xlate-to=JA --xlate-format=xtxt .+))
            ->setstdin($input)->run;
        is($result->status, 0, 'deepl engine exits successfully');
        # Check that output contains Japanese characters (Hiragana/Katakana/Kanji)
        my $output = $result->stdout;
        like($output, qr/[\x{3040}-\x{30FF}\x{4E00}-\x{9FFF}]/, 'output contains Japanese characters');
    };

    subtest 'deepl engine - Japanese to English' => sub {
        my $input = "こんにちは\n";
        my $result = xlate(qw(--xlate --xlate-engine=deepl --xlate-to=EN-US --xlate-format=xtxt .+))
            ->setstdin($input)->run;
        is($result->status, 0, 'deepl engine exits successfully');
        my $output = $result->stdout;
        like($output, qr/[Hh]ello/i, 'Japanese translated to English');
    };
}

# Test with GPT-4o (if API key available)
SKIP: {
    skip 'OPENAI_API_KEY not set', 2 unless $ENV{OPENAI_API_KEY};

    subtest 'gpt4o engine - English to Japanese' => sub {
        my $input = "Good morning\n";
        my $result = xlate(qw(--xlate --xlate-engine=gpt4o --xlate-to=JA --xlate-format=xtxt .+))
            ->setstdin($input)->run;
        is($result->status, 0, 'gpt4o engine exits successfully');
        my $output = $result->stdout;
        like($output, qr/[\x{3040}-\x{30FF}\x{4E00}-\x{9FFF}]/, 'output contains Japanese characters');
    };

    subtest 'gpt4o engine - Japanese to English' => sub {
        my $input = "おはよう\n";
        my $result = xlate(qw(--xlate --xlate-engine=gpt4o --xlate-to=EN --xlate-format=xtxt .+))
            ->setstdin($input)->run;
        is($result->status, 0, 'gpt4o engine exits successfully');
        my $output = $result->stdout;
        like($output, qr/[Mm]orning|[Hh]ello|[Gg]ood/i, 'Japanese translated to English');
    };
}

# Test output formats with null engine
subtest 'output formats' => sub {
    my $input = "Test line\n";

    # xtxt format (default)
    my $result = xlate(qw(--xlate --xlate-engine=null --xlate-to=JA --xlate-format=xtxt .+))
        ->setstdin($input)->run;
    is($result->status, 0, 'xtxt format works');
    like($result->stdout, qr/Test line/, 'xtxt output contains text');

    # cm format (conflict markers)
    $result = xlate(qw(--xlate --xlate-engine=null --xlate-to=JA --xlate-format=cm .+))
        ->setstdin($input)->run;
    is($result->status, 0, 'cm format works');
    like($result->stdout, qr/<<<<<<<.*=======.*>>>>>>>/s, 'cm output contains conflict markers');

    # ifdef format
    $result = xlate(qw(--xlate --xlate-engine=null --xlate-to=JA --xlate-format=ifdef .+))
        ->setstdin($input)->run;
    is($result->status, 0, 'ifdef format works');
    like($result->stdout, qr/#ifdef/, 'ifdef output contains #ifdef');
};

# Test with file input
subtest 'file input' => sub {
    my $result = xlate(qw(--xlate --xlate-engine=null --xlate-to=JA .+), 'cpanfile')->run;
    is($result->status, 0, 'file input works');
    like($result->stdout, qr/requires/, 'file content is processed');
};

##############################################################################
# Tests for script/xlate command
##############################################################################

my $xlate_cmd = File::Spec->rel2abs('script/xlate');

sub run_xlate {
    my $out = `@_`;
    my $status = $? >> 8;
    return (Encode::decode('utf-8', $out), $status);
}

# Test script/xlate with null engine
subtest 'script/xlate with null engine' => sub {
    my ($out, $status) = run_xlate(qq{echo "Hello, World!" | $xlate_cmd -e null -t JA -p '.+' 2>&1});
    is($status, 0, 'script/xlate exits successfully');
    like($out, qr/Hello, World!/, 'output contains input text');
};

# Test script/xlate with DeepL
SKIP: {
    skip 'DEEPL_AUTH_KEY not set', 1 unless $ENV{DEEPL_AUTH_KEY};

    subtest 'script/xlate with deepl engine' => sub {
        my ($out, $status) = run_xlate(qq{echo "Hello" | $xlate_cmd -a -e deepl -t JA -p '.+' 2>&1});
        is($status, 0, 'script/xlate with deepl exits successfully');
        like($out, qr/[\x{3040}-\x{30FF}\x{4E00}-\x{9FFF}]/, 'output contains Japanese');
    };
}

# Test script/xlate with GPT-4o
SKIP: {
    skip 'OPENAI_API_KEY not set', 1 unless $ENV{OPENAI_API_KEY};

    subtest 'script/xlate with gpt4o engine' => sub {
        my ($out, $status) = run_xlate(qq{echo "Hello" | $xlate_cmd -a -e gpt4o -t JA -p '.+' 2>&1});
        is($status, 0, 'script/xlate with gpt4o exits successfully');
        like($out, qr/[\x{3040}-\x{30FF}\x{4E00}-\x{9FFF}]/, 'output contains Japanese');
    };
}

# Test script/xlate output formats
subtest 'script/xlate output formats' => sub {
    # cm format
    my ($out, $status) = run_xlate(qq{echo "Test" | $xlate_cmd -e null -t JA -o cm -p '.+' 2>&1});
    like($out, qr/<<<<<<<.*>>>>>>>/s, 'cm format produces conflict markers');

    # ifdef format
    ($out, $status) = run_xlate(qq{echo "Test" | $xlate_cmd -e null -t JA -o ifdef -p '.+' 2>&1});
    like($out, qr/#ifdef/, 'ifdef format produces #ifdef');
};

done_testing;
