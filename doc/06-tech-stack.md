# 06. 技術選型與開發環境

## 技術選型

| 項目 | 選擇 | 理由／備註 |
| --- | --- | --- |
| 後端框架 | Laravel 12 | 穩定版；13 屬嘗鮮版暫不用（issue #2） |
| 語言 | PHP 8.2+ | Laravel 12 最低需求 |
| 套件管理 | Composer 2 | |
| 資料庫 | PostgreSQL 16 | `.env.example` 預設 `DB_CONNECTION=pgsql` |
| 權限 | spatie/laravel-permission | 角色與使用者對應直接用套件表 |
| 前端 | **待確認** | 候選：Blade + Livewire、Inertia + Vue。P0 以最少前端建置為原則 |
| 佇列 | database driver（P0） | 通知模組需要；之後可換 Redis |
| 排程 | Laravel scheduler | Airtable 同步 |
| 檔案儲存 | local disk（P0） | 照片、活動檔案；之後可換 S3 相容儲存 |
| 容器 | Docker Compose | 一鍵啟動（issue #3） |

## 專案結構

Laravel 骨架建在 repo 根目錄，讓 docker compose 直接以根目錄為 context。

```
event-platform/
├── app/
│   ├── Models/
│   ├── Http/Controllers/
│   ├── Enums/               # 狀態列舉
│   ├── Services/Airtable/   # 同步邏輯
│   └── Console/Commands/    # airtable:sync 等指令
├── database/
│   ├── migrations/          # 依模組分檔，見 03-data-model.md
│   └── seeders/             # roles、supply_types、respond_fields、file_categories 初始資料
├── doc/                     # 本資料夾
├── docker/                  # Dockerfile、nginx 設定
├── docker-compose.yml
├── .env.example
└── .claude/skills/          # AI 開發流程 skill
```

P0 先用標準 Laravel 目錄；模組多了再考慮 `app/Modules/<Module>/` 拆分，避免過度設計。

## Docker Compose（issue #3）

使用 Docker Compose 2.24+，clone 後執行 `docker compose up -d --build`，開啟 http://localhost:8000。
完整使用方式、服務關係、資料保存與驗證指令見 [09-docker.md](09-docker.md)。

| 服務 | 映像 | 用途 |
| --- | --- | --- |
| `init` | 共用 PHP image | 產生並保存金鑰、執行 migration，成功後其他 PHP 服務才啟動 |
| `app` | php:8.2-fpm-bookworm 自建 | Laravel（含 Composer 依賴與 Node 22 建置的前端資產） |
| `web` | nginx:stable-alpine 自建 | 靜態資產與 FastCGI 入口 |
| `db` | postgres:16 | 資料庫，volume 持久化 |
| `queue` | 同 app | `php artisan queue:work` |
| `scheduler` | 同 app | `php artisan schedule:work` |

程式碼在 image 建置時複製，修改後需要重新 `docker compose up -d --build`。
首次啟動不自動執行業務 seed；依需要手動 `docker compose exec app php artisan db:seed`。

## 環境變數

`.env.example` 進版控作為範本，`.env` 不進版控。

```
APP_NAME="FNC Event Platform"
APP_ENV=local
APP_KEY=
APP_URL=http://localhost
APP_LOCALE=zh_TW
APP_TIMEZONE=UTC
APP_DISPLAY_TIMEZONE=Asia/Taipei

DB_CONNECTION=pgsql
DB_HOST=db
DB_PORT=5432
DB_DATABASE=event_platform
DB_USERNAME=postgres
DB_PASSWORD=secret

QUEUE_CONNECTION=database

# Airtable sync (issue #5)
AIRTABLE_API_TOKEN=
AIRTABLE_BASE_ID=
AIRTABLE_EVENT_TABLE=
AIRTABLE_TEACHER_TABLE=
AIRTABLE_SYNC_SINCE=2025-10-01

# 歷史統計基底（2025-10 前已辦成場次）
STATS_HISTORICAL_EVENT_COUNT=900
```

`secret` 僅供本機開發；正式環境請使用獨立帳密。實際 `.env` 不進版控。

## 時區

**`APP_TIMEZONE=UTC`（Laravel 預設值，固定不改），資料庫一律存 UTC，只在顯示時轉 `Asia/Taipei`。**

理由：Airtable 回傳的時間是帶時區位移的 ISO 8601，轉成 UTC 沒有歧義；套件（queue delay、scheduler、
`timestamps`）都以 app timezone 運作，維持 Laravel 預設最不會有意外；台灣沒有日光節約時間，顯示轉換是無損的。

Laravel 的具體做法：

1. `config/app.php` 加一個顯示用時區，跟運算用時區分開：

   ```php
   'timezone' => env('APP_TIMEZONE', 'UTC'),
   'display_timezone' => env('APP_DISPLAY_TIMEZONE', 'Asia/Taipei'),
   ```

2. 顯示層統一走一個 Blade component（或 Carbon macro），不要在各頁面自己 `->timezone()`：

   ```php
   // app/Providers/AppServiceProvider.php  boot()
   Carbon::macro('local', fn (string $format = 'Y-m-d H:i') => $this
       ->copy()
       ->timezone(config('app.display_timezone'))
       ->format($format));
   ```

   ```blade
   {{ $event->data->start_at->local() }}
   ```

3. 表單送進來的時間是台北時間，存檔前明確轉換，不要依賴預設：

   ```php
   $startAt = CarbonImmutable::createFromFormat(
       'Y-m-d H:i', $request->input('start_at'), config('app.display_timezone')
   )->utc();
   ```

4. 排程任務要用台北時間思考時，明講時區，不要靠 app timezone：

   ```php
   Schedule::command('airtable:sync')->everyFifteenMinutes();
   Schedule::command('report:daily')->dailyAt('09:00')->timezone(config('app.display_timezone'));
   ```

5. Migration 用 `timestamp()` 即可，不用 `timestampTz()`：既然全部存 UTC，多存一份位移沒有意義；
   未來真要跨時區，改 schema 的成本也低於現在多背一層複雜度。

## 本機開發需求

- Docker 與 Docker Compose v2
- 若不用 Docker：PHP 8.2+、Composer 2、PostgreSQL 16、Node 20+（前端建置時）

## 待確認事項

- 前端方案。
- 正式環境部署位置（VPS？雲端？）與 CI/CD。
- OAuth 提供者（Google？LINE？）。
