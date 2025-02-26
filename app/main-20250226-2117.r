# 安裝必要的套件
# install.packages(c("rvest", "dplyr", "stringr", "purrr", "RSelenium"), repos = "https://cloud.r-project.org/")

# 載入必要的套件
library(rvest)
library(dplyr)
library(stringr)
library(purrr)
library(RSelenium)

# ===================


# 啟動Selenium服務器和瀏覽器
start_selenium <- function() {
  cat("啟動Selenium服務器...\n")
  # system("kill -9 $(lsof -t -i :4444)")

  # 啟動Chrome瀏覽器
  driver <- rsDriver(
    browser = "firefox",
    port = 4555L,
    chromever = NULL,
    verbose = TRUE,
    # extraCapabilities = list(
    #   chromeOptions = list(
    #     args = c('--headless', '--no-sandbox', '--disable-dev-shm-usage')
    #   )
    # )
  )

  return(driver$client)
}


# 啟動Selenium
driver <- start_selenium()

restart_selenium <- function() {
  # Stop any existing Selenium session
  try({
    rsDriver$close()
    driver$server$stop()
  }, silent = TRUE)
  
  # Kill any process using port 4444
  system("fuser -k 4444/tcp", intern = TRUE)  # Linux/macOS
  # system("taskkill /F /IM java.exe", intern = TRUE)  # Windows alternative

  cat("✅ RSelenium restarted successfully!\n")
}




# 爬取米其林餐廳資訊的函數
scrape_michelin_page <- function(url, driver) {
  # 使用Selenium訪問網頁

  tryCatch({
    driver$navigate(url)
  }, error = function(e) {
    # Run the function to restart Selenium
    restart_selenium()

    driver <- start_selenium()
    cat("連線出錯:", conditionMessage(e), "\n")
  })

  # 等待頁面加載（等待餐廳卡片出現）
  Sys.sleep(5)  # 給予JavaScript足夠的時間來加載內容

  # 獲取頁面源碼
  page_source <- driver$getPageSource()[[1]]
  webpage <- read_html(page_source)

  # 獲取所有餐廳卡片
  restaurant_cards <- html_nodes(webpage, ".restaurant__list-row .card__menu")
  cat("找到", length(restaurant_cards), "家餐廳\n")

  # 初始化數據框
  restaurants_df <- data.frame(
    餐廳名稱 = character(),
    餐廳地點 = character(),
    價位 = character(),
    類別 = character(),
    簡介 = character(),
    電話 = character(),
    stringsAsFactors = FALSE
  )

  # 處理每個餐廳卡片
  for (i in 1:length(restaurant_cards)) {
    tryCatch({
      card <- restaurant_cards[i]

      # 餐廳名稱
      name <- card %>%
        html_node(".card__menu-content--title") %>%
        html_text() %>%
        str_trim()

      cat("處理餐廳:", name, "\n")

      # 價位和類別 - 從底部區域獲取
      footer_elements <- card %>%
        html_nodes(".card__menu-footer--score, .card__menu-footer--price")

      price_category_text <- NA
      for (elem in footer_elements) {
        text <- html_text(elem) %>% str_trim()
        if (str_detect(text, "\\$") && str_detect(text, "·")) {
          price_category_text <- text
          break
        }
      }

      # 分解價位和類別
      price <- NA
      category <- NA
      if (!is.na(price_category_text)) {
        parts <- str_split(price_category_text, "·", simplify = TRUE)
        price <- str_trim(parts[1])
        category <- if(length(parts) > 1) str_trim(parts[2]) else NA
      }

      # 取得餐廳詳細頁面URL
      detail_url <- card %>%
        html_node(".card__menu-image a") %>%
        html_attr("href")

      location <- NA
      intro <- NA
      phone <- NA

      if (!is.na(detail_url) && !is.null(detail_url)) {
        # 確保URL是完整的
        if (!startsWith(detail_url, "https://")) {
          detail_url <- paste0("https://guide.michelin.com", detail_url)
        }

        cat("訪問餐廳詳細頁:", detail_url, "\n")

        # 使用Selenium訪問詳細頁面
        # driver$navigate(detail_url)
        tryCatch({
          driver$navigate(detail_url)
        }, error = function(e) {
          restart_selenium()
          driver <- start_selenium()
          cat("連線出錯:", conditionMessage(e), "\n")
        })
        Sys.sleep(3)  # 等待頁面加載

        # 獲取詳細頁面源碼
        detail_page_source <- driver$getPageSource()[[1]]
        detail_page <- read_html(detail_page_source)

        # 餐廳地點 - 從詳細頁面獲取
        location_node <- detail_page %>%
          html_node(".restaurant-details__heading--address, .data-sheet__detail-info .data-sheet__block--text")

        if (!is.null(location_node) && !is.na(location_node)) {
          location <- html_text(location_node) %>% str_trim()
        }

        # 簡介 - 從詳細頁面獲取
        intro_node <- detail_page %>%
          html_node(".restaurant-details__description--text, .data-sheet__description")

        if (!is.null(intro_node) && !is.na(intro_node)) {
          intro <- html_text(intro_node) %>% str_trim()
        }

        # 電話 - 從詳細頁面獲取
        phone_node <- detail_page %>%
          html_node("a.btn.phone")

        if (!is.null(phone_node) && !is.na(phone_node)) {
          # 從元素的文字內容獲取電話號碼
          phone_text <- html_text(phone_node) %>% str_trim()

          # 如果文字內容有效，使用它
          if (phone_text != "" && !is.na(phone_text)) {
            phone <- phone_text
          } else {
            # 否則嘗試從href屬性獲取
            phone_href <- html_attr(phone_node, "href")
            if (!is.na(phone_href) && str_detect(phone_href, "^tel:")) {
              phone <- str_replace(phone_href, "^tel:", "")
            }
          }
        }
      }

      # 將資料加入數據框
      new_row <- data.frame(
        餐廳名稱 = name,
        餐廳地點 = location,
        價位 = price,
        類別 = category,
        簡介 = intro,
        電話 = phone,
        stringsAsFactors = FALSE
      )

      restaurants_df <- rbind(restaurants_df, new_row)

    }, error = function(e) {
      cat("處理餐廳卡片時出錯:", conditionMessage(e), "\n")
    })
  }

  return(restaurants_df)
}

# 主函數
scrape_michelin_restaurants <- function(driver, start_page = 1, end_page = 2) {

  all_restaurants <- data.frame()

  # 處理指定頁數範圍
  for (page in start_page:end_page) {
    # 構建頁面URL
    if (page == 1) {
      page_url <- "https://guide.michelin.com/tw/zh_TW/restaurants"
    } else {
      page_url <- paste0("https://guide.michelin.com/tw/zh_TW/restaurants/page/", page)
    }

    # 爬取當前頁面
    page_restaurants <- scrape_michelin_page(page_url, driver)

    # 如果沒有找到餐廳，則跳出循環
    if (nrow(page_restaurants) == 0) {
      cat("沒有找到更多餐廳，停止爬取\n")
      break
    }

    all_restaurants <- rbind(all_restaurants, page_restaurants)

    # 頁面之間暫停
    Sys.sleep(2)
  }

  # 關閉Selenium
  driver$close()

  return(all_restaurants)
}

# 設定要爬取的頁面範圍
start_page <- 2  # 從第二頁開始
end_page <- 3    # 爬取到第三頁

# 執行爬蟲
all_restaurants <- scrape_michelin_restaurants(driver, start_page, end_page)

# 顯示結果
print(head(all_restaurants))
print(paste("總共爬取了", nrow(all_restaurants), "家餐廳"))

# 生成帶時間戳記的文件名
timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
filename <- paste0("/data/michelin_restaurants_taiwan_", start_page, '-', end_page, '_', timestamp, ".csv")

# 儲存為CSV
write.csv(all_restaurants, filename, row.names = FALSE, fileEncoding = "UTF-8")
cat("已將資料儲存為", filename, "\n")