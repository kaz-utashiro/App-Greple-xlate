use v5.14;
use warnings;
use utf8;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

my $xlate = File::Spec->rel2abs('script/xlate');
my $dozo = File::Spec->rel2abs('script/dozo');

# Use empty temp dir to avoid reading any .dozorc (HOME, git top, cwd)
my $empty_home = tempdir(CLEANUP => 1);
$ENV{HOME} = $empty_home;
chdir $empty_home or die "Cannot chdir to $empty_home: $!";

# Docker-dependent tests
SKIP: {
    my $docker_available = system('docker info >/dev/null 2>&1') == 0;
    skip 'Docker not available', 2 unless $docker_available;

    subtest 'Docker -C option' => sub {
        my $out = `$xlate -I alpine:latest -B -C echo "hello from container" 2>&1`;
        like($out, qr/hello from container/, '-C runs command in container');
    };

    subtest 'Docker environment inheritance' => sub {
        local $ENV{TEST_XLATE_VAR} = 'test_value';
        my $out = `$xlate -I alpine:latest -B -E TEST_XLATE_VAR -C sh -c 'echo \$TEST_XLATE_VAR' 2>&1`;
        like($out, qr/test_value/, '-E passes environment variable');
    };
}

done_testing;
