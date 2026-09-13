# 專案開發指引

先讀 `doc/README.md` 與 `doc/07-dev-workflow.md`，需求與資料模型以 `doc/` 及 issue 最新決議為準。

## 程式碼與 Docker Compose

`docker-compose.yml` 的 app、init、queue、scheduler 共用 `docker/Dockerfile`，在建置時複製根目錄程式、安裝 Composer 依賴並建置 Vite 資產；web 由 `docker/web.Dockerfile` 複製相同版本的 public 資產。容器不直接掛載本機程式碼，修改後用 `docker compose up -d --build` 更新。

修改 PHP 擴充、Composer／npm 依賴、前端產物、環境變數、資料库連線、queue、scheduler、上傳儲存或 HTTP 設定時，必須檢查是否影響 Dockerfile、Compose、entrypoint 或 nginx 設定；若有影響，要提出並一併更新相應容器設定與 `doc/09-docker.md`，說明驗證結果。

init 負責持久化 APP_KEY 及 migration，其他 PHP 服務等待 init 成功。資料庫與 storage 使用 named volumes；不得為了驗證清除使用者既有 volume。容器驗證請使用獨立 Compose project。
