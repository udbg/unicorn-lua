#!/bin/sh

eval "$(@LUAROCKS_EXE@ path)"
@BUSTED_EXE@ @BUSTED_CLI_ARGS@ --verbose --shuffle -f @CMAKE_CURRENT_BINARY_DIR@/busted-config.lua
