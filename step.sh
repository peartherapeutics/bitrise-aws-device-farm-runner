#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -e

#=======================================
# Functions
#=======================================

RESTORE='\033[0m'
RED='\033[00;31m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
GREEN='\033[00;32m'

function color_echo {
	color=$1
	msg=$2
	echo -e "${color}${msg}${RESTORE}"
}

function echo_fail {
	msg=$1
	echo
	color_echo "${RED}" "${msg}"
	exit 1
}

function echo_warn {
	msg=$1
	color_echo "${YELLOW}" "${msg}"
}

function echo_info {
	msg=$1
	echo
	color_echo "${BLUE}" "${msg}"
}

function echo_details {
	msg=$1
	echo "  ${msg}"
}

function echo_done {
	msg=$1
	color_echo "${GREEN}" "  ${msg}"
}

function validate_required_input {
	key=$1
	value=$2
	if [ -z "${value}" ] ; then
		echo_fail "[!] Missing required input: ${key}"
	fi
}

function validate_required_input_with_options {
	key=$1
	value=$2
	options=$3

	validate_required_input "${key}" "${value}"

	found="0"
	for option in "${options[@]}" ; do
		if [ "${option}" == "${value}" ] ; then
			found="1"
		fi
	done

	if [ "${found}" == "0" ] ; then
		echo_fail "Invalid input: (${key}) value: (${value}), valid options: ($( IFS=$", "; echo "${options[*]}" ))"
	fi
}

#=======================================
# Main
#=======================================

#
# Validate parameters
echo_info "Configs:"
if [[ -n "$access_key_id" ]] ; then
	echo_details "* access_key_id: ***"
else
	echo_details "* access_key_id: [EMPTY]"
fi
if [[ -n "$secret_access_key" ]] ; then
	echo_details "* secret_access_key: ***"
else
	echo_details "* secret_access_key: [EMPTY]"
fi
echo_details "* device_farm_project: $device_farm_project"
echo_details "* test_package_name: $test_package_name"
echo_details "* test_type: $test_type"
echo_details "* ios_pool: $ios_pool"
echo_details "* run_name_prefix: $run_name_prefix"
echo_details "* upload_bucket: $upload_bucket"
echo_details "* upload_local_path: $upload_local_path"
echo_details "* acl_control: $acl_control"
echo_details "* set_acl_only_on_changed_objets: $set_acl_only_on_changed_objets"
echo_details "* aws_region: $aws_region"
echo

validate_required_input "access_key_id" $access_key_id
validate_required_input "secret_access_key" $secret_access_key
validate_required_input "device_farm_project" $device_farm_project
validate_required_input "test_package_name" $test_package_name
validate_required_input "test_type" $test_type
validate_required_input "ios_pool" $ios_pool
#validate_required_input "upload_bucket" $upload_bucket
#validate_required_input "upload_local_path" $upload_local_path

####### Set up device farm run ##########
set -o nounset
set -o errexit
set -o pipefail

# Get most recent test bundle ARN
test_package_arn=$(aws devicefarm list-uploads --arn="$device_farm_project" --query="uploads[?name=='${test_package_name}'] | max_by(@, &created).arn" --no-paginate | sed 's/\"//g')

echo_details "Got test bundle ARN:'${test_package_arn}'"

#TODO upload app bundle and get ARN from that
app_arn='HARDCODE APP ARN HERE'

#TODO get these from bitrise env
platform='ios'
bitrise_build_number='0'
device_pool="$ios_pool"

run_params=(--project-arn="$device_farm_project")
run_params+=(--device-pool-arn="$device_pool")
run_params+=(--app-arn="$app_arn")
run_params+=(--test="{\"type\": \"${test_type}\",\"testPackageArn\": \"${test_package_arn}\",\"parameters\": {\"TestEnvVar\": \"foo\"}}")
run_params+=(--query='run.arn')

if [ ! -n "${run_name_prefix}" ]; then
    run_params+=(--name="${run_name_prefix}_${platform}_${bitrise_build_number}")
fi
run_arn=$(aws devicefarm schedule-run "${run_params[@]}" | sed 's/\"//g')
echo "Got run ARN:'${run_arn}'"

exit 0

####### S3 UPLOAD CODE: #######

options=("public-read"  "private")
validate_required_input_with_options "acl_control" $acl_control "${options[@]}"

options=("true"  "no")
validate_required_input_with_options "set_acl_only_on_changed_objets" $set_acl_only_on_changed_objets "${options[@]}"

# this expansion is required for paths with ~
#  more information: http://stackoverflow.com/questions/3963716/how-to-manually-expand-a-special-variable-ex-tilde-in-bash
eval expanded_upload_local_path="${upload_local_path}"

if [ ! -n "${upload_bucket}" ]; then
  echo_fail 'Input upload_bucket is missing'
  exit 1
fi

if [ ! -e "${expanded_upload_local_path}" ]; then
  echo_fail "The specified local path doesn't exist at: ${expanded_upload_local_path}"
  exit 1
fi

aclcmd='private'
if [ "${acl_control}" == 'public-read' ]; then
  echo_details "ACL 'public-read' specified!"
  aclcmd='public-read'
fi

if [[ "$aws_region" != "" ]] ; then
	echo_details "AWS region (${aws_region}) specified!"
	export AWS_DEFAULT_REGION="${aws_region}"
fi

s3_url="s3://${upload_bucket}"
export AWS_ACCESS_KEY_ID="${access_key_id}"
export AWS_SECRET_ACCESS_KEY="${secret_access_key}"

# do a sync -> delete no longer existing objects
echo_info "$ aws s3 sync ${expanded_upload_local_path} ${s3_url} --delete --acl ${aclcmd}"
aws s3 sync "${expanded_upload_local_path}" "${s3_url}" --delete --acl ${aclcmd}

if [[ "${set_acl_only_on_changed_objets}" != "true" ]] ; then
  echo_details "Setting ACL on every object, this can take some time..."
  # `sync` only sets the --acl for the modified files, so we'll
  #  have to query the objects manually, and set the required acl one by one
  IFS=$'\n'
  for a_s3_obj_key in $(aws s3api list-objects --bucket "${upload_bucket}" --query Contents[].[Key] --output text)
  do
    echo_info "$ aws s3api put-object-acl --acl ${aclcmd} --bucket ${upload_bucket} --key ${a_s3_obj_key}"
    aws s3api put-object-acl --acl ${aclcmd} --bucket "${upload_bucket}" --key "${a_s3_obj_key}"
  done
  unset IFS
else
  echo_details "ACL is only changed on objects which were changed by the sync"
fi

echo_done "Success"
echo_details "Access Control set to: ${acl_control}"
if [[ -n ${AWS_DEFAULT_REGION} ]] ; then
  echo_details "AWS Region: ${aws_region}"
fi
echo_details "Base URL: http://${upload_bucket}.s3.amazonaws.com/"
