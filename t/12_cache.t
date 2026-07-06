use v5.14;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use JSON::PP;

use App::Greple::xlate::Cache;

my $dir = tempdir(CLEANUP => 1);
my $J = JSON::PP->new->utf8->canonical;

sub write_json {
    my($path, $data) = @_;
    open my $fh, '>', $path or die "$path: $!";
    print $fh $J->encode($data);
    close $fh;
}

sub read_json {
    my($path) = @_;
    open my $fh, '<', $path or die "$path: $!";
    local $/;
    $J->decode(scalar <$fh>);
}

# 対訳 5 ペアの list 形式キャッシュ
my @PAIRS = map [ "src$_\n" => "trans$_\n" ], 1 .. 5;

subtest 'old list order retention and query API' => sub {
    my $file = "$dir/order.json";
    write_json($file, \@PAIRS);
    my $c = App::Greple::xlate::Cache->new(name => $file);

    is($c->old_size, 5, 'old_size');
    is($c->old_position("src3\n"), 2, 'old_position finds key');
    is($c->old_position("nosuch\n"), undef, 'old_position returns undef');

    my @mid = $c->old_entries_slice(1, 3);
    is_deeply(\@mid, [ @PAIRS[1..3] ], 'slice returns pairs in order');

    my @clamped = $c->old_entries_slice(-5, 100);
    is_deeply(\@clamped, \@PAIRS, 'slice clamps out-of-range bounds');

    my @empty = $c->old_entries_slice(3, 1);
    is_deeply(\@empty, [], 'inverted range is empty');

    # FETCH 済み(saved→current 移動後)でも値が取れる
    $c->access("src2\n");
    my $v = $c->get("src2\n");
    is($v, "trans2\n", 'get moves saved to current');
    my @after = $c->old_entries_slice(1, 1);
    is_deeply(\@after, [ [ "src2\n" => "trans2\n" ] ],
              'old_entries_slice sees fetched values too');

    $c->name = '';   # DESTROY 時の書き出しを抑止
};

subtest 'legacy HASH format has no old order' => sub {
    my $file = "$dir/hash.json";
    write_json($file, +{ map @$_, @PAIRS });
    my $c = App::Greple::xlate::Cache->new(name => $file);
    is($c->old_size, 0, 'HASH format: old order is empty');
    is($c->old_position("src1\n"), undef, 'old_position undef');
    is($c->get("src1\n"), "trans1\n", 'values still readable');
    $c->name = '';
};

subtest 'no warning for accessed-but-unset keys (dryrun case)' => sub {
    my $file = "$dir/dryrun.json";
    write_json($file, [ $PAIRS[0] ]);
    my @warn;
    {
        local $SIG{__WARN__} = sub { push @warn, $_[0] };
        my $c = App::Greple::xlate::Cache->new(name => $file);
        $c->access("src1\n");
        $c->get("src1\n");                    # hit
        $c->access("newkey\n");
        $c->set("newkey\n" => undef);         # dryrun のミス相当
        $c->update;
        $c->name = '';
    }
    ok(!(grep { /not in cache/ } @warn),
       'no "not in cache" warning') or diag "@warn";
    my $data = read_json($file);
    is_deeply($data, [ $PAIRS[0] ], 'undef entry is silently dropped');
};

done_testing;
