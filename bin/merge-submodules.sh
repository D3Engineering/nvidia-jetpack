#! /bin/bash
#
# merge-submodules.sh
# Copyright (C) 2020 D3 Engineering
#
# Distributed under terms of the MIT license.
#

rp=$(pwd)

test -z ${1} || test -z ${2} && \
	echo "Usage: merge-submodules.sh <New Submodule Target Branch> <Upstream Tag/Branch to Merge>" && \
	exit 1

git submodule foreach git checkout -b "$1" > /dev/null
exec 3>&1
merge_out=$(git submodule foreach "git merge "$2" || echo 'MERGE_ERR!' && :" 2>/dev/null)
exec 3>&-

echo ""
echo "$merge_out" | grep "Entering\|MERGE_ERR"
