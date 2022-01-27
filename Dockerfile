FROM debian:bookworm-slim as build
RUN apt-get update && apt-get install wget -y
RUN wget https://aka.ms/downloadazcopy-v10-linux \
    && tar -xvf downloadazcopy-v10-linux \
    && cp ./azcopy_linux_amd64_*/azcopy /usr/bin/

FROM debian:bookworm as release
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
    && update-ca-certificates
WORKDIR /home/logs
COPY --from=build  /usr/bin/azcopy /usr/bin
CMD sleep infinity
