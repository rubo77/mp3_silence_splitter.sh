# MP3 Splitter Script

This Bash script splits an MP3 audio file into smaller chunks, preserving silence between segments. It uses `ffmpeg` for audio processing and `pydub` (a Python library) for audio manipulation.

## Features

*   Splits MP3 files into a specified number of chunks.
*   Preserves silence between audio segments, maintaining the original timing.
*   Creates a new output directory with a timestamp if the default output directory already exists.

## Dependencies

*   `ffmpeg`: For audio decoding and encoding. Install it using your system's package manager (e.g., `sudo apt install ffmpeg` on Debian/Ubuntu, `brew install ffmpeg` on macOS).
*   `python3` and `pip3`: Python 3 and its package installer. Most modern systems have these pre-installed. If not, install them using your system's package manager.

## Installation and Usage

1.  **Save the script:** Save the script to a file named `mp3_silence_splitter.sh` (or any other name you prefer).

2.  **Make it executable:**
    ```bash
    chmod +x mp3_silence_splitter.sh
    ```

3.  **Run the script:**
    ```bash
    ./mp3_silence_splitter.sh [options] <MP3 file>
    ```

    *   `<MP3 file>`: The path to the MP3 file you want to split.

## Options

*   `-h`: Show help/usage information.
*   `-n <number>`: Number of chunks to split the audio into (default: 10).
*   `-o <output>`: Output directory (default: `<input_dir>/<input_filename>`).
*   `-v`: Verbose mode (show detailed output).
*   `-s <milliseconds>`: Minimum silence length
*   `-t <dBFS>`: Silence threshold 

## Examples

*   Split `audio.mp3` into 5 chunks and save them to a directory named `audio`:
    ```bash
    ./mp3_silence_splitter.sh -n 5 audio.mp3
    ```

*   Split `audio.mp3` into the default number of chunks (10) and save them to a directory named `my_output`:
    ```bash
    ./mp3_silence_splitter.sh -o my_output audio.mp3
    ```

*   Split `audio.mp3` into 8 chunks with verbose output:
    ```bash
    ./mp3_silence_splitter.sh -n 8 -v audio.mp3
    ```

## How it works

The script first checks for the required dependencies (`ffmpeg`, `python3`, `pip3`). Then, it creates a virtual environment to isolate the `pydub` installation. It installs `pydub` within this virtual environment using `pip`. The provided MP3 file is then processed by the Python script, which uses `pydub` to detect silence segments and split the audio accordingly. The resulting chunks are saved to the specified output directory.

## Notes

*   The script uses a minimum silence length of 1000 milliseconds and a silence threshold of -40 dBFS for silence detection. These values can be adjusted within the Python script if needed.

## Author

Ruben Barkow-Kuder

## License

free to use