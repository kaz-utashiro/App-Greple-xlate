#!/usr/bin/env perl
use v5.24;
use warnings;
use Test::More;
use App::Greple::xlate::Mask;

use File::Temp qw(tempdir);
my $dir = tempdir(CLEANUP => 1);

sub write_file {
    my($path, $text) = @_;
    open my $fh, '>:encoding(utf8)', $path or die "$path: $!";
    print $fh $text;
    close $fh;
}

# Copied from t/Util.pm
sub trap (&) {
    my $code = shift;
    my $ret;
    {
        local $@;
        eval { $ret = $code->() };
        $ret = $@ if $@;
    }
    $ret;
}

subtest 'dictionary: JSON format' => sub {
    my $f = "$dir/dict.json";
    write_file($f, <<'END');
[
  { "category": "person",  "text": "山田太郎", "note": "ignored" },
  { "category": "company", "regex": "アクメ(?:株式会社)?" }
]
END
    my $m = App::Greple::xlate::Mask->new(STABLE => 1);
    $m->load_anonymize_file($f);
    my @t = ("山田太郎はアクメ株式会社にいた。アクメの件。\n");
    $m->mask(@t);
    is($t[0], "<person id=1 />は<company id=1 />にいた。<company id=2 />の件。\n",
       'literal and regex rules from JSON');
    $m->unmask(@t); $m->reset;
};

subtest 'dictionary: JSON errors' => sub {
    my $m = App::Greple::xlate::Mask->new(STABLE => 1);
    my $bad1 = "$dir/bad1.json";
    write_file($bad1, '[ { "category": "person" } ]');
    like(trap { $m->load_anonymize_file($bad1) }, qr/text.*regex|regex.*text/i,
         'missing text/regex dies');
    my $bad2 = "$dir/bad2.json";
    write_file($bad2, '[ { "category": "person", "text": "a", "regex": "b" } ]');
    like(trap { $m->load_anonymize_file($bad2) }, qr/both/i,
         'both text and regex dies');
    my $bad3 = "$dir/bad3.json";
    write_file($bad3, '[ { "category": "lit", "text": "a" } ]');
    like(trap { $m->load_anonymize_file($bad3) }, qr/lit.*reserved/i,
         'lit category dies');
    my $bad4 = "$dir/bad4.json";
    write_file($bad4, '[ { "category": "Bad-Name", "text": "a" } ]');
    like(trap { $m->load_anonymize_file($bad4) }, qr/invalid category/i,
         'invalid category dies');
};

subtest 'dictionary: line format' => sub {
    my $f = "$dir/dict.txt";
    write_file($f, <<'END');
# comment
person   山田太郎
company  /アクメ(?:株式会社)?/
END
    my $m = App::Greple::xlate::Mask->new(STABLE => 1);
    $m->load_anonymize_file($f);
    my @t = ("山田太郎とアクメ株式会社\n");
    $m->mask(@t);
    is($t[0], "<person id=1 />と<company id=1 />\n", 'line format rules');
    $m->unmask(@t); $m->reset;
};

subtest 'inline mark extraction' => sub {
    my $text = <<'END';
担当は {{ person("山田太郎") }} である。
発注元は {{ company('アクメ株式会社') }} である。
再訪: {{ person("山田太郎") }}
END
    my $rules = App::Greple::xlate::Mask::extract_marks(
        $text, $App::Greple::xlate::Mask::DEFAULT_MARK);
    is(scalar @$rules, 2, 'deduplicated to two rules');
    is($rules->[0][0], 'person', 'category extracted');
    like("山田太郎", qr/$rules->[0][1]/, 'pattern matches the literal');

    like(trap {
        App::Greple::xlate::Mask::extract_marks(
            '{{ person("X") }} {{ company("X") }}',
            $App::Greple::xlate::Mask::DEFAULT_MARK)
    }, qr/conflicting categor/i, 'same text different category dies');

    like(trap {
        App::Greple::xlate::Mask::extract_marks('x', 'no captures here')
    }, qr/category.*text|named capture/i, 'regex without captures dies');

    like(trap {
        App::Greple::xlate::Mask::extract_marks(
            '{{ lit("X") }}', $App::Greple::xlate::Mask::DEFAULT_MARK)
    }, qr/lit.*reserved/i, 'lit mark dies');
};

done_testing;
