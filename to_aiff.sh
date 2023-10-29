#!/bin/bash
usage() {
	echo "Usage: $0 -i <input_dir> -o <output_dir>"
	echo "Converts FLAC/WAV files to AIFF from the input directory to the output directory. No audio quality should be lost."
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
for file in "$input_dir"/*.{flac,wav}; do
	extension=$(basename "$file" | rev | cut -d. -f1 | rev)
	filename=$(basename -- "$file" ."$extension")

	if [[ $extension == "flac" ]]; then
		bit_depth=$(ffprobe -v error -select_streams a:0 -show_entries stream=bits_per_raw_sample -of default=noprint_wrappers=1:nokey=1 "$file")
	else # Do not use 'stream=bits_per_raw_sample' because it returns noting for floating-point PCMs (ex: pcm_f32le). Grep it from the codec name
		bit_depth=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$file" | sed 's/[^0-9]//g')
	fi

	if [[ $bit_depth -eq 16 ]]; then
		output_format="pcm_s16be"
	elif [[ $bit_depth -eq 24 ]]; then
		output_format="pcm_s24be"
	elif [[ $bit_depth -eq 32 ]]; then
		output_format="pcm_s32be"
	fi

	echo $file $extension $filename $output_format $bit_depth

	ffmpeg -i "$file" -map_metadata 0 -fflags +bitexact -c:a "$output_format" "$output_dir"/"$filename".aiff
done