# vim:set ft=dockerfile:
FROM ubuntu:trusty

ENV DEBIAN_FRONTEND=noninteractive

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r mysql && useradd -r -g mysql mysql

RUN mkdir /docker-entrypoint-initdb.d

RUN apt-get install -y  wget

RUN echo 'deb http://repositories.ecg.so/percona trusty main' > /etc/apt/sources.list.d/percona.list
RUN wget -q 'http://repositories.ecg.so/keys/percona.gpg' -O- | apt-key add -

ENV PERCONA_MAJOR 5.5
ENV PERCONA_VERSION 5.5.46-rel37.5-1.trusty

# the "/var/lib/mysql" stuff here is because the mysql-server postinst doesn't have an explicit way to disable the mysql_install_db codepath besides having a database already "configured" (ie, stuff in /var/lib/mysql/mysql)
# also, we set debconf keys to make APT a little quieter
RUN { \
		echo percona-server-server-$PERCONA_MAJOR percona-server-server/root_password password '123qwe'; \
		echo percona-server-server-$PERCONA_MAJOR percona-server-server/root_password_again password '123qwe'; \
	} | debconf-set-selections \
	&& apt-get update \
	&& apt-get install -y \
		percona-server-server-$PERCONA_MAJOR=$PERCONA_VERSION \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /var/lib/mysql \
	&& mkdir /var/lib/mysql

# comment out a few problematic configuration values
# don't reverse lookup hostnames, they are usually another container
#RUN sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/my.cnf \
#	&& echo 'skip-host-cache\nskip-name-resolve' | awk '{ print } $1 == "[mysqld]" && c == 0 { c = 1; system("cat") }' /etc/mysql/my.cnf > /tmp/my.cnf \
#	&& mv /tmp/my.cnf /etc/mysql/my.cnf

COPY my.cnf /etc/mysql/my.cnf

VOLUME /var/lib/mysql

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 3306
CMD ["mysqld"]
