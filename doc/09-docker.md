# Docker Compose 本機啟動

需要 Docker Engine 與 Docker Compose **2.24+**。在 repo 根目錄執行：

```bash
docker compose up -d --build
docker compose ps -a
docker compose logs init
```

開啟 http://localhost:8000。首次建置需下載 PHP、Node、Composer、nginx、PostgreSQL 映像與套件。init 正常結束時顯示 Exited (0)，失敗時其他 PHP 服務不會啟動，請查看 init logs。

不需要本機 PHP、Composer 或 Node，也不需要先複製 `.env`；Compose 讀 `.env.example`，若已有 `.env` 則覆蓋設定。容器內資料庫 host/port 固定為 `db:5432`，不受本機 `.env` 的 DB_HOST 影響；帳密及資料庫名稱仍沿用 `.env`。本機 PostgreSQL 不會被連入，db 不開放主機 port。

可以在 `.env` 設定 `WEB_PORT=8080` 改用 http://localhost:8080，並相應設定 `APP_URL`。此組設定用於本機開發，HTTP 綁定 127.0.0.1。

## 啟動流程與資料

- PHP image 安裝 Composer 依賴（含開發測試套件）、必要擴充；Node 建置 Vite 資產。
- PostgreSQL 健康檢查成功後，init 產生缺少的 APP_KEY，存到共用 storage volume，再執行 `migrate --force`；若 `.env` 已指定 APP_KEY 則優先使用。
- app、queue 與 scheduler 等 init 成功；nginx 提供 public 資產並將入口 PHP 轉給 app。
- `db_data` 保留資料庫，`app_storage` 保留上傳、log、session 與產生的金鑰。重啟不會換金鑰或重建資料庫。備份時兩個 volume 都要備份。
- 不自動 seed：現有骨架 seeder 會新增測試帳號，業務 seed 由 #4 處理。確實需要時手動執行 `docker compose exec app php artisan db:seed`。

## 常用操作

```bash
# 程式或依賴修改後重建並更新全部服務
docker compose up -d --build
# 查看 log
docker compose logs --tail=100 app web queue scheduler
# 執行 Laravel 指令
docker compose exec app php artisan migrate:status
# 停止並保留資料
docker compose down
```

程式碼沒有 bind mount，修改不會即時反映到容器；每次更新需重建。web 與 app 使用相同 public 資產版本。公開上傳透過 nginx 的 `/storage/` 路徑直接讀取 `storage/app/public`，不需執行 `storage:link`。

`docker compose down -v` 會刪除資料庫、上傳及自動產生的金鑰，只有確定不需資料時才能使用。更改 POSTGRES 帳密不會自動修改既有 volume 內的資料庫帳號；已有資料時需另外執行資料庫帳號變更。

## 驗證

```bash
docker compose config --quiet
docker compose exec app php artisan --version
docker compose exec app php artisan db:show
curl --fail http://localhost:8000/up
```

Feature tests 需要獨立 `event_platform_test` 資料庫，且會重建測試資料表。可在這組開發 db 建立測試資料庫後再執行：

```bash
docker compose exec db sh -c 'createdb -U "$POSTGRES_USER" event_platform_test'
docker compose exec app php artisan test
```

若 Docker 回報 permission denied，請先取得目前登入帳號的 Docker daemon 存取權；Compose 設定檢查不代表容器已完成實際啟動驗證。
