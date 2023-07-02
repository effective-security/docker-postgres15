# Build on top of base CentOS 9 Stream image
FROM quay.io/centos/centos:stream9

# Adding the package path to local
ENV LANG=en_US.UTF-8
ENV PATH=$PATH:/usr/pgsql-15/bin
ENV PG_CONFDIR="/var/lib/pgsql"
ENV PGDATA="/var/lib/pgsql/data"
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_COLLATE=C
ENV LC_CTYPE=en_US.UTF-8

# create local repo
#RUN mkdir -p /sql-localrepo
ADD ./postgresql-setup.sh /usr/bin/postgresql-setup.sh
ADD ./start_postgres.sh /start_postgres.sh
ADD ./postgresql.conf /var/lib/pgsql/postgresql.conf

RUN dnf -y install \
    which \
    systemd-sysv \
    yum-utils

RUN dnf -y install glibc-all-langpacks langpacks-en

# install PostgreSQL rpm repository:
RUN dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
# Need to disable the built-in PostgreSQL module for OS version 8 and 9:
RUN dnf -qy module disable postgresql
RUN dnf install -y postgresql15-server

# Cleanup
RUN dnf -y clean all && dnf update -y

#ADD ./repodata/ /sql-localrepo
#ADD ./sql-localrepo.repo /etc/yum.repos.d/sql-localrepo.repo
# RUN createrepo -v /sql-localrepo/ && \
#     yum repolist && \
#     yum -y install --disablerepo="*" --enablerepo="sql-localrepo" \
#     postgresql11-server

RUN chmod a+x /usr/bin/* && \
    chmod a+x /start_postgres.sh && \
    chown -R postgres.postgres /var/lib/pgsql && \
    chown postgres.postgres /start_postgres.sh && \
    echo "host    all             all             0.0.0.0/0               trust" >> /var/lib/pgsql/pg_hba.conf

RUN /usr/bin/postgresql-setup.sh initdb || cat /var/lib/pgsql/initdb.log

VOLUME ["/var/lib/pgsql","/scripts/pgsql"]

EXPOSE 5432

CMD ["/bin/bash", "/start_postgres.sh"]
