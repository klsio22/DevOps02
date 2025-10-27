FROM alpine:3.18

RUN apk add --no-cache openssl bash

WORKDIR /ca

COPY generate-certs.sh /ca/generate-certs.sh
RUN chmod +x /ca/generate-certs.sh

ENTRYPOINT ["/ca/generate-certs.sh"]
