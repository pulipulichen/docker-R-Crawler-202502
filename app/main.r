install.packages("webdriver")
library(webdriver)
webdriver::install_phantomjs()

pjs <- run_phantomjs()
pjs