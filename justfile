image := 'ghcr.io/acidghost/yt-dlp-oci'
engine := 'docker'
platform_flags := '--platform linux/amd64'

build-image:
    {{engine}} build {{platform_flags}} -t {{image}}:local .

smoke-image: build-image
    {{engine}} run --rm {{platform_flags}} {{image}}:local --version
    {{engine}} run --rm {{platform_flags}} --entrypoint deno {{image}}:local --version
    {{engine}} run --rm {{platform_flags}} --entrypoint python {{image}}:local -c 'import yt_dlp, yt_dlp_ejs'

update-requirements:
    uv pip compile --generate-hashes --exclude-newer=P7D \
        --output-file=requirements.txt requirements.in
