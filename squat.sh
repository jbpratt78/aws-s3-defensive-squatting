#!/bin/bash

# redundant due to '--region' flag overriding env variable
region=$(printenv AWS_DEFAULT_REGION)
file=common.txt
new=new_buckets.txt
count=0
companynames=$*
delimiters=("." "-" "" "_")

if [ -z "${1}" ]; then
	echo "Must provide a name as an argument"
	echo "Usage: ./squat.sh <company-name>"
	echo "Options: -h | --hard    Use the file with more common words"
	exit 1
fi

if [[ ${1} == -h || ${1} == --hard ]]; then
	echo "Squatting super hard"
	file=more-common.txt
	shift
	companynames=$*
fi

for companyname in $companynames; do
	while IFS= read -r i; do
		for delim in "${delimiters[@]}"; do
			bucket=$(printf "%s%s%s" "${companyname}" "${delim}" "${i}")
			res=$(aws s3api head-bucket --bucket "${bucket}" 2> >(grep -c '403'))
			if [[ ${res} -eq 1 ]]; then
				echo "$bucket already exists"
				continue
			fi
			if aws s3api create-bucket --bucket "${bucket}" --region "${region}" --acl private >/dev/null 2>&1; then
				echo "${bucket}" >>$new
				echo "${bucket} created successfully"
				((count = count + 1))
				continue
			fi
		done
	done <"${file}"
done

echo "made ${count} buckets"
