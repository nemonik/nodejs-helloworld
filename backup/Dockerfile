FROM alpine:latest
MAINTAINER <github.com@nemonik.com> Michael Joseph Walsh

RUN mkdir -p /aws &&  \
    apk -Uuv add --no-cache groff less python py-pip bash mysql-client && \
    pip install --upgrade pip && \
    pip install awscli && \
    apk --purge -v del py-pip

ADD backup.sh backup.sh

RUN chmod +x ./backup.sh

ENV AWS_ACCESS_KEY_ID=**provide**

ENV AWS_SECRET_ACCESS_KEY=**provide**

ENV AWS_DEFAULT_REGION=us-east-1

CMD ["/backup.sh"]
