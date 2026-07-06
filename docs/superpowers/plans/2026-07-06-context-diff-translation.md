# 文脈つき差分翻訳 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 変更段落の再翻訳時に周辺原文スライス・周辺対訳・変更前の旧対訳を LLM に渡し(ギャップ領域単位)、あわせてキャッシュ種付け・逐次書き出し・accumulate 修正・dryrun 警告修正・ローダ修正を行う。

**Architecture:** postgrep が順序つきマッチ列から連続ミス列(ギャップ領域)を作り、領域ごとに文脈(Cache の旧順序リストからの挟み撃ち・キャッシュの対訳・文書バッファの生スライス)を組み立てて `$call_context` 経由でエンジンに渡す。llm.pm の `build_system` が文脈 3 節をレンダリングし、優先度つき切り詰めで上限内に収める。文脈対応エンジンは `our $XLATE_CONTEXT = 1` を宣言し、未対応エンジン(gpty/deepl/null)は従来フローのまま。

**Tech Stack:** Perl (v5.14+)、既存依存のみ(JSON, Command::Run, List::Util, Hash::Util)。テストはスタブ llm(t/bin/llm、API 費用ゼロ)。

**Spec:** docs/superpowers/specs/2026-07-06-context-aware-diff-translation-design.md

## Global Constraints

- **インデントにタブを使わない** — スペースのみ(CLAUDE.md Coding Style。旧タブは 8 桁展開済み)
- 全ファイルは必ず改行で終わること(末尾は単一の改行)
- 新規 Perl 依存を追加しない
- `lib/App/Greple/xlate/gpty/` 配下、`deepl.pm`、`null.pm`、`Text.pm`、`Mask.pm` には触らない
- gpty/deepl/null エンジンの動作(呼び出し回数・ペイロード)を変えない
- `$VERSION` は変更しない
- 既存テスト(10 ファイル 75 個)が全て通り続けること
- 内部定数: `$CONTEXT_SOURCE_MAX = 2000`(スライス片側上限)、`$CONTEXT_MAX = 8000`(文脈合計上限)、`$CONTEXT_SOURCE_MIN = 500`(切り詰め時のスライス下限)
- オプション既定値: `--xlate-context-window` は 2
- git コミットメッセージ末尾に以下の 2 行を付ける:
  ```
  Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_015Wte6DCZZAEjT7zEboeDid
  ```

## 前提知識(全タスク共通)

- キャッシュは tie されたハッシュ `%cache`(実体 `App::Greple::xlate::Cache`)。
  tied オブジェクトへは `tied %cache` でアクセスする
- `exists $cache{$key}` / `$cache{$key}` は access() を呼び、キーを
  `accessed`/`order` に記録する。FETCH は saved → current へ移動する
- **dryrun 警告の根本原因**: postgrep がミスに `$cache{$key} = undef` を
  STORE すると `updated` が増え、update() は undef 値を current から
  削除するが `order` にはキーが残るため、list_data() が
  `warn "$key: not in cache."`(Cache.pm:164)を出す
- postgrep のマッチ `$m = [$s, $e, $i]`(開始・終了オフセット、
  パターン番号)。`$grep->cut(@$m)` でテキストを取得。begin() では
  `$_` が文書全体(末尾改行補正後)

---

### Task 1: Cache.pm — 旧リスト順序の保持と参照 API、dryrun 警告修正

**Files:**
- Modify: `lib/App/Greple/xlate/Cache.pm`
- Test: `t/12_cache.t`(新規)

**Interfaces:**
- Produces:
  - `$obj->old_position($key)` → 旧リスト内の位置(0 起点)。無ければ undef
  - `$obj->old_size` → 旧リストの要素数
  - `$obj->old_entries_slice($lo, $hi)` → 旧リストの `[$key, $value]` の
    リスト(範囲はクランプ、値が undef のものは除く。値は
    `saved->{k} // current->{k}` — FETCH 済みでも取れる)
  - `list_data()` は値のないキーを **warn せず黙ってスキップ**する
  - `load_data($json_text)` — open() から切り出した読み込み共通部
    (Task 3 の seed が再利用)

- [ ] **Step 1: 失敗するテストを書く**

`t/12_cache.t` を以下の内容で作成:

```perl
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
```

- [ ] **Step 2: テストを実行して失敗を確認**

Run: `prove -l t/12_cache.t`
Expected: FAIL — `Can't locate object method "old_size"`

- [ ] **Step 3: Cache.pm を修正**

(a) `%default` に 1 行追加(`saved => undef,` の下):

```perl
    saved_order => [],  # keys of saved data in file order
```

(b) `open` メソッドを以下に置き換え、`load_data` を新設
(現在の open は JSON 読み込みを内包している):

```perl
sub open {
    my $obj = shift;
    my $file = $obj->name || return;
    if ($obj->clear) {
        warn "created $file\n" unless -f $file;
        CORE::open my $fh, '>', $file or die "$file: $!\n";
        print $fh "{}\n";
    }
    $obj->{saved} = {};
    $obj->{saved_order} = [];
    if (CORE::open my $fh, $file) {
        my $data = do { local $/; <$fh> };
        $obj->load_data($data) if $data ne '';
        warn "read cache from $file\n";
    }
    $obj;
}

sub load_data {
    my($obj, $data) = @_;
    my $json = &json->decode($data);
    if (ref $json eq 'HASH') {
        $obj->{saved} = $json;
        $obj->{saved_order} = [];   # legacy format: no order info
    } elsif (ref $json eq 'ARRAY') {
        $obj->{saved} = +{ map @{$_}[0,1], @$json };
        $obj->{saved_order} = [ map $_->[0], @$json ];
    } else {
        die "unexpected json data.";
    }
}
```

(c) 参照 API を追加(`load_data` の下):

```perl
sub old_size {
    my $obj = shift;
    scalar @{$obj->saved_order};
}

sub old_position {
    my($obj, $key) = @_;
    my $pos = $obj->{old_pos} //= do {
        my $order = $obj->saved_order;
        +{ map { $order->[$_] => $_ } 0 .. $#$order };
    };
    $pos->{$key};
}

sub old_entries_slice {
    my($obj, $lo, $hi) = @_;
    my $order = $obj->saved_order;
    $lo = 0 if $lo < 0;
    $hi = $#$order if $hi > $#$order;
    my @out;
    for my $k (@$order[$lo .. $hi]) {
        my $v = $obj->saved->{$k} // $obj->current->{$k};
        push @out, [ $k, $v ] if defined $v;
    }
    @out;
}
```

`old_pos` はメモ化キャッシュなので `%default` にも追加する:

```perl
    old_pos => undef,   # memoized key-to-position map of saved_order
```

(d) `list_data` の warn を黙ったスキップに変更:

```perl
    for my $key (@{$obj->order}) {
        next unless exists $hash{$key};
        push @list, [ $key => delete $hash{$key} ];
    }
```

(現在の `warn "$key: not in cache.";` を含む if/else を上記に置き換える。
続く `not in order list` の warn は内部不整合の検出なので残す)

- [ ] **Step 4: テストを実行して通ることを確認**

Run: `prove -l t/12_cache.t`
Expected: PASS(3 subtests)

- [ ] **Step 5: 回帰確認**

Run: `prove -l t/`
Expected: 全 PASS

- [ ] **Step 6: コミット**

```bash
git add lib/App/Greple/xlate/Cache.pm t/12_cache.t
git commit -m "feat: retain old cache list order with query API; silence dryrun warning"
```

---

### Task 2: Cache.pm — checkpoint 書き出しと accumulate 修正

**Files:**
- Modify: `lib/App/Greple/xlate/Cache.pm`
- Test: `t/12_cache.t`(追記)

**Interfaces:**
- Consumes: Task 1 の `saved_order` / `load_data`
- Produces:
  - `$obj->checkpoint` — saved∪current(current 優先)を **purge せず**
    list 形式で書き出す。順序は「saved_order → 新規キー(アクセス順)→
    legacy 残り(ソート順)」。ファイル名が無ければ何もしない
  - `update()` の accumulate: 未使用エントリを無条件に保持(POD の約束
    通り)。`updated == 0` なら書き出し省略(ディスク内容が変わらないため)

- [ ] **Step 1: 失敗するテストを追記**

`t/12_cache.t` の `done_testing;` の前に追加:

```perl
subtest 'checkpoint keeps unused entries (no purge)' => sub {
    my $file = "$dir/ckpt.json";
    write_json($file, \@PAIRS);
    my $c = App::Greple::xlate::Cache->new(name => $file);
    # src2 だけアクセスし、新規 1 件を格納
    $c->access("src2\n"); $c->get("src2\n");
    $c->access("new1\n"); $c->set("new1\n" => "NEW1\n");
    $c->checkpoint;
    my $data = read_json($file);
    is_deeply($data,
              [ @PAIRS, [ "new1\n" => "NEW1\n" ] ],
              'checkpoint: all old entries in order + new appended');
    # 最終書き出しは従来通り purge する
    $c->update;
    $data = read_json($file);
    is_deeply($data,
              [ $PAIRS[1], [ "new1\n" => "NEW1\n" ] ],
              'final update still purges unused entries');
    $c->name = '';
};

subtest 'accumulate keeps unused entries even with new translations' => sub {
    my $file = "$dir/accum.json";
    write_json($file, \@PAIRS);
    my $c = App::Greple::xlate::Cache->new(name => $file, accumulate => 1);
    $c->access("src2\n"); $c->get("src2\n");                  # 使用
    $c->access("new1\n"); $c->set("new1\n" => "NEW1\n");      # 新規翻訳あり
    $c->update;
    my $data = read_json($file);
    my %got = map @$_, @$data;
    is(scalar @$data, 6, 'accumulate: all 5 old + 1 new survive');
    is($got{"src4\n"}, "trans4\n", 'unused old entry survived');
    is($got{"new1\n"}, "NEW1\n", 'new entry saved');
    $c->name = '';
};

subtest 'accumulate with no changes skips rewrite' => sub {
    my $file = "$dir/accum2.json";
    write_json($file, \@PAIRS);
    my $mtime_probe = "$dir/probe";
    my $c = App::Greple::xlate::Cache->new(name => $file, accumulate => 1);
    $c->access("src1\n"); $c->get("src1\n");
    my @warn;
    {
        local $SIG{__WARN__} = sub { push @warn, $_[0] };
        $c->update;
    }
    ok(!(grep { /write cache/ } @warn), 'no rewrite when nothing changed');
    $c->name = '';
};
```

- [ ] **Step 2: テストを実行して失敗を確認**

Run: `prove -l t/12_cache.t`
Expected: FAIL — `Can't locate object method "checkpoint"`

- [ ] **Step 3: 実装**

(a) `checkpoint` を追加(`update` の下):

```perl
##
## Write out the merged state (saved and current, current wins)
## WITHOUT purging unused entries.  Called after each translation
## batch so that an interrupted run does not lose paid API results.
## The final write (update) keeps the purging semantics.
##
sub checkpoint {
    my $obj = shift;
    my $file = $obj->name || return;
    my(@list, %done);
    for my $key (@{$obj->saved_order}) {
        next if $done{$key}++;
        my $v = $obj->current->{$key} // $obj->saved->{$key};
        push @list, [ $key => $v ] if defined $v;
    }
    for my $key (@{$obj->order}) {
        next if $done{$key}++;
        my $v = $obj->current->{$key};
        push @list, [ $key => $v ] if defined $v;
    }
    for my $key (sort keys %{$obj->saved}) {   # legacy HASH caches
        next if $done{$key}++;
        my $v = $obj->saved->{$key};
        push @list, [ $key => $v ] if defined $v;
    }
    if (CORE::open my $fh, '>', $file) {
        print $fh &json->encode(\@list);
    } else {
        warn "$file: $!\n";
    }
}
```

(b) `update` の冒頭ブロックを置き換え。現在:

```perl
    if (not $obj->force_update and $obj->updated == 0) {
        if (%{$obj->saved} == 0) {
            return;
        } elsif ($obj->accumulate) {
            for (keys %{$obj->saved}) {
                $obj->current->{$_} //= delete $obj->saved->{$_};
            }
        }
    }
```

新:

```perl
    if (not $obj->force_update and $obj->updated == 0) {
        # accumulate: nothing changed, disk content is already right.
        # otherwise: return only when there is nothing to purge.
        return if $obj->accumulate or %{$obj->saved} == 0;
    }
    if ($obj->accumulate) {
        # POD promises unused entries survive: adopt them unconditionally
        for my $k (@{$obj->saved_order}, sort keys %{$obj->saved}) {
            next if $obj->accessed->{$k};
            defined(my $v = delete $obj->saved->{$k}) or next;
            $obj->current->{$k} //= $v;
            $obj->access($k);
        }
    }
```

(旧コードの「新規翻訳が 1 件でもあると accumulate でも未使用エントリが
消える」動作がこれで直る。未使用エントリは saved_order 順で order 末尾に
足されるので、legacy HASH 由来でも `not in order list` の warn は出ない)

- [ ] **Step 4: テストを実行して通ることを確認**

Run: `prove -l t/12_cache.t`
Expected: PASS(6 subtests)

- [ ] **Step 5: 回帰確認とコミット**

Run: `prove -l t/`
Expected: 全 PASS

```bash
git add lib/App/Greple/xlate/Cache.pm t/12_cache.t
git commit -m "feat: add cache checkpoint write; honor accumulate promise"
```

---

### Task 3: キャッシュ種付け(--xlate-cache-seed)

**Files:**
- Modify: `lib/App/Greple/xlate/Cache.pm`(seed 読み込み)
- Modify: `lib/App/Greple/xlate.pm`(%opt・builtin・begin の 3 箇所)
- Test: `t/12_cache.t`(追記)

**Interfaces:**
- Consumes: Task 1 の `load_data`
- Produces:
  - `App::Greple::xlate::Cache->new(name => ..., seed => $path)` —
    対象キャッシュに saved エントリが無いときだけ seed ファイルを読み込む。
    有るときは `warn "<seed>: seed ignored (cache exists)\n"`
  - `$obj->seeded` — seed が適用されたら真。update() は seeded なら
    updated == 0 でも書き出す(新文書のキャッシュを実体化する)
  - xlate.pm: `--xlate-cache-seed=FILE`(`our $cache_seed`、%opt キー
    `cache_seed`)。begin() が tie 時に `seed => $cache_seed` を渡す

- [ ] **Step 1: 失敗するテストを追記**

`t/12_cache.t` の `done_testing;` の前に追加:

```perl
subtest 'seeding an empty cache' => sub {
    my $seed_file = "$dir/seed-src.json";
    write_json($seed_file, \@PAIRS);
    my $file = "$dir/seeded.json";
    write_json($file, []);          # 空のキャッシュ(saved なし)

    my $c = App::Greple::xlate::Cache->new(name => $file, seed => $seed_file);
    ok($c->seeded, 'seeded flag set');
    is($c->old_size, 5, 'seed entries loaded with order');
    is($c->get("src1\n"), "trans1\n", 'seeded value readable');

    # 全ヒット・新規なしでも update が対象ファイルへ書き出す
    $c->access($_) , $c->get($_) for map $_->[0], @PAIRS;
    $c->update;
    my $data = read_json($file);
    is_deeply($data, \@PAIRS, 'seeded content persisted to target cache');
    $c->name = '';
};

subtest 'seed ignored when cache has entries' => sub {
    my $seed_file = "$dir/seed-src2.json";
    write_json($seed_file, [ [ "other\n" => "OTHER\n" ] ]);
    my $file = "$dir/nonempty.json";
    write_json($file, [ $PAIRS[0] ]);
    my @warn;
    {
        local $SIG{__WARN__} = sub { push @warn, $_[0] };
        my $c = App::Greple::xlate::Cache->new(name => $file,
                                               seed => $seed_file);
        ok(!$c->seeded, 'seeded flag not set');
        is($c->old_position("other\n"), undef, 'seed content not loaded');
        $c->name = '';
    }
    ok((grep { /seed ignored/ } @warn), 'warned about ignored seed');
};
```

- [ ] **Step 2: テストを実行して失敗を確認**

Run: `prove -l t/12_cache.t`
Expected: FAIL — `seed: Invalid ...`(lock_keys により未知キーで die)

- [ ] **Step 3: Cache.pm に seed を実装**

(a) `%default` に追加:

```perl
    seed => undef,      # seed cache file for a fresh cache
    seeded => 0,        # true when the seed was actually loaded
```

(b) `open` の `warn "read cache from $file\n";` を含む if ブロックの
**後**(`$obj;` の前)に追加:

```perl
    if (my $seed = $obj->seed) {
        if (%{$obj->saved}) {
            warn "$seed: seed ignored (cache exists)\n";
        } elsif (CORE::open my $fh, $seed) {
            my $data = do { local $/; <$fh> };
            if ($data ne '') {
                $obj->load_data($data);
                $obj->seeded = 1;
                warn "seed cache from $seed\n";
            }
        } else {
            warn "$seed: $!\n";
        }
    }
```

(c) `update` の書き出し省略条件に seeded を加える(Task 2 で入れた行):

```perl
        return if $obj->accumulate or %{$obj->saved} == 0;
```

を

```perl
        return if not $obj->seeded and ($obj->accumulate or %{$obj->saved} == 0);
```

に変更(種付け直後の全ヒット実行でも対象キャッシュを実体化する)。

- [ ] **Step 4: xlate.pm にオプションを追加**

(a) `%opt` 定義(`contexts => (\our @contexts),` の前)に追加:

```perl
    cache_seed => \(our $cache_seed),
```

(b) `__DATA__` の builtin 宣言(`builtin xlate-context=s    @contexts`
の下)に追加:

```
builtin xlate-cache-seed=s $cache_seed
```

(c) `begin()` の tie オプション組み立て(`if ($force_update) {...}` の
後)に追加:

```perl
        if (defined $cache_seed) {
            push @opt, seed => $cache_seed;
        }
```

- [ ] **Step 5: テストを実行して通ることを確認**

Run: `prove -l t/12_cache.t && prove -l t/`
Expected: 全 PASS

- [ ] **Step 6: コミット**

```bash
git add lib/App/Greple/xlate/Cache.pm lib/App/Greple/xlate.pm t/12_cache.t
git commit -m "feat: add --xlate-cache-seed to initialize a cache from another document"
```

---

### Task 4: ローダの require エラー握りつぶし修正

**Files:**
- Modify: `lib/App/Greple/xlate.pm`(setup 内ローダループ)
- Test: `t/09_llm_loader.t`(追記)

**Interfaces:**
- Consumes: なし(独立)
- Produces: エンジン候補の require が「その候補自身が見つからない」以外の
  理由で失敗したら die してエラーを見せる(構文エラー・内部依存欠如は
  フォールバックしない)

- [ ] **Step 1: 失敗するテストを追記**

`t/09_llm_loader.t` の `done_testing;` の前に追加:

```perl
use File::Temp qw(tempdir);
use File::Path qw(make_path);

subtest 'engine compile errors are not swallowed' => sub {
    my $fixdir = tempdir(CLEANUP => 1);
    make_path("$fixdir/App/Greple/xlate/llm");
    open my $fh, '>', "$fixdir/App/Greple/xlate/llm/broken.pm" or die $!;
    print $fh "package App::Greple::xlate::llm::broken;\nthis is not perl ((\n1;\n";
    close $fh;

    my $r = Command::Run->new
        ->command($^X, '-Ilib', "-I$fixdir", '-e', $probe, 'broken')
        ->run(stderr => 'capture');
    isnt($r->{result}, 0, 'broken engine fails');
    like($r->{error}, qr/broken\.pm/, 'error names the broken module');
    unlike($r->{error}, qr/not available/,
           'did not fall through to "not available"');
};
```

(既存の `my $probe = <<'END';` と `sub probe` はそのまま使う。probe は
`-Ilib` 固定なので、このサブテストだけ Command::Run を直接使い
`-I$fixdir` を追加している)

- [ ] **Step 2: テストを実行して失敗を確認**

Run: `prove -l t/09_llm_loader.t`
Expected: FAIL — 現状はコンパイルエラーが握りつぶされ、bare 名まで
フォールバックして `not available` で die するため
`error names the broken module` が落ちる

- [ ] **Step 3: ローダを修正**

`lib/App/Greple/xlate.pm` setup() 内の候補ループ。現在:

```perl
        my $mod;
        for my $cand ((map __PACKAGE__ . "::$_\::$xlate_engine", @backend),
                      __PACKAGE__ . "::$xlate_engine") {
            if (eval "require $cand; 1") { $mod = $cand; last }
        }
```

新:

```perl
        my $mod;
        for my $cand ((map __PACKAGE__ . "::$_\::$xlate_engine", @backend),
                      __PACKAGE__ . "::$xlate_engine") {
            if (eval "require $cand; 1") { $mod = $cand; last }
            # Fall through only when the candidate itself is missing;
            # a syntax error or a missing dependency inside an existing
            # module must be reported, not silently skipped.
            (my $path = $cand) =~ s{::}{/}g;
            die $@ unless $@ =~ /^Can't locate \Q$path.pm\E /;
        }
```

- [ ] **Step 4: テストを実行して通ることを確認**

Run: `prove -l t/09_llm_loader.t && prove -l t/`
Expected: 全 PASS(既存の resolution テスト・unknown engine テスト含む)

- [ ] **Step 5: コミット**

```bash
git add lib/App/Greple/xlate.pm t/09_llm_loader.t
git commit -m "fix: do not swallow engine compile errors in the loader"
```

---

### Task 5: postgrep のギャップ領域化と配管

**Files:**
- Modify: `lib/App/Greple/xlate.pm`(postgrep / cache_update / begin /
  setup / %opt / builtin)
- Modify: `lib/App/Greple/xlate/llm/gpt5.pm`(`$XLATE_CONTEXT` フラグ 1 行)
- Test: `t/11_llm_context.t`(新規、最小)

**Interfaces:**
- Consumes: Task 2 の `checkpoint`
- Produces:
  - `cache_update(\%region)` — `{ texts => \@keys, context => \%ctx|undef }`
    を受ける。XLATE 呼び出しの間 `local $call_context = $context`
  - `our $call_context`(xlate.pm)— エンジンが読む文脈ハッシュ(または undef)
  - `our $engine_supports_context` — setup() がエンジンの
    `$XLATE_CONTEXT` から設定
  - `our $context_window = 2`(%opt キー `context_window`、
    builtin `xlate-context-window=i`)
  - `$current_text`(ファイルスコープ my)— begin() が文書全体を保持
  - `region_context(\@blocks, $from, $to)` — このタスクでは
    **undef を返すスタブ**(Task 6 で実装)
  - gpt5 エンジンは `our $XLATE_CONTEXT = 1;` を宣言

- [ ] **Step 1: 失敗するテストを書く**

`t/11_llm_context.t` を以下の内容で作成:

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

done_testing;
```

- [ ] **Step 2: テストを実行して現状の挙動を確認**

Run: `prove -l t/11_llm_context.t`
Expected: PASS の可能性が高い(従来フローでも 1 ミス = 1 呼び出しのため)。
これはこのタスクが**挙動を保つ配管**であることの確認になる。失敗する場合は
原因を調べてから進むこと。

- [ ] **Step 3: xlate.pm を改修**

(a) `%opt` 定義に追加(Task 3 の `cache_seed` の下):

```perl
    context_window => \(our $context_window = 2),
```

(b) `__DATA__` builtin に追加(`builtin xlate-cache-seed=s` の下):

```
builtin xlate-context-window=i $context_window
```

(c) 変数宣言。`my $current_file;`(612 行付近)の直後に追加:

```perl
my $current_text;              # whole document, set in begin()
our $call_context;             # per-call context for context-aware engines
our $engine_supports_context;  # engine declares $XLATE_CONTEXT
```

(d) setup() のエンジン束縛部。`*XLATE = \&{"$mod\::xlate"};` の直後
(同じ `no strict 'refs'` ブロック内)に追加:

```perl
        $engine_supports_context = ${"$mod\::XLATE_CONTEXT"};
```

(e) begin() の `s/\z/\n/ if /.\z/;` の直後に追加:

```perl
    $current_text = $_;
```

(f) postgrep を以下に置き換え:

```perl
sub postgrep {
    my $grep = shift;
    my @blocks;
    for my $r ($grep->result) {
        my($b, @match) = @$r;
        for my $m (@match) {
            my($s, $e, $i) = @$m;
            my $key = App::Greple::xlate::Text
                ->new($grep->cut(@$m), paragraph => ($i % 2 == 0))
                ->normalized;
            my $hit = exists $cache{$key};
            $cache{$key} = undef if not $hit;
            push @blocks, { key => $key, s => $s, e => $e, hit => $hit };
        }
    }
    my @regions;
    my $i = 0;
    while ($i < @blocks) {
        if ($blocks[$i]{hit}) { $i++; next }
        my $j = $i;
        $j++ while $j < @blocks and not $blocks[$j]{hit};
        push @regions, [ $i, $j - 1 ];
        $i = $j;
    }
    return if not @regions;
    my $with_context = $engine_supports_context
        && $context_window > 0
        && grep { $_->{hit} } @blocks;
    if ($with_context) {
        for my $region (@regions) {
            my %seen;
            my @texts = grep { not $seen{$_}++ }
                        map $blocks[$_]{key}, $region->[0] .. $region->[1];
            cache_update({
                texts   => \@texts,
                context => region_context(\@blocks, @$region),
            });
        }
    } else {
        my %seen;
        my @texts = grep { not $seen{$_}++ }
                    map $blocks[$_]{key},
                    map { $_->[0] .. $_->[1] } @regions;
        cache_update({ texts => \@texts, context => undef });
    }
}

##
## Build the per-region context (surrounding source slices, neighbor
## pairs, previous-version pairs).  Implemented in the next task.
##
sub region_context {
    return undef;
}
```

(g) cache_update を以下に置き換え(従来のフラット引数も受ける):

```perl
sub cache_update {
    binmode STDERR, ':encoding(utf8)';

    my $region = ref $_[0] eq 'HASH' ? shift : { texts => [ @_ ] };
    my @from = @{$region->{texts}};
    my $context = $region->{context};

    if ($context) {
        my $refs = @{$context->{hits_before} // []}
                 + @{$context->{hits_after} // []};
        my $olds = @{$context->{old_pairs} // []};
        _progress({label => "Context"},
                  sprintf("%d reference pair(s), %d previous pair(s)",
                          $refs, $olds));
        warn Dumper $context if opt('debug');
    }
    _progress({label => "From"}, @from);
    return @from if $dryrun;

    $maskobj->mask(@from) if $maskobj;
    my @chop = grep { $from[$_] =~ s/(?<!\n)\z/\n/ } keys @from;
    my @to = do {
        local $call_context = $context;
        map { s/ +$//mgr } &XLATE(@from);
    };
    chop @to[@chop];
    $maskobj->unmask(@to)->reset if $maskobj;

    _progress({label => "To"}, @to);
    die "Unmatched response:\n@to" if @from != @to;
    @cache{@{$region->{texts}}} = @to;
    if (my $obj = tied %cache) {
        $obj->checkpoint;
    }
}
```

(h) xlate.pm 冒頭の use 群に `use Data::Dumper;` が無ければ追加する
(確認: `grep -n 'use Data::Dumper' lib/App/Greple/xlate.pm`)。

- [ ] **Step 4: gpt5 エンジンにフラグを追加**

`lib/App/Greple/xlate/llm/gpt5.pm` の
`our $method = __PACKAGE__ =~ s/.*://r;` の直後に追加:

```perl
our $XLATE_CONTEXT = 1;     # consumes $App::Greple::xlate::call_context
```

- [ ] **Step 5: テストを実行して通ることを確認**

Run: `prove -l t/11_llm_context.t && prove -l t/`
Expected: 全 PASS(t/10 の全ミス系は fallback 経路で従来と同一挙動)

- [ ] **Step 6: コミット**

```bash
git add lib/App/Greple/xlate.pm lib/App/Greple/xlate/llm/gpt5.pm t/11_llm_context.t
git commit -m "feat: translate cache misses per gap region with context plumbing"
```

---

### Task 6: 文脈の組み立てとプロンプトへのレンダリング

**Files:**
- Modify: `lib/App/Greple/xlate.pm`(region_context 本実装 + スライス)
- Modify: `lib/App/Greple/xlate/llm.pm`(context_sections + build_system)
- Test: `t/11_llm_context.t`(追記)

**Interfaces:**
- Consumes: Task 1 の `old_position`/`old_size`/`old_entries_slice`、
  Task 5 の `@blocks` 構造(`{key, s, e, hit}`)と `$call_context`
- Produces:
  - `region_context(\@blocks, $from, $to)` → スペック通りのハッシュ:
    `{ source_before, source_after, hits_before, hits_after, old_pairs }`
    (hits_* は近い順の `[src, trans]`、old_pairs は文書順)
  - `App::Greple::xlate::llm::context_sections()` → `$call_context` から
    文脈 3 節のテキスト(空なら '')。`$CONTEXT_MAX` 超過時は
    「遠フランク → スライス縮小(500 字まで)→ 近フランク → old_pairs 端」
    の順で切り詰め
  - `build_system` は既存の組み立ての後に `context_sections()` を連結

- [ ] **Step 1: 失敗するテストを追記**

`t/11_llm_context.t` の `done_testing;` の前に追加:

```perl
subtest 'context sections appear in the system prompt' => sub {
    # 前 subtest の続き: 現キャッシュは beta 改訂版を含む
    (my $mod = $DOC) =~ s/beta paragraph original/beta paragraph rerevised/;
    write_file($doc, $mod);
    my $log = "$dir/context.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($doc);
    is($r->status, 0, 'run succeeds');
    my @calls = stub_calls($log);
    is(scalar @calls, 1, 'one llm call');
    my $sys = sys_of($calls[0]);

    like($sys, qr/Surrounding document source/, 'source slice section');
    like($sys, qr/## SECTION ONE/, 'slice contains non-translated heading');
    like($sys, qr/\Q[...]\E/, 'slice has the passage marker');

    like($sys, qr/Reference translations/, 'reference section');
    like($sys, qr/alpha paragraph original text/, 'neighbor source');
    like($sys, qr/ALPHA PARAGRAPH ORIGINAL TEXT/, 'neighbor translation');

    like($sys, qr/Previous version of the passage/, 'previous section');
    like($sys, qr/beta paragraph revised text/, 'old source pair');
    like($sys, qr/BETA PARAGRAPH REVISED TEXT/, 'old translation pair');

    like($r->stdout, qr/BETA PARAGRAPH REREVISED TEXT/, 'output updated');
};

subtest 'truncation drops far flanks first' => sub {
    require App::Greple::xlate::llm;
    my $big = "x" x 3000;
    local $App::Greple::xlate::call_context = {
        source_before => "line before\n",
        source_after  => "line after\n",
        hits_before   => [ [ "near b\n", "NEAR B\n" ],
                           [ "$big\n",   "FAR B\n"  ] ],
        hits_after    => [ [ "near a\n", "NEAR A\n" ],
                           [ "$big\n",   "FAR A\n"  ] ],
        old_pairs     => [ [ "old src\n", "OLD TRANS\n" ] ],
    };
    my $text = App::Greple::xlate::llm::context_sections();
    cmp_ok(length($text), '<=', $App::Greple::xlate::llm::CONTEXT_MAX,
           'within limit');
    like($text, qr/NEAR B/, 'near flank kept');
    like($text, qr/NEAR A/, 'near flank kept (after)');
    unlike($text, qr/FAR B/, 'far flank dropped');
    like($text, qr/OLD TRANS/, 'old pair survives truncation');
};

subtest 'empty context renders nothing' => sub {
    local $App::Greple::xlate::call_context = undef;
    is(App::Greple::xlate::llm::context_sections(), '', 'undef context');
};
```

- [ ] **Step 2: テストを実行して失敗を確認**

Run: `prove -l t/11_llm_context.t`
Expected: FAIL — `context_sections` 未定義、および system プロンプトに
文脈節が無い

- [ ] **Step 3: xlate.pm に region_context と slice を実装**

Task 5 で置いたスタブ `region_context` を以下に置き換え、直後に
slice 関数 2 つと定数を追加:

```perl
our $CONTEXT_SOURCE_MAX = 2000;   # per-side raw source slice limit

sub region_context {
    my($blocks, $from, $to) = @_;
    my(@before, @after);
    for (my $k = $from - 1; $k >= 0 and @before < $context_window; $k--) {
        next unless $blocks->[$k]{hit};
        my $v = $cache{$blocks->[$k]{key}};
        push @before, [ $blocks->[$k]{key}, $v ] if defined $v;
    }
    for (my $k = $to + 1; $k < @$blocks and @after < $context_window; $k++) {
        next unless $blocks->[$k]{hit};
        my $v = $cache{$blocks->[$k]{key}};
        push @after, [ $blocks->[$k]{key}, $v ] if defined $v;
    }
    my @old;
    if (my $tied = tied %cache) {
        my %is_hit = map { $_->{key} => 1 } grep { $_->{hit} } @$blocks;
        my($lo, $hi);
        for (my $k = $from - 1; $k >= 0; $k--) {
            next unless $blocks->[$k]{hit};
            my $pos = $tied->old_position($blocks->[$k]{key});
            if (defined $pos) { $lo = $pos + 1; last }
        }
        for (my $k = $to + 1; $k < @$blocks; $k++) {
            next unless $blocks->[$k]{hit};
            my $pos = $tied->old_position($blocks->[$k]{key});
            if (defined $pos) { $hi = $pos - 1; last }
        }
        $lo //= 0;
        $hi //= $tied->old_size - 1;
        @old = grep { not $is_hit{$_->[0]} }
               $tied->old_entries_slice($lo, $hi);
    }
    return {
        source_before => source_slice_before($blocks->[$from]{s}),
        source_after  => source_slice_after($blocks->[$to]{e}),
        hits_before   => \@before,
        hits_after    => \@after,
        old_pairs     => \@old,
    };
}

sub source_slice_before {
    my $end = shift;
    return '' unless defined $current_text and $end > 0;
    my $start = $end - $CONTEXT_SOURCE_MAX;
    $start = 0 if $start < 0;
    my $s = substr($current_text, $start, $end - $start);
    $s =~ s/\A[^\n]*\n// if $start > 0;    # round up to a line start
    $s;
}

sub source_slice_after {
    my $start = shift;
    return '' unless defined $current_text
        and $start < length($current_text);
    my $s = substr($current_text, $start, $CONTEXT_SOURCE_MAX);
    if ($start + $CONTEXT_SOURCE_MAX < length($current_text)) {
        $s =~ s/(?<=\n)[^\n]*\z//;         # drop trailing partial line
    }
    $s;
}
```

- [ ] **Step 4: llm.pm に context_sections を実装**

(a) `my $json = JSON->new->canonical->pretty;` の下に追加:

```perl
my $json_flat = JSON->new->canonical;

our $CONTEXT_MAX = 8000;          # total rendered context limit
our $CONTEXT_SOURCE_MIN = 500;    # slice floor while truncating
```

(b) `build_system` の `$system;`(返り値)の直前に追加:

```perl
    $system .= context_sections();
```

(c) `build_system` の直後に追加:

```perl
sub _pairs_json {
    $json_flat->encode(
        [ map { +{ source => $_->[0], translation => $_->[1] } } @_ ]);
}

##
## Render the three context sections from $call_context, trimming to
## $CONTEXT_MAX in the spec's priority order: far flank pairs, source
## slices (down to $CONTEXT_SOURCE_MIN per side), near flank pairs,
## then old pairs from the far end.
##
sub context_sections {
    my $ctx = $App::Greple::xlate::call_context or return '';
    my @before = @{$ctx->{hits_before} // []};   # near to far
    my @after  = @{$ctx->{hits_after}  // []};   # near to far
    my @old    = @{$ctx->{old_pairs}   // []};   # document order
    my $sb = $ctx->{source_before} // '';
    my $sa = $ctx->{source_after}  // '';

    my $render = sub {
        my $out = '';
        if (length $sb or length $sa) {
            $out .= "\n\nSurrounding document source, shown for context only.\n"
                  . "Do NOT translate or output any of it. The passage you will be\n"
                  . "asked to translate sits at the [...] marker:\n"
                  . "$sb\[...]\n$sa";
        }
        if (@before or @after) {
            $out .= "\n\nReference translations from the surrounding document.\n"
                  . "Match their style, tone, and terminology:\n"
                  . _pairs_json(reverse(@before), @after);
        }
        if (@old) {
            $out .= "\n\nPrevious version of the passage you are about to translate\n"
                  . "(source and translation before the source was edited).\n"
                  . "Where the new source text is unchanged from this previous\n"
                  . "version, keep the previous translation's wording exactly;\n"
                  . "change only what the source changes require:\n"
                  . _pairs_json(@old);
        }
        $out;
    };

    my @trim = (
        sub {
            if    (@before > 1) { pop @before; 1 }
            elsif (@after  > 1) { pop @after;  1 }
            else  { 0 }
        },
        sub {
            if (length($sb) > $CONTEXT_SOURCE_MIN) {
                $sb = substr($sb, -$CONTEXT_SOURCE_MIN);
                $sb =~ s/\A[^\n]*\n//;
                return 1;
            }
            if (length($sa) > $CONTEXT_SOURCE_MIN) {
                $sa = substr($sa, 0, $CONTEXT_SOURCE_MIN);
                $sa =~ s/(?<=\n)[^\n]*\z//;
                return 1;
            }
            0;
        },
        sub {
            if    (@before) { pop @before; 1 }
            elsif (@after)  { pop @after;  1 }
            else  { 0 }
        },
        sub { @old ? do { pop @old; 1 } : 0 },
    );
    my $text = $render->();
    STEP: for my $step (@trim) {
        while (length($text) > $CONTEXT_MAX) {
            $step->() or next STEP;
            $text = $render->();
        }
        last;
    }
    $text;
}
```

- [ ] **Step 5: テストを実行して通ることを確認**

Run: `prove -l t/11_llm_context.t && prove -l t/`
Expected: 全 PASS(t/07 の build_system テストは `$call_context` 未設定
なので影響なし)

- [ ] **Step 6: コミット**

```bash
git add lib/App/Greple/xlate.pm lib/App/Greple/xlate/llm.pm t/11_llm_context.t
git commit -m "feat: assemble gap-region context and render it into the system prompt"
```

---

### Task 7: 要素種別の慣習指示(プロンプト 1 文)

**Files:**
- Modify: `lib/App/Greple/xlate/llm/gpt5.pm`(prompt ヒアドキュメント)
- Test: `t/08_llm_gpt5.t`(追記)

**Interfaces:**
- Consumes: なし
- Produces: gpt5 のベースプロンプトに要素種別の慣習指示 1 文。
  **これにより gpty 版とのプロンプト同一性は意図的に崩れる**
  (仕様の「プロンプト構成」節に記録済みの承認事項。キャッシュのキーは
  原文なので既存キャッシュのヒットには影響しない)

- [ ] **Step 1: 失敗するテストを追記**

`t/08_llm_gpt5.t` の
`like($system, qr/XML-style marker tag/, 'mask tag instruction preserved');`
の直後に追加:

```perl
like($system, qr/conventions for that kind of element/,
     'element-type convention instruction present');
```

- [ ] **Step 2: テストを実行して失敗を確認**

Run: `prove -l t/08_llm_gpt5.t`
Expected: FAIL — 新しいアサーションのみ落ちる

- [ ] **Step 3: プロンプトに 1 文追加**

`lib/App/Greple/xlate/llm/gpt5.pm` の prompt ヒアドキュメント内、

```
If an element is a blank string or an XML-style marker tag (e.g., "<m id=1 />"), leave it unchanged and do not translate it.
```

の**直後**に次の行を追加:

```
If an element is a heading, list item, caption, or other structural element rather than body text, follow the target language's conventions for that kind of element (e.g. heading capitalization).
```

- [ ] **Step 4: テストを実行して通ることを確認**

Run: `prove -l t/08_llm_gpt5.t && prove -l t/`
Expected: 全 PASS

- [ ] **Step 5: コミット**

```bash
git add lib/App/Greple/xlate/llm/gpt5.pm t/08_llm_gpt5.t
git commit -m "feat: instruct llm to follow target-language element conventions"
```

---

### Task 8: 統合テストの完全化

**Files:**
- Test: `t/11_llm_context.t`(追記のみ。実装変更なし —
  テストが失敗したら実装のバグなので、勝手に実装へ回避策を入れず
  DONE_WITH_CONCERNS で報告すること)

**Interfaces:**
- Consumes: Task 1-7 の全成果

- [ ] **Step 1: シナリオテストを追記**

`t/11_llm_context.t` の `done_testing;` の前に追加:

```perl
subtest 'two distant changes make two isolated regions' => sub {
    # 状態リセット: 原文とキャッシュを作り直す
    write_file($doc, $DOC);
    write_file($cache, '');
    run_xlate($doc);
    (my $mod = $DOC) =~ s/alpha paragraph original/alpha paragraph revised/;
    $mod =~ s/delta paragraph original/delta paragraph revised/;
    write_file($doc, $mod);
    my $log = "$dir/distant.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($doc);
    is($r->status, 0, 'run succeeds');
    my @calls = stub_calls($log);
    is(scalar @calls, 2, 'two llm calls for two gaps');
    my($sys1, $sys2) = map sys_of($_), @calls;
    # Previous 節は最後の節なので、その見出し以降に何が居るかで判定する
    # (原文スライス節には他領域のテキストが正当に現れ得るため)
    like($sys1, qr/Previous version.*alpha paragraph original/s,
         'region 1 previous pair is alpha');
    unlike($sys1, qr/Previous version.*delta paragraph original/s,
           'region 1 does not carry delta as previous');
    like($sys2, qr/Previous version.*delta paragraph original/s,
         'region 2 previous pair is delta');
};

subtest 'consecutive changes form one region with both old pairs' => sub {
    write_file($doc, $DOC);
    write_file($cache, '');
    run_xlate($doc);
    (my $mod = $DOC) =~ s/beta paragraph original/beta paragraph revised/;
    $mod =~ s/gamma paragraph original/gamma paragraph revised/;
    write_file($doc, $mod);
    my $log = "$dir/consec.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($doc);
    my @calls = stub_calls($log);
    is(scalar @calls, 1, 'one llm call for adjacent misses');
    my $sys = sys_of($calls[0]);
    like($sys, qr/beta paragraph original/, 'old pair for beta');
    like($sys, qr/gamma paragraph original/, 'old pair for gamma');
    is_deeply(JSON::PP->new->decode($calls[0]{stdin}),
              [ "beta paragraph revised text\n",
                "gamma paragraph revised text\n" ],
              'both paragraphs in one payload');
};

subtest 'window=0 disables context and falls back to flat batch' => sub {
    write_file($doc, $DOC);
    write_file($cache, '');
    run_xlate($doc);
    (my $mod = $DOC) =~ s/gamma paragraph original/gamma paragraph revised/;
    write_file($doc, $mod);
    my $log = "$dir/nowin.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($doc, '--xlate-context-window=0');
    my @calls = stub_calls($log);
    is(scalar @calls, 1, 'one call');
    my $sys = sys_of($calls[0]);
    unlike($sys, qr/Reference translations/, 'no reference section');
    unlike($sys, qr/Surrounding document source/, 'no slice section');
};

subtest 'all-miss (fresh document) falls back without context' => sub {
    my $doc2 = "$dir/fresh.txt";
    write_file($doc2, $DOC);
    write_file("$doc2.xlate-gpt5-EN-US.json", '');
    my $log = "$dir/fresh.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($doc2);
    is($r->status, 0, 'run succeeds');
    my @calls = stub_calls($log);
    is(scalar @calls, 1, 'single flat batch');
    my $sys = sys_of($calls[0]);
    unlike($sys, qr/Reference translations/, 'no context sections');
};

subtest 'cache seeding carries pairs across documents' => sub {
    # doc.txt のキャッシュを整えてから、それを seed に新文書を翻訳
    write_file($doc, $DOC);
    write_file($cache, '');
    run_xlate($doc);
    (my $mod = $DOC) =~ s/beta paragraph original/beta paragraph seeded/;
    my $doc3 = "$dir/issue2.txt";
    my $cache3 = "$doc3.xlate-gpt5-EN-US.json";
    write_file($doc3, $mod);
    write_file($cache3, '');
    my $log = "$dir/seed.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($doc3, "--xlate-cache-seed=$cache");
    is($r->status, 0, 'seeded run succeeds');
    my @calls = stub_calls($log);
    is(scalar @calls, 1, 'only the changed paragraph is translated');
    my $sys = sys_of($calls[0]);
    like($sys, qr/beta paragraph original/, 'old pair comes from the seed');
    like($r->stdout, qr/ALPHA PARAGRAPH ORIGINAL TEXT/,
         'unchanged paragraphs come from the seed without API calls');

    # 2 回目: 対象キャッシュが実体化済みなので seed は無視される
    $mod =~ s/beta paragraph seeded/beta paragraph reseeded/;
    write_file($doc3, $mod);
    my $log2 = "$dir/seed2.log";
    local $ENV{LLM_STUB_LOG} = $log2;
    my $r2 = run_xlate($doc3, "--xlate-cache-seed=$cache");
    my @calls2 = stub_calls($log2);
    is(scalar @calls2, 1, 'second run: one call');
    my $sys2 = sys_of($calls2[0]);
    like($sys2, qr/beta paragraph seeded/,
         'previous pair comes from own cache, not the seed');
};
```

- [ ] **Step 2: テストを実行して通ることを確認**

Run: `prove -l t/11_llm_context.t`
Expected: PASS(全 subtests)。失敗した場合は実装バグとして原因を調べて
報告する(テスト側を実装に合わせて弱めない)

- [ ] **Step 3: フルスイート実行とコミット**

Run: `prove -l t/`
Expected: 全 PASS

```bash
git add t/11_llm_context.t
git commit -m "test: cover distant/consecutive gaps, window=0, all-miss, and seeding"
```

---

### Task 9: POD とドキュメントの更新、全体確認

**Files:**
- Modify: `lib/App/Greple/xlate.pm`(POD の OPTIONS 節)
- Modify: `lib/App/Greple/xlate/llm/gpt5.pm`(POD の DESCRIPTION 節)

**Interfaces:**
- Consumes: Task 3/5/6 のオプションと挙動

- [ ] **Step 1: xlate.pm の POD に 2 オプションを追加**

POD の `=item B<--xlate-context>` 項(`grep -n 'xlate-context' lib/App/Greple/xlate.pm` で場所を特定)の**後**に追加:

```pod
=item B<--xlate-context-window>=I<n>

(Context-aware engines only, e.g. C<gpt5> on the llm backend)
Number of surrounding translated blocks passed as reference context
when re-translating changed blocks (default 2).  The context also
includes the raw source text around the changed region (headings,
list structure, captions) and, when available, the previous version
of the changed text recovered from the cache, so that unchanged
wording is preserved.  Set to 0 to disable context-aware translation
entirely.

=item B<--xlate-cache-seed>=I<file>

Initialize a new document's cache from another document's cache
file.  Useful for periodic reports: seed the new issue's cache with
the previous issue's, so unchanged paragraphs are not re-translated
and edited paragraphs keep the previous issue's wording.  The seed
is used only when the target cache is empty; otherwise it is
ignored with a warning.
```

- [ ] **Step 2: llm/gpt5.pm の POD に文脈対応の記述を追加**

DESCRIPTION 節の末尾(`=head1 CONFIGURATION` の前)に追加:

```pod
This engine is context-aware: when re-translating changed blocks it
receives the surrounding source text, neighboring translation pairs,
and the previous version of the changed text, controlled by the
B<--xlate-context-window> option of L<App::Greple::xlate>.
```

- [ ] **Step 3: POD 検証と全テスト**

Run: `podchecker lib/App/Greple/xlate.pm lib/App/Greple/xlate/llm/gpt5.pm`
Expected: `pod syntax OK`(既存警告があれば新規でないことを確認)

Run: `prove -l t/`
Expected: 全 PASS

- [ ] **Step 4: コミット**

```bash
git add lib/App/Greple/xlate.pm lib/App/Greple/xlate/llm/gpt5.pm
git commit -m "docs: document context window and cache seeding options"
```

---

## 自己レビュー記録

- 仕様カバレッジ: ギャップ領域(T5)、挟み撃ち旧対訳・スライス(T6)、
  文脈 3 節+切り詰め(T6)、要素種別指示(T7)、既定有効+window=0
  無効化(T5/T8)、種付け(T3/T8)、checkpoint(T2/T5)、accumulate
  (T2)、dryrun 警告(T1)、ローダ(T4)、フォールバック(T5/T8)、
  POD(T9)— 仕様の全節に対応タスクあり
- 型整合: `region_context(\@blocks, $from, $to)` の返すハッシュのキーは
  仕様・T5 スタブ・T6 実装・llm.pm の消費側で一致。Cache API 名
  (old_position/old_size/old_entries_slice/checkpoint/load_data/seeded)
  は T1-T3 の定義と T6 の消費で一致
- 挙動保存: 非対応エンジン(null/deepl/gpty)は `$XLATE_CONTEXT` 不在で
  常に fallback 経路(単一 cache_update・context undef)を通り、呼び出し
  回数・ペイロードとも従来通り。dryrun は cache_update 冒頭で早期 return
  し checkpoint も呼ばれない
- 既知の許容事項(レビュー指摘対象外): 同一キーが同一文書に複数回
  出現する場合、2 回目以降は「hit(値は翻訳完了まで undef)」に分類され
  ギャップが分割されることがある。フランク採取は defined 値のみ使うので
  安全。従来と同じく最初の出現だけが翻訳される
