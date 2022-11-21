FROM oraclelinux:7.9
LABEL author="Jove-2761781"

ADD assets /assets

RUN chmod -R 755 /assets && /assets/setup.sh

EXPOSE 1521
EXPOSE 8080

CMD ["/assets/entrypoint.sh"]
