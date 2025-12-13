use v5.14;
use warnings;
use utf8;

use Test::More;
use File::Spec;

my $xrun = File::Spec->rel2abs('script/xrun');

# Check if xrun exists
ok(-x $xrun, 'xrun is executable');

# Check if getoptlong.sh exists
ok(-f 'share/getoptlong/getoptlong.sh', 'getoptlong.sh exists');

# Test: help option
subtest 'help option' => sub {
    my $out = `$xrun --help 2>&1`;
    like($out, qr/xrun.*Docker Runner/i, '--help shows description');
    like($out, qr/--image/, '--help shows --image option');
    like($out, qr/--live/, '--help shows --live option');
    like($out, qr/--kill/, '--help shows --kill option');
};

# Test: missing image error
subtest 'missing image error' => sub {
    my $out = `$xrun echo hello 2>&1`;
    my $status = $? >> 8;
    isnt($status, 0, 'exits with error when no image specified');
    like($out, qr/image.*must be specified/i, 'error message mentions image');
};

# Test: option parsing (dry-run style test using debug mode)
subtest 'option parsing' => sub {
    # Test that options are recognized (will fail due to no image, but options should parse)
    my $out = `$xrun -I test:image -W -B -R 2>&1`;
    # Since no Docker, it will try to run and may fail, but options should be parsed
    unlike($out, qr/不正なオプション|invalid option/i, 'options -W -B -R are recognized');
};

# Test: combined options like -KL
subtest 'combined options' => sub {
    my $out = `$xrun -I test:image --help 2>&1`;
    like($out, qr/--kill/, '-K option documented');
    like($out, qr/--live/, '-L option documented');
};

# Docker-dependent tests (skip if Docker is not available)
SKIP: {
    my $docker_available = system('docker info >/dev/null 2>&1') == 0;
    skip 'Docker not available', 4 unless $docker_available;

    subtest 'run simple command' => sub {
        my $out = `$xrun -I alpine:latest -B echo hello 2>&1`;
        like($out, qr/hello/, 'can run echo command in container');
    };

    subtest 'command with options' => sub {
        my $out = `$xrun -I alpine:latest -B ls -la / 2>&1`;
        like($out, qr/root/, 'ls -la works (command options passed correctly)');
    };

    subtest 'environment variable' => sub {
        my $out = `$xrun -I alpine:latest -B -E TEST_VAR=hello sh -c 'echo \$TEST_VAR' 2>&1`;
        like($out, qr/hello/, 'environment variable is passed');
    };

    subtest 'unmount option' => sub {
        my $out = `$xrun -I alpine:latest -B -U pwd 2>&1`;
        like($out, qr{^/$}m, '-U unmount option works (working dir is /)');
    };
}

done_testing;
