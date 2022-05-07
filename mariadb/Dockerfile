FROM mariadb:latest

RUN echo "[mysqld]" >> /etc/mysql/mariadb.conf.d/mariadb.cnf \
    && echo "server-id=1" >> /etc/mysql/mariadb.conf.d/mariadb.cnf \
    #&& echo "log_bin=/var/log/mysql/mariadb-bin" >> /etc/mysql/mariadb.conf.d/mariadb.cnf \
    #&& echo "log_bin_index=/var/log/mysql/mariadb-bin.index" >> /etc/mysql/mariadb.conf.d/mariadb.cnf \
    && echo "log_bin=master" >> /etc/mysql/mariadb.conf.d/mariadb.cnf \
    && echo "binlog_format=row" >> /etc/mysql/mariadb.conf.d/mariadb.cnf
    #&& echo "binlog_row_image=full" >> /etc/mysql/mariadb.conf.d/mariadb.cnf \
    #&& echo "expire_logs_days=10" >> /etc/mysql/mariadb.conf.d/mariadb.cnf
