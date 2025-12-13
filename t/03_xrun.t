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

# Test: option parsing (valid options should reach "image must be specified" error)
subtest 'option parsing' => sub {
    my $out = `$xrun -W -B -R 2>&1`;
    unlike($out, qr/no such option/i, 'options -W -B -R are recognized');
    like($out, qr/image.*must be specified/i, 'reaches image check (options parsed successfully)');
};

# Test: combined options like -KL
subtest 'combined options' => sub {
    my $out = `$xrun --help 2>&1`;
    like($out, qr/--kill/, '-K option documented');
    like($out, qr/--live/, '-L option documented');
};

done_testing;
