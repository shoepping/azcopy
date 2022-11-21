FROM debian:bookworm-slim as build
RUN apt-get update && apt-get install wget -y
RUN wget https://aka.ms/downloadazcopy-v10-linux \
    && tar -xvf downloadazcopy-v10-linux \
    && cp ./azcopy_linux_amd64_*/azcopy /usr/bin/

RUN chmod 755 /usr/bin/azcopy

FROM debian:bookworm as release
RUN useradd -rm -d /home/azcopy -s /bin/bash -g root -G sudo -u 1000 azcopy
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates xz-utils file \
    && update-ca-certificates \
    && lsof
WORKDIR /home
RUN mkdir logs volume
COPY --from=build  /usr/bin/azcopy /usr/bin
COPY script.sh /home
RUN chmod +x script.sh
ENTRYPOINT ["/home/script.sh"]
CMD ["true"]

USER 1000
# CMD sleep infinity
