FROM alpine:3.7

ENV name=test-service
ENV type=download-link

RUN apk update && apk add --no-cache curl jq

RUN touch test.file && url=$(curl --upload-file test.file https://transfer.sh/test.file) && \
curl -X POST -H "Content-Type: application/json" -d '{"value1":"'"${name}"'","value2":"'"${type}"'","value3":"'"${url}"'"}' https://maker.ifttt.com/trigger/upload/with/key/cPy1lybKqXvF7uT3LvDTkk

RUN dd if=/dev/zero of=test2.file  bs=1024  count=14336 && response=$(curl -F "file=@test2.file" https://file.io) && url=$(echo $response | jq -r .link) && \
curl -X POST -H "Content-Type: application/json" -d '{"value1":"'"${name}"'","value2":"'"${type}"'","value3":"'"${url}"'"}' https://maker.ifttt.com/trigger/upload/with/key/cPy1lybKqXvF7uT3LvDTkk




RUN dd if=/dev/zero of=lede-snapshot-combined-ext4.img.gz && response=$(curl -F "file=@lede-snapshot-combined-ext4.img.gz" https://file.io) && url=$(echo $response | jq -r .link) && \
curl -X POST -H "Content-Type: application/json" -d '{"value1":"'"${name}"'","value2":"'"${type}"'","value3":"'"${url}"'"}' https://maker.ifttt.com/trigger/upload/with/key/cPy1lybKqXvF7uT3LvDTkk

