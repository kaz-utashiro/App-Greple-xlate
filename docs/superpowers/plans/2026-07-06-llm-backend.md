# llm バックエンド (gpt5) 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** gpt5 エンジンのバックエンドを gpty シェルアウトから `llm` CLI シェルアウトに差し替える(共通基盤 llm.pm + 薄い llm/gpt5.pm + ローダ拡張)。

**Architecture:** `lib/App/Greple/xlate/llm.pm` に llm CLI 実行・JSON 配列プロトコル・バッチングを一般化して置き、`lib/App/Greple/xlate/llm/gpt5.pm` はモデル名・プロンプト・オプション表だけの薄い定義にする。エンジンローダはバックエンド候補を `llm → gpty → bare` の順に解決する。テストは PATH に差し込むスタブ `llm` で API 費用ゼロで行う。

**Tech Stack:** Perl (v5.14+), Command::Run(既存依存), JSON(既存依存), JSON::PP(スタブ用、コアモジュール), Test::More, 既存の t/Util.pm + t/runner/Runner.pm テストハーネス。

**Spec:** docs/superpowers/specs/2026-07-06-llm-backend-design.md

## Global Constraints

- 全ファイルは必ず改行で終わること(プロジェクト CLAUDE.md の必須要件)
- インデント等は周辺コードのスタイルに合わせる(既存モジュールはタブ 8 幅 + 4 スペース)
- 新規 Perl 依存を追加しない(Command::Run と JSON は cpanfile 済み。スタブはコアの JSON::PP のみ使用)
- llm/gpt5.pm の翻訳プロンプトは gpty/gpt5.pm(lib/App/Greple/xlate/gpty/gpt5.pm:245-259)と**一字一句同一**にする(キャッシュ・出力同等性の前提)
- `temperature` は llm に**渡さない**
- llm 呼び出しには常に `--no-stream --no-log` を付ける
- 新規モジュールの `$VERSION` は lib/App/Greple/xlate.pm の `$VERSION` と同じ値にする(`grep 'VERSION' lib/App/Greple/xlate.pm` で確認)
- `lib/App/Greple/xlate/gpty/` 配下、`deepl.pm`、`Cache.pm`、`Text.pm`、`Mask.pm` には触らない
- git コミットメッセージ末尾に以下を付ける:
  ```
  Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_015Wte6DCZZAEjT7zEboeDid
  ```

---

### Task 1: スタブ llm コマンド(テスト基盤)

**Files:**
- Create: `t/bin/llm`(実行可能な Perl スクリプト)
- Test: `t/06_llm_stub.t`

**Interfaces:**
- Produces: PATH 先頭に `t/bin` を足すと `llm` として呼べるスタブ。
  - `llm models` → モデル一覧を stdout に出して終了(stdin は読まない)
  - それ以外の引数 → stdin の JSON 配列を読み、各要素を `uc`(大文字化)した JSON 配列を stdout に返す
  - 環境変数 `LLM_STUB_LOG`=FILE: 呼び出しごとに `{"argv":[...],"stdin":"..."}` の JSON 1 行を FILE に追記
  - 環境変数 `LLM_STUB_MODE`: `ok`(既定)/ `fail`(stderr に "stub llm: simulated failure" を出して exit 1)/ `nomodel`(prompt 呼び出しは "Error: unknown model" で exit 1、`models` は gpt-5.5 を含まない一覧を返す)/ `short`(応答配列の末尾要素を欠落させる)/ `badjson`(JSON でないテキストを返す)

- [ ] **Step 1: スタブ本体を書く**

`t/bin/llm` を以下の内容で作成:

```perl
#!/usr/bin/env perl

##
## Stub llm command for testing App::Greple::xlate::llm without API access.
##
## LLM_STUB_MODE:
##   ok      - (default) return input JSON array elements uppercased
##   fail    - exit 1 with an error message on stderr
##   nomodel - prompt call fails; "llm models" output lacks gpt-5.5
##   short   - drop the last element from the response array
##   badjson - return non-JSON text
## LLM_STUB_LOG: append {"argv":[...],"stdin":"..."} JSON line per call
##

use strict;
use warnings;
use JSON::PP;

binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';

my $mode = $ENV{LLM_STUB_MODE} // 'ok';

# "llm models" subcommand (used by the failure diagnosis)
if (@ARGV and $ARGV[0] eq 'models') {
    if ($mode eq 'nomodel') {
	print "OpenAI Chat: gpt-4o-mini\n";
    } else {
	print "OpenAI Chat: gpt-5.5\n";
	print "OpenAI Chat: test-model\n";
    }
    exit 0;
}

my $input = do { binmode STDIN, ':encoding(utf8)'; local $/; <STDIN> } // '';

if (my $log = $ENV{LLM_STUB_LOG}) {
    open my $fh, '>>:encoding(utf8)', $log or die "$log: $!\n";
    print $fh JSON::PP->new->canonical->encode({ argv => \@ARGV, stdin => $input }), "\n";
    close $fh;
}

if ($mode eq 'fail') {
    print STDERR "stub llm: simulated failure\n";
    exit 1;
}
if ($mode eq 'nomodel') {
    print STDERR "Error: unknown model\n";
    exit 1;
}
if ($mode eq 'badjson') {
    print "I'm sorry, I can't do that.\n";
    exit 0;
}

my $list = JSON::PP->new->decode($input);
my @out = map { uc } @$list;
pop @out if $mode eq 'short';
print JSON::PP->new->canonical->encode(\@out), "\n";
```

実行属性を付ける:

```bash
chmod +x t/bin/llm
```

- [ ] **Step 2: スタブの自己テストを書く**

`t/06_llm_stub.t` を以下の内容で作成:

```perl
use v5.14;
use warnings;
use utf8;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP;
use Command::Run;

my $stub = File::Spec->rel2abs('t/bin/llm');
ok(-x $stub, 'stub is executable');

my $tmpdir = tempdir(CLEANUP => 1);

sub run_stub {
    my %args = @_;
    local %ENV = (%ENV, %{$args{env} // {}});
    Command::Run->new->command($stub, @{$args{argv} // []})
	->run(stdin => $args{stdin} // '', stderr => 'capture');
}

subtest 'ok mode' => sub {
    my $log = "$tmpdir/ok.log";
    my $r = run_stub(argv  => ['-m', 'test-model'],
		     stdin => q(["hello\n"]),
		     env   => { LLM_STUB_LOG => $log });
    is($r->{result}, 0, 'exit status 0');
    is_deeply(JSON::PP->new->decode($r->{data}), ["HELLO\n"], 'uppercased array');
    open my $fh, '<', $log or die "$log: $!";
    my $rec = JSON::PP->new->decode(scalar <$fh>);
    is_deeply($rec->{argv}, ['-m', 'test-model'], 'argv recorded');
    is($rec->{stdin}, q(["hello\n"]), 'stdin recorded');
};

subtest 'models subcommand' => sub {
    my $r = run_stub(argv => ['models']);
    is($r->{result}, 0, 'exit status 0');
    like($r->{data}, qr/gpt-5\.5/, 'lists gpt-5.5');
    $r = run_stub(argv => ['models'], env => { LLM_STUB_MODE => 'nomodel' });
    unlike($r->{data}, qr/gpt-5\.5/, 'nomodel mode hides gpt-5.5');
};

subtest 'failure modes' => sub {
    my $r = run_stub(env => { LLM_STUB_MODE => 'fail' }, stdin => q(["a\n"]));
    isnt($r->{result}, 0, 'fail mode exits non-zero');
    like($r->{error}, qr/simulated failure/, 'error message on stderr');

    $r = run_stub(env => { LLM_STUB_MODE => 'short' }, stdin => q(["a\n","b\n"]));
    is_deeply(JSON::PP->new->decode($r->{data}), ["A\n"], 'short mode drops last element');

    $r = run_stub(env => { LLM_STUB_MODE => 'badjson' }, stdin => q(["a\n"]));
    ok(!eval { JSON::PP->new->decode($r->{data}); 1 }, 'badjson mode returns non-JSON');
};

done_testing;
```

- [ ] **Step 3: テストを実行して通ることを確認**

Run: `prove -l t/06_llm_stub.t`
Expected: PASS(スタブとテストを同時に作るタスクなので、ここでは成功を確認)

- [ ] **Step 4: コミット**

```bash
git add t/bin/llm t/06_llm_stub.t
git commit -m "test: add stub llm command for API-free backend testing"
```

---

### Task 2: llm.pm — システムプロンプト組み立てとコマンド構成(純関数)

**Files:**
- Create: `lib/App/Greple/xlate/llm.pm`
- Test: `t/07_llm_unit.t`
- Modify: `t/00_compile.t`(モジュール追加)

**Interfaces:**
- Consumes: `App::Greple::xlate` の `%opt`/`&opt`(export 済み)、`App::Greple::xlate::Lang` の `%LANGNAME`
- Produces:
  - `App::Greple::xlate::llm::build_system(\%param)` → system プロンプト文字列。
    `$param->{prompt}` の `%s` を `$LANGNAME{$param->{lang_to}}` で展開(未知言語は die)。
    `opt('prompt')`(--xlate-prompt)があれば全置換。`@contexts` があれば
    `"\n\nTranslation context:\n- ..."` を追記。**②(文脈つき差分翻訳)はこの関数を拡張する**
  - `App::Greple::xlate::llm::llm_command(\%param, $system)` → コマンドライン配列
    `('llm', '-m', MODEL, '-s', SYSTEM, '-o', KEY, VALUE, ..., '--no-stream', '--no-log')`
  - `%param` のキー: `model`(文字列), `prompt`(文字列), `options`(`[[key,value],...]` 順序保持),
    `max`(バッチ上限文字数), `lang_from`/`lang_to`(言語コード)

- [ ] **Step 1: 失敗するテストを書く**

`t/07_llm_unit.t` を以下の内容で作成:

```perl
use v5.14;
use warnings;
use utf8;

use Test::More;

use App::Greple::xlate;
use App::Greple::xlate::llm;

# quiet progress output during tests
$App::Greple::xlate::show_progress = 0;

my %param = (
    model     => 'test-model',
    max       => 1000,
    options   => [ [ alpha => 'one' ], [ beta => 'two' ] ],
    prompt    => "Translate the following JSON array into %s.\n",
    lang_from => 'ORIGINAL',
    lang_to   => 'JA',
);

subtest 'build_system' => sub {
    my $system = App::Greple::xlate::llm::build_system(\%param);
    like($system, qr/\ATranslate the following JSON array into Japanese\./,
	 '%s expands to language name');

    {
	local @App::Greple::xlate::contexts = ('background info');
	my $system = App::Greple::xlate::llm::build_system(\%param);
	like($system, qr/Translation context:\n- background info/,
	     '--xlate-context is appended');
    }
    {
	local $App::Greple::xlate::prompt = "Custom prompt.";
	my $system = App::Greple::xlate::llm::build_system(\%param);
	is($system, "Custom prompt.", '--xlate-prompt replaces the default');
    }
    {
	my %p = (%param, lang_to => 'XX');
	ok(!eval { App::Greple::xlate::llm::build_system(\%p); 1 },
	   'unknown language dies');
	like($@, qr/XX: unknown lang/, 'die message names the language');
    }
};

subtest 'llm_command' => sub {
    my @cmd = App::Greple::xlate::llm::llm_command(\%param, 'SYSTEM PROMPT');
    is_deeply(\@cmd,
	      [ 'llm', '-m', 'test-model', '-s', 'SYSTEM PROMPT',
		'-o', 'alpha', 'one', '-o', 'beta', 'two',
		'--no-stream', '--no-log' ],
	      'command line assembled in order');
};

done_testing;
```

- [ ] **Step 2: テストを実行して失敗を確認**

Run: `prove -l t/07_llm_unit.t`
Expected: FAIL — `Can't locate App/Greple/xlate/llm.pm`

- [ ] **Step 3: llm.pm の最初の実装を書く**

`lib/App/Greple/xlate/llm.pm` を以下の内容で作成($VERSION は xlate.pm に合わせる):

```perl
package App::Greple::xlate::llm;

our $VERSION = "1.0202";

=encoding utf-8

=head1 NAME

App::Greple::xlate::llm - common backend for llm-based translation engines

=head1 DESCRIPTION

This module provides the shared machinery for translation engines built
on the C<llm> command line tool (L<https://llm.datasette.io/>): command
construction, JSON array protocol, batching, progress display, and
failure diagnosis.  Engine modules such as
L<App::Greple::xlate::llm::gpt5> only define the model name, prompt,
and model options.

=head1 SEE ALSO

L<App::Greple::xlate>, L<App::Greple::xlate::llm::gpt5>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use v5.14;
use warnings;
use utf8;
use Data::Dumper;
{
    no warnings 'redefine';
    *Data::Dumper::qquote = sub { qq["${\(shift)}"] };
    $Data::Dumper::Useperl = 1;
}

use Command::Run;
use JSON;

use App::Greple::xlate qw(%opt &opt);
use App::Greple::xlate::Lang qw(%LANGNAME);

my $json = JSON->new->canonical->pretty;

sub _progress {
    print STDERR @_ if opt('progress');
}

##
## Assemble the system prompt: expand %s to the target language name
## and append --xlate-context entries.  Phase 2 (context-aware
## differential translation) extends this function.
##
sub build_system {
    my $param = shift;
    my $prompt = opt('prompt') || $param->{prompt};
    my @vars = do {
	if ($prompt =~ /%s/) {
	    $LANGNAME{$param->{lang_to}} // die "$param->{lang_to}: unknown lang.\n";
	} else {
	    ();
	}
    };
    my $system = sprintf($prompt, @vars);
    if (my @contexts = @{$opt{contexts}}) {
	$system .= "\n\nTranslation context:\n" . join("\n", map "- $_", @contexts);
    }
    $system;
}

sub llm_command {
    my($param, $system) = @_;
    my @command = ('llm', '-m' => $param->{model}, '-s' => $system);
    for my $kv (@{$param->{options} // []}) {
	push @command, '-o', @$kv;
    }
    push @command, '--no-stream', '--no-log';
    @command;
}

1;
```

- [ ] **Step 4: テストを実行して通ることを確認**

Run: `prove -l t/07_llm_unit.t`
Expected: PASS(2 subtests)

- [ ] **Step 5: 00_compile.t にモジュールを追加**

`t/00_compile.t` の `use_ok` リストの `App::Greple::xlate::gpty::gpt5` の次の行に追加:

```perl
    App::Greple::xlate::llm
```

Run: `prove -l t/00_compile.t`
Expected: PASS

- [ ] **Step 6: コミット**

```bash
git add lib/App/Greple/xlate/llm.pm t/07_llm_unit.t t/00_compile.t
git commit -m "feat: add llm backend base with prompt/command assembly"
```

---

### Task 3: llm.pm — 実行・診断・JSON プロトコル・バッチング

**Files:**
- Modify: `lib/App/Greple/xlate/llm.pm`(Task 2 で作成したファイルの `llm_command` の後、`1;` の前に追加)
- Test: `t/07_llm_unit.t`(追記)

**Interfaces:**
- Consumes: Task 1 のスタブ llm(PATH 経由)、Task 2 の `build_system`/`llm_command`
- Produces:
  - `App::Greple::xlate::llm::run_llm(\%param, $stdin_text)` → llm の stdout 文字列。
    非ゼロ終了なら `diagnose()` のメッセージで die。成功時に stderr 出力があれば STDERR に透過
  - `App::Greple::xlate::llm::diagnose(\%param, \%result)` → 原因別のエラーメッセージ文字列
    (llm 不在 / モデル未知 / その他)
  - `App::Greple::xlate::llm::xlate_each(\%param, @blocks)` → JSON 配列プロトコル 1 往復
  - `App::Greple::xlate::llm::xlate_with(\%param, @blocks)` → バッチング付き翻訳。
    **エンジンが呼ぶ公開エントリポイント**。gpty/gpt5.pm の `xlate` と同じ検証
    (要素数不一致 die、maxlen 超過 die)を行う

- [ ] **Step 1: 失敗するテストを追記**

`t/07_llm_unit.t` の `done_testing;` の**前**に以下を追加:

```perl
use File::Spec;
use File::Temp qw(tempdir);

my $bin = File::Spec->rel2abs('t/bin');
my $tmpdir = tempdir(CLEANUP => 1);

sub trap (&) {
    my $code = shift;
    eval { $code->() };
    $@;
}

subtest 'xlate_with via stub' => sub {
    local $ENV{PATH} = "$bin:$ENV{PATH}";
    my @to = App::Greple::xlate::llm::xlate_with(\%param, "hello\n", "world\n");
    is_deeply(\@to, ["HELLO\n", "WORLD\n"], 'round trip through stub llm');

    @to = App::Greple::xlate::llm::xlate_with(\%param, "one\ntwo\n", "three\n");
    is_deeply(\@to, ["ONE\nTWO\n", "THREE\n"], 'line counts per block preserved');
};

subtest 'batching by maxlen' => sub {
    local $ENV{PATH} = "$bin:$ENV{PATH}";
    my $log = "$tmpdir/batch.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my %p = (%param, max => 12);
    my @to = App::Greple::xlate::llm::xlate_with(\%p, "aaaa bbbb\n", "cccc dddd\n");
    is_deeply(\@to, ["AAAA BBBB\n", "CCCC DDDD\n"], 'both blocks translated');
    open my $fh, '<', $log or die "$log: $!";
    my @calls = <$fh>;
    is(scalar @calls, 2, 'split into two llm calls (maxlen=12)');

    my %q = (%param, max => 4);
    like(trap { App::Greple::xlate::llm::xlate_with(\%q, "too long line\n") },
	 qr/longer than max length/, 'oversized block dies');
};

subtest 'error handling' => sub {
    local $ENV{PATH} = "$bin:$ENV{PATH}";
    {
	local $ENV{LLM_STUB_MODE} = 'short';
	like(trap { App::Greple::xlate::llm::xlate_with(\%param, "a\n", "b\n") },
	     qr/Unexpected response \(1 < 2\)/, 'element count mismatch dies');
    }
    {
	local $ENV{LLM_STUB_MODE} = 'badjson';
	like(trap { App::Greple::xlate::llm::xlate_with(\%param, "a\n") },
	     qr/Invalid JSON response/, 'non-JSON response dies');
    }
    {
	local $ENV{LLM_STUB_MODE} = 'fail';
	my $err = trap { App::Greple::xlate::llm::xlate_with(\%param, "a\n") };
	like($err, qr/llm failed/, 'generic failure reported');
	like($err, qr/simulated failure/, 'stderr from llm included');
    }
    {
	local $ENV{LLM_STUB_MODE} = 'nomodel';
	my %p = (%param, model => 'gpt-5.5');
	like(trap { App::Greple::xlate::llm::xlate_with(\%p, "a\n") },
	     qr/does not know model "gpt-5\.5"/, 'unknown model diagnosed');
    }
};

subtest 'llm command not found' => sub {
    local $ENV{PATH} = $tmpdir;    # empty directory: no llm here
    like(trap { App::Greple::xlate::llm::xlate_with(\%param, "a\n") },
	 qr/llm: command not found/, 'missing command diagnosed');
};
```

- [ ] **Step 2: テストを実行して失敗を確認**

Run: `prove -l t/07_llm_unit.t`
Expected: FAIL — `Undefined subroutine &App::Greple::xlate::llm::xlate_with`

- [ ] **Step 3: 実装を追加**

`lib/App/Greple/xlate/llm.pm` の `llm_command` サブルーチンの後、`1;` の前に追加:

```perl
sub run_llm {
    state $run = Command::Run->new;
    my($param, $text) = @_;
    my @command = llm_command($param, build_system($param));
    warn Dumper \@command if opt('debug');
    my $result = $run->command(@command)
		     ->run(stdin => $text, stderr => 'capture');
    if ($result->{result} != 0) {
	die diagnose($param, $result);
    }
    print STDERR $result->{error} if $result->{error};
    $result->{data};
}

##
## Called when the llm command fails: figure out why and return a
## message useful to the user.
##
sub diagnose {
    my($param, $result) = @_;
    my $stderr = $result->{error} // '';
    if (! grep { -x "$_/llm" } split /:/, $ENV{PATH} // '') {
	return "llm: command not found.\n" .
	       "Install llm <https://llm.datasette.io/> with " .
	       "\"pip install llm\" or \"pipx install llm\".\n";
    }
    my $model = $param->{model};
    my $models = Command::Run->new->command('llm', 'models')
	->run(stderr => 'capture')->{data} // '';
    if ($models !~ /\Q$model\E/) {
	return "llm does not know model \"$model\".\n" .
	       "Upgrade llm (\"pip install -U llm\") or register the model " .
	       "in extra-openai-models.yaml.\n" .
	       ($stderr ? "\n$stderr" : "");
    }
    return "llm failed:\n$stderr";
}

sub xlate_each {
    my $param = shift;
    my @count = map { int tr/\n/\n/ } @_;
    _progress("From:\n", map s/^/\t< /mgr, @_);
    my @in = map { m/.*\n/mg } @_;
    my $out = run_llm($param, $json->encode(\@in));
    my $obj = eval { $json->decode($out) };
    ref $obj eq 'ARRAY'
	or die "Invalid JSON response:\n\n$out\n";
    my @out = map { s/(?<!\n)\z/\n/r } @$obj;
    _progress("To:\n", map s/^/\t> /mgr, @out);
    if (@out < @in) {
	my $to = join '', @out;
	die sprintf("Unexpected response (%d < %d):\n\n%s\n",
		    int(@out), int(@in), $to);
    }
    map { join '', splice @out, 0, $_ } @count;
}

##
## Public entry point for engine modules: batch the blocks up to the
## maxlen/maxline limits and translate each batch in one llm call.
##
sub xlate_with {
    my $param = shift;
    my @from = map { /\n\z/ ? $_ : "$_\n" } @_;
    my @to;
    my $max = $App::Greple::xlate::max_length || $param->{max} // die;
    my $maxline = $App::Greple::xlate::max_line;
    if (my @len = grep { $_ > $max } map length, @from) {
	die "Contain lines longer than max length (@len > $max).\n";
    }
    while (@from) {
	my @tmp;
	my $len = 0;
	while (@from) {
	    my $next = length $from[0];
	    last if $len + $next > $max;
	    $len += $next;
	    push @tmp, shift @from;
	    last if $maxline > 0 and @tmp >= $maxline;
	}
	@tmp > 0 or die "Probably text is longer than max length ($max).\n";
	push @to, xlate_each($param, @tmp);
    }
    @to;
}
```

- [ ] **Step 4: テストを実行して通ることを確認**

Run: `prove -l t/07_llm_unit.t`
Expected: PASS(全 subtests)

- [ ] **Step 5: コミット**

```bash
git add lib/App/Greple/xlate/llm.pm t/07_llm_unit.t
git commit -m "feat: add llm execution, JSON protocol, batching and diagnosis"
```

---

### Task 4: llm/gpt5.pm — gpt5 エンジン定義

**Files:**
- Create: `lib/App/Greple/xlate/llm/gpt5.pm`
- Test: `t/08_llm_gpt5.t`
- Modify: `t/00_compile.t`(モジュール追加)
- Reference: `lib/App/Greple/xlate/gpty/gpt5.pm:245-259`(プロンプトの転記元。**変更不可**)

**Interfaces:**
- Consumes: `App::Greple::xlate::llm::xlate_with(\%param, @blocks)`(Task 3)
- Produces: `App::Greple::xlate::llm::gpt5::xlate(@blocks)` → 訳文リスト。
  ローダ契約(`xlate` 関数 + `our $lang_from`/`$lang_to`)を満たすエンジンモジュール

- [ ] **Step 1: 失敗するテストを書く**

`t/08_llm_gpt5.t` を以下の内容で作成:

```perl
use v5.14;
use warnings;
use utf8;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP;

use App::Greple::xlate;
use App::Greple::xlate::llm::gpt5;

$App::Greple::xlate::show_progress = 0;

my $bin = File::Spec->rel2abs('t/bin');
my $tmpdir = tempdir(CLEANUP => 1);
my $log = "$tmpdir/gpt5.log";
$ENV{PATH} = "$bin:$ENV{PATH}";
$ENV{LLM_STUB_LOG} = $log;

$App::Greple::xlate::llm::gpt5::lang_to = 'EN-US';

my @to = App::Greple::xlate::llm::gpt5::xlate("hello world\n");
is_deeply(\@to, ["HELLO WORLD\n"], 'translation via stub');

open my $fh, '<', $log or die "$log: $!";
my $rec = JSON::PP->new->decode(scalar <$fh>);
my @argv = @{$rec->{argv}};
my $argv_str = join ' ', @argv;

is($argv[0], '-m', 'first option is -m');
is($argv[1], 'gpt-5.5', 'model is gpt-5.5');
like($argv_str, qr/-o reasoning_effort none/, 'reasoning_effort none');
like($argv_str, qr/-o verbosity low/, 'verbosity low');
like($argv_str, qr/-o max_tokens 16000/, 'max_tokens 16000');
like($argv_str, qr/--no-stream/, 'no-stream');
like($argv_str, qr/--no-log/, 'no-log');
unlike($argv_str, qr/temperature/, 'temperature is not sent');

my($i) = grep { $argv[$_] eq '-s' } 0 .. $#argv;
my $system = $argv[$i + 1];
like($system, qr/\ATranslate the following JSON array into American English\./,
     'system prompt with language expanded');
like($system, qr/XML-style marker tag/, 'mask tag instruction preserved');

is_deeply(JSON::PP->new->decode($rec->{stdin}), ["hello world\n"],
	  'stdin is JSON array of lines');

done_testing;
```

- [ ] **Step 2: テストを実行して失敗を確認**

Run: `prove -l t/08_llm_gpt5.t`
Expected: FAIL — `Can't locate App/Greple/xlate/llm/gpt5.pm`

- [ ] **Step 3: エンジンを実装**

`lib/App/Greple/xlate/llm/gpt5.pm` を以下の内容で作成。
**prompt ヒアドキュメントの中身は lib/App/Greple/xlate/gpty/gpt5.pm:245-259 からの正確な転記**
(下に全文を再掲している。転記後に `diff <(sed -n '246,259p' lib/App/Greple/xlate/gpty/gpt5.pm) <(sed -n '/END/,/^END/p' ...)` などで照合するより、
gpty/gpt5.pm から該当行をコピーして貼るのが確実):

```perl
package App::Greple::xlate::llm::gpt5;

our $VERSION = "1.0202";

=encoding utf-8

=head1 NAME

App::Greple::xlate::llm::gpt5 - GPT-5.5 translation engine (llm backend) for greple xlate module

=head1 SYNOPSIS

    greple -Mxlate --xlate-engine=gpt5 --xlate=ja file.txt

=head1 DESCRIPTION

This module provides GPT-5.5 translation support for the
App::Greple::xlate module, calling the model through the C<llm>
command line tool (L<https://llm.datasette.io/>) instead of the
older C<gpty> command.  The engine name, translation prompt, and
cache files (C<*.xlate-gpt5-*.json>) are fully compatible with the
gpty backend engine L<App::Greple::xlate::gpty::gpt5>.

The C<llm> command must be installed and must know the C<gpt-5.5>
model (llm 0.31 or later ships it built in; check with
C<llm models | grep gpt-5.5>).  If the call fails, this module
inspects the environment and reports what is missing.

=head1 CONFIGURATION

This engine uses the following defaults:

=over 4

=item * B<model>: gpt-5.5

=item * B<reasoning_effort>: none (fastest; suitable for translation)

=item * B<verbosity>: low

=item * B<max_tokens>: 16000

=item * B<max_length>: 3000 characters per batch

=back

No C<temperature> option is sent: reasoning models reject non-default
temperatures, and C<llm> only sends the option when specified.

=head1 ENVIRONMENT VARIABLES

=over 4

=item * B<OPENAI_API_KEY> - OpenAI API key, read by the C<llm> command.
Alternatively use C<llm keys set openai>.

=back

=head1 RELATED OPTIONS

=over 4

=item * B<--xlate-maxlen>=I<chars> - Maximum characters sent per request
(defaults to this engine's value of 3000 when unset)

=item * B<--xlate-maxline>=I<n> - Maximum lines sent per request
(default 0 = unlimited); useful as a safety valve if a large batch
causes a response element-count mismatch

=item * B<--xlate-debug> - Dump the C<llm> command and parameters

=item * B<--xlate-setopt backend=gpty> - Force the old gpty backend
engine for comparison

=back

=head1 DEPENDENCIES

=over 4

=item * L<App::Greple::xlate>

=item * C<llm> command (L<https://llm.datasette.io/>)

=item * L<Command::Run>, L<JSON>

=back

=head1 SEE ALSO

=over 4

=item * L<App::Greple::xlate>

=item * L<App::Greple::xlate::llm>

=item * L<App::Greple::xlate::gpty::gpt5>

=back

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use v5.14;
use warnings;
use utf8;

use App::Greple::xlate::llm;

our $lang_from //= 'ORIGINAL';
our $lang_to   //= 'JA';
our $method = __PACKAGE__ =~ s/.*://r;

my %param = (
    model   => 'gpt-5.5',
    max     => 3000,
    options => [ [ reasoning_effort => 'none' ],
		 [ verbosity        => 'low'  ],
		 [ max_tokens       => 16000  ] ],
    prompt  => <<'END',
Translate the following JSON array into %s.
For each input array element, output only the corresponding translated element at the same array index.
If an element is a blank string or an XML-style marker tag (e.g., "<m id=1 />"), leave it unchanged and do not translate it.
Do not output the original (pre-translation) text under any circumstances.
The number and order of output elements must always match the input exactly: output element n must correspond to input element n.
Output only the translated elements or unchanged tags/blank strings as a JSON array.
Do not leave any unnecessary spaces or tabs at the end of any array element in your output.
Before finishing, carefully check that there are absolutely no omissions, duplicate content, or trailing spaces of any kind in your output.

Return the result as a JSON array and nothing else.
Your entire output must be valid JSON.
Do not include any explanations, code blocks, or text outside of the JSON array.
If you cannot produce a valid JSON array, return an empty JSON array ([]).
END
);

sub initialize {
    my($mod, $argv) = @_;
    $mod->setopt(default => "-Mxlate --xlate-engine=$method");
}

sub xlate {
    App::Greple::xlate::llm::xlate_with(
	{ %param, lang_from => $lang_from, lang_to => $lang_to }, @_);
}

1;

__DATA__

# set in &initialize()
# option default -Mxlate --xlate-engine=gpt5
```

- [ ] **Step 4: プロンプトが gpty 版と同一であることを機械的に確認**

Run(ヒアドキュメントの中身だけを両ファイルから抜き出して diff):

```bash
extract() { sed -n '/prompt *=> <</,/^END$/p' "$1" | sed '1d;$d'; }
diff <(extract lib/App/Greple/xlate/gpty/gpt5.pm) \
     <(extract lib/App/Greple/xlate/llm/gpt5.pm) && echo IDENTICAL
```

Expected: `IDENTICAL`(diff 出力なし)。差分が出たら llm/gpt5.pm のプロンプトを
gpty/gpt5.pm:246-259 から転記し直す。

- [ ] **Step 5: テストを実行して通ることを確認**

Run: `prove -l t/08_llm_gpt5.t`
Expected: PASS

- [ ] **Step 6: 00_compile.t にモジュールを追加**

`t/00_compile.t` の `use_ok` リストの `App::Greple::xlate::llm` の次の行に追加:

```perl
    App::Greple::xlate::llm::gpt5
```

Run: `prove -l t/00_compile.t`
Expected: PASS

- [ ] **Step 7: コミット**

```bash
git add lib/App/Greple/xlate/llm/gpt5.pm t/08_llm_gpt5.t t/00_compile.t
git commit -m "feat: add gpt5 engine on the llm backend"
```

---

### Task 5: エンジンローダ拡張と backend 強制オプション

**Files:**
- Modify: `lib/App/Greple/xlate.pm`(%opt 定義: 589-610 行付近、ローダ: 674-687 行付近)
- Test: `t/09_llm_loader.t`

**Interfaces:**
- Consumes: Task 4 の `App::Greple::xlate::llm::gpt5`
- Produces:
  - エンジン解決順 `llm::<engine> → gpty::<engine> → <engine>`
  - `%opt` の新キー `backend`(`our $engine_backend = ''`)。
    `--xlate-setopt backend=NAME` で `<NAME>::<engine> → <engine>` に候補を絞る

- [ ] **Step 1: 失敗するテストを書く**

`t/09_llm_loader.t` を以下の内容で作成:

```perl
use v5.14;
use warnings;

use Test::More;
use Command::Run;

my $probe = <<'END';
use App::Greple::xlate;
my($engine, $backend) = @ARGV;
App::Greple::xlate::opt('backend') = $backend if defined $backend;
$App::Greple::xlate::xlate_engine = $engine;
App::Greple::xlate::setup();
print "$_\n" for sort grep m{App/Greple/xlate/}, keys %INC;
END

sub probe {
    Command::Run->new->command($^X, '-Ilib', '-e', $probe, @_)
	->run(stderr => 'capture');
}

my $r = probe('gpt5');
is($r->{result}, 0, 'gpt5 loads successfully');
like($r->{data}, qr{^App/Greple/xlate/llm/gpt5\.pm$}m,
     'gpt5 resolves to the llm backend');

$r = probe('gpt4o');
like($r->{data}, qr{^App/Greple/xlate/gpty/gpt4o\.pm$}m,
     'gpt4o still resolves to the gpty backend');

$r = probe('gpt5', 'gpty');
like($r->{data}, qr{^App/Greple/xlate/gpty/gpt5\.pm$}m,
     'backend=gpty forces gpty::gpt5');
unlike($r->{data}, qr{^App/Greple/xlate/llm/gpt5\.pm$}m,
       'llm::gpt5 is not loaded when gpty is forced');

$r = probe('null');
like($r->{data}, qr{^App/Greple/xlate/null\.pm$}m,
     'null resolves to the bare name');

$r = probe('nonexistent');
isnt($r->{result}, 0, 'unknown engine fails');
like($r->{error}, qr/not available/, 'clear error message');

done_testing;
```

- [ ] **Step 2: テストを実行して失敗を確認**

Run: `prove -l t/09_llm_loader.t`
Expected: FAIL — `opt('backend')` が `backend: Invalid option` 相当で die
(%opt に backend キーがまだ無い)、かつ gpt5 が gpty::gpt5 に解決される

- [ ] **Step 3: %opt に backend キーを追加**

`lib/App/Greple/xlate.pm` の `%opt` 定義(589 行付近)で、
`contexts => (\our @contexts),` の行の**前**に追加:

```perl
    backend  => \(our $engine_backend = ''),
```

- [ ] **Step 4: ローダを書き換え**

`lib/App/Greple/xlate.pm` の setup() 内(675-687 行付近)、以下の旧コード:

```perl
	# Resolve the engine module.  Backend-based engines live under a
	# backend namespace (e.g. gpty::gpt5); others live directly under
	# App::Greple::xlate (e.g. deepl, null).  Try the backend namespace
	# FIRST so that --xlate-engine=gpt5 binds to gpty::gpt5 even if a
	# stale top-level App::Greple::xlate::gpt5 lingers in @INC from an
	# older install.  This also makes the future llm backend selectable
	# the same way.
	my $backend = 'gpty';
	my $mod;
	for my $cand (__PACKAGE__ . "::$backend\::$xlate_engine",
		      __PACKAGE__ . "::$xlate_engine") {
	    if (eval "require $cand; 1") { $mod = $cand; last }
	}
```

を以下に置換:

```perl
	# Resolve the engine module.  Backend-based engines live under a
	# backend namespace (e.g. llm::gpt5, gpty::gpt5); others live
	# directly under App::Greple::xlate (e.g. deepl, null).  Try
	# backend namespaces FIRST, in order of preference, so that
	# --xlate-engine=gpt5 binds to llm::gpt5 even if a stale
	# top-level App::Greple::xlate::gpt5 lingers in @INC from an
	# older install.  Use --xlate-setopt backend=NAME to force a
	# specific backend (e.g. backend=gpty for comparison with the
	# old gpty engine).
	my @backend = length($engine_backend // '') ? $engine_backend : qw(llm gpty);
	my $mod;
	for my $cand ((map __PACKAGE__ . "::$_\::$xlate_engine", @backend),
		      __PACKAGE__ . "::$xlate_engine") {
	    if (eval "require $cand; 1") { $mod = $cand; last }
	}
```

- [ ] **Step 5: テストを実行して通ることを確認**

Run: `prove -l t/09_llm_loader.t`
Expected: PASS(全アサーション)

- [ ] **Step 6: 既存テストの回帰確認**

Run: `prove -l t/00_compile.t t/01_unit.t t/02_run.t t/04_xlate_script.t t/05_translate.t`
Expected: PASS(null/deepl 系の解決が変わっていないこと)

- [ ] **Step 7: コミット**

```bash
git add lib/App/Greple/xlate.pm t/09_llm_loader.t
git commit -m "feat: resolve engines through llm/gpty backend list with override"
```

---

### Task 6: greple パイプライン統合テスト

**Files:**
- Test: `t/10_llm_run.t`

**Interfaces:**
- Consumes: Task 1-5 の全成果(スタブ llm、llm::gpt5 エンジン、ローダ)、
  t/Util.pm の `xlate()` ヘルパ(greple -Mxlate を起動し `->setstdin->run->status/stdout` を持つ)

- [ ] **Step 1: 統合テストを書く**

`t/10_llm_run.t` を以下の内容で作成:

```perl
use v5.14;
use warnings;
use utf8;

use Test::More;
use File::Spec;

use lib '.';
use t::Util;

$ENV{NO_COLOR} = 1;
$ENV{PATH} = File::Spec->rel2abs('t/bin') . ":$ENV{PATH}";

subtest 'gpt5 engine through greple pipeline' => sub {
    my $result = xlate(qw(--xlate --xlate-engine=gpt5 --xlate-to=EN-US
			  --xlate-cache=never --xlate-format=xtxt .+))
	->setstdin("hello world\n")->run;
    is($result->status, 0, 'exits successfully');
    like($result->stdout, qr/HELLO WORLD/, 'stub translation appears in output');
};

subtest 'conflict format' => sub {
    my $result = xlate(qw(--xlate --xlate-engine=gpt5 --xlate-to=EN-US
			  --xlate-cache=never --xlate-format=cm .+))
	->setstdin("hello world\n")->run;
    is($result->status, 0, 'exits successfully');
    like($result->stdout, qr/<<<<<<<.*hello world.*=======.*HELLO WORLD.*>>>>>>>/s,
	 'conflict markers contain original and translation');
};

subtest 'response count mismatch fails' => sub {
    local $ENV{LLM_STUB_MODE} = 'short';
    my $result = xlate(qw(--xlate --xlate-engine=gpt5 --xlate-to=EN-US
			  --xlate-cache=never .+))
	->setstdin("hello\nworld\n")->run;
    isnt($result->status, 0, 'non-zero exit on element count mismatch');
};

done_testing;
```

- [ ] **Step 2: テストを実行して通ることを確認**

Run: `prove -l t/10_llm_run.t`
Expected: PASS(3 subtests)

失敗した場合の代表的な原因: (a) Runner が %ENV を子プロセスに渡していない
→ t/runner/Runner.pm の実装を確認して環境変数の渡し方を合わせる。
(b) stdin 入力でキャッシュファイルを作ろうとして失敗
→ `--xlate-cache=never` が効いているか `App::Greple::xlate::begin` を確認。

- [ ] **Step 3: コミット**

```bash
git add t/10_llm_run.t
git commit -m "test: add end-to-end llm backend test through greple pipeline"
```

---

### Task 7: ドキュメント更新と全体確認

**Files:**
- Modify: `lib/App/Greple/xlate.pm`(POD の --xlate-engine 項)
- Modify: `docs/llm-backend-reference.md`(§4/§9 のバージョンガード記述を実態に合わせる)

**Interfaces:**
- Consumes: Task 5 のローダ仕様(解決順・backend オプション)

- [ ] **Step 1: xlate.pm の POD に解決順を追記**

`lib/App/Greple/xlate.pm` の POD 内 `=item B<--xlate-engine>=I<engine>` 項
(`grep -n 'xlate-engine' lib/App/Greple/xlate.pm` で場所を特定)の説明文の
末尾に、以下の段落を追加:

```pod
Engine modules are searched in backend namespaces first (C<llm>, then
C<gpty>), then directly under C<App::Greple::xlate>.  So C<gpt5> loads
C<App::Greple::xlate::llm::gpt5> which calls the C<llm> command, while
C<gpt4o> falls back to C<App::Greple::xlate::gpty::gpt4o>.  Use
C<--xlate-setopt backend=gpty> to force a specific backend.
```

- [ ] **Step 2: llm-backend-reference.md の記述を実態に合わせる**

`docs/llm-backend-reference.md` の §4(gpt-5.5 モデルの利用可否)に、
実機確認の結果を反映する。以下の一文を §4 の箇条書きの末尾に追加:

```markdown
- **実機確認 (2026-07-06)**: llm **0.31** でも `gpt-5.5` /
  `gpt-5.5-2026-04-23` はコア組み込みで利用可能(ただし Responses でなく
  Chat Completions 経由)。したがって実装はバージョン番号でなく
  「`llm models` にモデルが居るか」で検出する(xlate::llm の diagnose)。
```

- [ ] **Step 3: 全テストスイートを実行**

Run: `prove -l t/`
Expected: 全ファイル PASS(00_compile, 01_unit, 02_run, 04_xlate_script,
05_translate, 06_llm_stub, 07_llm_unit, 08_llm_gpt5, 09_llm_loader, 10_llm_run)

- [ ] **Step 4: 実 API での手動同等性確認の準備(実行はしない)**

以下のコマンドを README 的に確認するだけ(**API 費用が発生するため、
ユーザーの承認なしに実行しない**):

```bash
# 小さなファイルで gpty 版と llm 版を比較する手順(手動・要承認)
greple -Mxlate --xlate-engine=gpt5 --xlate-setopt backend=gpty \
       --xlate --xlate-to=JA --match-paragraph somefile.txt   # 旧
greple -Mxlate --xlate-engine=gpt5 \
       --xlate --xlate-to=JA --match-paragraph somefile.txt   # 新
```

- [ ] **Step 5: コミット**

```bash
git add lib/App/Greple/xlate.pm docs/llm-backend-reference.md
git commit -m "docs: document backend resolution order and llm 0.31 reality"
```

---

## 自己レビュー記録

- 仕様カバレッジ: 共通基盤(Task 2-3)、薄いエンジン(Task 4)、ローダ+backend
  オプション(Task 5)、失敗時診断(Task 3)、スタブテスト(Task 1, 6)、
  POD/ドキュメント(Task 4, 7)、実 API 手動確認の手順化(Task 7)—
  仕様書の全節に対応タスクあり
- 型整合: `xlate_with(\%param, @blocks)` を Task 3 で定義し Task 4 が同名で消費。
  `%param` のキー(model/max/options/prompt/lang_from/lang_to)は Task 2 の
  Interfaces 定義と Task 4 の実装で一致
- lang_from/lang_to の受け渡しは仕様の選択肢のうち「エンジンの xlate が
  %param に詰めて渡す」方式を採用(caller ハックより明示的)
