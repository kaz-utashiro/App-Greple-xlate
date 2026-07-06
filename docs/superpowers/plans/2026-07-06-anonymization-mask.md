# 匿名化マスク 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 機密情報をカテゴリ付き XML タグへ安定置換して API 送信時のみ秘匿し(辞書 JSON/行形式・インラインマークの 3 方式+退避層)、テンプレート式の保全検証(F1)と front matter サポート(F2)を追加する。

**Architecture:** Mask.pm に新経路(ルール列・安定採番・参照モード・追跡検証)を追加し、旧経路(maskfile)はバイト互換のまま残す。xlate.pm は匿名化オブジェクト($anonobj: 退避ルール+辞書+マーク)を maskfile より先に適用し、②の文脈は複製に参照モードで適用する。F1 は cache_update でエンジン非依存に式列を照合。F2 は greple のオプション合成で front matter を match から除外し、begin で値ルール導出とスライス起点補正を行う。

**Tech Stack:** Perl (v5.14+)、既存依存のみ(JSON は cpanfile 済み)。テストはスタブ llm(t/bin/llm、API 費用ゼロ)。

**Spec:** docs/superpowers/specs/2026-07-06-anonymization-mask-design.md

## Global Constraints

- **インデントにタブを使わない** — スペースのみ(CLAUDE.md Coding Style)
- 全ファイルは必ず改行で終わること(末尾は単一の改行)
- 新規 Perl 依存を追加しない(Mask.pm に `use JSON;` を足すのは可 — 既存依存)
- `lib/App/Greple/xlate/gpty/` 配下、`deepl.pm`、`null.pm`、`Cache.pm`、`Text.pm` には触らない
- **maskfile の現行動作(出現ごと採番・単一置換・重複 warn)はバイト互換で不変**(旧経路)
- 匿名化・F1・F2 を指定しない実行は完全に現行動作(既存 102 テストが不変で通ること)
- カテゴリ名(=タグ名)は `[a-z][a-z0-9_]*`。`lit` は退避層の予約語
- 適用順: 退避 → 匿名化 → maskfile(本文=追跡、文脈=参照)。復元は逆順
- git コミットメッセージ末尾に以下の 2 行:
  ```
  Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_015Wte6DCZZAEjT7zEboeDid
  ```

## 前提知識(全タスク共通)

- 現行 Mask.pm(98 行)は正規表現 → `<m id=N />` の出現ごと採番。
  `${^MATCH}` を使うため置換は `/gpe` 修飾
- cache_update(xlate.pm:887-934)は②で eval ラップ済み:
  失敗時 checkpoint+readonly 凍結。マスクは eval 内の
  `$maskobj->mask(@from)` → XLATE → `$maskobj->unmask(@to)->reset`
- `$call_context`(xlate.pm:650)はハッシュ参照
  `{source_before, source_after, hits_before, hits_after, old_pairs}`。
  **postgrep が組んだ実体を書き換えてはならない**(複製に適用)
- llm.pm build_system(llm.pm:68-84)は prompt 展開 → contexts 追記 →
  `context_sections()` 連結の順
- スタブ llm は `uc` 変換。**ASCII は大文字化されるが日本語・数字・
  記号は不変** — F1 テストは `{{ 報告者 }}` のような日本語式なら
  保全がそのまま確認でき、ASCII 式 `{{ reporter }}` は大文字化されて
  検証 die の負系が作れる

---

### Task 0: スタブ llm のタグ保全(前提修正)

**Files:**
- Modify: `t/bin/llm`
- Test: `t/06_llm_stub.t`(追記)

**Interfaces:**
- Produces: スタブの ok/short モードの変換が「タグ形スパン
  `<[a-z][a-z0-9_]* [a-z0-9_]+=\d+ */>` は**そのまま**、他は uc」になる
  (プロンプトのタグ保全指示に従う良い LLM の模倣)。これが無いと
  マスクした payload の復元が `<PERSON ID=1 />` になり全テストが壊れる

- [ ] **Step 1: 失敗するテストを追記**

`t/06_llm_stub.t` の `done_testing;` の前に追加:

```perl
subtest 'tag-shaped spans survive the transform' => sub {
    my $r = run_stub(stdin => q(["see <person id=1 /> and text\n"]));
    is($r->{result}, 0, 'exit 0');
    is_deeply(JSON::PP->new->decode($r->{data}),
              [ "SEE <person id=1 /> AND TEXT\n" ],
              'tag kept verbatim, rest uppercased');
};
```

- [ ] **Step 2: 失敗を確認**

Run: `prove -l t/06_llm_stub.t`
Expected: FAIL — 現状は `<PERSON ID=1 />` になる

- [ ] **Step 3: スタブを修正**

`t/bin/llm` の変換部分。現在:

```perl
my $list = JSON::PP->new->decode($input);
my @out = map { uc } @$list;
```

新:

```perl
my $list = JSON::PP->new->decode($input);
# A well-behaved model keeps XML-style marker tags verbatim; mimic
# that: uppercase everything except tag-shaped spans.
sub transform {
    my $s = shift;
    join '', map {
        /\A<[a-z][a-z0-9_]* [a-z0-9_]+=\d+ *\/>\z/ ? $_ : uc
    } split /(<[a-z][a-z0-9_]* [a-z0-9_]+=\d+ *\/>)/, $s;
}
my @out = map { transform($_) } @$list;
```

- [ ] **Step 4: テスト確認とコミット**

Run: `prove -l t/06_llm_stub.t && prove -l t/`
Expected: 全 PASS(既存テストはタグ無し入力なので挙動不変)

```bash
git add t/bin/llm t/06_llm_stub.t
git commit -m "test: stub llm keeps marker tags verbatim like a compliant model"
```

---

### Task 1: Mask.pm — 新経路(ルール列・安定採番・追跡検証・参照モード・退避層)

**Files:**
- Modify: `lib/App/Greple/xlate/Mask.pm`(全面改稿。旧経路は関数内で温存)
- Test: `t/13_mask.t`(新規)

**Interfaces:**
- Consumes: なし
- Produces(新経路。すべて `STABLE => 1` のオブジェクトで有効):
  - `App::Greple::xlate::Mask->new(STABLE => 1)` — 安定採番モード
  - `$obj->add_rule($tag, $pattern)` — 恒久ルール追加($pattern は
    正規表現文字列。リテラルは呼び出し側で quotemeta 済みを渡す)
  - `$obj->file_rules([ [$tag, $pattern], ... ])` — ファイル単位ルールの
    差し替え(begin ごと。恒久ルールは保持)
  - `$obj->add_escape_rule` — 退避ルール(tag `lit`、パターン
    `<[a-z][a-z0-9_]* [a-z0-9_]+=\d+ */>`)を**ルール列の先頭**に追加
  - `$obj->mask(@texts)` — 追跡モード置換(in-place)。同一
    (tag, 文字列) は常に同じタグ。応答で復元必須として登録
  - `$obj->mask_reference(@texts)` — 同じ置換・同じ採番だが復元必須
    登録をしない(文脈用)
  - `$obj->unmask(@texts)` — 全域置換(`s///g`)で復元し、追跡タグの
    欠落を検出して die。その後も安定採番表は保持
  - `$obj->reset` — TABLE/追跡集合をクリア(採番表・ルールは保持)
- 旧経路(`STABLE => 0`、既定): mask/unmask/reset の挙動は現行と
  バイト互換

- [ ] **Step 1: 失敗するテストを書く**

`t/13_mask.t` を以下の内容で作成:

```perl
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
```

- [ ] **Step 2: テストを実行して失敗を確認**

Run: `prove -l t/13_mask.t`
Expected: FAIL — `Can't locate object method "add_rule"`

- [ ] **Step 3: Mask.pm を改稿**

`lib/App/Greple/xlate/Mask.pm` 全体を以下の内容に置き換える:

```perl
package App::Greple::xlate::Mask;

use v5.24;
use warnings;
use Data::Dumper;

use Hash::Util qw(lock_keys);

my %default = (
    TAG       => 'm',
    INDEX     => 'id',
    NUMBER    => 0,
    PATTERN   => [],
    TABLE     => [],
    AUTORESET => 0,
    # --- stable (anonymization) path ---
    STABLE    => 0,     # same (tag, string) -> same tag
    RULES     => undef, # permanent [ [tag, pattern], ... ]
    FILERULES => undef, # per-document rules, replaced via file_rules()
    COUNTER   => undef, # per-tag counters
    ASSIGNED  => undef, # "tag\0string" -> tag string
    ASSIGN_ORDER => undef, # tag strings in assignment order
    ORIGIN    => undef, # tag string -> original string
    TRACK     => undef, # tag string -> 1 (must come back in response)
);

sub new {
    my $class = shift;
    my $obj = bless { %default }, $class;
    # NOTE: reference-valued defaults must get fresh copies here
    $obj->{PATTERN} = [];
    $obj->{TABLE} = [];
    $obj->{RULES} = [];
    $obj->{FILERULES} = [];
    $obj->{COUNTER} = {};
    $obj->{ASSIGNED} = {};
    $obj->{ASSIGN_ORDER} = [];
    $obj->{ORIGIN} = {};
    $obj->{TRACK} = {};
    lock_keys %{$obj};
    $obj->configure(@_);
    $obj;
}

sub reset {
    my $obj = shift;
    $obj->{NUMBER} = 0;
    $obj->{TABLE} = [];
    $obj->{TRACK} = {};
    $obj;
}

sub configure {
    my $obj = shift;
    while (my($a, $b) = splice @_, 0, 2) {
        if ($a eq 'pattern') {
            my @pattern = ref $b ? @$b : $b;
            push @{$obj->{PATTERN}}, @pattern;
        }
        elsif ($a eq 'file') {
            open my $fh, '<:encoding(utf8)', $b or die "$b: $!\n";
            my @p = map s/\\(?=\n)//gr, split /(?<!\\)\n/, do { local $/; <$fh> };
            push @{$obj->{PATTERN}}, @p;
        }
        else {
            $obj->{$a} = $b;
        }
    }
}

sub add_rule {
    my($obj, $tag, $pattern) = @_;
    $tag =~ /\A[a-z][a-z0-9_]*\z/
        or die "$tag: invalid category name.\n";
    push @{$obj->{RULES}}, [ $tag, $pattern ];
    $obj;
}

sub file_rules {
    my($obj, $rules) = @_;
    $obj->{FILERULES} = [ @$rules ];
    $obj;
}

##
## Escape rule: hide pre-existing tag-shaped literals so that every
## tag in the working text is one of ours.  Must be the first rule;
## restored last (rules are restored in reverse order of the TABLE).
##
sub add_escape_rule {
    my $obj = shift;
    unshift @{$obj->{RULES}}, [ 'lit', '<[a-z][a-z0-9_]* [a-z0-9_]+=\d+ */>' ];
    $obj;
}

sub _all_rules {
    my $obj = shift;
    (@{$obj->{RULES}}, @{$obj->{FILERULES}});
}

sub _stable_tag {
    my($obj, $tag, $matched) = @_;
    my $key = "$tag\0$matched";
    $obj->{ASSIGNED}{$key} //= do {
        my $t = sprintf("<%s %s=%d />",
                        $tag, $obj->{INDEX}, ++$obj->{COUNTER}{$tag});
        $obj->{ORIGIN}{$t} = $matched;
        push @{$obj->{ASSIGN_ORDER}}, $t;
        $t;
    };
}

sub _mask_stable {
    my($obj, $track) = splice @_, 0, 2;
    for (@_) {
        for my $rule ($obj->_all_rules) {
            my($tag, $pat) = @$rule;
            s{$pat}{
                my $t = $obj->_stable_tag($tag, ${^MATCH});
                $obj->{TRACK}{$t} = 1 if $track;
                $t;
            }gpe;
        }
    }
    return $obj;
}

sub mask {
    my $obj = shift;
    if ($obj->{STABLE}) {
        return $obj->_mask_stable(1, @_);
    }
    my $pattern = $obj->{PATTERN} // die;
    my @patterns = ref $pattern ? @$pattern : $pattern;
    my $fromto = $obj->{TABLE};
    # edit parameters in place
    for (@_) {
        for my $pat (@patterns) {
            next if $pat =~ /^\s*(#|$)/;
            s{$pat}{
                my $tag = sprintf("<%s %s=%d />",
                                  $obj->{TAG}, $obj->{INDEX}, ++$obj->{NUMBER});
                push @$fromto, [ $tag, ${^MATCH} ];
                $tag;
            }gpe;
        }
    }
    return $obj;
}

sub mask_reference {
    my $obj = shift;
    $obj->{STABLE} or die "mask_reference requires STABLE mode.\n";
    $obj->_mask_stable(0, @_);
}

sub unmask {
    my $obj = shift;
    if ($obj->{STABLE}) {
        my %missing = %{$obj->{TRACK}};
        for (@_) {
            # Restore in REVERSE assignment order: the escape rule runs
            # first, so its tags are assigned first and must be restored
            # last -- an escaped literal may itself look like one of our
            # later tags, and restoring it earlier would let a later
            # substitution corrupt it.
            for my $t (reverse @{$obj->{ASSIGN_ORDER}}) {
                my $orig = $obj->{ORIGIN}{$t};
                if (s/\Q$t/$orig/g) {
                    delete $missing{$t};
                }
            }
        }
        if (%missing) {
            die sprintf("Masking error: \"%s\" missing in the output(%s).\n",
                        join('", "', sort keys %missing),
                        join('', @_),
                    );
        }
        return $obj;
    }
    my @tags = map $_->[0], @{$obj->{TABLE}};
    my %tags = map { $_ => 1 } @tags;
    # edit parameters in place
    for (@_) {
        for my $fromto (reverse @{$obj->{TABLE}}) {
            my($from, $to) = @$fromto;
            # update the first one
            if (my $n = s/\Q$from/$to/) {
                if ($n > 1 or not exists $tags{$from}) {
                    warn "Masking error: \"$from\" duplicated.\n";
                }
                delete $tags{$from};
            }
        }
    }
    if (%tags) {
        die sprintf("Masking error: \"%s\" missing in the output(%s).\n",
                    join('", "', keys %tags),
                    join('', @_),
                );
    }
    $obj->reset if $obj->{AUTORESET};
    return $obj;
}

1;
```

- [ ] **Step 4: テストを実行して通ることを確認**

Run: `prove -l t/13_mask.t && prove -l t/`
Expected: 全 PASS(既存スイートは maskfile 旧経路が不変なので影響なし)

- [ ] **Step 5: コミット**

```bash
git add lib/App/Greple/xlate/Mask.pm t/13_mask.t
git commit -m "feat: add stable categorized masking path to Mask.pm"
```

---

### Task 2: Mask.pm — 辞書ローダとインラインマーク抽出

**Files:**
- Modify: `lib/App/Greple/xlate/Mask.pm`
- Test: `t/13_mask.t`(追記)

**Interfaces:**
- Consumes: Task 1 の `add_rule`
- Produces:
  - `$obj->load_anonymize_file($path)` — 先頭非空白が `[` なら JSON
    (`[{"category":...,"text":...|"regex":...},...]`、未知フィールド
    無視、text/regex 同時・欠落は die)、それ以外は行形式
    (`カテゴリ 空白 パターン`、`/.../` は正規表現、`#` コメント、
    バックスラッシュ行継続)。`lit` カテゴリは die
  - `App::Greple::xlate::Mask::extract_marks($text, $regex)` —
    クラス関数。`(?<category>...)` と `(?<text>...)` を含む $regex で
    $text を全走査し、重複排除済みの `[ [category, quotemeta(text)],
    ... ]` を返す。同一 text に異カテゴリ → die。`lit` → die。
    $regex に両キャプチャ名が(文字列として)無ければ die
  - `$App::Greple::xlate::Mask::DEFAULT_MARK` — 既定マーク正規表現
    (`\{\{\s*(?<category>[a-z][a-z0-9_]*)\(\s*(?<q>["'])(?<text>.+?)\k<q>\s*\)\s*\}\}`)

- [ ] **Step 1: 失敗するテストを追記**

`t/13_mask.t` の `done_testing;` の前に追加:

```perl
use File::Temp qw(tempdir);
my $dir = tempdir(CLEANUP => 1);

sub write_file {
    my($path, $text) = @_;
    open my $fh, '>:encoding(utf8)', $path or die "$path: $!";
    print $fh $text;
    close $fh;
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
```

- [ ] **Step 2: テストを実行して失敗を確認**

Run: `prove -l t/13_mask.t`
Expected: FAIL — `Can't locate object method "load_anonymize_file"`

- [ ] **Step 3: 実装を追加**

`lib/App/Greple/xlate/Mask.pm` に追加(`add_escape_rule` の後):

```perl
use JSON;

our $DEFAULT_MARK =
    q[\{\{\s*(?<category>[a-z][a-z0-9_]*)\(\s*(?<q>["'])(?<text>.+?)\k<q>\s*\)\s*\}\}];

sub _check_category {
    my $tag = shift;
    die "lit: reserved category name.\n" if $tag eq 'lit';
    $tag =~ /\A[a-z][a-z0-9_]*\z/
        or die "$tag: invalid category name.\n";
    $tag;
}

sub load_anonymize_file {
    my($obj, $path) = @_;
    open my $fh, '<:encoding(utf8)', $path or die "$path: $!\n";
    my $data = do { local $/; <$fh> };
    if ($data =~ /\A\s*\[/) {
        my $list = JSON->new->decode($data);
        ref $list eq 'ARRAY' or die "$path: JSON array expected.\n";
        for my $e (@$list) {
            ref $e eq 'HASH' or die "$path: object expected.\n";
            my $cat = _check_category($e->{category}
                // die "$path: category missing.\n");
            my $has_text  = defined $e->{text};
            my $has_regex = defined $e->{regex};
            die "$path: both text and regex given.\n"
                if $has_text and $has_regex;
            die "$path: either text or regex required.\n"
                unless $has_text or $has_regex;
            $obj->add_rule($cat,
                           $has_text ? quotemeta($e->{text}) : $e->{regex});
        }
    } else {
        my @lines = map s/\\(?=\n)//gr, split /(?<!\\)\n/, $data;
        for my $line (@lines) {
            next if $line =~ /^\s*(#|$)/;
            my($cat, $pat) = $line =~ /^\s*(\S+)\s+(.*?)\s*$/
                or die "$path: unparsable line: $line\n";
            _check_category($cat);
            if ($pat =~ m{\A/(.*)/\z}s) {
                $obj->add_rule($cat, $1);
            } else {
                $obj->add_rule($cat, quotemeta($pat));
            }
        }
    }
    $obj;
}

sub extract_marks {
    my($text, $regex) = @_;
    index($regex, '(?<category>') >= 0 and index($regex, '(?<text>') >= 0
        or die "mark regex needs (?<category>...) and (?<text>...) named captures.\n";
    my(%cat, @rules);
    while ($text =~ /$regex/g) {
        my($cat, $str) = ($+{category}, $+{text});
        _check_category($cat);
        if (exists $cat{$str}) {
            $cat{$str} eq $cat
                or die "\"$str\": conflicting categories ($cat{$str} vs $cat).\n";
            next;
        }
        $cat{$str} = $cat;
        push @rules, [ $cat, quotemeta($str) ];
    }
    \@rules;
}
```

- [ ] **Step 4: テストを実行して通ることを確認**

Run: `prove -l t/13_mask.t && prove -l t/`
Expected: 全 PASS

- [ ] **Step 5: コミット**

```bash
git add lib/App/Greple/xlate/Mask.pm t/13_mask.t
git commit -m "feat: anonymization dictionary loader and inline mark extraction"
```

---

### Task 3: xlate.pm — 匿名化 3 層の統合

**Files:**
- Modify: `lib/App/Greple/xlate.pm`(%opt / __DATA__ / setup / begin /
  cache_update / mask_string)
- Test: `t/14_anon.t`(新規)

**Interfaces:**
- Consumes: Task 1-2 の Mask 新経路 API
- Produces:
  - `--xlate-anonymize=FILE`(%opt `anonymize`、
    builtin `xlate-anonymize=s`)
  - `--xlate-anonymize-mark[=REGEX]`(%opt `anonymize_mark`、
    builtin `xlate-anonymize-mark:s`。'' は既定記法)
  - `$anonobj` — STABLE Mask(退避ルール+辞書。マークは begin ごとに
    `file_rules`)。cache_update で本文=mask() / 文脈複製=
    mask_reference() を maskfile より**先**に適用、復元は maskfile の
    **後**
  - `clone_context($context)` — 文脈ハッシュの複製(文字列・ペアとも
    新実体)

- [ ] **Step 1: 失敗するテストを書く**

`t/14_anon.t` を以下の内容で作成:

```perl
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
prologue paragraph one

yamada taro visited acme corporation

yamada taro came back again

epilogue paragraph last
END

sub write_file {
    my($path, $text) = @_;
    open my $fh, '>:encoding(utf8)', $path or die "$path: $!";
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

my @XLATE = (qw(--xlate --xlate-engine=gpt5 --xlate-to=EN-US),
             qw(--xlate-format=xtxt --all --need=0),
             '--re', '^([a-z].*\n)+');

sub run_xlate {
    my($file, @extra) = @_;
    xlate(@XLATE, @extra, $file)->run;
}

my $dict = "$dir/dict.json";
write_file($dict, <<'END');
[
  { "category": "person",  "text": "yamada taro" },
  { "category": "company", "text": "acme corporation" }
]
END

subtest 'dictionary anonymization end to end' => sub {
    my $doc = "$dir/doc.txt";
    my $cache = "$doc.xlate-gpt5-EN-US.json";
    write_file($doc, $DOC);
    write_file($cache, '');
    run_xlate($doc, "--xlate-anonymize=$dict");   # 全訳を作る
    # 1 段落変更して文脈つき再翻訳を発生させる
    (my $mod = $DOC) =~ s/came back again/came back once more/;
    write_file($doc, $mod);
    my $log = "$dir/dict.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($doc, "--xlate-anonymize=$dict");
    is($r->status, 0, 'run succeeds');
    my @calls = stub_calls($log);
    is(scalar @calls, 1, 'one call');
    my $payload = $calls[0]{stdin};
    my $sys = sys_of($calls[0]);
    unlike($payload, qr/yamada taro/, 'payload has no real name');
    like($payload, qr/<person id=1 \/>/, 'payload uses category tag');
    unlike($sys, qr/yamada taro/, 'context sections have no real name');
    unlike($sys, qr/acme corporation/, 'context sections have no company');
    like($sys, qr/<person id=1 \/>/, 'context uses the same tag');
    like($r->stdout, qr/YAMADA TARO CAME BACK ONCE MORE/,
         'output restored (stub upcases only non-tag text)');
};

subtest 'inline mark anonymization' => sub {
    my $doc = "$dir/mark.txt";
    my $cache = "$doc.xlate-gpt5-EN-US.json";
    my $marked = <<'END';
introduction line here

the contact is {{ person("suzuki hanako") }} for now

suzuki hanako answers the phone
END
    write_file($doc, $marked);
    write_file($cache, '');
    my $log = "$dir/mark.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($doc, '--xlate-anonymize-mark');
    is($r->status, 0, 'run succeeds');
    my @calls = stub_calls($log);
    my $payload = join '', map $_->{stdin}, @calls;
    unlike($payload, qr/suzuki hanako/, 'marked name gone everywhere');
    like($payload, qr/\{\{ person\("<person id=1 \/>"\) \}\}/,
         'mark syntax survives around the tag');
    like($r->stdout, qr/SUZUKI HANAKO ANSWERS/,
         'unmarked occurrence restored too');
    like($r->stdout, qr/\{\{ PERSON\("suzuki hanako"\) \}\}|\{\{ person\("suzuki hanako"\) \}\}/i,
         'mark restored in output');
};

subtest 'escape layer protects tag-shaped literals' => sub {
    my $doc = "$dir/esc.txt";
    my $cache = "$doc.xlate-gpt5-EN-US.json";
    write_file($doc, <<'END');
literal <person id=1 /> appears here

yamada taro appears here
END
    write_file($cache, '');
    my $log = "$dir/esc.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($doc, "--xlate-anonymize=$dict");
    is($r->status, 0, 'run succeeds');
    my @calls = stub_calls($log);
    my $payload = join '', map $_->{stdin}, @calls;
    like($payload, qr/<lit id=1 \/>/, 'literal escaped');
    like($r->stdout, qr/LITERAL <person id=1 \/> APPEARS|literal <person id=1 \/> appears/i,
         'literal restored exactly');
};

subtest 'maskfile combination keeps both layers working' => sub {
    my $doc = "$dir/combo.txt";
    my $cache = "$doc.xlate-gpt5-EN-US.json";
    write_file($doc, <<'END');
keep C<verbatim> and yamada taro together
END
    write_file($cache, '');
    my $mf = "$dir/maskfile";
    write_file($mf, "C<[^>]*>\n");
    my $log = "$dir/combo.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($doc, "--xlate-anonymize=$dict",
                      '--xlate-setopt', "maskfile=$mf");
    is($r->status, 0, 'run succeeds');
    my @calls = stub_calls($log);
    my $payload = join '', map $_->{stdin}, @calls;
    like($payload, qr/<m id=1 \/>/, 'maskfile layer applied');
    like($payload, qr/<person id=1 \/>/, 'anonymize layer applied');
    unlike($payload, qr/yamada taro|C<verbatim>/, 'both hidden');
    like($r->stdout, qr/C<verbatim>/, 'maskfile restored');
    like($r->stdout, qr/YAMADA TARO|yamada taro/i, 'name restored');
};

done_testing;
```

- [ ] **Step 2: テストを実行して失敗を確認**

Run: `prove -l t/14_anon.t`
Expected: FAIL — `--xlate-anonymize` が未知オプション

- [ ] **Step 3: xlate.pm を改修**

(a) `%opt`(`contexts` の前)に追加:

```perl
    anonymize => \(our $anonymize_file),
    anonymize_mark => \(our $anonymize_mark),
```

(b) `__DATA__` の builtin(`builtin xlate-context-window=i` の下)に追加:

```
builtin xlate-anonymize=s      $anonymize_file
builtin xlate-anonymize-mark:s $anonymize_mark
```

(c) 変数宣言(`my $maskobj;` の下)に追加:

```perl
my $anonobj;
```

(d) setup() の maskfile ブロックの**後**に追加:

```perl
    if (defined $anonymize_file or defined $anonymize_mark) {
        $anonobj = App::Greple::xlate::Mask->new(STABLE => 1);
        $anonobj->add_escape_rule;
        $anonobj->load_anonymize_file($anonymize_file)
            if defined $anonymize_file;
    }
```

(e) begin() の `$current_text = $_;` の直後に追加:

```perl
    if ($anonobj and defined $anonymize_mark) {
        my $regex = length($anonymize_mark)
            ? $anonymize_mark : $App::Greple::xlate::Mask::DEFAULT_MARK;
        $anonobj->file_rules(
            App::Greple::xlate::Mask::extract_marks($current_text, $regex));
    }
```

(f) cache_update の eval ブロックを次のように変更する。現在:

```perl
    my @result = eval {
        $maskobj->mask(@from) if $maskobj;
        my @chop = grep { $from[$_] =~ s/(?<!\n)\z/\n/ } keys @from;
        my @to = do {
            local $call_context = $context;
            map { s/ +$//mgr } &XLATE(@from);
        };
        chop @to[@chop];
        $maskobj->unmask(@to)->reset if $maskobj;
```

新(退避+匿名化($anonobj)→ maskfile($maskobj)の順で掛け、
逆順で復元。文脈は複製に参照モードで $anonobj のみ適用):

```perl
    my @result = eval {
        my $masked_context = $context;
        if ($anonobj) {
            $anonobj->mask(@from);
            if ($context) {
                $masked_context = clone_context($context);
                $anonobj->mask_reference(
                    $masked_context->{source_before},
                    $masked_context->{source_after});
                for my $pairs (@{$masked_context}{qw(hits_before hits_after old_pairs)}) {
                    $anonobj->mask_reference(@$_) for @$pairs;
                }
            }
        }
        $maskobj->mask(@from) if $maskobj;
        my @chop = grep { $from[$_] =~ s/(?<!\n)\z/\n/ } keys @from;
        my @to = do {
            local $call_context = $masked_context;
            map { s/ +$//mgr } &XLATE(@from);
        };
        chop @to[@chop];
        $maskobj->unmask(@to)->reset if $maskobj;
        if ($anonobj) {
            $anonobj->unmask(@to);
            $anonobj->reset;
        }
```

(`mask_reference($hash->{key})` / `mask_reference(@$pair)` は
ハッシュ・配列要素のエイリアスを受けるので in-place 編集できる)

**Step 3 の設計注記(実装者へ)**: 仕様は maskfile も文脈へ参照モードで
適用するとしているが、旧経路には参照モードがない。ここでは
**maskfile の文脈適用は行わない**(品質向上のみの層であり秘匿には
無関係。$anonobj の文脈適用だけで秘匿要件は満たされる)。この逸脱は
コミットメッセージと POD に明記し、仕様書の該当行も本タスクで
「maskfile の文脈適用は行わない(旧経路に参照モードが無いため。
秘匿要件には影響しない)」に修正すること
(docs/superpowers/specs/2026-07-06-anonymization-mask-design.md の
「(1) maskfile も文脈へ参照モードで適用される(品質向上のみ)」の行)。

(g) ヘルパーを cache_update の直前に追加(複製のみ。文字列への
参照モード適用は (f) のとおり cache_update 内でエイリアス渡しする):

```perl
sub clone_context {
    my $ctx = shift;
    return {
        source_before => $ctx->{source_before},
        source_after  => $ctx->{source_after},
        hits_before   => [ map [ @$_ ], @{$ctx->{hits_before} // []} ],
        hits_after    => [ map [ @$_ ], @{$ctx->{hits_after}  // []} ],
        old_pairs     => [ map [ @$_ ], @{$ctx->{old_pairs}   // []} ],
    };
}
```

(h) mask_string(--xlate-mask プレビュー)に anonobj を追加:

```perl
sub mask_string {
    my($s) = +{ @_ }->{match};
    if ($anonobj) {
        $anonobj->mask($s);
    }
    if ($maskobj) {
        $maskobj->mask($s);
    }
    $s;
}
```

- [ ] **Step 4: テストを実行して通ることを確認**

Run: `prove -l t/14_anon.t && prove -l t/`
Expected: 全 PASS(匿名化未指定の経路は $anonobj が undef で完全不変)

- [ ] **Step 5: 仕様書の maskfile 文脈適用の行を修正(Step 3 注記どおり)**

- [ ] **Step 6: コミット**

```bash
git add lib/App/Greple/xlate.pm t/14_anon.t docs/superpowers/specs/2026-07-06-anonymization-mask-design.md
git commit -m "feat: wire three-layer anonymization into the pipeline"
```

---

### Task 4: F1 — テンプレート式の保全検証

**Files:**
- Modify: `lib/App/Greple/xlate.pm`(%opt / __DATA__ / cache_update)
- Modify: `lib/App/Greple/xlate/llm.pm`(build_system)
- Test: `t/15_template.t`(新規)

**Interfaces:**
- Consumes: Task 3 後の cache_update 構造
- Produces:
  - `--xlate-template[=REGEX]`(%opt `template`、builtin
    `xlate-template:s`。'' は既定 Jinja2 パターン
    `\{\{.*?\}\}|\{%.*?%\}|\{#.*?#\}`)
  - `template_regex()` — 有効時に正規表現文字列を返す(無効時 undef)
  - cache_update: 応答検証「送信形 @from(マスク適用後)の式列 ==
    応答 @to の式列」(要素ごと)。不一致は die(②の凍結保護が効く)
  - llm.pm build_system: 有効時に保全指示 1 文を追記

- [ ] **Step 1: 失敗するテストを書く**

`t/15_template.t` を以下の内容で作成:

```perl
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

sub write_file {
    my($path, $text) = @_;
    open my $fh, '>:encoding(utf8)', $path or die "$path: $!";
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

my @XLATE = (qw(--xlate --xlate-engine=gpt5 --xlate-to=EN-US),
             qw(--xlate-format=xtxt --all --need=0),
             '--re', '^([a-z].*\n)+');

sub run_xlate {
    my($file, @extra) = @_;
    xlate(@XLATE, @extra, $file)->run;
}

subtest 'expressions preserved (Japanese variable names)' => sub {
    # スタブは uc 変換: 日本語・記号は不変なので式はそのまま返る
    my $doc = "$dir/tmpl.txt";
    write_file($doc, <<'END');
this case was handled by {{ 報告者 }} yesterday

the client {% if 発注会社 %}{{ 発注会社 }}{% endif %} agreed
END
    write_file("$doc.xlate-gpt5-EN-US.json", '');
    my $log = "$dir/ok.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($doc, '--xlate-template');
    is($r->status, 0, 'run succeeds');
    my @calls = stub_calls($log);
    my $sys = sys_of($calls[0]);
    like($sys, qr/opaque placeholders/, 'preservation instruction present');
    like($r->stdout, qr/\{\{ 報告者 \}\}/, 'expression intact in output');
    like($r->stdout, qr/\{% if 発注会社 %\}/, 'statement intact in output');
};

subtest 'broken expression is detected' => sub {
    # ASCII 変数名はスタブの uc で {{ REPORTER }} に変形される →
    # 式列不一致 → die(非ゼロ終了)
    my $doc = "$dir/broken.txt";
    write_file($doc, <<'END');
handled by {{ reporter }} yesterday
END
    write_file("$doc.xlate-gpt5-EN-US.json", '');
    my $r = run_xlate($doc, '--xlate-template');
    isnt($r->status, 0, 'mangled expression dies');
};

subtest 'cache preserved on verification failure' => sub {
    my $doc = "$dir/protect.txt";
    my $cache = "$doc.xlate-gpt5-EN-US.json";
    write_file($doc, <<'END');
first stable paragraph here

second stable paragraph here
END
    write_file($cache, '');
    run_xlate($doc);                       # キャッシュ作成(template なし)
    my $before = do { open my $fh, '<', $cache or die; local $/; <$fh> };
    (my $mod = "first stable paragraph here\n\nhandled by {{ reporter }} now\n");
    write_file($doc, $mod);
    my $r = run_xlate($doc, '--xlate-template');
    isnt($r->status, 0, 'run fails');
    my $after = do { open my $fh, '<', $cache or die; local $/; <$fh> };
    like($after, qr/FIRST STABLE PARAGRAPH/,
         'existing pairs survive the failure (checkpoint+freeze)');
};

done_testing;
```

- [ ] **Step 2: テストを実行して失敗を確認**

Run: `prove -l t/15_template.t`
Expected: FAIL — `--xlate-template` が未知オプション

- [ ] **Step 3: xlate.pm を実装**

(a) `%opt` に追加(`anonymize_mark` の下):

```perl
    template => \(our $template_option),
```

(b) `__DATA__` builtin に追加:

```
builtin xlate-template:s   $template_option
```

(c) 定数とヘルパー(`our $CONTEXT_SOURCE_MAX` の近く)に追加:

```perl
our $TEMPLATE_DEFAULT = q[\{\{.*?\}\}|\{%.*?%\}|\{#.*?#\}];

sub template_regex {
    return undef unless defined $template_option;
    length($template_option) ? $template_option : $TEMPLATE_DEFAULT;
}
```

(d) cache_update の eval 内、`_progress({label => "To"}, @to);` の
直後に検証を追加:

```perl
        if (defined(my $tre = template_regex())) {
            for my $i (0 .. $#from) {
                my @want = $from[$i] =~ /($tre)/g;
                my @got  = ($to[$i] // '') =~ /($tre)/g;
                if ("@want" ne "@got") {
                    die sprintf("Template expressions broken in response:\n" .
                                "  expected: %s\n  got: %s\n",
                                "@want", "@got");
                }
            }
        }
```

(検証位置は unmask の**前** — 式は平文で送られ unmask の影響を
受けないが、送信形 @from はマスク適用後の姿なので同じ土俵で比較できる)

- [ ] **Step 4: llm.pm に保全指示を追加**

build_system の `$system .= context_sections();` の**前**に追加:

```perl
    if (defined(my $tre = App::Greple::xlate::template_regex())) {
        $system .= "\n\nThe input contains template expressions"
                 . " (such as {{ ... }} or {% ... %})."
                 . " Treat them as opaque placeholders: copy each one"
                 . " to the output unchanged, byte for byte.";
    }
```

(プロンプト内の "opaque placeholders" という語はテストのアサーションと
一致させること)

- [ ] **Step 5: テストを実行して通ることを確認**

Run: `prove -l t/15_template.t && prove -l t/`
Expected: 全 PASS

- [ ] **Step 6: コミット**

```bash
git add lib/App/Greple/xlate.pm lib/App/Greple/xlate/llm.pm t/15_template.t
git commit -m "feat: verify template expressions survive translation (F1)"
```

---

### Task 5: F2 — YAML front matter

**Files:**
- Modify: `lib/App/Greple/xlate.pm`(%opt / __DATA__ option 合成 /
  begin / source_slice_before)
- Test: `t/15_template.t`(追記)

**Interfaces:**
- Consumes: Task 3 の $anonobj、Task 4 のテスト基盤
- Produces:
  - `--xlate-frontmatter`(greple option 合成: front matter を
    `--exclude` しつつ `--xlate-setopt frontmatter=1`)
  - begin: front matter 検出時、(a) `$frontmatter_len` を記録し
    スライス起点を補正、(b) フラット `キー: 値` の値を `var`
    カテゴリの匿名化ルールとして $anonobj に追加($anonobj が無ければ
    生成)

- [ ] **Step 1: 失敗するテストを追記**

`t/15_template.t` の `done_testing;` の前に追加:

```perl
subtest 'front matter: excluded, values anonymized, slices adjusted' => sub {
    my $doc = "$dir/fm.txt";
    my $cache = "$doc.xlate-gpt5-EN-US.json";
    write_file($doc, <<'END');
---
template: report.j2
報告者: yamada taro
発注会社: acme corporation
---
opening paragraph of the body

the visitor was yamada taro that day

closing paragraph of the body
END
    write_file($cache, '');
    my $log0 = "$dir/fm0.log";
    {
        local $ENV{LLM_STUB_LOG} = $log0;
        my $r0 = run_xlate($doc, '--xlate-frontmatter');
        is($r0->status, 0, 'initial run succeeds');
        my @calls = stub_calls($log0);
        my $payload = join '', map $_->{stdin}, @calls;
        unlike($payload, qr/report\.j2|template:/,
               'front matter is not a translation target');
        unlike($payload, qr/yamada taro/, 'value anonymized in body');
        like($payload, qr/<var id=\d+ \/>/, 'var category tag used');
    }
    # 文脈スライスにも front matter が出ないこと(1 段落変更)
    (my $mod = do { open my $fh, '<', $doc or die; local $/; <$fh> })
        =~ s/visitor was/visitor happened to be/;
    write_file($doc, $mod);
    my $log = "$dir/fm.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($doc, '--xlate-frontmatter');
    is($r->status, 0, 'second run succeeds');
    my @calls = stub_calls($log);
    my $sys = sys_of($calls[0]);
    unlike($sys, qr/template: report\.j2/, 'slice does not show front matter');
    unlike($sys, qr/yamada taro|acme corporation/,
           'values hidden from context too');
};

subtest 'no frontmatter option: behavior unchanged' => sub {
    my $doc = "$dir/nofm.txt";
    write_file($doc, "---\nkey: value\n---\nbody paragraph here\n");
    write_file("$doc.xlate-gpt5-EN-US.json", '');
    my $log = "$dir/nofm.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($doc);
    is($r->status, 0, 'runs');
    my @calls = stub_calls($log);
    my $payload = join '', map $_->{stdin}, @calls;
    like($payload, qr/key: value/, 'without the option fm is ordinary text');
};
```

- [ ] **Step 2: テストを実行して失敗を確認**

Run: `prove -l t/15_template.t`
Expected: FAIL — `--xlate-frontmatter` が未知オプション

- [ ] **Step 3: 実装**

(a) `%opt` に追加(`template` の下):

```perl
    frontmatter => \(our $use_frontmatter = 0),
```

(b) `__DATA__` に **builtin ではなく option 合成**で追加
(`option --cache-clear` の近く):

```
option --xlate-frontmatter \
        --xlate-setopt frontmatter=1 \
        --exclude \A---\n(?s:.*?)^---\n
```

(c) 変数宣言(`my $current_text;` の下)に追加:

```perl
my $frontmatter_len = 0;       # body starts after this offset
```

(d) begin() の `$current_text = $_;` とマーク抽出の**間**に追加:

```perl
    $frontmatter_len = 0;
    if ($use_frontmatter
        and $current_text =~ /\A(---\n(?s:.*?)^---\n)/m) {
        my $fm = $1;
        $frontmatter_len = length $fm;
        my @values;
        for my $line (split /\n/, $fm) {
            next if $line =~ /^---/;
            my($k, $v) = $line =~ /^([^\s:#][^:]*):\s*(.+?)\s*$/ or next;
            push @values, $v;
        }
        if (@values) {
            if (not $anonobj) {
                $anonobj = App::Greple::xlate::Mask->new(STABLE => 1);
                $anonobj->add_escape_rule;
            }
            $anonobj->add_rule(var => quotemeta($_)) for @values;
        }
    }
```

(e) source_slice_before の起点補正。現在:

```perl
sub source_slice_before {
    my $end = shift;
    return '' unless defined $current_text and $end > 0;
    my $start = $end - $CONTEXT_SOURCE_MAX;
    $start = 0 if $start < 0;
```

新:

```perl
sub source_slice_before {
    my $end = shift;
    return '' unless defined $current_text and $end > $frontmatter_len;
    my $start = $end - $CONTEXT_SOURCE_MAX;
    $start = $frontmatter_len if $start < $frontmatter_len;
```

**注意**: begin は複数ファイルで呼ばれるため `$frontmatter_len = 0;` の
リセットを必ず begin 冒頭側(上記 (d) の 1 行目)で行う。
また (d) の add_rule はファイルごとに恒久ルールへ追記されるため、
複数ファイル実行では前ファイルの値ルールが残る(安全側:
秘匿が広がる方向)。この挙動は POD に明記する。

- [ ] **Step 4: テストを実行して通ることを確認**

Run: `prove -l t/15_template.t && prove -l t/`
Expected: 全 PASS

- [ ] **Step 5: コミット**

```bash
git add lib/App/Greple/xlate.pm t/15_template.t
git commit -m "feat: front matter exclusion with value anonymization (F2)"
```

---

### Task 6: gpt5 プロンプトのタグ例拡張

**Files:**
- Modify: `lib/App/Greple/xlate/llm/gpt5.pm`(prompt 1 箇所)
- Test: `t/08_llm_gpt5.t`(アサーション 1 行追加)

**Interfaces:** なし(文言のみ)

- [ ] **Step 1: 失敗するアサーションを追加**

`t/08_llm_gpt5.t` の
`like($system, qr/conventions for that kind of element/, ...)` の直後に:

```perl
like($system, qr/<person id=2 \/>/, 'category tag example present');
```

- [ ] **Step 2: 失敗を確認**

Run: `prove -l t/08_llm_gpt5.t`
Expected: FAIL(新アサーションのみ)

- [ ] **Step 3: プロンプトを 1 箇所変更**

`lib/App/Greple/xlate/llm/gpt5.pm` の prompt 内:

```
If an element is a blank string or an XML-style marker tag (e.g., "<m id=1 />"), leave it unchanged and do not translate it.
```

を

```
If an element is a blank string or an XML-style marker tag (e.g., "<m id=1 />" or "<person id=2 />"), leave it unchanged and do not translate it.
```

に変更。

- [ ] **Step 4: テスト確認とコミット**

Run: `prove -l t/08_llm_gpt5.t && prove -l t/`
Expected: 全 PASS

```bash
git add lib/App/Greple/xlate/llm/gpt5.pm t/08_llm_gpt5.t
git commit -m "feat: mention category tags in the gpt5 prompt tag example"
```

---

### Task 7: POD・レシピ・全体確認

**Files:**
- Modify: `lib/App/Greple/xlate.pm`(POD の MASKING 節の後に
  ANONYMIZATION 節を新設、OPTIONS に 4 項目追加)

**Interfaces:**
- Consumes: Task 3-5 のオプション群

- [ ] **Step 1: OPTIONS に 4 項目を追加**

POD の `=item B<--xlate-cache-seed>=I<file>` 項の後に追加:

```pod
=item B<--xlate-anonymize>=I<file>

Anonymize sensitive strings before they are sent to the translation
API, and restore them in the output.  The dictionary file gives one
entry per item: in JSON (canonical, machine-generatable)

    [ { "category": "person",  "text": "山田太郎" },
      { "category": "company", "regex": "アクメ(株式会社)?" } ]

or in a simple line format (C<category pattern>, C</.../> for regex).
Each item is replaced by a category tag such as C<< <person id=1 /> >>;
the same string always gets the same tag, so the model can keep track
of who is who.  Unknown JSON fields are ignored, so generators (e.g. a
local LLM extracting entities) may add their own annotations.
Category C<lit> is reserved.  Local cache files still store restored
plain text: the concealment target is API transmission only.

=item B<--xlate-anonymize-mark>[=I<regex>]

Collect anonymization entries from inline marks in the document
itself.  Mark the first occurrence like C<{{ person("山田太郎") }}>
and every occurrence of the string document-wide is anonymized.  The
mark itself stays in the source and in the translation, so a document
can also be processed by a Jinja2-style macro processor (define the
C<person> macro to print or redact the name).  A custom I<regex> must
contain C<< (?<category>...) >> and C<< (?<text>...) >> named captures.

=item B<--xlate-template>[=I<regex>]

Treat template expressions (default: Jinja2 C<{{ ... }}>,
C<{% ... %}>, C<{# ... #}>) as opaque placeholders: instruct the
model to copy them unchanged and verify, per block, that the response
contains exactly the same expression sequence.  A broken expression
aborts the run; the cache is checkpointed and frozen, so nothing paid
for is lost.

=item B<--xlate-frontmatter>

Treat a leading C<---> ... C<---> block as YAML front matter: exclude
it from translation and from the phase-2 context slices, and add its
flat C<key: value> values to the anonymization rules (category
C<var>) as a safety net.  With multiple input files the collected
values accumulate (erring on the side of concealment).
```

- [ ] **Step 2: ANONYMIZATION 節を新設(MASKING 節の後)**

```pod
=head1 ANONYMIZATION AND TEMPLATES

For form documents (quarterly reports and the like), define the
actors up front and reference them in the body:

    ---
    報告者: 山田太郎
    発注会社: アクメ株式会社
    ---
    本件について {{ 報告者 }} が調査を行った。

Translate the template once per language with C<--xlate-template>
(and C<--xlate-frontmatter> when the values are kept in the file),
then render each case with B<pandoc-embedz> standalone mode --
values under C<global:> in an external config never reach the
translation API at all:

    greple -Mxlate --xlate --xlate-engine=gpt5 --xlate-to=EN-US \
           --xlate-template report-template.md > report-template.EN.md
    pandoc-embedz --standalone report-template.EN.md \
                  -c case-123.yaml -o report-123.EN.md < /dev/null

For inline marks, providing a macro definition config makes the same
translated template render either the real names or a redacted
version:

    # macros.yaml           # macros-redacted.yaml
    preamble: |             preamble: |
      {% macro person(name) %}{{ name }}{% endmacro %}
                              {% macro person(name) %}(関係者){% endmacro %}

Exclude embedz blocks from translation when a document contains them:

    --exclude '^```embedz\n(?s:.*?)^```\n'
```

- [ ] **Step 3: 検証とコミット**

Run: `podchecker lib/App/Greple/xlate.pm`
Expected: `pod syntax OK`

Run: `prove -l t/`
Expected: 全ファイル PASS

```bash
git add lib/App/Greple/xlate.pm
git commit -m "docs: document anonymization, template, and front matter options"
```

---

## 自己レビュー記録

- 仕様カバレッジ: Mask 一般化(T1)、辞書 JSON/行(T2)、インライン
  マーク(T2/T3)、退避層(T1/T3)、3 層適用+文脈参照モード(T3)、
  --xlate-mask プレビュー(T3h)、F1(T4)、F2(T5)、プロンプト例
  (T6)、POD/レシピ(T7)— 仕様の全節に対応
- 逸脱の明示: maskfile(旧経路)の文脈適用は行わない(参照モードが
  無い)— T3 で仕様書を修正し、コミットに記録する
- 型整合: `add_rule($tag,$pattern)` / `file_rules(\@rules)` /
  `mask_reference(@aliases)` / `extract_marks($text,$regex)->\@rules` /
  `load_anonymize_file($path)` を T1/T2 で定義し T3/T5 が消費。
  `template_regex()` を T4 で定義し llm.pm が消費
- スタブ llm の uc 特性を利用: 日本語式は保全がそのまま、ASCII 式は
  変形されて F1 の負系になる(新スタブモード不要)
- T1 Step 1 のテストには書き誤り防止の注記を含めた(実装者は注記
  どおり最終形のアサーションで作成する)
