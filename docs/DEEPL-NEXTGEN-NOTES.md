# DeepL Next-Gen Model と split_sentences パラメータの挙動変更

## 概要

2024年Q4以降、DeepL API に next-gen モデル（`quality_optimized`）が導入され、
`split_sentences` パラメータの挙動が変更されました。

## 問題

以前の DeepL API では、入力テキストの行数と出力テキストの行数が一致していました。
しかし、next-gen モデルを使用すると、複数行が1行にまとめられてしまうことがあります。

## 原因

### split_sentences パラメータが無視される

[DeepL API ドキュメント](https://developers.deepl.com/api-reference/translate)によると：

> **The `split_sentences` value will be ignored when using next-gen models**
> (model_type_used=quality_optimized)

Next-gen モデル使用時、`split_sentences` パラメータは無視され、
以下のデフォルト値が使用されます：

- タグ処理なし: `0`（分割なし、入力全体を1文として扱う）
- タグ処理あり: `nonewlines`（改行では分割しない）

### model_type パラメータ

2024年Q4に追加された `model_type` パラメータ：

| 値 | 説明 |
|---|---|
| `latency_optimized` | クラシックモデル使用（従来のデフォルト） |
| `quality_optimized` | next-gen モデル使用（高品質） |
| `prefer_quality_optimized` | next-gen を優先、フォールバックあり |

### デフォルトの挙動

現在の DeepL API は、`model_type` が指定されない場合：

- **通常**: クラシックモデルを使用
- **例外**: 以下の場合は next-gen モデルが使用される
  - タイ語など、next-gen のみサポートの言語
  - `tag_handling_version=v2` 使用時
  - `source_lang` 省略時（自動言語検出）
  - `style_id` または `custom_instructions` 使用時

### 2025年12月時点の状況

> As of December 2025, all source and target languages are supported by next-gen models.

すべての言語ペアで next-gen モデルがサポートされています。

## 対処方法

### 方法1: クラシックモデルを明示的に指定

```
model_type=latency_optimized
```

これにより従来の `split_sentences` の挙動が維持されます。

### 方法2: source_lang を明示的に指定

`source_lang` を省略すると自動言語検出のために next-gen モデルが使用されます。
ソース言語が分かっている場合は明示的に指定することで、クラシックモデルを使用できます。

### 方法3: 入力テキストを1行ずつ送信

各行を個別の API リクエストとして送信すれば、行の対応関係が保たれます。
ただし、API 呼び出し回数が増加します。

## deepl CLI のオプション

`deepl text` コマンドは以下の関連オプションをサポートしています：

```
--split-sentences {0,1,nonewlines}
    control sentence splitting before translation

--model-type {quality_optimized,latency_optimized,prefer_quality_optimized}
    control model used for translation

--show-model-type-used
    print the model type used for each text
```

### 使用例

```bash
# クラシックモデルを使用（split_sentences が有効）
deepl text --to JA --model-type latency_optimized "Hello world"

# next-gen モデルを使用（split_sentences は無視される）
deepl text --to JA --model-type quality_optimized "Hello world"

# 使用されたモデルタイプを表示
deepl text --to JA --show-model-type-used "Hello world"
```

## xlate モジュールへの影響

現在の xlate モジュール（App::Greple::xlate::deepl）は `deepl` CLI を呼び出していますが、
`--model-type` オプションを渡す機能がありません。

### 現在の回避策

1. 環境変数や設定ファイルで deepl CLI のデフォルト動作を変更する（未確認）
2. xlate モジュールを修正して `--model-type` オプションを追加する

### 将来の対応案

xlate モジュールに以下のオプションを追加することを検討：

```
--xlate-deepl-model-type={quality_optimized|latency_optimized|prefer_quality_optimized}
```

## 参考リンク

- [Translate Text - DeepL Documentation](https://developers.deepl.com/api-reference/translate)
- [OpenAPI spec for text translation](https://developers.deepl.com/docs/api-reference/translate/openapi-spec-for-text-translation)
- [DeepL Release Notes](https://developers.deepl.com/docs/resources/release-notes)
- [DeepL Python Library Changelog](https://github.com/DeepLcom/deepl-python/blob/main/CHANGELOG.md)

## 更新履歴

- 2026-01-26: 初版作成
