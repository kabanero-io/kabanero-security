FROM registry.access.redhat.com/ubi8:latest

RUN yum --disableplugin=subscription-manager module -y  enable php:7.2 \
#  && yum --disableplugin=subscription-manager install -y httpd php libzip php-pecl-zip mod_ssl\
  && yum --disableplugin=subscription-manager install -y httpd php libzip php-pecl-zip\
  && yum --disableplugin=subscription-manager install -y zip unzip

RUN mkdir -p /var/www/sigstore/html/staging/ \
  && rm -f /etc/httpd/conf.d/welcome.conf

COPY phpfile/store.php /var/www/sigstore/html/staging/

RUN sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf \
  && sed -i 's/DocumentRoot "\/var\/www\/html"/DocumentRoot "\/var\/www\/sigstore\/html"/' /etc/httpd/conf/httpd.conf \
  && echo -e "\n<Directory /var/www/sigstore>\n\tOptions -Indexes\n</Directory>" >> /etc/httpd/conf/httpd.conf \
  && echo -e "\nRewriteEngine On\nRewriteCond %{REQUEST_METHOD} !^(GET|PUT|HEAD)\nRewriteRule .* - [R=405,L]\n" >> /etc/httpd/conf/httpd.conf \
  && echo -e "\nScript PUT /staging/store.php\n" >> /etc/httpd/conf/httpd.conf \
  && sed -i 's/;clear_env = no/clear_env = no/' /etc/php-fpm.d/www.conf \
  && mkdir /run/php-fpm \
  && chgrp -R 0 /var/log/httpd /var/run/httpd /run/php-fpm /var/www/sigstore \
  && chmod -R g=u /var/log/httpd /var/run/httpd /run/php-fpm /var/www/sigstore

EXPOSE 8080
CMD php-fpm & httpd -D FOREGROUND
