# This file is intended to be used apart from the containing source code tree.

FROM python:3-alpine AS builder

# Version of Radicale (e.g. v3)
ARG VERSION=master

# Optional dependencies (e.g. bcrypt or ldap)
ARG DEPENDENCIES=bcrypt

# py-vobject version supporting vCard v4.0
# see:
#   https://github.com/Kozea/Radicale/pull/1948
# no longer required if the following is merged:
#   https://github.com/py-vobject/vobject/pull/124
ARG VOBJECT="vobject @ git+https://github.com/jwiegley/vobject.git"

RUN apk add --no-cache --virtual gcc libffi-dev musl-dev git \
    && python -m venv /app/venv \
    && /app/venv/bin/pip install --no-cache-dir "${VOBJECT}" "Radicale[${DEPENDENCIES}] @ https://github.com/Kozea/Radicale/archive/${VERSION}.tar.gz"


FROM python:3-alpine

WORKDIR /app

RUN addgroup -g 1000 radicale \
    && adduser radicale --home /var/lib/radicale --system --uid 1000 --disabled-password -G radicale \
    && apk add --no-cache ca-certificates openssl curl git

COPY --chown=radicale:radicale --from=builder /app/venv /app

# Persistent storage for data
VOLUME /var/lib/radicale
# Run Radicale
ENTRYPOINT [ "/app/bin/python", "/app/bin/radicale"]
CMD ["--hosts", "0.0.0.0:5232,[::]:5232"]

USER radicale
