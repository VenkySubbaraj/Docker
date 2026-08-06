FROM ubuntu as base
WORKDIR /app

COPY init ./init
COPY mysql ./mysql

RUN mkdir output && \
    cp -r init output && \
    cp -r mysql output


FROM mysql:8.4 as final
COPY --from=base /app/output/init \
    /docker-entrypoint-initdb.d

COPY --from=base /app/output/mysql/my.cnf \
    /etc/mysql/conf.d/my.cnf


ENV MYSQL_ROOT_PASSWORD=root
ENV MYSQL_DATABASE=mydb
ENV MYSQL_USER=myuser
ENV MYSQL_PASSWORD=password123

EXPOSE 3306