# xlate の llm バックエンド向け `llm` CLI リファレンス

App::Greple::xlate に `llm` ベースの翻訳バックエンドを実装する（`gpty` バック
エンドの置き換え）ための参考資料。一次情報は `llm` のソース
（`~/Clone/llm`、バージョン **0.32a3**）と CLI の実機確認。

`llm` は Simon Willison 製の各種 LLM 用コマンドラインクライアント
（<https://llm.datasette.io/>）。活発にメンテされ PyPI で配布され、xlate /
texlive-pandoc-ja の Docker イメージにも導入済み。`gpty`（OpenAI 専用）と
違い、プラグイン経由で OpenAI・Anthropic/Claude・Gemini などに到達できる。

---

## 1. xlate が必要とする呼び出し

xlate のエンジンがやることは「テキストを入れ、訳文を受け取る。system プロン
プトといくつかのモデルオプションを添えて」だけ。`gpty` の呼び出しはそのまま
対応づく。

```sh
printf '%s' "$json" | llm -m gpt-5.5 \
    --system "$system_prompt" \
    -o reasoning_effort none \
    -o verbosity low \
    -o max_tokens 16000 \
    --no-stream --no-log
```

- **stdin**（パイプ）がユーザプロンプトになる。位置引数のプロンプトも与える
  と `stdin + " " + 引数` で連結されるので、**本文は stdin に流し、位置引数は
  与えない**こと。（`llm/cli.py: read_prompt()`）
- **stdout** にはモデルの回答テキストのみが出る（gpty 同様にそのまま取得可）。
- エラーは **stderr**、失敗時は非ゼロ終了。

これは現行の `gpty --engine ... --system ... -` と同じ使い方。

---

## 2. xlate に関係する `llm prompt` オプション

（`prompt` は既定サブコマンドなので `llm ...` == `llm prompt ...`）

| オプション | xlate での用途 |
|---|---|
| `-m, --model ID` | 使用モデル（例 `gpt-5.5`）。環境変数 `LLM_MODEL`。 |
| `-s, --system TEXT` | system プロンプト（翻訳指示）。 |
| `-o, --option KEY VALUE` | モデルオプション。複数可。gpty のパラメータを対応。 |
| `--no-stream` | ストリーミングせず一括で返す。 |
| `-n, --no-log` | プロンプト/応答を llm の sqlite ログに**書かない**。バッチ翻訳では DB 肥大防止に付ける。 |
| `-R, --hide-reasoning` | reasoning 出力を抑制（保険。`reasoning_effort none` なら元々出ない）。 |
| `--key KEY` | API キー上書き（無指定なら環境変数/保存キー）。 |
| `--options` | （診断）選択モデルの利用可能オプションを表示。 |
| `-u, --usage` | （診断）トークン使用量を stderr に表示。 |

xlate に不要: 添付（`-a`）、ツール（`-T`/`--functions`）、フラグメント
（`-f`）、テンプレート（`-t`）、スキーマ、会話継続（`-c`/`--cid`）。

---

## 3. モデルオプション（`-o key value`）

OpenAI モデルのオプションは `SharedOptions` ＋モデル別の追加
（`llm/default_plugins/openai_models.py`）。

共通（全 OpenAI モデル）: `temperature`、`max_tokens`、`top_p`、
`frequency_penalty`、`presence_penalty`、`stop`、`logit_bias`、`seed`、
`json_object`。

reasoning モデルの追加オプション:

- **`reasoning_effort`** — 列挙: `none`, `minimal`, `low`, `medium`,
  `high`, `xhigh`（出典 `ReasoningEffortEnum`）。低いほど高速・トークン少。
  xlate は翻訳用途で **`none`**。
- **`verbosity`** — 列挙: `low`, `medium`, `high`（`VerbosityEnum`）。
  xlate は **`low`**。
- **`chat_completions`** — 真値で `/v1/responses` でなく旧
  `/v1/chat/completions` を強制（§5 参照）。

注意:

- **`max_tokens`** が出力上限。Responses API モデルでは
  `max_output_tokens` として送られる（gpty の `--max-completion-tokens`）。
- **`temperature`**: gpt-5.5 では**渡さない**こと。llm はオプションを指定した
  ときだけ temperature を送る。reasoning モデルは既定以外の temperature を
  拒否するので、付けないのが正しい（gpty は特別処理していたが、llm では単に
  `-o temperature` を付けなければよい）。
- 未知/非対応の `-o` キーは llm がモデルのオプション定義に照らして拒否する。
  指定はモデルが宣言するものに限る。確認は `llm models --options`。

### gpty → llm オプション対応

| gpty | llm |
|---|---|
| `--engine gpt-5.5` | `-m gpt-5.5` |
| `--system TEXT` | `-s TEXT` |
| `--reasoning-effort none` | `-o reasoning_effort none` |
| `--verbosity low` | `-o verbosity low` |
| `--max-completion-tokens 16000` | `-o max_tokens 16000` |
| `--temperature 1`（gpt-5* では無視） | *（省略）* |
| stdin `-` | stdin（パイプ） |

---

## 4. gpt-5.5 モデルの利用可否

- **llm 0.32+ は `gpt-5.5`（および `gpt-5.5-2026-04-23`）を組み込みモデルと
  して同梱**。**Responses API** 経由・`reasoning=True`・`verbosity=True` で
  登録済み（出典 `openai_models.py` の "GPT-5.5" ブロック）。よって新しめの
  llm なら**追加設定なしで `-m gpt-5.5` がそのまま使える**。
- 古い llm（例: ホストの 0.27.1）は `gpt-5` までしか知らず `verbosity` も無い。
  **したがって llm バックエンドは新しめの llm を要求すべき**（gpt-5.5 を含む
  バージョン＝0.32+ を要件に）。
- 各環境での確認: `llm models | grep gpt-5.5`。

---

## 5. Responses API と Chat Completions

新しい OpenAI モデル（gpt-5.x）は llm では既定で **`/v1/responses`** を使う。
gpty は旧 **`/v1/chat/completions`** を使っていた。xlate から見た差:

- 出力は変わらず stdout のプレーンテキスト。呼び出し方は同じ。
- `max_tokens` は自動的に `max_output_tokens` になる。
- 旧エンドポイントを強制したい場合（gpty との対比検証など）は
  `-o chat_completions 1`。

---

## 6. カスタムモデル登録（フォールバック）

インストール済み llm が gpt-5.5 より古い場合や、私設/プロキシのモデルを足す
場合のみ必要。ファイル: `<llm user dir>/extra-openai-models.yaml`
（macOS: `~/Library/Application Support/io.datasette.llm/`。場所は
`dirname "$(llm logs path)"` で判明）。書式（`openai_models.py` のローダ）:

```yaml
- model_id: gpt-5.5
  model_name: gpt-5.5
  responses: true        # Responses API を使う（省略すると Chat Completions）
  reasoning: true        # -o reasoning_effort を有効化
  supports_schema: true
  # aliases: [5.5]
  # api_base: https://...   # OpenAI 互換プロキシ向け
```

推奨方針: **このファイルを同梱せず、新しめの llm を要求して組み込みの
`gpt-5.5` に頼る**。

---

## 7. API キー

- 環境変数 `OPENAI_API_KEY` を読む（gpty と同じ）。または `llm keys set
  openai` で保存（llm user dir の `keys.json`）、あるいは `--key`。
- プラグインごとのキーは別（例 `llm keys set gemini`）。

---

## 8. マルチプロバイダ（将来のエンジン）

gpty より llm を選ぶ理由＝プラグインで他プロバイダに対応できる（Docker
イメージに導入済み）:

- `llm-gemini` → `gemini-2.5-pro` 等
- `llm-anthropic`（`llm-claude-3` の後継）→ `claude-...` 系
- `llm-openrouter`、`llm-perplexity` など

各プラグインは独自のモデル ID と `-o` オプションを持つ（reasoning 系の制御は
プロバイダごとに異なる）。導入済み一覧は `llm models`、モデル別オプションは
`llm models --options -m MODEL`。汎用 llm バックエンドなら `-m` と `-o` を
変えるだけで Claude/Gemini の翻訳エンジンも出せる——最初の gpt-5.5 ステップの
範囲外だが、これが移行の動機。

---

## 9. xlate 実装に向けたメモ・決定事項

- **バックエンド呼び出し**: `gpty/gpt5.pm` の `gpty()` シェルアウトを `llm`
  シェルアウト（Command::Run）に置換。JSON 配列を stdin に流し、`-s` で
  system、`-o` で reasoning_effort/verbosity/max_tokens、加えて
  `--no-stream --no-log`。JSON 配列プロトコル（`xlate`/`xlate_each`）は
  バックエンド非依存なのでそのまま再利用。
- **バージョンガード**: `gpt-5.5` を知る程度に新しい llm（0.32+）を要求/検出。
  足りなければ明確なメッセージで失敗させる。
- **再現性/同等性**: 同一モデル＋`reasoning_effort none` なら gpty バックエンド
  と同等の結果になる前提（移行の仮定）なので、共通の `gpt5` キャッシュは有効
  のまま。厳密に合わせたい場合は `-o chat_completions 1` で gpty と同じ
  エンドポイントを再現。
- **出力の清浄性**: stdout に訳文のみが出るようにする——`--no-stream` を使い、
  `reasoning_effort none` で reasoning は出ず、`-R` も保険として使える。
- **エラー**: 非ゼロ終了＋stderr。gpty 経路と同様に利用者へ伝える。

---

*出典: `~/Clone/llm` @ 0.32a3 — `llm/cli.py`（`prompt` オプション、
`read_prompt`）、`llm/default_plugins/openai_models.py`（`SharedOptions`、
`ReasoningEffortEnum`、`VerbosityEnum`、`build_options_class`、GPT-5.5 を
含むモデル登録、`extra-openai-models.yaml` ローダ）、公式 docs
`docs/openai-models.md`、`docs/usage.md`。*
