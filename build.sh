#!/bin/bash
export OUTER_UID=$UID
docker build --compress -t jonathonf/manjaro-build .
