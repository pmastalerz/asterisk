# Softphones over a private network / VPN

Copy into your config volume (merge carefully with existing samples):

- `pjsip.conf` — two endpoints (`100`, `200`)
- `extensions.conf` — dial between them + echo test

Change passwords before use. Video is **passthrough** (VP8/H.264 negotiated by
the softphones); the image does not transcode video.
