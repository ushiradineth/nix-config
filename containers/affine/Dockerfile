FROM ghcr.io/toeverything/affine:0.27.4@sha256:adb3cea3eb4a50a6116dbab7dc045252b54ede3e73828a85a58daf78da3b1f6d

COPY import-errors.ts /tmp/affine-import-errors.ts
RUN node --experimental-strip-types /tmp/affine-import-errors.ts /app/static
