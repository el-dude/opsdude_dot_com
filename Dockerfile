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

### Install the opsdude code assets & templates
COPY ./assets/ /app/assets/
COPY ./templates/ /app/templates/
COPY ./markdown/ /app/markdown/
COPY ./opsdude.go /

### Build the opsdude App 
RUN cp opsdude.go /go/src/
RUN go build opsdude.go
RUN rm -f opsdude.go

# Cleanup 
RUN cp opsdude /app/
RUN rm -f opsdude

WORKDIR /app

EXPOSE 8080

ENTRYPOINT ["/app/opsdude"]


