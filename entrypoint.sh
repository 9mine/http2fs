#!/bin/sh

execfuse-static /http2fs /usr/inferno-os/host/http2fs
emu-g /dis/sh /lib/sh/profile
