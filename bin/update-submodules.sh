#! /bin/bash
#
# update-submodules.sh
# Copyright (C) 2020 d3engineering
#
# Distributed under terms of the MIT license.
#
# This script exists to allow rapid interaction in updating the submodules of a
# git repo.
#


# Updates a single submodule to a different commit
# $1 - Submodule path
# $2 - Commit to move submodule to
function update_submodule {
	# Check for required parameters
	test -z ${1} || test -z ${2} && \
		echo "Missing parameter in ${FUNCNAME[0]}" && \
		return 1

	ret_dir="$(pwd)"
	cd "$1"
	pwd
	git fetch -a
	git checkout "$2"
	cd "$ret_dir"
}


# Puts a submodule commit onto a branch
# $1 - Submodule path
# $2 - Target branch name to create
function branch_submodule {
	# Check for required parameters
	test -z ${1} || test -z ${2} && \
		echo "Missing parameter in ${FUNCNAME[0]}" && \
		return 1

	ret_dir="$(pwd)"
	cd "$1"
	git fetch -a
	git checkout -b "$2"
	cd "$ret_dir"
}


# Push submodule to remote
# $1 - Submodule path
# $2 - Target branch name to create on remote
function push_submodule {
	# Check for required parameters
	test -z ${1+x} || test -z ${2+x} && \
		echo "Missing parameter in ${FUNCNAME[0]}" && \
		return 1

	ret_dir="$(pwd)"
	cd "$1"
	git push -u origin "$2"
	cd "$ret_dir"
}


# Attempts a merge of a submodule with a specific commit
# Will have non-zero exit on merge issue
# $1 - Submodule path
# $2 - Target commit/branch to merge with
function merge_submodule {
	# Check for required parameters
	test -z ${1} || test -z ${2} && \
		echo "Missing parameter in ${FUNCNAME[0]}" && \
		return 1

	ret=0
	ret_dir="$(pwd)"
	cd "$1"
	git fetch -a
	if ! git merge "$2"; then
		ret=1
		tput setf 1
		echo "Unable to automatically merge!"
		tput sgr0
	fi
	cd "$ret_dir"
	return $ret
}

# Attempts to update all submodules to match that of another branch
# $1 - Target release to attempt to upgrade to
# $2 - upgrade target branch name
function update_all_to_release {
	# Check for required parameters
	test -z ${1} || test -z ${2} && \
		echo "Missing parameter in ${FUNCNAME[0]}" && \
		return 1

	ret=0
	ret_dir="$(pwd)"
	cd "$(git rev-parse --show-toplevel)"
	home_commit="$(git rev-parse HEAD)"

	# check if target branch is valid while probing it
	if ! git checkout "$1"; then
		tput setf 1
		echo "Target branch for upgrade not found. ABORTING!"
		tput sgr0
		exit 1
	fi
	git submodule update --recursive
	target_submodule_output=$(git submodule status)

	# return to starting branch
	git checkout "$home_commit"
	git submodule update --recursive

	# create destination branch
	if ! git checkout -b "$2"; then
		tput setf 1
		echo "Could not make target branch. ABORTING!"
		tput sgr0
		exit 1
	fi

	# merge each submodule and create a branch
	IFS=$'\n'
	for line in $target_submodule_output; do
		sm_path=$(echo $line | \
			awk '{print $2}')
		sm_target_commit=$(echo $line | \
			awk '{print $1}')
		if ! merge_submodule "$sm_path" "$sm_target_commit"
		then
			tput setf 1
			echo "Merging submodules returned non zero. ABORTING!"
			echo "Please fix merge conflicts in $submodule_path"
			echo "Once done, restart this script."
			tput sgr0
			exit 1
		fi
		branch_submodule "$sm_path" "$2"
		push_submodule "$sm_path" "$2"
		git add "$sm_path"
	done
	unset IFS

	git commit -m "USS: Update from $home_commit to $1"

}

# Check for required parameters
test -z ${1} || test -z ${2} && \
	echo "Usage: update-submodules.sh <target upgrade branch>"\
	"<destination branch>" && \
	exit 1

cd "$(git rev-parse --show-toplevel)"
update_all_to_release "$1" "$2"
