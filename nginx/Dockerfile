FROM nginx:latest

RUN openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -sha256 -days 365 -nodes -subj "/CN=cloudtictactoe.com"

COPY ./nginx.conf /etc/nginx/conf.d/default.conf