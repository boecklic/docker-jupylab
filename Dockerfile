FROM python:3.6-jessie
#RUN /sbin/ip route|awk '/default/ { print $3 }'
RUN bash -c "cat /etc/apt/apt.conf"
ENV http_proxy "http://127.0.0.1:10080"
ENV https_proxy "http://127.0.0.1:10080"
RUN apt-get update && apt-get install python3-dev
COPY requirements.txt /tmp/
RUN pip install --yes --file /tmp/requirements.txt
