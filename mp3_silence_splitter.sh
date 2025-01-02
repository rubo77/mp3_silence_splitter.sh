#!/bin/bash
# MP3 Splitter Script (Using pipx and pydub)
# Author: Ruben Barkow-Kuder
# Script to split an MP3 file into chunks, maintaining silence at the end of each chunk

# Function to show help/usage information
show_help() {
  echo "Usage: $0 [options] <MP3 file>"
  echo "Options:"
  echo "  -h            Show this help"
  echo "  -n <number>   Number of chunks (default: 10)"
  echo "  -o <output>   Output directory (default: directory with subfolder)"
  echo "  -v            Verbose mode (show detailed output)"
  echo "  -s <milliseconds> Minimum silence length (default: 800)"
  echo "  -t <dBFS>       Silence threshold (default: -60)"
}

# Default values
num_chunks=10
output_dir=""
verbose=false
min_silence_len=800
silence_thresh=-60

# Parse options (including new options)
while getopts "hn:o:vs:t:" opt; do
  case "$opt" in
    h) show_help; exit 0 ;;
    n) num_chunks="$OPTARG" ;;
    o) output_dir="$OPTARG" ;;
    v) verbose=true ;;
    s) min_silence_len="$OPTARG" ;; # Option for silence length
    t) silence_thresh="$OPTARG" ;;   # Option for silence threshold
    ?) show_help; exit 1 ;;
  esac
done

shift $((OPTIND - 1))

# Check input file
if [ $# -eq 0 ]; then
  echo "Error: Please provide an MP3 file." >&2
  show_help
  exit 1
fi

input_file="$1"

# Set default output directory
if [ -z "$output_dir" ]; then
  output_dir=$(dirname "$input_file")/$(basename "$input_file" .mp3)
fi

# Check if output directory exists, create a new one with timestamp if it does
if [ -d "$output_dir" ]; then
  timestamp=$(date +%Y-%m-%d_%H-%M-%S)
  output_dir="$output_dir ($timestamp)"
  if $verbose; then echo "Output directory exists, creating: $output_dir"; fi
fi

mkdir -p "$output_dir" || { echo "Error: Could not create output directory." >&2; exit 1; }

# Check dependencies (ffmpeg, python3, pip, pipx)
if ! command -v ffmpeg &> /dev/null; then
  echo "Error: ffmpeg is not installed." >&2
  exit 1
fi

if ! command -v python3 &> /dev/null || ! command -v pip &> /dev/null; then
  echo "Error: Python 3 and pip are required." >&2
  exit 1
fi

if ! command -v pipx &> /dev/null; then
  echo "Error: pipx is not installed." >&2
  exit 1
fi

# Create wrapper script
wrapper_script=$(mktemp)
cat <<EOF > "$wrapper_script"
from pydub import AudioSegment, silence
import os
import sys

# Get variables from environment
input_file = os.environ.get("INPUT_FILE")
output_dir = os.environ.get("OUTPUT_DIR")
num_chunks = int(os.environ.get("NUM_CHUNKS"))
verbose = os.environ.get("VERBOSE") == "true"
min_silence_len = int(os.environ.get("MIN_SILENCE_LEN", 1000)) # Provide defaults
silence_thresh = int(os.environ.get("SILENCE_THRESH", -70))   # Provide defaults

if verbose:
    print(f"Loading audio file: {input_file}")

try:
    audio = AudioSegment.from_file(input_file)
except Exception as e:
    print(f"Error loading audio file: {e}")
    sys.exit(1)

# Find silence segments
silence_segments = silence.detect_silence(audio, min_silence_len=min_silence_len, silence_thresh=silence_thresh)

# Create split points
split_points = [0]
for start, end in silence_segments:
    split_points.append(start)
split_points.append(len(audio))

# Group chunks based on maximum chunk duration
max_chunk_duration = len(audio) // num_chunks
grouped_chunks = []
current_chunk = AudioSegment.empty()

for i in range(1, len(split_points)):
    chunk = audio[split_points[i-1]:split_points[i]]
    if len(current_chunk) + len(chunk) <= max_chunk_duration:
        current_chunk += chunk
    else:
        grouped_chunks.append(current_chunk)
        current_chunk = chunk

grouped_chunks.append(current_chunk)

# Save the chunks
os.makedirs(output_dir, exist_ok=True)
try:
    for i, chunk in enumerate(grouped_chunks):
        filename = f"{str(i + 1).zfill(2)}_{os.path.basename(input_file)}"
        output_path = os.path.join(output_dir, filename)
        chunk.export(output_path, format="mp3", bitrate="320k")
        if not verbose:
            sys.stdout.write(".")
            sys.stdout.flush()
        elif verbose:
            print(f"Exported chunk {i + 1}: {output_path}")
    if not verbose:
        print("")
except Exception as e:
    print(f"Error exporting chunk: {e}")
    sys.exit(1)

print(f"Audio file split into {len(grouped_chunks)} parts in directory '{output_dir}'.")
EOF

chmod +x "$wrapper_script"

# Set environment variables
export VERBOSE="$verbose"
export INPUT_FILE="$input_file"
export OUTPUT_DIR="$output_dir"
export NUM_CHUNKS="$num_chunks"
export MIN_SILENCE_LEN="$min_silence_len"
export SILENCE_THRESH="$silence_thresh"

# Run wrapper script with pipx
if $verbose; then echo "Running Python script..."; fi

pipx run --spec pydub python3 "$wrapper_script"

# Clean up wrapper script
rm "$wrapper_script"

# Final message
if $verbose; then echo "Script completed successfully."; fi

exit 0