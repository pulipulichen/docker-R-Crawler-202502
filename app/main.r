# install.packages("webdriver")
library(webdriver)

pjs <- run_phantomjs()
pjs

ses <- Session$new(port = pjs$port)

ses$go("https://guide.michelin.com/tw/zh_TW/restaurants/page/2")
ses$getUrl()

# 頁面之間暫停
Sys.sleep(5)

ses$getTitle()

install <- ses$findElement("h1")
install$getText()