FROM alpine as ioncube_loader
RUN apk add git \
	&& git -c http.sslVerify=false clone https://git.dev.glo.gb/cloudhostingpublic/ioncube_loader \
	&& tar zxf ioncube_loader/ioncube_loaders_lin_x86-64.tar.gz

FROM 1and1internet/debian-9:latest
MAINTAINER brian.wilkinson@1and1.co.uk
ARG DEBIAN_FRONTEND=noninteractive
COPY files /

# Mongodb client + tools
RUN apt-get update && \
    apt-get install wget gnupg && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 \
            --recv 2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5 && \
    apt-get update && \
    apt-get install -y --allow-unauthenticated mongodb-clients && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    apt-get update && \
    apt-get install -y  postgresql-client-10 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=ioncube_loader /ioncube/ioncube_loader_lin_7.2.so /usr/lib/php/20170718/

RUN \
  apt-get update && \
  apt-get install -y --allow-unauthenticated software-properties-common apt-transport-https ca-certificates curl && \
  wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg && \
  apt-get update && \
  apt-get install -y \
    mysql-client libmariadbclient-dev-compat perl ruby ruby-dev rake zlib1g-dev sqlite sqlite3 \
    git vim traceroute telnet nano dnsutils curl wget iputils-ping openssh-client openssh-sftp-server \
    virtualenv python3-venv python3-virtualenv python3-all python3-setuptools python3-pip python-dev python3-dev python-pip \
    gnupg build-essential ruby2.3-dev libsqlite3-dev redis-tools && \
  apt-get install -y imagemagick graphicsmagick && \
  apt-get install -y php7.1-bcmath php7.1-bz2 php7.1-cli php7.1-common php7.1-curl php7.1-dba php7.1-gd php7.1-gmp php7.1-imap php7.1-intl php7.1-ldap php7.1-mbstring php7.1-mcrypt php7.1-mysql php7.1-odbc php7.1-pgsql php7.1-recode php7.1-snmp php7.1-soap php7.1-sqlite php7.1-tidy php7.1-xml php7.1-xmlrpc php7.1-xsl php7.1-zip && \
  apt-get install -y php7.2-bcmath php7.2-bz2 php7.2-cli php7.2-common php7.2-curl php7.2-dba php7.2-gd php7.2-gmp php7.2-imap php7.2-intl php7.2-ldap php7.2-mbstring php7.2-mysql php7.2-odbc php7.2-pgsql php7.2-recode php7.2-snmp php7.2-soap php7.2-sqlite php7.2-tidy php7.2-xml php7.2-xmlrpc php7.2-xsl php7.2-zip && \
  apt-get install -y php7.3-bcmath php7.3-bz2 php7.3-cli php7.3-common php7.3-curl php7.3-dba php7.3-gd php7.3-gmp php7.3-imap php7.3-intl php7.3-ldap php7.3-mbstring php7.3-mysql php7.3-odbc php7.3-pgsql php7.3-recode php7.3-snmp php7.3-soap php7.3-sqlite php7.3-tidy php7.3-xml php7.3-xmlrpc php7.3-xsl php7.3-zip && \
  apt-get install -y php7.4-bcmath php7.4-bz2 php7.4-cli php7.4-common php7.4-curl php7.4-dba php7.4-gd php7.4-gmp php7.4-imap php7.4-intl php7.4-ldap php7.4-mbstring php7.4-mysql php7.4-odbc php7.4-pgsql php7.4-snmp php7.4-soap php7.4-sqlite php7.4-tidy php7.4-xml php7.4-xmlrpc php7.4-xsl php7.4-zip && \
  apt-get install -y php-gnupg php-imagick php-fxsl && \
  DISTRO=$(lsb_release -c -s) && \
  NODEREPO="node_6.x" && \
  curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
  echo "deb https://deb.nodesource.com/${NODEREPO} ${DISTRO} main" > /etc/apt/sources.list.d/nodesource.list && \
  echo "deb-src https://deb.nodesource.com/${NODEREPO} ${DISTRO} main" >> /etc/apt/sources.list.d/nodesource.list && \
  apt-get update -q && \
  apt-get install -y build-essential nodejs && \
  apt-get remove -y python-software-properties software-properties-common && \
  apt-get autoremove -y && apt-get autoclean -y && \
  mkdir -p --mode 0777 /var/www && \
  mkdir /tmp/composer/ && \
  cd /tmp/composer && \
  curl -sS https://getcomposer.org/installer | php && \
  mv composer.phar /usr/local/bin/composer && \
  rm -rf /tmp/composer && \
  rm -rf /var/lib/apt/lists/* && \
  chmod 0755 /usr/local/bin/composer && \
  chmod 0755 -R /hooks /init && \
  chmod 0777 /etc/passwd /etc/group && \
  mkdir --mode 0777 /usr/local/composer && \
  COMPOSER_HOME=/usr/local/composer /usr/local/bin/composer --no-ansi --no-interaction global require drush/drush:8.* && \
  COMPOSER_HOME=/usr/local/composer /usr/local/bin/composer --no-ansi --no-interaction global clearcache && \
  mv /usr/bin/cpan /usr/bin/cpan_disabled && \
  mv /usr/bin/cpan_override /usr/bin/cpan && \
  rm -f /etc/ssh/ssh_host_* && \
  chmod -R 0777 /etc/supervisor/conf.d

ENV COMPOSER_HOME=/var/www \
    HOME=/var/www

WORKDIR /var/www

# Install and configure the cron service
ENV EDITOR=/usr/bin/vim \
	CRON_LOG_FILE=/var/spool/cron/cron.log \
	CRON_LOCK_FILE=/var/spool/cron/cron.lock \
	CRON_ARGS=""
RUN \
  apt-get update && apt-get install -y -o Dpkg::Options::="--force-confold" logrotate man && \
  cd /src/cron-3.0pl1 && \
  make install && \
  mkdir -p /var/spool/cron/crontabs && \
  chmod -R 777 /var/spool/cron && \
  cp debian/crontab.main /etc/crontab && \
  cd - && \
  rm -rf /src && \
  find /etc/cron.* -type f | egrep -v 'logrotate|placeholder' | xargs -i rm -f {} && \
  chmod 666 /etc/logrotate.conf && \
  chmod -R 777 /var/lib/logrotate && \
  rm -rf /var/lib/apt/lists/*
