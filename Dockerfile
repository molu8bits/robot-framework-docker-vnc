FROM ubuntu:18.04
LABEL maintainer "molu8bits@gmail.com"
LABEL description "Ubuntu 18.04 based container to run Robot Framework Test"


# Chrome 69
#ENV CHROME_URL https://www.slimjet.com/chrome/download-chrome.php?file=files%2F69.0.3497.92%2Fgoogle-chrome-stable_current_amd64.deb
# Chrome 70
#ENV CHROME_URL https://ftp.slimbrowser.net/chrome/download-chrome.php?file=files%2F70.0.3538.77%2Fgoogle-chrome-stable_current_amd64.deb
# Chrome 71
ENV CHROME_URL https://www.slimjet.com/chrome/download-chrome.php?file=files%2F71.0.3578.80%2Fgoogle-chrome-stable_current_amd64.deb
# Chrome 75
#ENV CHROME_URL https://www.slimjet.com/chrome/download-chrome.php?file=files%2F75.0.3770.80%2Fgoogle-chrome-stable_current_amd64.deb
# Chrome newest
#ENV CHROME_URL https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb


# ChromeDriver 75
#ENV CHROME_DRIVER_URL https://chromedriver.storage.googleapis.com/75.0.3770.8/chromedriver_linux64.zip
# ChromeDriver 74
#ENV CHROME_DRIVER_URL https://chromedriver.storage.googleapis.com/74.0.3729.6/chromedriver_linux64.zip
# ChromeDriver 2.45
ENV CHROME_DRIVER_URL https://chromedriver.storage.googleapis.com/2.45/chromedriver_linux64.zip
# ChromeDriver 2.46
# ENV CHROME_DRIVER_URL https://chromedriver.storage.googleapis.com/2.46/chromedriver_linux64.zip
# ChromeDriver 2.43
#ENV CHROME_DRIVER_URL https://chromedriver.storage.googleapis.com/2.43/chromedriver_linux64.zip
# ChromeDriver 2.41
#ENV CHROME_DRIVER_URL https://chromedriver.storage.googleapis.com/2.41/chromedriver_linux64.zip

RUN apt-get update && apt-get install -y wget curl && \
  apt-get install -y xvfb dbus dbus-x11 && \
  apt-get install -y firefox x11vnc xdotool x11-apps && \
  apt-get install -y python2.7 python-pip libssl1.0-dev s3cmd

# Google Chromei & chromedriver & its requirements
RUN apt-get install -y fonts-liberation libappindicator3-1 libnspr4 libnss3 xdg-utils unzip
RUN wget --no-check-certificate ${CHROME_URL} -O /tmp/google-chrome.deb && dpkg -i /tmp/google-chrome.deb && rm -rf /tmp/google-chrome.deb
RUN wget ${CHROME_DRIVER_URL} -O /tmp/chromedriver.zip && cd /usr/local/bin && unzip /tmp/chromedriver.zip && cd


# Firefox geckodriver
RUN wget https://github.com/mozilla/geckodriver/releases/download/v0.21.0/geckodriver-v0.21.0-linux64.tar.gz -O /tmp/geckodriver.tar.gz && tar -zxf /tmp/geckodriver.tar.gz -C /usr/local/bin/ && chmod o+x /usr/local/bin/geckodriver && rm -rf /tmp/geckodriver.tar.gz

RUN mkdir ~/.vnc && mkdir /opt/xrobo
#RUN x11vnc -storepasswd 1234 ~/.vnc/passwd


#ENV PATH=/opt/xrobo:$PATH
ENV DISPLAY ":99"


# Change location of google-chrome
RUN mv /usr/bin/google-chrome /opt/xrobo/


COPY files/requirements.txt /opt/xrobo/requirements.txt
COPY files/chromedriver.sh /opt/xrobo/chromedriver
COPY files/google-chrome.sh /usr/bin/google-chrome
COPY files/run.sh /opt/xrobo/run.sh
COPY files/manual-run.sh /opt/xrobo/manual-run.sh
RUN chmod +x /opt/xrobo/run.sh
RUN chmod +x /opt/xrobo/manual-run.sh

# Importing internal certs for browsers if there are such any
#RUN tar -C /root -xf /opt/xrobo/internal-certs.tar


RUN pip install -r /opt/xrobo/requirements.txt


CMD [ "/opt/xrobo/run.sh" ]
