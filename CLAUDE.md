# 專案指引

請讀取並遵循根目錄 `AGENTS.md`、`doc/README.md` 與 `doc/07-dev-workflow.md`。

程式碼在 Docker image 建置時複製，app、queue、scheduler 與 init 共用 PHP image，web 複製同版 public 資產。程式、依賴、環境變數、PHP 擴充、queue／scheduler、儲存或 HTTP 設定變更時，應檢查並提議更新 `docker-compose.yml`、`docker/` 與使用文件 `doc/09-docker.md`。更新容器使用 `docker compose up -d --build`；保留既有資料庫及 storage volumes。
