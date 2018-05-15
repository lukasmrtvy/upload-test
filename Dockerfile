FROM alpine:3.7

ENV name=test-service
ENV type=download-link

RUN apk update && apk add --no-cache curl jq

RUN touch test.file && url=$(curl --upload-file test.file https://transfer.sh/test.file) && \
curl -X POST -H "Content-Type: application/json" -d '{"value1":"'"${name}"'","value2":"'"${type}"'","value3":"'"${url}"'"}' https://maker.ifttt.com/trigger/upload/with/key/cPy1lybKqXvF7uT3LvDTkk

RUN touch test2.file && response=$(curl -F "file=@test2.file" https://file.io) && url=$(echo $response | jq -r .link) && \
curl -X POST -H "Content-Type: application/json" -d '{"value1":"'"${name}"'","value2":"'"${type}"'","value3":"'"${url}"'"}' https://maker.ifttt.com/trigger/upload/with/key/cPy1lybKqXvF7uT3LvDTkk



