# circleci-laravel

A docker image containing all of the tools necessary to build and test a Laravel application.

- **PHP version:** 7.4
- **MySQL version:** 5.7
- **NodeJS versions:** 10, 12, 14

### PHP Modules:
```
bcmath
bz2
Core
ctype
curl
date
dom
exif
fileinfo
filter
ftp
gd
hash
iconv
imagick
imap
interbase
intl
json
libxml
mbstring
mysqli
mysqlnd
openssl
pcntl
pcre
PDO
pdo_mysql
pdo_sqlite
Phar
posix
readline
Reflection
session
SimpleXML
soap
sodium
SPL
sqlite3
standard
tokenizer
xml
xmlreader
xmlrpc
xmlwriter
xsl
zip
zlib
```

## Available tags
- `latest`

## Building and publishing

Ensure you are logged in locally to hub.docker.com using `docker login` (note: your username is used, not your email address).

```
$ docker build ./ --tag johanvanhelden/circleci-laravel:TAG
$ docker push johanvanhelden/circleci-laravel:TAG
```

Replace `TAG` with either develop or latest.

## Development

If you want to test a new feature, create a new tag for it. This way, it can not introduce issues in the production image if something is not working properly.

Once it works, delete the custom tag and introduce it into `latest`

## Testing the image locally

```
$ docker-compose up --build
$ docker exec -it circleci-laravel bash
```

## Accessing projects
Projects are mounted to `/var/www/projects`.

## Running MySQL
`/usr/bin/mysqld_safe --user=mysql &`

## Interacting with MySQL
`mysql -u root -proot`

## Laravel Dusk Chrome Driver

If the image is updated, Chrome is updated as well. This might break your Dusk test if you are using an older Chrome driver.
To make sure this does not happen, you can use artisan to download the proper Chrome driver based on this image's Chrome version.

A `CHROME_VERSION` environment variable is available containing the current Chrome version (i.e. `79`). So you can automate downloading the proper Chrome version like this:

```bash
php artisan dusk:chrome-driver ${CHROME_VERSION}
```

If the platform you run Dusk on does not support reading the environment variables from the docker image, you can, for example, manually create the variable, like so:

```bash
CHROME_VERSION=$(cat /root/chrome_version)
```

Make sure you create it before running the download command.
