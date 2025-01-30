# Audio Splitter Script

This Bash script splits an Audio or M4A audio file into smaller Audio chunks, preserving silence between segments. It uses `ffmpeg` for audio processing and `pydub` (a Python library) for audio manipulation.

## Features

* Splits Audio files into a specified number of chunks (Supported formats: MP3, M4A/AAC, WAV, FLAC, OGG, and many more, depending on your FFmpeg installation)
* Preserves silence between audio segments, maintaining the original timing.
* Creates a new output directory with a timestamp if the default output directory already exists.

## Dependencies

* `ffmpeg`: For audio decoding and encoding. Install it using your system's package manager (e.g., `sudo apt install ffmpeg` on Debian/Ubuntu, `brew install ffmpeg` on macOS).
* `python3` and `pip3`: Python 3 and its package installer. Most modern systems have these pre-installed. If not, install them using your system's package manager.

## Installation and Usage

1.  **Save the script:** Save the script to a file named `mp3_silence_splitter.sh` (or any other name you prefer). E.g. in the folder `/usr/local/sbin`:
    
      curl -o /usr/local/sbin/mp3_silence_splitter.sh https://raw.githubusercontent.com/rubensmp/mp3-silence-splitter/main/mp3_silence_splitter.sh

2.  **Make it executable:**
    
      chmod +x /usr/local/sbin/mp3_silence_splitter.sh

3.  **Run the script:**
    
      ./mp3_silence_splitter.sh [options] <Audio file>

    * `<Audio file>`: The path to the Audio file you want to split.

4.  **Output:**
        
      The script will create a new directory (default: `<input_dir>/<input_filename>`) containing the split audio files. Each file will be named `<input_filename>_partN.mp3`, where `N` is the part number. Default: 10 parts, the same audio format as the input, maximum bitrate for the format e.g. 320 kbps for mp3.

## Options

* `-h`: Show help/usage information.
* `-v`: Verbose mode (show detailed output).
* `-n <number>`: Number of chunks to split the audio into (default: 10).
* `-o <output>`: Output directory (default: `<input_dir>/<input_filename>`).
* `-s <milliseconds>`: Minimum silence length (default: 800).
* `-t <dBFS>`: Silence threshold (default: -60).
* `-f <format>`: Output format (default: <input_format>).
* `-b <bitrate>`: Output bitrate (default: "320k" for "mp3").

## Examples

* Split `audio.mp3` into 5 chunks and save them to a directory named `audio`:
    
      ./mp3_silence_splitter.sh -n 5 audio.mp3

* Split `audio.mp3` into the default number of chunks (10) and save them to a directory named `my_output` with a bitrate of 128k:
    
      ./mp3_silence_splitter.sh -o my_output -b 128k audio.mp3

* Split `audio.mp3` into 8 chunks with verbose output:
    
      ./mp3_silence_splitter.sh -n 8 -v audio.mp3

## How it works

The script first checks for the required dependencies (`ffmpeg`, `python3`, `pip3`). Then, it creates a virtual environment to isolate the `pydub` installation. It installs `pydub` within this virtual environment using `pip`. The provided Audio file is then processed by the Python script, which uses `pydub` to detect silence segments and split the audio accordingly. The resulting chunks are saved to the specified output directory.

## Notes

* The script uses a minimum silence length of 1000 milliseconds and a silence threshold of -40 dBFS for silence detection. These values can be adjusted within the Python script if needed.

## Author

Ruben Barkow-Kuder

## License

free to use