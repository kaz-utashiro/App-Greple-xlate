# 文脈つき差分翻訳 設計書

日付: 2026-07-06
ステータス: 承認済み(実装前)
前提: docs/superpowers/specs/2026-07-06-llm-backend-design.md(①、実装済み)

## 背景と目的

xlate の差分翻訳は「変更された段落だけ」を API に送るが、現状その段落は
**孤立して**送られ、前後の文脈・既訳・変更前の旧訳は一切渡らない。その結果、

1. 変更段落の訳が周囲と文体・訳語で不整合になる
2. 小さな修正でも段落全体の言い回しが翻訳のたびに変わってしまう

本設計は、キャッシュに既にある情報(周辺段落の原文+既訳、purge 直前の
旧エントリ)を再翻訳プロンプトに注入してこの 2 つを解決する。

## 決定事項(ブレインストーミング承認済み)

- 文脈 = **周辺原文スライス(構造要素込み)** と **周辺段落の原文+既訳**
  と **変更前の旧対訳**(既存の静的 `--xlate-context` は従来通り併用)。
  周辺原文スライスは、翻訳対象にならない構造要素(見出し、箇条書き、
  キャプション、コードブロック等)が文脈から欠落する問題への対策で、
  ギャップ領域の前後の文書バッファを**マッチ・非マッチを問わず生のまま**
  切り出して渡す。フォーマット非依存(書式ごとの見出し検出は不要)
- 旧訳の対応付けは**位置ベース(挟み撃ち)**: キャッシュ list が文書順を
  保存していることを利用。段落の移動には対応しない(その場合は旧訳なしで翻訳)
- 呼び出し単位は**ギャップ領域**(連続ミス段落の列)ごと。全段落ミス
  (初回翻訳)やキャッシュ不在時は従来の一括バッチへ自動フォールバック
- llm 系エンジンでは**既定で有効**。`--xlate-context-window=0` で無効化
- エンジン契約はパッケージ変数方式(案 A): `$XLATE_CONTEXT` フラグ +
  `$call_context` 変数。gpty/deepl は完全に従来動作
- 周辺修繕 4 件を同スコープに含む: キャッシュ逐次書き出し、accumulate
  仕様確定、dryrun 警告修正、ローダ require エラー握りつぶし修正

## スコープ

- lib/App/Greple/xlate.pm — postgrep のギャップ領域化、cache_update の
  領域単位化、`$call_context`、`--xlate-context-window` オプション、
  ローダのエラー処理修正
- lib/App/Greple/xlate/Cache.pm — 旧リスト順序の保持、
  `old_entries_between`、checkpoint 書き出し、accumulate 修正、警告修正
- lib/App/Greple/xlate/llm.pm — `build_system` の文脈節追記と切り詰め
- lib/App/Greple/xlate/llm/gpt5.pm — `$XLATE_CONTEXT = 1` 宣言
- テスト(スタブ llm、API 費用ゼロ)

## 非スコープ

- gpty/・deepl.pm の変更(動作・コストとも完全不変)
- キャッシュファイル形式の変更(list of [原文, 訳文] のまま。メタデータ
  追加はしない)
- Claude エンジン(①')、匿名化(③)
- 応答リトライ・バッチ分割回復

## 設計

### 用語

- **マッチ列**: postgrep が見る、文書順のマッチブロック列。各要素は
  正規化キーを持ち、キャッシュに存在すれば **hit**、なければ **miss**
- **ギャップ領域**: 連続する miss の極大列
- **フランク**: ギャップの前後にある hit 段落。文書端では欠けてよい

### データフロー(postgrep → cache_update → エンジン)

```
postgrep:
  マッチ列を正規化キー+hit/miss 判定つきで構築
  if (エンジンの $XLATE_CONTEXT && context_window > 0 && hit が 1 個以上) {
      ギャップ領域ごとに:
        region = {
          texts         => [ギャップ内の miss キー列(文書順)],
          source_before => 領域直前の原文スライス(生テキスト、下記),
          source_after  => 領域直後の原文スライス(生テキスト),
          hits_before   => [直前の hit 最大 W 個の [原文, 訳文](近い順に外へ)],
          hits_after    => [直後の hit 最大 W 個の [原文, 訳文]],
          old_pairs     => [挟み撃ちで得た旧 [原文, 訳文] 列(下記)],
        }
        cache_update($region)
  } else {
      # 従来フロー(初回翻訳・キャッシュなし・window=0・非対応エンジン)
      cache_update({ texts => [全 miss], context => undef })
  }
```

- W = `--xlate-context-window`(既定 2)。フランクは miss を飛ばして
  外側へ走査し、hit だけを最大 W 個集める
- **原文スライス**: 文書バッファ上で、領域開始オフセットの手前
  `$CONTEXT_SOURCE_MAX`(内部定数 2000)文字以内(行頭に切り上げ)を
  `source_before`、領域終了オフセットの直後同量以内(行末で切り捨て)を
  `source_after` として生のまま切り出す。マッチしなかった行(見出し・
  箇条書き・キャプション・コード等)もそのまま含まれる。翻訳対象の
  テキスト自体はスライスに含めない(ペイロードとして別途送るため)
- `cache_update` は領域ごとに: dryrun 処理 → マスク →
  `local $call_context = 文脈` を設定して `XLATE(@texts)` → アンマスク →
  検証 → `%cache` へ格納 → **checkpoint 書き出し**(下記)
- エンジン内部の maxlen/maxline バッチングは従来通り(領域内で分割。
  各サブバッチは同じ `$call_context` を共有する)

### 旧対訳の取得(挟み撃ち)

Cache.pm は読み込んだ旧リストの**順序**を保持する。ギャップの最近接
フランク hit キー(前側・後側)を旧リスト内で探し、その 2 位置の間に
ある旧エントリを `old_pairs` として返す。

- 前側フランクが旧リストに見つからない場合はさらに外側のフランクで
  再試行し、尽きたらリスト先頭を境界とする(後側も対称)
- 区間内のエントリのうち、今回の実行で hit しているキーは除外する
  (それは「変更前の同じ箇所」ではない)
- 両側とも境界が定まらない(旧リストが空など)場合は `old_pairs = []`

Cache.pm の新メソッド:

```perl
$cache_obj->old_entries_between($before_key, $after_key);
# → ([原文, 訳文], ...) 旧リスト順。$before_key/$after_key は undef 可
#   (undef はリスト端を意味する)
```

tied ハッシュからオブジェクトへは `tied %cache` でアクセスする。

### エンジン契約の拡張(案 A)

- 文脈対応エンジンはパッケージ変数 `our $XLATE_CONTEXT = 1;` を宣言する。
  setup() がロード後に `${"$mod\::XLATE_CONTEXT"}` を読んで
  `$engine_supports_context` に保持
- コアは XLATE 呼び出しの間だけ `our $call_context`
  (`$App::Greple::xlate::call_context`)に以下のハッシュ参照を設定する:

```perl
{
  source_before => "...",                   # 生テキスト('' 可)
  source_after  => "...",                   # 生テキスト('' 可)
  hits_before   => [ [src, trans], ... ],   # 近い順
  hits_after    => [ [src, trans], ... ],   # 近い順
  old_pairs     => [ [src, trans], ... ],   # 文書順
}
```

- 未対応エンジン(gpty/deepl/null)ではフラグが無いため、postgrep は
  従来フローを使い `$call_context` は常に undef。**呼び出し回数・
  ペイロードとも完全に従来通り**

### プロンプト構成(llm.pm build_system の拡張)

`$call_context` が真のとき、system プロンプト(既存の prompt 展開 +
`--xlate-context` 追記のあと)に以下の 3 節を追記する。対訳は
JSON 配列(`[{"source":...,"translation":...},...]`)で埋め込む:

```
Surrounding document source, shown for context only.
Do NOT translate or output any of it. The passage you will be asked
to translate sits at the [...] marker:
<source_before>
[...]
<source_after>

Reference translations from the surrounding document.
Match their style, tone, and terminology:
<hits_before + hits_after の JSON>

Previous version of the passage you are about to translate
(source and translation before the source was edited).
Where the new source text is unchanged from this previous version,
keep the previous translation's wording exactly; change only what
the source changes require:
<old_pairs の JSON>
```

- 節は対応する内容が空なら省略する(スライスは両側空のとき省略)
- **切り詰め**: 文脈の合計文字数(JSON 化後)が上限
  `$CONTEXT_MAX`(内部定数 8000 文字)を超える場合、次の順に削って
  上限内に収める:
  1. 遠いフランク対訳(W 個のうち外側)から削る
  2. 原文スライスを両側それぞれ 500 文字まで(領域から遠い側を)縮める
  3. 近いフランク対訳を削る
  4. old_pairs の端(文書順で遠い側)から削る
- この指示文はプロトコル指示(JSON 配列で返せ等)と別の節なので、
  `--xlate-prompt` によるユーザ全置換とは干渉しない(全置換時も
  文脈節は追記される)

### オプション

- `builtin xlate-context-window=i $context_window`(既定 2)
- `%opt` キー `context_window`。0 で本機能を完全無効化(postgrep は
  従来フロー)
- POD に追記: 機能説明、既定値、無効化方法、コストへの影響

### キャッシュ逐次書き出し(checkpoint)

- Cache.pm に `checkpoint` メソッドを追加: **saved と current を
  マージ(current 優先)し、purge せずに**ファイルへ書き出す。
  キー順は「旧リスト順を基本に、新規キーはアクセス順で末尾」
- cache_update が各領域の格納後に呼ぶ(ファイル裏付けのある
  キャッシュのみ。dryrun 時は呼ばない)
- 最終書き出し(DESTROY 経由の update)は従来のセマンティクス
  (アクセスされなかったエントリの purge)を維持する

### accumulate の仕様確定

POD の約束「未使用データをファイルに残す」に実装を合わせる:
`--xlate-cache=accumulate` のとき、最終書き出しは常に
saved ∪ current(current 優先)とし、`updated` の値や
`--xlate-update` の有無にかかわらず purge しない。
(現実装は「新規翻訳が 1 件でもあると未使用エントリが消える」)

### dryrun 警告修正

ミスがある状態で dryrun 実行すると、書き出し時に
`: not in cache. at Cache.pm line 164 during global destruction`
の警告が出る(アクセスだけされ値が格納されなかったキーが
順序リストに残るため)。書き出しループで**値のないキーを黙って
スキップ**する。

### dryrun / 進捗表示

- 領域ごとに進捗へ 1 行追加:
  `Context: <n> reference pair(s), <m> previous pair(s)`
- `--xlate-debug` 時は文脈 JSON もダンプする
- dryrun では従来の From 表示に加えて上記 Context 行を出す
  (送信内容の事前確認)

### ローダの require エラー処理修正

現行はエンジン候補の `eval "require $cand; 1"` が失敗理由を問わず
次候補へフォールバックし、エンジンモジュール自体のコンパイルエラーを
握りつぶす。修正:

```perl
(my $path = $cand) =~ s{::}{/}g;
eval "require $cand; 1" and do { $mod = $cand; last };
die $@ unless $@ =~ /^Can't locate \Q$path.pm\E /;
```

- 候補モジュール**自体**が存在しない場合のみフォールバック
- 構文エラーや、候補モジュール内部の依存欠如
  (`Can't locate <別モジュール>.pm`)は die してユーザーに見せる

## エラー処理

- 文脈構築に必要な情報が欠けた場合(旧リスト空、フランク不在等)は
  該当要素を空にして続行する。文脈が全部空でも翻訳は行う
  (節を省略するだけ)
- checkpoint の書き出し失敗は warn して続行(最終書き出しで再挑戦)
- 応答検証(要素数一致)・診断は①のまま

## テスト計画(すべてスタブ llm、API 費用ゼロ)

スタブ llm は argv を記録するので、`-s` の値(system プロンプト)から
文脈節を検証できる。

1. **t/11_llm_context.t(パイプライン)**
   - 準備: 3〜5 段落の原文と、その全対訳が入ったキャッシュ JSON を
     生成(スタブの uc 変換で作ると自己整合的)
   - 中央の 1 段落を変更して実行 → llm 呼び出しは 1 回、system に
     Surrounding source 節(翻訳対象でない見出し行・箇条書き行を
     含むこと)、Reference 節(前後の対訳)、Previous version 節
     (旧ペア)が含まれ、訳文が正しく差し替わる
   - 離れた 2 段落を変更 → 呼び出し 2 回、各領域の文脈が各自の
     近傍のみを含む
   - `--xlate-context-window=0` → 呼び出し 1 回(従来バッチ)、
     文脈節なし
   - キャッシュなし(全ミス)→ 従来バッチ、文脈節なし
   - 連続 2 段落変更 → 1 領域 1 呼び出し、old_pairs に 2 旧ペア
2. **t/12_cache.t(単体)**
   - `old_entries_between` の区間・端・hit 除外・空リスト
   - checkpoint: 途中書き出しに未アクセスの saved が残る(purge
     されない)こと、最終書き出しでは purge されること
   - accumulate: 新規翻訳ありでも未使用エントリが残ること
   - dryrun 相当(アクセスのみのキー)で警告が出ないこと
3. **t/09_llm_loader.t(拡張)**
   - 構文エラーを含むダミーエンジンを一時 @INC に置き、
     フォールバックせず die し、エラーにモジュール名が出ること
   - 存在しないモジュールは従来通りフォールバック
4. **切り詰め(llm.pm 単体)**
   - 巨大なフランクで `$CONTEXT_MAX` 超過時に遠い側から削られること
5. **回帰**: 既存全テスト(75 個)が無変更で通ること。特に
   gpty/deepl/null の経路(従来フロー)が不変であること

実 API での確認は①と同じ手動レシピ(既存キャッシュ + 1 段落変更)を
文脈ありで実行し、旧訳の言い回しが維持されることを目視確認する
(費用 1〜2 円、実行前に承認を得る)。

## 互換性

- キャッシュファイル形式は不変(読み書きとも従来ファイルと互換)
- gpty/deepl/null エンジン: 呼び出し回数・ペイロード・出力とも完全不変
- llm 系エンジン: 変更段落があるときのみプロンプトが文脈分だけ増える。
  無変更なら従来通り API 呼び出しゼロ
- `--xlate-context-window=0` で①の動作に完全に戻せる

## ③(匿名化)との接続

文脈節に含まれる周辺原文(スライス・対訳ペア)・旧訳は**マスク前の
平文**である点に注意(現行の mask は cache_update 内で対象テキストに
だけ適用される)。
③で機密マスクを導入する際は、文脈節にも同じマスクを適用する必要が
ある。本設計では文脈組み立てとマスクの適用順を cache_update 内に
集約してあるため、③での拡張点は cache_update 1 箇所で済む。
