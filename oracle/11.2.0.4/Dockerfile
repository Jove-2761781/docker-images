# HOW TO BUILD THIS IMAGE
# -----------------------
# Put the downloaded file in the same directory as this Dockerfile
# Run: 
#      $ docker build -t jove2761781/database:11.2.0.4-ee . 
#
FROM oraclelinux:7.9
LABEL author="jove2761781"

ENV s_ORACLE_BASE=/u01/app/oracle \
    s_ORACLE_HOME=/u01/app/oracle/product/11.2.0/db_1 \
    s_ORACLE_INVENTORY=/u01/app/oraInventory \
    s_ORACLE_SID=orcl

ADD assets /assets
RUN chmod -R 755 /assets && /assets/setup.sh

EXPOSE 1521
EXPOSE 8080

CMD ["/assets/entrypoint.sh"]
