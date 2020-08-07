FROM alpine:3.11 as liquidsoap-builder

RUN apk add --no-cache \
        git \
        wget \
        curl \
        unzip \
        make \
        bash \
        patch \
        autoconf \
        automake \
        cmake \
        g++ \
        gcc \
        pcre-dev \
        musl-dev \
        m4 \
        curl \
        coreutils \
        musl-dev \
        faad2-dev ffmpeg-dev lame-dev libmad-dev libsamplerate-dev taglib-dev libvorbis-dev flac-dev \
        ocaml \
        ocaml-compiler-libs \
        opam

RUN addgroup liquidsoap \
    && adduser -D -s /bin/bash -G liquidsoap liquidsoap && \
    mkdir -p /opt/opam && \
    chown -R liquidsoap:liquidsoap /opt/opam

USER liquidsoap

ENV OPAMROOT=/opt/opam

RUN opam init -a -y --disable-sandboxing --root /opt/opam

RUN eval $(opam env --root=/opt/opam) && opam install ffmpeg taglib mad lame cry samplerate faad vorbis flac -y
RUN opam pin add liquidsoap https://github.com/savonet/liquidsoap.git#1.4.2 -y


FROM alpine:3.11 as final

RUN apk add --no-cache \
        bash \
        pcre \
        faad2 \
        ffmpeg \
        lame \
        libmad \
        libsamplerate \
        taglib \
        libvorbis \
        flac

RUN addgroup liquidsoap && adduser -D -s /bin/bash -G liquidsoap liquidsoap && \
    mkdir -p /opt/opam/default/lib/liquidsoap/share/liquidsoap/1.4.2/libs/ && \
    mkdir -p /opt/opam/default/bin

COPY --from=liquidsoap-builder /opt/opam/default/bin/liquidsoap /opt/opam/default/bin/liquidsoap
COPY --from=liquidsoap-builder \
    /opt/opam/default/lib/liquidsoap/share/liquidsoap/1.4.2/libs \
    /opt/opam/default/lib/liquidsoap/share/liquidsoap/1.4.2/libs

RUN chmod +x /opt/opam/default/bin/liquidsoap && \
    ln -s /opt/opam/default/bin/liquidsoap /usr/local/bin/liquidsoap

ENTRYPOINT ["liquidsoap"]

CMD ["--help"]

