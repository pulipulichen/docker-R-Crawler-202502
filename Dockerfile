# 使用官方 R 版本作為基礎映像
FROM rocker/r-ver:4.1.3

RUN apt-get update 

RUN apt-get install -y \
    curl \
    wget \
    gnupg \
    unzip \
    libx11-dev \
    libgtk-3-0 \
    libxtst6 \
    libxss1 \
    libnss3 \
    libasound2 \
    fonts-liberation \
    libappindicator3-1 \
    libxrandr2 \
    xdg-utils

RUN apt-get install -y wget unzip
# RUN wget https://mirror.cs.uchicago.edu/google-chrome/pool/main/g/google-chrome-stable/google-chrome-stable_114.0.5735.90-1_amd64.deb -O google-chrome-stable_current_amd64.deb
COPY ./build/google-chrome-stable_114.0.5735.90-1_amd64.deb /google-chrome-stable_current_amd64.deb
RUN apt install -y /google-chrome-stable_current_amd64.deb
RUN apt-get install -y curl
# RUN wget -O /tmp/chromedriver.zip https://chromedriver.storage.googleapis.com/$(curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE)/chromedriver_linux64.zip
COPY ./build/chromedriver_linux64.zip /tmp/chromedriver.zip
RUN unzip /tmp/chromedriver.zip -d /usr/local/bin/
RUN chmod +x /usr/local/bin/chromedriver

RUN apt-get install -y libxml2-dev libssl-dev
RUN apt-get install -y pkg-config
RUN apt-get install -y r-base-dev

WORKDIR /

# RUN Rscript -e 'install.packages(c("rvest", "dplyr", "stringr", "purrr", "RSelenium"), repos = "https://cloud.r-project.org/")'
RUN Rscript -e 'install.packages(c("dplyr"), repos = "https://cloud.r-project.org/")'
RUN Rscript -e 'install.packages(c("stringr"), repos = "https://cloud.r-project.org/")'
RUN Rscript -e 'install.packages(c("purrr"), repos = "https://cloud.r-project.org/")'
RUN Rscript -e 'install.packages(c("rvest"))'
RUN Rscript -e 'install.packages(c("RSelenium"))'

RUN apt-get install -y default-jre default-jdk

RUN mkdir -p /root/.local/share/binman_geckodriver/linux64/0.36.0/
COPY ./build/geckodriver-v0.36.0-linux64.tar.gz /root/.local/share/binman_geckodriver/linux64/0.36.0/geckodriver-v0.36.0-linux64.tar.gz
COPY ./build/geckodriver-v0.36.0-linux64.tar.gz.asc /root/.local/share/binman_geckodriver/linux64/0.36.0/geckodriver-v0.36.0-linux64.tar.gz.asc

# RUN tar -xzf /geckodriver-v0.36.0-linux64.tar.gz
# RUN mv /geckodriver /usr/local/bin/
# RUN chmod +x /usr/local/bin/geckodriver

COPY ./build/prepare.r /prepare.r
RUN Rscript /prepare.r

RUN apt install net-tools -y
RUN apt install lsof -y
RUN apt-get install psmisc -y

RUN apt-get install -y firefox

# ENTRYPOINT [ "Rscript", "/app/main.R" ]
ENTRYPOINT [ ]