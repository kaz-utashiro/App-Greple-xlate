# llm バックエンド (gpt5) 設計書

日付: 2026-07-06
ステータス: 承認済み(実装前)
参考資料: docs/llm-backend-reference.md(llm CLI の調査と決定事項)

## 背景と目的

xlate の翻訳エンジンを gpty(OpenAI 専用 CLI)依存から、マルチプロバイダ対応の
`llm` CLI(Simon Willison 製)ベースに刷新する第一段階。本設計は
「gpt5 エンジンの中身を gpty シェルアウトから llm シェルアウトに差し替える」
ことだけを扱う。Claude 等の他プロバイダエンジン、文脈つき差分翻訳、匿名化は
後続サブプロジェクトで扱う。

刷新全体の段階計画:

1. **llm バックエンド新設(本書)** — gpty → llm の基盤差し替え
2. 文脈つき差分翻訳 — 変更段落の翻訳時に周辺段落の原文+既訳を注入
3. 匿名化マスク — 安定仮名マッピング・カテゴリ付きプレースホルダ

## スコープ

- `lib/App/Greple/xlate/llm.pm`(共通基盤)の新設
- `lib/App/Greple/xlate/llm/gpt5.pm`(薄いエンジン定義)の新設
- エンジンローダのバックエンド候補リスト化と `backend` 強制オプション
- スタブ llm によるテスト

## 非スコープ(触らないもの)

- `gpty/` 配下の 4 エンジン(gpt3/gpt4/gpt4o/gpt5)— 削除も変更もしない。
  処遇は別タイミングで判断
- `deepl.pm` — DeepL は今後の設計対象外だがコードは温存
- キャッシュ形式・Cache.pm — accumulate の既知問題(下記)は②で扱う
- Claude エンジン — 共通基盤の上に①'として後日追加
- リトライ・バッチ分割などのエラー回復強化 — ②以降で検討

## 設計

### ファイル構成

```
lib/App/Greple/xlate/
├─ llm.pm          ← 共通基盤(新規)
│    シェルアウト / JSON 配列プロトコル / バッチング / 進捗 / 診断
├─ llm/
│   └─ gpt5.pm     ← 薄い定義(新規): モデル名・プロンプト・-o オプション表
├─ gpty/           ← 触らない
└─ deepl.pm        ← 触らない
```

### llm.pm(共通基盤)

gpty/gpt5.pm の `xlate` / `xlate_each` / `gpty` / `_progress` を、エンジン固有
パラメータをハッシュで受け取る形に一般化して移設する。

エンジンから見たインターフェース:

```perl
App::Greple::xlate::llm::xlate_with(\%param, @from);  # 訳文リストを返す
```

`%param` のキー:

- `model` — llm の `-m` に渡すモデル ID(例 `gpt-5.5`)
- `prompt` — system プロンプト。`%s` があれば `Lang.pm` の `%LANGNAME` で
  対象言語名に展開(未知コードは die、現行踏襲)
- `options` — `-o KEY VALUE` の組の配列(順序を保つためハッシュでなく配列のペア)
- `max` — バッチ上限文字数のデフォルト(`--xlate-maxlen` 未指定時)

共通基盤が担う処理(いずれも現行 gpty/gpt5.pm のロジックを移設):

1. **コマンド構成**: `llm -m MODEL -s SYSTEM -o KEY VALUE ... --no-stream --no-log`。
   本文 JSON は stdin へパイプ(位置引数は与えない。llm-backend-reference.md §1)。
   実行は Command::Run(既存依存、新規 Perl 依存なし)
2. **`--xlate-prompt`** 指定時は `%param->{prompt}` を全置換(現行踏襲)
3. **`--xlate-context`** は system プロンプト末尾に
   `Translation context:` として追記(現行踏襲)
4. **JSON 配列プロトコル**: 入力ブロック群を行に分割 → JSON 配列にエンコード →
   応答をデコード → 要素数検証(不足なら die)→ 元ブロックの行数で再組立
5. **バッチング**: `--xlate-maxlen`(既定は `$param->{max}`)まで貪欲に詰め、
   `--xlate-maxline` を安全弁として尊重(現行踏襲)
6. **進捗表示**(`--xlate-progress`)と **デバッグダンプ**(`--xlate-debug` で
   コマンドラインを warn)

注意: ローダは `$lang_from` / `$lang_to` を**エンジンパッケージ**
(llm::gpt5)のパッケージ変数に注入する(xlate.pm:691-692)。共通基盤は
自パッケージにこれらを持たないため、呼び出し元エンジンのパッケージ変数を
参照する(`caller` で呼び出し元パッケージを特定するか、エンジンの `xlate`
が `%param` に詰めて渡す。実装時にどちらかを選ぶ)。

**②への前方互換**: ②(文脈つき差分翻訳)では xlate.pm 側
(postgrep / cache_update / エンジン契約)が拡張され、翻訳対象と一緒に
文脈情報(周辺段落の原文+既訳、変更前の旧訳)がエンジンに渡るようになる。
①の時点で文脈機能は実装しないが、llm.pm は以下を守って作る:

- system プロンプトの組み立て(prompt 展開 + context 追記)を 1 関数に
  集約し、②で文脈項目を追加する変更が局所で済むようにする
- `xlate_with` の引数は「パラメータハッシュ + テキストリスト」とし、
  ②で呼び出し単位のオプション(文脈など)を追加できる余地を残す
  (フラットな引数リストに直接依存する書き方をしない)

### llm/gpt5.pm(薄いエンジン定義)

```perl
model   => 'gpt-5.5',
max     => 3000,
options => [ [ reasoning_effort => 'none' ],
             [ verbosity        => 'low'  ],
             [ max_tokens       => 16000  ] ],
prompt  => (gpty/gpt5.pm の prompt と一字一句同一),
```

- **temperature は渡さない**。llm は指定時のみ送信し、reasoning モデルは既定外
  の temperature を拒否するため、省略が正しい(llm-backend-reference.md §3)。
  gpty 版の `temp => '1'` は移設しない
- `max_completion_tokens` は llm では `-o max_tokens`(Responses API では
  `max_output_tokens` として送られる)
- `initialize()` は現行同様
  `setopt(default => "-Mxlate --xlate-engine=gpt5")`
- `our $lang_from //= 'ORIGINAL'; our $lang_to //= 'JA';` は現行踏襲
- 新規モジュールの `$VERSION` は dist の現行バージョンに合わせる

### エンジンローダ(xlate.pm setup)

現行(xlate.pm:682): `my $backend = 'gpty';` のハードコード。

変更後: バックエンド候補をリスト化し、次の順で `require` を試す。

```
llm::<engine> → gpty::<engine> → <engine>
```

- `--xlate-engine=gpt5` は llm::gpt5 に解決される(切り替えの実体)
- `--xlate-engine=gpt3|gpt4|gpt4o` は llm:: に存在しないため従来通り
  gpty:: に解決される(挙動不変)
- `deepl` / `null` は bare 名に解決される(挙動不変)

**backend 強制オプション**: `--xlate-setopt backend=gpty` のように指定すると
候補を `<backend>::<engine> → <engine>` に絞る。移行期に gpty 版と llm 版の
出力を比較検証する用途。`%opt` に `backend`(既定 `''` = 自動順)を追加する
だけで、専用コマンドラインオプションは作らない。

### エラー処理と環境診断

- **事前チェックはしない**(毎回 `llm models` を実行すると Python 起動分の
  レイテンシがかかる)。llm 呼び出しが失敗したとき(exec 失敗または非ゼロ終了)
  に限り診断を行い、原因別のメッセージで die する:
  - `llm` コマンドが見つからない → インストール方法を案内
    (`pip install llm` / `pipx install llm`)
  - モデルが未知(`llm models` に `gpt-5.5` がない)→ llm の更新
    (0.32+ 推奨)または `extra-openai-models.yaml` を案内
  - それ以外 → llm の stderr をそのまま提示
- **バージョン番号ではなくモデルの有無で判定する**。リファレンス §4 は
  「0.32+ 必須」とするが、実環境の llm 0.31 でも gpt-5.5 は組み込み済み
  (Chat Completions 経由)であることを確認済みのため、`llm models` の
  出力に基づく検出の方が頑健
- 応答要素数の不一致 die は現行のまま(回復強化はスコープ外)
- API キーは llm 自身が `OPENAI_API_KEY` または保存キー(`llm keys`)を読む。
  xlate 側でのキー処理は行わない

### キャッシュ互換性

- キャッシュファイル名は bare エンジン名を使う(xlate.pm cache_file)ため、
  llm::gpt5 でも `.xlate-gpt5-<LANG>.json` のまま。既存キャッシュ資産
  (docs/ 配下の git 管理 JSON 含む)をそのまま継承する
- 同一プロンプト・同一モデル・`reasoning_effort none` なら gpty と同等出力
  という前提(llm-backend-reference.md §9)。llm 0.31 では gpt-5.5 が gpty と
  同じ Chat Completions エンドポイントを使うため、同等性はより強く成立する。
  0.32+ では Responses API になるが、許容範囲とする(厳密比較が必要なら
  `-o chat_completions 1` を手動指定できる)
- キャッシュキー(Text.pm の正規化)には一切手を入れない

### プライバシー上の注意

`--no-log` を常時付与する。llm は既定でプロンプト/応答をローカル sqlite
(`logs.db`)に記録するため、これを抑止しないと翻訳原文がローカル DB に
蓄積される(DB 肥大防止に加え、③匿名化の観点でも必須)。

## テスト計画

- `t/` にスタブ `llm` 実行ファイル(Perl スクリプト)を置き、`PATH` を
  差し替えてテストする。スタブは:
  - 渡された引数を記録ファイルに書き出す(コマンド構成の検証用)
  - stdin の JSON 配列を読み、決定的な変換(例: 各要素に接頭辞付与)を
    JSON 配列で返す
  - 環境変数指定で異常系(非ゼロ終了、要素数不足、不正 JSON)を再現できる
- 検証項目:
  1. コマンド構成(`-m gpt-5.5`、`-o` 3 種、`--no-stream --no-log`、
     temperature 非送出、stdin 渡し)
  2. JSON プロトコルの往復(行分割・再組立・末尾改行の扱い)
  3. バッチ分割(maxlen/maxline)
  4. 要素数不一致で die
  5. ローダ解決順: `--xlate-engine=gpt5` が llm::gpt5 に解決されること、
     gpt4o が gpty:: に解決されること、`backend=gpty` 強制が効くこと
  6. 失敗時診断メッセージ(llm 不在・モデル未知)
- 既存テスト(00_compile / 01_unit / 02_run、null エンジン)は無変更で
  通ること
- **実 API での同等性確認は手動ステップ**とし、実行前に費用を確認する
  (小さなファイルで gpty 版と llm 版のキャッシュヒット状況を比較)

## ドキュメント更新

- llm/gpt5.pm に POD(llm CLI 要件、OPENAI_API_KEY、関連オプション、
  gpty 版との関係)
- llm.pm に共通基盤としての簡潔な POD
- xlate.pm のローダ周辺コメントの更新(gpty ハードコード前提の記述を修正)
- README 再生成は Minilla のリリースフローに任せる(本作業では POD 変更を
  最小限に留める)

## 既知問題の記録(本設計では扱わない)

調査で確認した、後続作業で扱うべき問題:

1. **`--xlate-cache=accumulate` の POD と実装の食い違い**: POD は「未使用
   データをファイルに残す」と無条件に説明するが、Cache.pm:124-135 の実装は
   新規翻訳が 1 件でもある実行では未使用エントリを purge する。②のキャッシュ
   作業でセマンティクスを確定する
2. **キャッシュ書き出しが tie の DESTROY 頼み**: 長時間の API 呼び出し中に
   プロセスが落ちるとその実行分の翻訳が失われる。逐次書き出し(チェック
   ポイント)は②で検討
3. **文脈の構造的欠落**: postgrep はキャッシュミスした段落だけを孤立させて
   エンジンに送る。②の主題。xlate.pm の本格改修は②で行う。特定済みの
   改修ポイント: postgrep(xlate.pm:708-725、全マッチのヒット/ミスを
   順序つきで知る唯一の場所。ミス段落に周辺段落の原文+既訳を紐づける)、
   cache_update(xlate.pm:742-758、フラット配列 → 構造化データへ)、
   エンジン契約(XLATE に文脈を渡す経路の追加)、Cache.pm(purge で
   捨てられる変更前の旧訳を参考訳として取り出す経路)
4. **マスク機構の限界**: キャッシュに平文が残る・出現ごとに別 ID・カテゴリ
   情報なし。③の主題
