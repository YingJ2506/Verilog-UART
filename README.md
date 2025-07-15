# Verilog-UART
Verilog project - UART

# UART模組設計

# 功能敘述
設計一非同步傳送資料模組UART，包含傳送模組(TX)與接收模組(RX)，使用常見Baud rate傳輸速度115200 bpm與FPGA常見頻率50MHz進行處理，資料寬度先以8bits作為設計需求，預期含有傳送(transmitter)、接收(receiver)資料與reset功能，待完成基礎功能後以TOP module 將TX & RX串聯起來測試lookback，後續再加入其它功能。

# RTL模組設計邏輯
## 傳輸模組TX
- 8bits 資料&允許傳輸訊號input
- 輸出資料&傳輸中訊號output
- reset 功能導入
- 單筆資料傳輸，tx_busy導入
- 每 434 clk進行資料傳遞

## 接收模組RX
- 8bits 資料輸出output
- 輸出完成時跳完成訊號output
- 接收資料input
- reset功能導入
- 單筆資料傳輸，rx_busy導入
- 每 217 clk（位元中點）進行收值，避免資料因雜訊被誤判


# TB測試項目與目標
## 傳輸模組TX
- 開啟reset測試是否回到初始值
- idle時，TX保持在高電位
- 啟動傳輸訊號&資料傳入，能否正常傳完傳輸資料回到idle
- 能正常傳送多組data
- 傳送過程reset中斷，能否正常回到初始值
- 第一筆資料傳輸過程有有其它資料輸入，不影響第一組的資料且會等傳完再傳第二筆 (需有FIFO buffer)

## 接收模組RX
- 開啟reset測試是否回到初始值
- idle時，RX保持在高電位
- 能正確以434clk間隔接收8bits資料，並在完成時都產生rx_done高電位
- 能正常接收多組data
- 接收過程reset中斷，能否正常回到初始值 (corner case)
- 第一筆資料接收過程有有其它資料輸入，不影響第一組的資料且會等接收完再收第二筆 (需有FIFO buffer)

使用EDAplayground(Icarus verilog + EPWave)進行模擬與驗證


# 模擬結果
EPWave 波型圖可視化測試結果（見附圖）
## 傳輸模組TX
![image](https://github.com/user-attachments/assets/d5a1cbfe-b219-44c2-8487-2ff88c147bdc)
![image](https://github.com/user-attachments/assets/b95fa6b5-ca22-47d6-b93e-527510c2fea1)

## 接收模組RX
![image](https://github.com/user-attachments/assets/6eea5dbb-3452-4501-ad13-466f683aaddd)
![image](https://github.com/user-attachments/assets/88ed4a1c-8540-4bf0-8332-d13f394c7025)
<img width="1327" height="362" alt="image" src="https://github.com/user-attachments/assets/91ee5dec-05d8-4147-801a-aa7af81a94fb" />


## Lookback測試
![image](https://github.com/user-attachments/assets/f9c37b69-4088-425a-8b6e-aefc0b5b8921)


# 修正心得
- 輸出邏輯設計： 在設計 TX/RX 模組時，參考以往 FIFO 模組中採用 assign output = output_s; 的方式，讓邏輯與輸出分開，提高模組可維護性。並特別注意 reg 計數器的位寬設定，避免 overflow 或範圍不足問題。
- TX 傳輸結束判斷錯誤： 原本在 TX 模組中使用 bit_c == 10 判斷資料傳送完成，導致傳輸多等一拍才釋放 busy 訊號，待更版修正為 bit_c == 9 即釋放，避免多餘延遲。
- RX Check Point 設計理念： RX 模組中的 check_p = 434/2 並非單純延遲使用，而是透過「在資料位元中心點採樣」來避免雜訊干擾，確保資料準確性。這也是 UART 接收中常見的 anti-jitter 技術。
- 時脈延遲誤會釐清： 起初觀察到 RX 在每個 check point 後需再等一個 clock cycle 才繼續進行 clk 計數，誤以為是 clock 錯位。後來確認這是設計上為了抗干擾的機制，並非 bug，屬於合理行為。
- 位元順序測試錯誤： 在手動加入第二筆資料時，輸入 01101111（十進位 111），但解碼後變成 11110110（246），後來發現是 test case 位元順序搞錯（Verilog 預設右邊是低位），修正後正確顯示。
- 接收中 reset 行為修正： 原本在 RX 模組接收資料過程中若觸發 reset，模組會在 reset 結束後立即重新開始接收，導致資料錯亂。為避免這種不當觸發，新增兩項邏輯判斷：1.檢查 rx 是否從高轉低（1→0）作為啟動依據；2.確保只有在模組明確 idle 且資料穩定後才重新啟動接收。最終可正確處理 reset 並避免誤啟動。
- if-else 到 case 語句的轉換挑戰： RX RTL使用狀態機邏輯轉換。一開始寫的程式碼完全無法正常顯示波形圖。後來重新理解並確認了 always_ff 用於時序賦值和 always_comb 用於組合邏輯狀態轉換的原則。當波形圖能正常跑出後，進行了多輪的修正包括確保計數器的正常運作、狀態在正確時序的轉換，以及接收值的準確性。而在導入 rx 從 1 變 0 瞬間才啟動的功能時，波形圖又一度異常，會延遲到第二次 rx 變 0 才動作。在檢查 IDLE 轉 RX_START 邏輯未發現異常後，最終與 Gemini 確認並發現是 Testbench 中 reset 後的 IDLE 時間不足。這讓我深刻了解到，驗證錯誤在Testbench 的設定上也同樣關鍵。

# 待優化功能
- 增加Parity bit 功能
- 增加FIFO buffer
- AXI接口整合
- Baud rate 修改為可參數化設定 -> done
- 支援不同長度資料傳輸 -> done
- 改用標準的狀態機設計 -> done
- 導入task封裝資料 -> done

# 更版紀錄
## v1.0---初始版本，完成基本 TX/RX 模組(loopback測試ok)
## v1.1---模組進行了功能強化與結構優化，提升了模組的靈活性和驗證的可靠性
  - UART TX RTL：
    1. 優化位元計數邏輯，確保在第 9 位元完成後立即釋放。
    2. 全面參數化配置，方便不同傳輸需求。
    3. 加入 assert 語句，增強設計健壯性與錯誤檢測。
  - UART TX Testbench：
    1. 引入 task 進行資料發送，簡化測試流程。
    2. 實現參數化設定，提升測試彈性。
    3. 新增 assert 語句，強化驗證自動化與結果檢查。
  - UART RX RTL：
    1. 將原 if-else 狀態機邏輯重構為更清晰的 always_comb 和 case 結構。
    2. 全面參數化配置，提高模組通用性。
  - UART RX Testbench：
    1. 採用 task 封裝資料發送，提高測試程式碼的可讀性與重用性。
    2. 支援參數化設定，便於不同場景下的測試。
