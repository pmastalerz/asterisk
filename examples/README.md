# Example configs (not seeded into the image)

These snippets are **reference only**. Copy what you need into your bind-mounted
`/etc/asterisk` (Unraid appdata). The image already includes the compile-time
capabilities (PJSIP, SRTP, WebSocket hooks); you normally do **not** rebuild
for dialplan / endpoints / codecs-allowed.

| Example | Purpose |
| --- | --- |
| [`softphone-vpn/`](softphone-vpn/) | Two PJSIP softphones + simple dialplan (voice/video over VPN) |
