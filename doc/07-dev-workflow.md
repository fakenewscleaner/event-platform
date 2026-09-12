# 07. 開發流程

## Issue 驅動開發

所有工作以 GitHub Issue 為單位：<https://github.com/fakenewscleaner/event-platform/issues>

每個 issue 有一個 repo 層級的 Issue Field `wait_for`，標示目前輪到誰處理：

| `wait_for` 值 | 意義 | 誰處理 |
| --- | --- | --- |
| `AI_plan` | 請 AI 針對 issue 回覆開發計劃，不動程式 | AI |
| `AI_explain` | 請 AI 回答 issue 裡的問題 | AI |
| `AI_code` | 計劃已確認，AI 開始實作並 commit | AI |
| `Humain_review` | AI 做完了，等人類 review（注意拼字是 `Humain`） | 人類 |
| `to_merge` | review 通過，可以合併 | 人類 |

流程：

```
人類開 issue，設 wait_for = AI_plan
  → AI 回覆計劃，改成 Humain_review
    → 人類看計劃，同意就改 AI_code；有疑問就留言並改回 AI_plan / AI_explain
      → AI 實作、commit，改成 Humain_review
        → 人類 review，通過改 to_merge
```

AI 在 `AI_code` 階段若遇到沒釐清的問題，會停下來留言、**不會**改 `wait_for`，等人類回覆。

AI 端的操作細節（GraphQL 查詢、mutation）記在 `.claude/skills/ai-issue-workflow/SKILL.md`。

## 分支與 commit

- `main` 為主分支，隨時可部署。
- 每個 issue 開一個分支：`feat/<issue編號>-<簡述>`，例如 `feat/4-migrations`。
- Commit 訊息用中文或英文皆可，第一行簡述，內文附 `Closes #<n>` 或 `Refs #<n>`。
- 合併用 PR，PR 描述要說明改了什麼、怎麼驗證。

## 程式慣例

### Migration

- 依模組分檔，一個模組一個 migration，見 [03-data-model.md](03-data-model.md) 的「Migration 分組建議」。
- 表名複數（`events`），關聯表單數字母排序（`event_teacher`）。
- 狀態欄位用 `string` + PHP enum，不用 PostgreSQL 原生 enum type。
- 外鍵一律 `foreignId()->constrained()`，刪除行為明確指定（`cascadeOnDelete` 或 `nullOnDelete`）。
- 唯一約束在 migration 內宣告，不只靠程式檢查。

### 資料初始化

`seeders/` 提供：`roles`、`supply_types`、`respond_fields`、`file_categories` 的初始資料，以及本機開發用的假使用者（每種角色一個）。

### 權限

- 用 `spatie/laravel-permission` 的 role；場次層級的判斷（總召、講師）寫在 Policy 裡。
- 每個 controller action 都要有對應的 Policy 或 middleware，不允許「先開著之後補」。

### 測試

- Feature test 至少覆蓋：權限矩陣（每個角色對每個頁面的可／不可）、報名流程、Airtable 同步的欄位對應。
- `php artisan test` 要在 CI 綠燈才能合併。

## 文件更新

- 規格變更先改 `doc/`，再改程式；PR 內兩者一起。
- 試算表是討論工作區，定案後搬進 `doc/`，並在試算表註記「已定案，以 doc 為準」。
