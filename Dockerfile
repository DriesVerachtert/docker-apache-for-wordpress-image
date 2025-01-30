from ubuntu:24.04

LABEL Name "Apache and PHP modules to run a Wordpress site"
LABEL Version 0.0.4
LABEL Maintainer "Dries Verachtert" <dries.verachtert@dries.eu>

ENV DEBIAN_FRONTEND=noninteractive
ENV APACHE_SERVERADMIN=root@localhost.localdomain
ENV APACHE_ALLOWOVERRIDE=none
ENV APACHE_OPTIONS="Indexes FollowSymlinks"
ENV APACHE_SERVERNAME=wp_container

# The selected timezone doesn't matter much because you have to set
# the correct timezone in Wordpress anyway.
RUN ln -fs /usr/share/zoneinfo/Europe/Brussels /etc/localtime && \
  apt-get update && \
  apt-get -y install php php-mysql php-curl php-gd \
    php-json php-pgsql php-sqlite3 php-xml php-xmlrpc \
    php-bcmath php-bz2 php-intl php-mbstring php-zip \
    fontconfig apache2 tzdata libapache2-mod-auth-plain \
    libapache2-mod-php && \
  dpkg-reconfigure --frontend noninteractive tzdata && \
  apt-get clean && \
  a2enmod php8.3 && \
  a2enmod headers && \
  a2enmod rewrite && \
  sed -i 's|ServerAdmin .*|ServerAdmin ${APACHE_SERVERADMIN}|;' /etc/apache2/sites-available/000-default.conf && \
  sed -i 's|ErrorLog .*|ErrorLog /proc/self/fd/2|;' /etc/apache2/sites-available/000-default.conf && \
  sed -i 's|CustomLog .*|CustomLog /proc/self/fd/1 combined|;' /etc/apache2/sites-available/000-default.conf && \
  sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/site|;' /etc/apache2/sites-available/000-default.conf && \
  sed -i 's|^ErrorLog .*|ErrorLog /proc/self/fd/2|;' /etc/apache2/apache2.conf && \
  echo '<Directory /var/www/html>\n  AllowOverride ${APACHE_ALLOWOVERRIDE}\n  Options ${APACHE_OPTIONS}\n  Require all granted\n</Directory>' >> /etc/apache2/sites-available/000-default.conf && \
  mkdir -p /var/www/html/site && mkdir -p /var/www/html/media && \
  a2query -s && a2query -v && a2query -m

VOLUME /var/www/html/site
VOLUME /var/www/html/media
EXPOSE 80

CMD /usr/sbin/apachectl -D FOREGROUND -c "ServerName ${APACHE_SERVERNAME}" -c "ServerTokens Prod"

# Note: the apache Directory statement allows /var/www/html but DocumentRoot is set to /var/www/html/site.
# The goal is to allow read-only and read-write mounts, for example:
#   * regular wordpress blog in /var/www/html/site, mounted read-only, with wp-content/uploads a symbolic link
#     towards /var/www/html/media
#   * a directory for the uploads mounted read-write on /var/www/html/media
