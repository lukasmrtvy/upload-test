FROM alpine:3.7

ENV TZ=Europe/Prague
ENV name=test-service

RUN apk update && apk add --no-cache curl jq tzdata

RUN touch test.file && url=$(curl --upload-file test.file https://transfer.sh/test.file) && \
curl -X POST -H "Content-Type: application/json" -d '{"value1":"'"${name}"'","value2":"'"${type}"'","value3":"'"${url}"'"}' https://maker.ifttt.com/trigger/upload/with/key/cPy1lybKqXvF7uT3LvDTkk


RUN datum=$(date +"%Y-%m-%dT%H:%M:%SZ") && touch /tmp/kokot && response=$(curl -F "file=@/tmp/kokot" https://file.io) && url=$(echo $response | jq -r .link) && \
curl -X POST -H "Content-Type: application/json" -d '{"value1":"'"${name}"'","value2":"'"${datum}"'","value3":"'"${url}"'"}' https://maker.ifttt.com/trigger/upload/with/key/cPy1lybKqXvF7uT3LvDTkk

