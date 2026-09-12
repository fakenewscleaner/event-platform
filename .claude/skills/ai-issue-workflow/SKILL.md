---
name: ai-issue-workflow
description: 掃描 fakenewscleaner/event-platform 的 open issue，處理 wait_for 欄位是 AI_plan / AI_explain / AI_code 的 issue（回覆計劃、回答問題、或動手開發並 commit），完成後把 wait_for 改成 Humain_review。當使用者要求「處理 AI issue」「跑 AI_plan/AI_code 流程」時使用。
---

# AI Issue Workflow

這個 repo 用一個叫 `wait_for` 的 **repo 層級 Issue Field**（不是 GitHub Projects 的欄位！）來標示每個 issue 目前輪到誰處理。

## 欄位位置的踩雷紀錄（重要）

`wait_for` **不是**：
- Issue 的 label
- GitHub Projects v2 的自訂欄位（`repository.projectsV2` / `organization.projectsV2`）
- Issue Types（`repository.issueTypes`，那個只有 Task/Bug/Feature）

`wait_for` **是** GitHub 較新的「Issue Fields」功能，掛在 `Issue.issueFieldValues` 和 `Repository.issueFields` 上，是一個 union type，查詢時要用 inline fragment：

```graphql
# 1. 找出所有 issue 目前的 wait_for 值
query {
  repository(owner: "fakenewscleaner", name: "event-platform") {
    issues(first: 20, states: OPEN) {
      nodes {
        number
        title
        issueFieldValues(first: 20) {
          nodes {
            ... on IssueFieldSingleSelectValue {
              name
              field { ... on IssueFieldSingleSelect { name } }
            }
          }
        }
      }
    }
  }
}
```

```graphql
# 2. 拿到 wait_for 欄位本身、所有選項的 id、以及要更新的 issue 的 node id
query {
  repository(owner: "fakenewscleaner", name: "event-platform") {
    issueFields(first: 20) {
      nodes {
        ... on IssueFieldSingleSelect {
          id
          name
          options { id name }
        }
      }
    }
    issue(number: 2) { id number }
  }
}
```

```graphql
# 3. 更新某個 issue 的 wait_for 值
mutation {
  updateIssueFieldValue(input: {
    issueId: "<issue node id>",
    issueField: {
      fieldId: "<wait_for 的 fieldId>",
      singleSelectOptionId: "<目標選項的 id>"
    }
  }) {
    issue { number }
  }
}
```

用 `gh api graphql -f query='...'` 執行以上查詢/mutation 即可，不需要額外套件。

**選項拼字要注意**：完成後要設回去的值，實際選項名稱是 **`Humain_review`**（不是 `Human_review`，是原本設定時的拼字），下 mutation 前務必用步驟 2 的查詢重新確認一次目前 repo 裡實際存在的選項名稱與 id，不要憑記憶硬編。

其他已知選項：`AI_plan`、`AI_explain`、`AI_code`、`Humain_review`、`to_merge`。

## 執行流程

1. 用 `gh issue list --repo fakenewscleaner/event-platform --state open` 列出所有 open issue。
2. 用上面的查詢 1，找出 `wait_for` 是 `AI` 開頭（`AI_plan` / `AI_explain` / `AI_code`）的 issue。
3. 對每個符合的 issue：
   - 用 `gh issue view <number> --repo fakenewscleaner/event-platform --comments` 讀完整內文與所有留言。
   - 讀專案中相關的檔案（如果 repo 裡已經有程式碼的話）。
   - 指派一個 subagent 執行對應動作：
     - **`AI_plan`**：針對 issue 內容回覆接下來的開發計劃，盡量簡潔，能先寫程式碼就先寫出來並說明。只回覆留言，不動手開發、不 commit。
     - **`AI_explain`**：針對討論內容回答問題，只回覆留言。
     - **`AI_code`**：表示計劃已確認，開始實際開發，完成後發一個 commit。開發過程中如果有任何問題沒有釐清，就暫停、不要硬做，回覆該 issue 說明問題卡在哪裡，然後停下來等人類回應（不要把 wait_for 改成 Humain_review）。
   - 留言用 `gh issue comment <number> --repo fakenewscleaner/event-platform --body-file <暫存檔>`（內容先寫進暫存檔再用 `--body-file`，避免 shell 轉義問題）。
4. 對於已經完整完成 `AI_plan` 回覆或 `AI_explain` 回答、或 `AI_code` 開發並成功 commit 的 issue，用上面的 mutation 3 把該 issue 的 `wait_for` 改成 `Humain_review`。
5. 向使用者回報：處理了哪些 issue、各自做了什麼、留言連結、（若有）commit hash、以及是否有卡住需要人類決策的 issue。

## 其他背景

- 這個 repo 目前（2026-09-12）幾乎是全新專案，一開始沒有任何 commit。
- `fakenewscleaner` 這個 org 的 project 建立權限（`viewerCanCreateProjects`）預設可能是關閉的，如果之後真的需要用到 GitHub Projects v2（而不是這個 issueFields 機制），要先請有權限的人去 org 設定開放，或請人直接在網頁建立好再給連結，API 端無法直接建立/修改。
