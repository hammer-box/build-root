#!/bin/bash
MODEL=wzr-hp-ag300h
svn co -r 32467 svn://svn.openwrt.org/openwrt/trunk $MODEL
cp feeds.conf $MODEL
cd $MODEL
scripts/feeds update -a
scripts/feeds install -a
scripts/feeds install -p hammer nginx
cp ../$MODEL.hammer .config
make -j8 V=99
