#!/bin/bash

script_path=$0

command_exists() {
  hash "$1" &>/dev/null
}

display_help() {
  echo "Usage: $script_path <video_path> <start_seconds> [end_cut_seconds]"
  exit 1
}

# Check must-have commands
for cmd in ffprobe ffmpeg bc; do
  if ! command_exists "$cmd"; then
    echo "Command '$cmd' not found. Please install it."
    exit 1
  fi
done

if [[ -z "${1-}" || -z "${2-}" ]]; then
  display_help
fi

video_path=$1
start_seconds=$2
end_cut_seconds=${3:-0}

# Validate numeric inputs
if ! [[ "$start_seconds" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
  echo "start_seconds must be a valid number."
  exit 1
fi

if [[ -n "$3" && ! "$end_cut_seconds" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
  echo "end_cut_seconds must be a valid number."
  exit 1
fi

if [ ! -f "$video_path" ]; then
  echo "path: $video_path does not exist. Please try again with a valid path."
  exit 1
fi

video_length=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$video_path" 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "Failed to get video duration with ffprobe."
  exit 1
fi

# Validate start_seconds
if [[ $(bc <<<"$start_seconds < 0") -eq 1 ]]; then
  echo "start_seconds cannot be negative."
  exit 1
fi
if [[ $(bc <<<"$start_seconds > $video_length") -eq 1 ]]; then
  echo "start_seconds is larger than video length ($video_length seconds)."
  exit 1
fi

# Validate end_cut_seconds
if [[ -n "$3" ]]; then
  if [[ $(bc <<<"$end_cut_seconds < 0") -eq 1 ]]; then
    echo "end_cut_seconds cannot be negative."
    exit 1
  fi
  if [[ $(bc <<<"$end_cut_seconds >= $video_length") -eq 1 ]]; then
    echo "end_cut_seconds cannot be larger or equal to video length ($video_length seconds)."
    exit 1
  fi
fi

duration=$(bc -l <<<"${video_length:-0} - ${start_seconds:-0} - ${end_cut_seconds:-0}")
if [ $(bc -l <<<"$duration <= 0") -eq 1 ]; then
  echo "Invalid duration to cut. Results in duration non-positive."
  exit 1
fi

extension="${video_path##*.}"
output_path="./cut_$(basename "$video_path" ".$extension").$extension"

if [ -f "$output_path" ]; then
  echo "Output file $output_path already exists. Please move or rename it."
  exit 1
fi

output_dir=$(dirname "$output_path")
if [ ! -w "$output_dir" ]; then
  echo "Cannot write to output directory: $output_dir"
  exit 1
fi

if ! ffmpeg -ss "$start_seconds" -i "$video_path" -t "$duration" -c copy "$output_path" 2>/dev/null; then
  echo "ffmpeg failed to cut the video."
  exit 1
fi

echo "Cut video saved as $output_path"
