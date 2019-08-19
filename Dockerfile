FROM php:7.2-cli

MAINTAINER Johan van Helden <johan@johanvanhelden.com>

RUN DEBIAN_FRONTEND=noninteractive

ARG TZ=Europe/Amsterdam
ENV TZ ${TZ}

RUN apt-get update && apt-get install -y gnupg apt-transport-https ca-certificates lsb-release wget

RUN wget -qO - https://repo.mysql.com/RPM-GPG-KEY-mysql | apt-key add -

# Prepare and install mysql
RUN echo "mysql-community-server mysql-community-server/root-pass password root" | debconf-set-selections &&\
  echo "mysql-community-server mysql-community-server/re-root-pass password root" | debconf-set-selections &&\
  echo "mysql-apt-config mysql-apt-config/select-server select mysql-5.7" | debconf-set-selections &&\
  curl -sSL http://repo.mysql.com/mysql-apt-config_0.8.9-1_all.deb -o ./mysql-apt-config_0.8.9-1_all.deb &&\
  export DEBIAN_FRONTEND=noninteractive &&\
  dpkg -i mysql-apt-config_0.8.9-1_all.deb

# Install dependencies
RUN apt-get update && apt-get install --no-install-recommends -y --force-yes \
  mysql-community-server \
  mysql-client \
  libfreetype6-dev \
  libjpeg62-turbo-dev \
  libmcrypt-dev \
  libpng-dev \
  libcurl4-nss-dev \
  libc-client-dev \
  libkrb5-dev \
  firebird-dev \
  libicu-dev \
  libxml2-dev \
  libxslt1-dev \
  libbz2-dev \
  git \
  mercurial \
  zip \
  xvfb \
  gtk2-engines-pixbuf \
  xfonts-cyrillic \
  xfonts-100dpi \
  xfonts-75dpi  \
  xfonts-base \
  xfonts-scalable \
  imagemagick \
  x11-apps \
  openssh-client

# Add maximum backwards compatibility with MySQL 5.6
RUN echo "[mysqld]" >> /etc/mysql/conf.d/z-circleci-config.cnf && \
  echo 'sql_mode = "NO_ENGINE_SUBSTITUTION"' >> /etc/mysql/conf.d/z-circleci-config.cnf

# Install PHP extensions
RUN docker-php-ext-install -j$(nproc) bz2 &&\
  docker-php-ext-install -j$(nproc) bcmath &&\
  docker-php-ext-install -j$(nproc) curl &&\
  docker-php-ext-install -j$(nproc) exif &&\
  docker-php-ext-install -j$(nproc) mbstring &&\
  docker-php-ext-install -j$(nproc) iconv &&\
  docker-php-ext-install -j$(nproc) interbase &&\
  docker-php-ext-install -j$(nproc) intl &&\
  docker-php-ext-install -j$(nproc) soap &&\
  docker-php-ext-install -j$(nproc) xmlrpc &&\
  docker-php-ext-install -j$(nproc) xsl &&\
  docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ &&\
  docker-php-ext-install -j$(nproc) gd &&\
  docker-php-ext-configure imap --with-kerberos --with-imap-ssl &&\
  docker-php-ext-install imap &&\
  docker-php-ext-install mysqli pdo pdo_mysql &&\
  docker-php-ext-install zip

RUN docker-php-ext-configure pcntl --enable-pcntl && \
  docker-php-ext-install pcntl

# Prepare and install NVM
ENV NVM_DIR /root/.nvm

RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash &&\
  . /root/.nvm/nvm.sh &&\
  nvm install 10 &&\
  nvm install 8 &&\
  nvm install 6 &&\
  nvm alias default 8

RUN echo "" >> ~/.bashrc && \
  echo 'export NVM_DIR="/root/.nvm"' >> ~/.bashrc && \
  echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm' >> ~/.bashrc \
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && \
  curl -o- -L https://yarnpkg.com/install.sh | bash; \
  echo "" >> ~/.bashrc && \
  echo 'export PATH="$HOME/.yarn/bin:$PATH"' >> ~/.bashrc

# Install Composer
RUN curl -sSL https://getcomposer.org/installer | php -- --filename=composer --install-dir=/usr/bin
RUN echo 'export PATH="$HOME/.composer/vendor/bin:$PATH"' >> ~/.bashrc

# Add our list of wanted packages
COPY ./configfiles/composer.json /root/.composer/composer.json
COPY ./configfiles/composer.lock /root/.composer/composer.lock

# Install the packages
RUN cd /root/.composer && composer install

#Install chrome - needed for Laravel Dusk
RUN curl -sS https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
  sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list' && \
  apt-get update && apt-get install -y google-chrome-stable

# Clean up APT when done
RUN apt-get autoclean &&\
  apt-get clean &&\
  apt-get autoremove &&\
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
