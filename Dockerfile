# syntax=docker/dockerfile:1.28.0@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b
FROM python:3.14.8-slim@sha256:a2b82f3c48559aa0a8446d9af49826b6e2b2016f4cd2afabfe6013ec53729170
COPY --from=denoland/deno:2.9.7@sha256:fa335acdf6b72106eda2cb6a8cb5f4187e7630e357467489db4b2e7352d5e432 /usr/bin/deno /usr/bin/deno
COPY requirements.txt /tmp/requirements.txt
RUN python3 -m pip install --no-cache-dir --require-hashes -r /tmp/requirements.txt \
 && python3 -m pip check \
 && groupadd --gid 1000 ytdlp \
 && useradd --uid 1000 --gid 1000 --create-home --shell /usr/sbin/nologin ytdlp \
 && rm /tmp/requirements.txt
USER ytdlp:ytdlp
WORKDIR /wa
ENTRYPOINT ["yt-dlp"]
