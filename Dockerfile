FROM r-base:4.4.2

RUN apt-get update && apt-get install -y wget unzip
RUN wget https://mirror.cs.uchicago.edu/google-chrome/pool/main/g/google-chrome-stable/google-chrome-stable_114.0.5735.90-1_amd64.deb -O google-chrome-stable_current_amd64.deb
RUN apt install -y ./google-chrome-stable_current_amd64.deb
RUN apt-get install -y curl
RUN wget -O /tmp/chromedriver.zip https://chromedriver.storage.googleapis.com/$(curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE)/chromedriver_linux64.zip
RUN unzip /tmp/chromedriver.zip -d /usr/local/bin/
RUN chmod +x /usr/local/bin/chromedriver

RUN apt-get install -y libxml2-dev libssl-dev

WORKDIR /

RUN Rscript -e 'install.packages(c("rvest", "dplyr", "stringr", "purrr", "RSelenium"), repos = "https://cloud.r-project.org/")'

ENTRYPOINT [ "Rscript", "/app/main.R" ]