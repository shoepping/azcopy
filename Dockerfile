FROM debian:bookworm-slim as build
RUN apt-get update && apt-get install wget -y
RUN wget https://aka.ms/downloadazcopy-v10-linux \
    && tar -xvf downloadazcopy-v10-linux \
    && cp ./azcopy_linux_amd64_*/azcopy /usr/bin/

FROM debian:bookworm as release
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates xz-utils file \
    && update-ca-certificates
WORKDIR /home
RUN mkdir logs volume
COPY --from=build  /usr/bin/azcopy /usr/bin
COPY script.sh /home
RUN chmod +x script.sh
# ENTRYPOINT ["/home/script.sh"]
CMD ["/home/script.sh"]
# CMD sleep infinity
