# syntax=docker/dockerfile:1.28.0@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b
FROM python:3.15.1-slim@sha256:533b0b2f9b5d46fd097091cf826f27902f1d6c3bca714b6dc74551356aa97a51
COPY --from=denoland/deno:2.9.8@sha256:a0d88a7fcbd44f062cba2748e19df67d30290ad12aa203c7c1e0b12462c483f0 /usr/bin/deno /usr/bin/deno
COPY requirements.txt /tmp/requirements.txt
RUN python3 -m pip install --no-cache-dir --require-hashes -r /tmp/requirements.txt \
 && python3 -m pip check \
 && groupadd --gid 1000 ytdlp \
 && useradd --uid 1000 --gid 1000 --create-home --shell /usr/sbin/nologin ytdlp \
 && rm /tmp/requirements.txt
USER ytdlp:ytdlp
WORKDIR /wa
ENTRYPOINT ["yt-dlp"]
