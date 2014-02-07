#!/bin/bash

# Repoclosure Report
# Author: Christopher Markieta

declare -a f19repos=(
    f19-updates-build
    f19-updates-candidate-build
    f19-updates-testing-build
    f19-rpfr-build
    #f19-rpfr-updates
    #f19-rpfr-updates-candidate
    #f19-rpfr-updates-testing
)

declare -a f20repos=(
    f20-build
    f20-updates-build
    f20-updates-candidate-build
    f20-updates-testing-build
    f20-rpfr-build
    #f20-rpfr-updates-build
    #f20-rpfr-updates-candidate
    #f20-rpfr-updates-testing
)

for repo in ${f19repos[@]} ${f20repos[@]}; do
    # List of packages and their dependencies
    repoclosure=$(repoclosure --arch=armv6hl --arch=noarch --repofrompath=v6,http://japan.proximity.on.ca/repos/$repo/latest/armv6hl/ -r v6)

    IFS=$'\r\n' # Change array delimiter to newline

    # List of all dependencies
    declare -a dependencies=($(
        echo "$repoclosure" | tail -n+7 |
        grep -v 'package: \| unresolved deps:' | sort | uniq -c | sort -rn |
        sed -E 's/^ *[0-9]+ //g'
    ))

    # Find packages with the unresolved dependency
    for dep in ${dependencies[@]}; do
        body=$body'Unresolved Dependency:'$dep'\n    Packages:\n'$(
            echo "$repoclosure" |
            awk -v dep="$dep" '/^package:/{pkg=$2} $0==dep{print "        "pkg}'
        )'\n\n'
    done

    echo -e "$body" > /tmp/$repo.txt
    body=
done

for release in f19repos[@] f20repos[@]; do
(
    echo See attached documents | mutt -a \
    $(
        for repo in ${!release}; do
            echo /tmp/$repo.txt
        done
     ) -s "${release::3} Repoclosure Report" \
     -- ostep-team@senecac.on.ca
) 
done
