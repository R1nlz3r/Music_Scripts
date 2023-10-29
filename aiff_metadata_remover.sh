#!/bin/bash
usage() {
	echo "Usage: $0 -i <input_dir> -o <output_dir>"
	echo "Removes the 'comment' and 'track' metadata tags on AIFF files from the input directory. Saves the modified files to the output directory."
	exit 1
}

while getopts "i:o:h" opt; do
	case $opt in
		i) input_dir="$OPTARG" ;;
		o) output_dir="$OPTARG" ;;
		h) usage ;;
		\?) echo "Invalid option: -$OPTARG"; usage ;;
	esac
done

[[ -z $input_dir || -z $output_dir || ! -d $input_dir ]] && usage
mkdir -p "$output_dir"

shopt -s nullglob
for file in "$input_dir"/*.aiff; do
	ffmpeg -i "$file" -c copy -map_metadata 0 -write_id3v2 1 -fflags +bitexact -metadata comment="" -metadata track="" "$output_dir"/"$file"
done
