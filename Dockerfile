# syntax=docker/dockerfile:1.29.0@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183
FROM python:3.15.2-slim@sha256:65a65fc7b30b06cb6df4930fd4650697cb23f4c2698ab81fc87e4b031bc36928
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
