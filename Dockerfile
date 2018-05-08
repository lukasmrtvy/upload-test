FROM alpine:3.7

ENV run2=test-service
ENV run3=another-parameter

RUN apk update && apk add --no-cache curl

RUN touch test.file && run=$(curl --upload-file test.file https://transfer.sh/test.file) && \
curl -X POST -H "Content-Type: application/json" -d '{"value1":"'"${run}"'","value2":"'"${run1}"'","value3":"'"${run2}"'"}' https://maker.ifttt.com/trigger/upload/with/key/cPy1lybKqXvF7uT3LvDTkk
