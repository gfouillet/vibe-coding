#!/bin/bash

#
# Copyright 2025 Canonical Ltd.
# Licensed under the AGPLv3, see LICENCE file for details.
#

# zipeditor.sh - A utility for editing files inside zip archives
#
# INSTALLATION:
# 1. Source this file in your shell configuration:
#    echo "source /path/to/zipeditor.sh" >> ~/.bashrc
#    
# 2. Restart your shell or run:
#    source ~/.bashrc
#
# USAGE:
#    zipedit <archive> <filepath>
#
# FEATURES:
# - Tab completion for .zip and .charm files as first argument
# - Tab completion for files inside the archive as second argument
# - Automatically updates the archive after editing
# - Supports both .zip and .charm files (.charm files are zip files with a different extension)
#
# Function to edit a file inside a zip or charm archive
# Usage: zipedit <archive> <filepath>
zipedit() {
    # Check if we have the required arguments
    if [ $# -lt 2 ]; then
        echo "Usage: zipedit <archive> <filepath>"
        return 1
    fi

    local zipfile="$1"
    local filepath="$2"

    # Check if the archive file exists
    if [ ! -f "$zipfile" ]; then
        echo "Error: Archive file '$zipfile' not found"
        return 1
    fi

    # Check if the file exists in the archive
    if ! unzip -l "$zipfile" | grep -q "$filepath"; then
        echo "Error: File '$filepath' not found in '$zipfile'"
        return 1
    fi

    # Create a temporary directory
    local tempdir=$(mktemp -d)

    # Extract the file to the temporary directory
    unzip -q "$zipfile" "$filepath" -d "$tempdir"

    # Check if extraction was successful
    if [ ! -f "$tempdir/$filepath" ]; then
        echo "Error: Failed to extract '$filepath' from archive '$zipfile'"
        rm -rf "$tempdir"
        return 1
    fi

    # Get the original timestamp for comparison later
    local original_timestamp=$(stat -c %Y "$tempdir/$filepath")

    # Open the file in vim
    vim "$tempdir/$filepath"

    # Check if the file was modified
    local new_timestamp=$(stat -c %Y "$tempdir/$filepath")
    if [ "$original_timestamp" != "$new_timestamp" ]; then
        # Update the zip file with the modified file
        # Convert zipfile to absolute path if it's not already
        local abs_zipfile="$zipfile"
        if [[ "$zipfile" != /* ]]; then
            abs_zipfile="$(pwd)/$zipfile"
        fi
        (cd "$tempdir" && zip -q "$abs_zipfile" "$filepath")
        echo "File '$filepath' updated in archive '$zipfile'"
    else
        echo "No changes made to '$filepath'"
    fi

    # Clean up
    rm -rf "$tempdir"
}

# Completion function for the first argument (zip and charm files)
_zipedit_complete_archives() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    local prev=${COMP_WORDS[COMP_CWORD-1]}

    if [ $COMP_CWORD -eq 1 ]; then
        # Complete with zip and charm files in the current directory
        local zip_files=($(compgen -f -X '!*.zip' -- "$cur"))
        local charm_files=($(compgen -f -X '!*.charm' -- "$cur"))
        COMPREPLY=( "${zip_files[@]}" "${charm_files[@]}" )
    elif [ $COMP_CWORD -eq 2 ]; then
        # Complete with files inside the archive
        local zipfile=${COMP_WORDS[1]}
        if [ -f "$zipfile" ]; then
            # Get the list of files in the archive, handling spaces and special characters
            local IFS=$'\n'
            local files=($(unzip -l "$zipfile" | tail -n +4 | head -n -2 | awk '{$1=$2=$3=""; print substr($0,4)}' | sed 's/^[ \t]*//' | sort))

            # Get the current path prefix and the part to complete
            local prefix=""
            local to_complete="$cur"

            # If we have a path with directories, extract the prefix
            if [[ "$cur" == */* ]]; then
                prefix="${cur%/*}/"
                to_complete="${cur##*/}"
            fi

            # Generate completions for the current directory level only
            local i
            local matches=()

            for i in "${files[@]}"; do
                # If we have a prefix, only consider files in that directory
                if [[ -n "$prefix" ]]; then
                    # Check if the file is in the current directory
                    if [[ "$i" == "$prefix"* && "$i" != "$prefix" ]]; then
                        # Extract the next path component
                        local next_component="${i#$prefix}"
                        next_component="${next_component%%/*}"

                        # If this component matches our completion and isn't already in matches
                        if [[ "$next_component" == "$to_complete"* ]]; then
                            # Check if this is a directory by looking for more path components
                            if [[ "$i" == *"$next_component/"* ]]; then
                                # It's a directory, add trailing slash if not already there
                                if [[ "$next_component" != */ ]] && ! [[ " ${matches[*]} " =~ " $next_component/ " ]]; then
                                    matches+=("$next_component/")
                                fi
                            else
                                # It's a file
                                if ! [[ " ${matches[*]} " =~ " $next_component " ]]; then
                                    matches+=("$next_component")
                                fi
                            fi
                        fi
                    fi
                else
                    # We're at the root level, show only top-level entries
                    if [[ "$i" != */* ]]; then
                        # Direct file in root
                        if [[ "$i" == "$to_complete"* ]]; then
                            matches+=("$i")
                        fi
                    else
                        # Directory in root
                        local dir="${i%%/*}"
                        if [[ "$dir" == "$to_complete"* ]] && ! [[ " ${matches[*]} " =~ " $dir/ " ]]; then
                            matches+=("$dir/")
                        fi
                    fi
                fi
            done

            # Generate completions
            for i in "${matches[@]}"; do
                # If the filename contains spaces, add quotes
                if [[ "$i" == *[[:space:]]* ]]; then
                    COMPREPLY+=("\"$prefix$i\"")
                else
                    COMPREPLY+=("$prefix$i")
                fi
            done

            # If no matches found, use compgen
            if [ ${#COMPREPLY[@]} -eq 0 ]; then
                COMPREPLY=($(compgen -W "$(printf '%q ' "${matches[@]}")" -- "$cur"))
            fi
        fi
    fi
}

# Register the completion function
# Use -o nospace to prevent adding a space after directory names (with trailing slashes)
# This allows continuous tab completion for navigating through directories
complete -o nospace -F _zipedit_complete_archives zipedit
