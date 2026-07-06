use v5.14;
use warnings;
use utf8;

use Test::More;

use App::Greple::xlate::Mask;

sub trap (&) {
    my $code = shift;
    eval { $code->() };
    $@;
}

subtest 'legacy path unchanged' => sub {
    my $m = App::Greple::xlate::Mask->new(pattern => ['C<[^>]*>']);
    my @t = ("see C<foo> and C<foo> here\n");
    $m->mask(@t);
    is($t[0], "see <m id=1 /> and <m id=2 /> here\n",
       'per-occurrence numbering');
    $m->unmask(@t);
    is($t[0], "see C<foo> and C<foo> here\n", 'restored');
};

subtest 'stable numbering with categories' => sub {
    my $m = App::Greple::xlate::Mask->new(STABLE => 1);
    $m->add_rule(person  => quotemeta('山田太郎'));
    $m->add_rule(company => quotemeta('アクメ株式会社'));
    my @t = ("山田太郎はアクメ株式会社の山田太郎である\n",
             "翌日、山田太郎が来た\n");
    $m->mask(@t);
    is($t[0], "<person id=1 />は<company id=1 />の<person id=1 />である\n",
       'same string same tag; per-category counters');
    is($t[1], "翌日、<person id=1 />が来た\n", 'stable across texts');
    $m->unmask(@t);
    is($t[0], "山田太郎はアクメ株式会社の山田太郎である\n", 'restored 0');
    is($t[1], "翌日、山田太郎が来た\n", 'restored 1');
};

subtest 'stable numbering persists across mask/reset cycles' => sub {
    my $m = App::Greple::xlate::Mask->new(STABLE => 1);
    $m->add_rule(person => quotemeta('山田太郎'));
    my @a = ("山田太郎です\n");
    $m->mask(@a); $m->unmask(@a); $m->reset;
    my @b = ("また山田太郎です\n");
    $m->mask(@b);
    like($b[0], qr/<person id=1 \/>/, 'same id after reset');
    $m->unmask(@b); $m->reset;
};

subtest 'reference mode is not verified' => sub {
    my $m = App::Greple::xlate::Mask->new(STABLE => 1);
    $m->add_rule(person => quotemeta('山田太郎'));
    my @payload = ("本文に山田太郎がいる\n");
    my @context = ("文脈にも山田太郎がいる\n");
    $m->mask(@payload);
    $m->mask_reference(@context);
    like($context[0], qr/<person id=1 \/>/, 'context masked with same tag');
    # 応答は本文のみ。文脈のタグが応答に無くても die しない
    my @resp = ($payload[0]);
    ok(!trap { $m->unmask(@resp) }, 'unmask verifies payload tags only');
    is($resp[0], "本文に山田太郎がいる\n", 'payload restored');
    $m->reset;
};

subtest 'missing tracked tag dies' => sub {
    my $m = App::Greple::xlate::Mask->new(STABLE => 1);
    $m->add_rule(person => quotemeta('山田太郎'));
    my @t = ("山田太郎です\n");
    $m->mask(@t);
    my @resp = ("タグが消えた応答\n");
    like(trap { $m->unmask(@resp) }, qr/Masking error/,
         'lost payload tag detected');
    $m->reset;
};

subtest 'escape layer round trip with nesting' => sub {
    my $m = App::Greple::xlate::Mask->new(STABLE => 1);
    $m->add_escape_rule;
    $m->add_rule(person => quotemeta('山田太郎'));
    my @t = ("原文に <person id=1 /> というリテラルと山田太郎がいる\n");
    $m->mask(@t);
    like($t[0], qr/<lit id=1 \/>/, 'tag-shaped literal escaped first');
    unlike($t[0], qr/山田太郎/, 'real name is gone from payload');
    is($t[0], "原文に <lit id=1 /> というリテラルと<person id=1 />がいる\n",
       'literal and name each got their own tag without collision');
    $m->unmask(@t);
    is($t[0], "原文に <person id=1 /> というリテラルと山田太郎がいる\n",
       'nested round trip restores exactly');
    $m->reset;
};

done_testing;
