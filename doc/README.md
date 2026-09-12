# event-platform 專案文件

假新聞清潔劑（FNC）活動／志工管理平台的專案文件。
本資料夾是「單一事實來源」：規格若有變動，請先改這裡，再改程式。

## 文件索引

| 編號 | 文件 | 內容 |
| --- | --- | --- |
| 01 | [專案概述](01-overview.md) | 專案目標、使用者角色、模組總覽、開發階段 |
| 02 | [角色與權限](02-roles-and-permissions.md) | 七種角色定義、頁面／功能權限矩陣 |
| 03 | [資料模型](03-data-model.md) | 資料表、欄位、狀態列舉、關聯表、ER 圖 |
| 04 | [Airtable 對應與同步](04-airtable-sync.md) | Airtable 欄位對應、保留／刪除決策、同步策略 |
| 05 | [功能模組](05-modules.md) | 各模組的功能清單、相依關係、對應資料表 |
| 06 | [技術選型與開發環境](06-tech-stack.md) | Laravel 12、PostgreSQL、Docker Compose、環境變數 |
| 07 | [開發流程](07-dev-workflow.md) | GitHub Issue 的 `wait_for` 機制、分支、migration 慣例 |
| 08 | [開發路線圖](08-roadmap.md) | P0 / P1 / P2 範圍與對應 issue |

## 原始來源

這些文件整理自兩份 Google 試算表（資料模型與 Airtable 欄位整理、功能與權限矩陣）。
試算表仍是討論用的工作區，定案後的內容以本資料夾為準；連結請向專案維護者索取。

## 文件慣例

- 資料表、欄位、狀態值一律使用英文 machine name（例如 `event_data.start_at`），中文名稱只作說明。
- 尚未定案的事項用「**待確認**」標記，並集中列在各文件末段的「待確認事項」。
- 日期用 `YYYY-MM-DD`。
