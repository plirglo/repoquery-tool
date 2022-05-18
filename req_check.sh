#!/bin/bash

set -euo pipefail

dependencies=$1

declare -a requirements=()
declare -a leaf=()
declare -a branch=()

get_requirements(){
    while read -r line
    do
        requirements+=($line)
    done < "$dependencies"
}

write_branch_to_file(){
    sorted_unique_deps=$( echo "${branch[@]}" |  tr ' ' '\n' | sort -u )
    echo $sorted_unique_deps | tr ' ' '\n' > branch
}

write_leaf_to_file(){
    sorted_unique_deps=$( echo "${leaf[@]}" |  tr ' ' '\n' | sort -u )
    echo $sorted_unique_deps | tr ' ' '\n' >> leaf
}

repoquery(){
    repoquery_output=$( dnf repoquery --archlist=aarch64,noarch --disableplugin=subscription-manager --latest-limit=1 --quiet --requires --resolve -y $1 )
    repoquery_output_count=$( echo $repoquery_output | wc -w )

    echo "Querying package $1"
    if [[ $repoquery_output_count == 0 ]]; then
        leaf+=($1);
    else
        branch+=($repoquery_output);
    fi
}

if [[ $# -eq 0 ]] ; then
    echo "You have to pass file with packages list as an argument... Exiting"
    exit 0
fi

echo "Reading packages list from $1 file..."
get_requirements
echo "Packages read"

echo "Querying packages' dependencies, it can take a while..."
for element in "${requirements[@]}";
    do repoquery "$element";
done
echo "Dependencies checked"

echo "Writing results to branch file"
write_branch_to_file
echo "Results saved in branch file"
echo "Adding results to leaf file"
write_leaf_to_file
echo "Results added to leaf file"