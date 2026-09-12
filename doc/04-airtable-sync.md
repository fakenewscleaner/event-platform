# 04. Airtable 對應與同步

## 原則

1. **P0 階段 Airtable 仍是活動的建檔來源。** 志工平台不建活動，只從 Airtable 匯入。
2. **單向同步：Airtable → 系統。** 系統不回寫 Airtable。
3. **Airtable 來的欄位在系統內唯讀。** 要改就去 Airtable 改，下次同步會覆蓋。
4. **系統自有欄位獨立存放。** 志工需求數、預計學員人數、給志工看的備註等 Airtable 沒有的欄位，同步時不會被覆蓋。
5. **完整 payload 存快照。** 每筆 record 的原始 fields 存進 `event_at_data.payload`，欄位對應之後改了可以重跑。
6. **API token 只放 `.env`。** `AIRTABLE_API_TOKEN`、`AIRTABLE_BASE_ID`、表名等一律環境變數，不進版控。

## 同步流程

```
排程（每 N 分鐘）或手動 artisan 指令
  └─ 依 Airtable 表分頁拉取 records
       └─ 每筆 record：
            1. 以 airtable_record_id 找 event_data；沒有就新建 event + event_data
            2. 寫入 / 更新 event_at_data.payload（原始快照）
            3. 依下方對應表寫入 event / event_data / event_admin / place / event_teacher
            4. 更新 synced_at
       └─ Airtable 已刪除的 record：標記 event_data.status = cancelled（不硬刪）
```

- 地點是純文字，匯入時以 `place.name` 比對，找不到就新建一筆 `place`。
- 講師是 Airtable 連結欄位，以講師表的 record id 對應 `user.airtable_record_id`；找不到的講師先建立 `status = pending` 的使用者。
- 同步結果（成功筆數、失敗筆數、錯誤）寫 log，失敗不中斷整批。

## 洽談進度（宣傳進度）對應

Airtable 的「宣傳進度」改名為「洽談進度」，對應 `event_admin.negotiation_status`，同時決定活動是否對志工顯示：

| Airtable 選項 | 新意義 | `negotiation_status` | 志工可見 |
| --- | --- | --- | --- |
| 0. 八字沒一撇 | 純口頭約定，定期 review 用 | `tentative` | 否 |
| 1. 洽談細節中 | 還在談 | `negotiating` | 否 |
| 2. 需要 Banner | 已確定有這場活動，上志工系統 | `confirmed` | **是** |
| ❌ 不用宣傳 | 已確定有這場活動，不需要志工 | `confirmed_no_volunteer` | 否 |
| 0. 因故取消 | 談了之後取消 | `cancelled` | 否 |
| 3. 有 Banner 待做活動 | 目前沒用，**刪除** | — | — |
| 4. 已建活動 | 目前沒用，**刪除** | — | — |
| 對方建活動，設共同主辦 | 目前沒用，**刪除** | — | — |

## 欄位對應表

### 保留並匯入

| Airtable 欄位 | 目標欄位 | 備註 |
| --- | --- | --- |
| 名稱 | `event.name` | 主要識別欄位 |
| 宣傳進度 | `event_admin.negotiation_status` | 選項對應見上表 |
| 只上內部行事曆 | `event_admin.is_internal_only` | 改意義為「僅限特定志工可看」 |
| 開始時間 | `event_data.start_at` | |
| 結束時間 | `event_data.end_at` | |
| 地點 | `place`（by name） | 純文字，匯入時對應／新建 |
| 地區 | `place.city` | 只寫進 `place.city`（`event_data` 不存 `city`）；選項改為縣市，未來加下一層行政區 |
| 活動性質 | `event_data.event_type` | 選項精簡，之後可由管理員自行增加 |
| 聽眾類型 | `event_data.audience_type` | 選項要改，待討論 |
| 講師 | `event_teacher` | 連結欄位 |
| 領款的講師 | `event_teacher.is_payee = true` | 講師費追蹤用 |
| Banner 主標 | `event_data.topic` | 改名「課程主題」，放主題、投影片標題 |
| [講師費] 單位提供講師費 | `event_admin.unit_fee` | |
| [講師費] 單位付款方式 | `event_admin.unit_payment_method` | |
| [講師費] 協會支付金額 | `event_admin.assoc_paid_amount` | |
| [講師費] 目前進度 | `event_admin.fee_status` | 含「已給協會」選項 |
| [講師費] 備註 | `event_admin.fee_note` | |
| 備註 | `event_data.note` | 聯絡資訊、需求、特殊狀況 |
| 行事曆連結 | `event_data.calendar_url` | |
| 參與人數 | `event_data.participant_count` | |

### 不匯入（Airtable 保留或刪除）

| Airtable 欄位 | 決定 | 理由 |
| --- | --- | --- |
| 屬性 | 刪 | |
| Banner 副標 | 刪 | |
| Banner 檔上傳這格 | 刪 | |
| [講師費] 單位付費總計 | 刪 | 公式欄位 |
| [講師費] 單位提供車馬費 | 刪 | 額外提供時跟講師費一併匯給協會；照票報銷時直接抵講師交通費，協會不經手 |
| 平均每位講師金額 | 不匯入，Airtable 先留 | 公式，脫離 Coda 後可能用到 |
| 講師人數 | 不匯入，Airtable 先留 | Count，脫離 Coda 後可能用到 |
| 年月 | 刪 | 公式，系統可從 `start_at` 算 |
| 設計擔當 | 刪 | |
| 完成期限 | 刪 | |
| 估計送出贈品人數 | 刪 | |
| 估計加入我們 LINE@ 帳號人數 | 刪 | |
| 發出文宣數 | 刪 | |
| 場地照片 | 刪 | |
| 心得、照片連結 | 刪 | |
| 活動照片（沒上傳到相簿的） | 刪 | |
| 活動相關檔案 | 刪 | |
| 專案連結 | 刪 | |
| 聯絡管道 | 刪 | |
| 詢問志工日期 | 刪 | |
| 通知志工日期 | 刪 | |
| 志工資訊 | 刪 | 改由系統的報名功能取代 |
| 心得/檢討 | 刪 | 以後用系統的回饋模組（`respond`）處理 |
| 小故事紀錄 | 刪 | 以後用系統的回饋模組（`respond`）處理 |

### 系統要新增、Airtable 沒有的欄位

| 欄位 | 目標 | 說明 |
| --- | --- | --- |
| 志工需求數 | `event_data.capacity` | 總召填寫。因為 Airtable 沒有，同步不會覆蓋 |
| 預計學員人數 | `event_data.expected_attendees` | |
| 給志工看的備註 | `event_data.volunteer_note` | 呈現在志工系統，跟現有「備註」不同 |
| 地區 | `place.city` | 見上 |

## 歷史資料範圍

- 只匯入 2025-10 之後的活動（「宣講-新竹科園里」之後）。
- 在那之前已辦成的活動共 **900 場**，這個數字作為統計基底寫死在設定檔，供「最近統計數字」使用。

## 環境變數

```
AIRTABLE_API_TOKEN=
AIRTABLE_BASE_ID=
AIRTABLE_EVENT_TABLE=
AIRTABLE_TEACHER_TABLE=
AIRTABLE_SYNC_SINCE=2025-10-01
```

## 待確認事項

- 「活動連結」欄位試算表標「刪」但「要加入資料庫」勾 TRUE。內含 FB 活動與社大課程連結，未來想留報名連結。目前**不匯入**，待決定。
- 「Geocaching」同樣標「刪」又勾 TRUE，目前**不匯入**。
- 心得/檢討、小故事紀錄的舊資料是否要一次性匯進 `respond`，還是只留在 Airtable。
- 同步頻率（建議每 15 分鐘）與是否需要 Airtable webhook 觸發。
- 講師表在 Airtable 的表名與欄位（本名、Email）尚未整理。
