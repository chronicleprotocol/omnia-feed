FROM alpine:3.16 as rust-builder
ARG TARGETARCH

ENV CARGO_NET_GIT_FETCH_WITH_CLI=true

WORKDIR /opt
RUN apk add clang lld curl build-base linux-headers git \
  && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > rustup.sh \
  && chmod +x ./rustup.sh \
  && ./rustup.sh -y

RUN [[ "$TARGETARCH" = "arm64" ]] && echo "export CFLAGS=-mno-outline-atomics" >> $HOME/.profile || true

WORKDIR /opt/foundry

ARG CAST_REF="cb925b1"
RUN git clone https://github.com/foundry-rs/foundry.git . \
  && git checkout --quiet ${CAST_REF}

RUN source $HOME/.profile && cargo build --release --bin cast \
  && strip /opt/foundry/target/release/cast

FROM python:3.9-alpine3.16

ENV GLIBC_KEY=https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
ENV GLIBC_KEY_FILE=/etc/apk/keys/sgerrand.rsa.pub
ENV GLIBC_RELEASE=https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.35-r0/glibc-2.35-r0.apk

RUN apk add --update --no-cache linux-headers gcompat git

RUN wget -q -O ${GLIBC_KEY_FILE} ${GLIBC_KEY} \
  && wget -O glibc.apk ${GLIBC_RELEASE} \
  && apk add glibc.apk --force

RUN pip install --no-cache-dir mpmath sympy ecdsa==0.16.0

COPY --from=rust-builder /opt/foundry/target/release/cast /usr/local/bin/cast
