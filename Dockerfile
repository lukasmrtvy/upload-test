FROM alpine:3.7


RUN apk update && apk install --no-cache curl

RUN touch test.file && run=$(curl --upload-file test.file https://transfer.sh/test.file) && echo "run"

#RUN curl -X POST -H "Content-Type: application/json" -d '{"value1":"a","value2":"b","value3":"c"}' https://maker.ifttt.com/trigger/upload/with/key/cPy1lybKqXvF7uT3LvDTkk
