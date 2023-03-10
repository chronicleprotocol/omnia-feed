FROM node:10.24.1-alpine3.11

RUN apk add bash git automake wget

# COPY ./docker/ssb-server/state/db /root/.ssb/db
COPY ./docker/ssb-server/config/manifest.json /root/.ssb/manifest.json

WORKDIR /root/ssb

ARG SSB_REF="tags/v15.3.0"

# RUN npm install -g --no-optional ssb-server
RUN git clone https://github.com/ssbc/ssb-server . \
  && git checkout ${SSB_REF}

RUN npm install

# Patching ssb-server
RUN wget https://raw.githubusercontent.com/chronicleprotocol/oracles/master/ssb-server/ssb-db%2B19.2.0.patch \
  && git apply ssb-db+19.2.0.patch

# COPY ./docker/ssb-server/bin/run.sh /root/ssb/bin/

# Disable 'sodium-native' warning message
ENV CHLORIDE_JS='1'

EXPOSE 8000

CMD [ "node", "./bin.js", "start" ]
