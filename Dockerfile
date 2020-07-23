FROM php:7.3-cli

LABEL maintainer="Johan van Helden <johan@johanvanhelden.com>"

RUN DEBIAN_FRONTEND=noninteractive

#####################################################################
# Insert any needed files
#####################################################################

# Add our list of wanted packages
COPY ./configfiles/composer.json /root/.composer/composer.json
COPY ./configfiles/composer.lock /root/.composer/composer.lock

# Add the PHP extension installer
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/

# Copy the PHPCS fixer rules inside the container
COPY ./configfiles/.php_cs /root/configfiles/.php_cs

#####################################################################
# Set environment variables
#####################################################################

# Prepare and install NVM
ENV NVM_DIR /root/.nvm

# Set the timezone
ARG TZ=Europe/Amsterdam
ENV TZ ${TZ}

#####################################################################
# Run the commands
#####################################################################

# Prepare MySQL 5.7
RUN apt update && apt install  --no-install-recommends -y gnupg apt-transport-https ca-certificates lsb-release wget &&\ 
  wget -qO - https://repo.mysql.com/RPM-GPG-KEY-mysql | apt-key add - &&\
  echo "mysql-community-server mysql-community-server/root-pass password root" | debconf-set-selections &&\
  echo "mysql-community-server mysql-community-server/re-root-pass password root" | debconf-set-selections &&\
  echo "mysql-apt-config mysql-apt-config/select-server select mysql-5.7" | debconf-set-selections &&\
  curl -sSL http://repo.mysql.com/mysql-apt-config_0.8.9-1_all.deb -o ./mysql-apt-config_0.8.9-1_all.deb &&\
  export DEBIAN_FRONTEND=noninteractive &&\
  dpkg -i mysql-apt-config_0.8.9-1_all.deb

# Install dependencies
RUN apt update && apt install --no-install-recommends -y \
  git \
  libpng-dev \
  mysql-community-server \
  mysql-client \
  openssh-client \
  unzip \
  xvfb \
  zip \
  &&\
  rm -rf /var/lib/apt/lists/* 

# Add maximum backwards compatibility with MySQL 5.6
RUN echo "[mysqld]" >> /etc/mysql/conf.d/z-circleci-config.cnf &&\
  echo 'sql_mode = "NO_ENGINE_SUBSTITUTION"' >> /etc/mysql/conf.d/z-circleci-config.cnf

# Install PHP extensions
RUN install-php-extensions \
  bz2 \
  bcmath \
  curl \
  exif \
  gd \
  interbase \
  imagick \
  imap \
  intl \
  mysqli \
  pcntl \
  pcov \
  pdo_mysql \
  soap \
  xmlrpc \
  xsl \
  zip \
  &&\
  docker-php-ext-install iconv &&\
  docker-php-ext-install mbstring &&\
  docker-php-ext-install pdo


# Install NVM, set NVM in bashrc and install yarn
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash &&\
  . /root/.nvm/nvm.sh &&\
  nvm install 14 &&\
  nvm install 12 &&\
  nvm install 10 &&\
  nvm alias default 10 &&\
  echo "" >> ~/.bashrc &&\
  echo 'export NVM_DIR="/root/.nvm"' >> ~/.bashrc &&\
  echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm' >> ~/.bashrc \
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" &&\
  curl -o- -L https://yarnpkg.com/install.sh | bash; \
  echo "" >> ~/.bashrc &&\
  echo 'export PATH="$HOME/.yarn/bin:$PATH"' >> ~/.bashrc

# Install composer, install packaes and set PHPCS
RUN curl -sSL https://getcomposer.org/installer | php -- --filename=composer --install-dir=/usr/bin &&\
  echo 'export PATH="$HOME/.composer/vendor/bin:$PATH"' >> ~/.bashrc &&\
  cd /root/.composer && composer install &&\
  /root/.composer/vendor/bin/phpcs --config-set installed_paths /root/.composer/vendor/phpcompatibility/php-compatibility

# Install chrome - needed for Laravel Dusk
# For easy Laravel Dusk driver management, make an environment variable available with the Chrome version
RUN curl -sS https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - &&\
  sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list' &&\
  apt update && apt install -y google-chrome-stable &&\
  google-chrome --version | grep -ioEh "([0-9]){2}" | head -n 1 > /root/chrome_version &&\
  echo 'export CHROME_VERSION=$(cat /root/chrome_version)' >> ~/.bashrc

# Clean up when done
RUN apt autoclean && apt clean && apt autoremove && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
