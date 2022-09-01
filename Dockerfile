##
## Build
##
FROM registry.redhat.io/rhel8/go-toolset:1.17.12-3.1661377020 as testserver_builder
## FROM docker.io/golang as testserver_builder
WORKDIR /opt/app-root
ADD . /opt/app-root
RUN CGO_ENABLED=0 GOOS=linux go build -o bin/testserver

##
## Deploy
##
FROM registry.access.redhat.com/ubi8/ubi-minimal:8.6
RUN mkdir /app
RUN microdnf install openssl
COPY --from=testserver_builder /opt/app-root/bin/testserver /app/testserver
RUN chmod -R 777 /app
COPY entrypoint.sh /app
EXPOSE 8080 8443
ENTRYPOINT [ "/app/entrypoint.sh" ]
