#!/bin/sh

if [ ! -d ./logs ]; then
	mkdir -p ./logs
else	
	rm logs/*.log
fi


CPU_NUM=4
if [[ `uname` == 'Linux' ]]; then
	CPU_NUM=`cat /proc/cpuinfo| grep "processor"| wc -l`
elif [[ `uname` == 'Darwin' ]]; then
	CPU_NUM=`sysctl -n hw.physicalcpu`
fi
export SKYNET_THREAD=`expr $CPU_NUM \* 2`

export TMPATH="../terminator"
export NODE_NAME="T800"
$TMPATH/skynet/skynet ./config.lua
