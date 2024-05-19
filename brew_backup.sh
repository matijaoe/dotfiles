#!/bin/bash

# Function to strip VSCode extensions from Brewfile
strip_vscode() {
    local input_file=$1
    local output_file=$2

    # Check if the input file exists
    if [[ ! -f "$input_file" ]]; then
        echo "Input file $input_file does not exist."
        exit 1
    fi

    # Use grep to exclude lines containing 'vscode' and save to the output file
    grep -v '^vscode ' "$input_file" > "$output_file"
}

# Specify the Brewfile name
brewfile="Brewfile"
filtered_brewfile="${brewfile}_no_vscode"

# Dump the Brewfile
brew bundle dump --file="$brewfile" --force --all

# Strip VSCode extensions from the Brewfile
strip_vscode "$brewfile" "$filtered_brewfile"

# Optionally, overwrite the original Brewfile with the filtered one
mv "$filtered_brewfile" "$brewfile"

echo "Brewfile dumped and VSCode extensions stripped. Result saved to $brewfile."
