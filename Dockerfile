FROM alpine:latest

RUN apk update && apk add --update --no-cache bash openssl git make musl-dev go


# Configure Go
ENV GOROOT /usr/lib/go
ENV GOPATH /go
ENV PATH /go/bin:$PATH

RUN mkdir -p ${GOPATH}/src ${GOPATH}/bin

# Install deps
RUN env GIT_TERMINAL_PROMPT=1 go get github.com/gin-contrib/static
RUN env GIT_TERMINAL_PROMPT=1 go get github.com/gin-gonic/gin
RUN env GIT_TERMINAL_PROMPT=1 go get github.com/russross/blackfriday

#WORKDIR $GOPATH

#CMD ["make"]

COPY ./assets/ /app/assets/
COPY ./templates/ /app/templates/
COPY ./markdown/ /app/markdown/
COPY ./opsdude.go /

RUN cp opsdude.go /go/src/
RUN go build opsdude.go

RUN cp opsdude /app/

WORKDIR /app

EXPOSE 8080

ENTRYPOINT ["/app/opsdude"]


