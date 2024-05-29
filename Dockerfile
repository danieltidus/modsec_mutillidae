# Install Modsecurity in a Docker container and config mutillidae app;
#Partially based on:
# 	https://miloserdov.org/?p=87
# 	https://www.howtoforge.com/install-modsecurity-with-apache-in-a-docker-container
#	https://www.linode.com/docs/guides/securing-apache2-with-modsecurity/


FROM ubuntu:22.04
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y

RUN apt-get install -y g++ flex bison curl apache2-dev \
	doxygen libyajl-dev ssdeep liblua5.2-dev \
	libgeoip-dev libtool dh-autoreconf \
	libcurl4-gnutls-dev libxml2 libpcre++-dev \
	libxml2-dev git wget tar apache2

RUN wget https://github.com/SpiderLabs/ModSecurity/releases/download/v3.0.12/modsecurity-v3.0.12.tar.gz

RUN tar xzf modsecurity-v3.0.12.tar.gz && rm -rf modsecurity-v3.0.12.tar.gz

RUN cd modsecurity-v3.0.12 && \
	./build.sh && ./configure && \
	make && make install

# Install ModSecurity-Apache Connector
RUN cd ~ && git clone https://github.com/SpiderLabs/ModSecurity-apache

RUN cd ~/ModSecurity-apache && \
	./autogen.sh && \
	./configure --with-libmodsecurity=/usr/local/modsecurity/ && \
	make && \
	make install

# Load the Apache ModSecurity Connector Module
RUN echo "LoadModule security3_module /usr/lib/apache2/modules/mod_security3.so" >> /etc/apache2/apache2.conf

# Configure ModSecurity
RUN mkdir /etc/apache2/modsecurity.d && \
	cp modsecurity-v3.0.12/modsecurity.conf-recommended /etc/apache2/modsecurity.d/modsecurity.conf && \
	cp modsecurity-v3.0.12/unicode.mapping /etc/apache2/modsecurity.d/ && \
	sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/apache2/modsecurity.d/modsecurity.conf
ADD modsec_rules.conf /etc/apache2/modsecurity.d/

# Install OWASP ModSecurity Core Rule Set (CRS) on Ubuntu
RUN git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git /etc/apache2/modsecurity.d/owasp-crs && \
	cp /etc/apache2/modsecurity.d/owasp-crs/crs-setup.conf.example /etc/apache2/modsecurity.d/owasp-crs/crs-setup.conf

# Activate ModSecurity
RUN mv /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.old
ADD 000-default.conf /etc/apache2/sites-available/

RUN apt install php-xml php-fpm libapache2-mod-php php-mysql php-gd php-imap php-curl php-mbstring mysql-server -y
RUN a2enmod proxy_fcgi setenvif
RUN a2enconf php8.1-fpm

RUN cd /tmp && git clone https://github.com/webpwnized/mutillidae && \
	mkdir /var/www/html/mutillidae/ &&  mv mutillidae/src/* /var/www/html/mutillidae
RUN  sed -i "s/'DB_PASSWORD', 'mutillidae'/'DB_PASSWORD', ''/" /var/www/html/mutillidae/includes/database-config.inc
RUN chown -R www-data:www-data /var/www/html/mutillidae/ && rm -rf mutillidae* && cd

ADD run.sh /

RUN chmod 755 /run.sh

EXPOSE 80
CMD ["/run.sh"]
