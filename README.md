# FNC Event Platform

假新聞清潔劑活動／志工管理平台。規格與開發流程見 [doc/README.md](doc/README.md)。

## 本機啟動

需要 PHP 8.2+（含 `pdo_pgsql`，`db:show` 另需 `intl`）、Composer 2、PostgreSQL 16，以及前端建置用的 Node.js 20.19+ 或 22.12+。

1. 建立 PostgreSQL 資料庫 `event_platform` 與獨立的 `event_platform_test`，讓開發帳號有建表權限。
2. 複製設定並安裝依賴：

   ```bash
   cp .env.example .env
   composer install
   ```

3. 修改 `.env` 的資料庫連線。本機直連請將 `DB_HOST=db` 改為 `127.0.0.1`；`secret` 只供本機開發使用，實際帳密放在不進版控的 `.env`。
4. 啟動：

   ```bash
   php artisan key:generate
   php artisan migrate
   npm install
   npm run build
   php artisan serve
   ```

開啟 http://localhost:8000。需要 queue、Vite 等開發程序時可改用 `composer run dev`。
Docker Compose 由 issue #3 建立，目前尚未提供一鍵容器啟動。

## 驗證

```bash
php artisan --version
php artisan db:show
php artisan test
vendor/bin/pint --test
```

測試沿用 `.env` 的 PostgreSQL host、port、帳密，但 `phpunit.xml` 強制使用 `event_platform_test`，並清空 `DB_URL`，避免連到開發資料庫。測試會在測試資料庫重建 migration；請勿放入需保留的資料。

應用程式與資料庫儲存時間統一為 UTC，顯示時區設定為 `Asia/Taipei`，實際顯示與表單轉換請依 [時區規範](doc/06-tech-stack.md#時區)。

本次提供 Laravel 12 原廠骨架及 PostgreSQL 設定。前端 starter kit 尚未選定；業務 migration、Airtable 同步、Spatie 權限及 CI 分別由 #4、#5、#6、#7 處理。
