#!/bin/sh

git clone https://github.com/epinna/weevely3
pushd weevely3
pipx install uv
uv tool install https://github.com/epinna/weevely3.git
popd
