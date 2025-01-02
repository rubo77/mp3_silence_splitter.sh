#!/bin/bash
# MP3 Splitter Script (Mit pipx - NICHT EMPFOHLEN)
# Autor: Ruben Barkow-Kuder
# Skript zum Aufteilen einer MP3-Datei in Chunks unter Beibehaltung der Stille am Ende jedes Chunks

# Funktion zur Anzeige von Hilfe/Nutzungsinformationen
show_help() {
  echo "Verwendung: $0 [Optionen] <MP3-Datei>"
  echo "Optionen:"
  echo "  -h            Diese Hilfe anzeigen"
  echo "  -n <Anzahl>   Anzahl der Chunks (Standard: 10)"
  echo "  -o <Ausgabe>  Ausgabeverzeichnis (Standard: Unterordner im gleichen Verzeichnis)"
  echo "  -v            Ausführlicher Modus (detaillierte Ausgabe anzeigen)"
  echo "  -s <Millisekunden> Minimale Stillelänge (Standard: 1000)"
  echo "  -t <dBFS>       Stille-Schwellwert (Standard: -70)"
}

# Standardwerte
num_chunks=10
output_dir=""
verbose=false
min_silence_len=1000
silence_thresh=-70

# Optionen parsen (einschließlich neuer Optionen)
while getopts "hn:o:vs:t:" opt; do
  case "$opt" in
    h) show_help; exit 0 ;;
    n) num_chunks="$OPTARG" ;;
    o) output_dir="$OPTARG" ;;
    v) verbose=true ;;
    s) min_silence_len="$OPTARG" ;; # Option für Stillelänge
    t) silence_thresh="$OPTARG" ;;   # Option für Stille-Schwellwert
    ?) show_help; exit 1 ;;
  esac
done

shift $((OPTIND - 1))

# Eingabedatei überprüfen
if [ $# -eq 0 ]; then
  echo "Fehler: Bitte geben Sie eine MP3-Datei an." >&2
  show_help
  exit 1
fi

input_file="$1"

# Standard-Ausgabeverzeichnis setzen
if [ -z "$output_dir" ]; then
  output_dir=$(dirname "$input_file")/$(basename "$input_file" .mp3)
fi

# Überprüfen, ob das Ausgabeverzeichnis existiert, andernfalls erstellen
if [ -d "$output_dir" ]; then
  timestamp=$(date +%Y-%m-%d_%H-%M-%S)
  output_dir="$output_dir ($timestamp)"
  if $verbose; then echo "Ausgabeverzeichnis existiert, erstelle: $output_dir"; fi
fi

mkdir -p "$output_dir" || { echo "Fehler: Konnte Ausgabeverzeichnis nicht erstellen." >&2; exit 1; }

# Abhängigkeiten überprüfen (ffmpeg, python3, pipx)
if ! command -v ffmpeg &> /dev/null; then
  echo "Fehler: ffmpeg ist nicht installiert." >&2
  exit 1
fi

if ! command -v python3 &> /dev/null || ! command -v pip &> /dev/null; then
  echo "Fehler: Python 3 und pip sind erforderlich." >&2
  exit 1
fi

if ! command -v pipx &> /dev/null; then
  echo "Fehler: pipx ist nicht installiert." >&2
  exit 1
fi

# Wrapper-Skript erstellen
wrapper_script=$(mktemp)
cat <<EOF > "$wrapper_script"
from pydub import AudioSegment, silence
import os
import sys

# Variablen aus der Umgebung abrufen
input_file = os.environ.get("INPUT_FILE")
output_dir = os.environ.get("OUTPUT_DIR")
num_chunks = int(os.environ.get("NUM_CHUNKS"))
verbose = os.environ.get("VERBOSE") == "true"
min_silence_len = int(os.environ.get("MIN_SILENCE_LEN", 500))
silence_thresh = int(os.environ.get("SILENCE_THRESH", -40))

if verbose:
    print(f"Lade Audiodatei: {input_file}")

try:
    audio = AudioSegment.from_file(input_file)
except Exception as e:
    print(f"Fehler beim Laden der Audiodatei: {e}")
    sys.exit(1)

# Finde Stille-Segmente
silence_segments = silence.detect_silence(audio, min_silence_len=min_silence_len, silence_thresh=silence_thresh)

# Erstelle Zeitpunkte zum Splitten
split_points = [0]
for start, end in silence_segments:
    split_points.append(start)
split_points.append(len(audio))

# Gruppiere Chunks basierend auf der maximalen Chunk-Dauer
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

# Speichere die Chunks
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
            print(f"Exportierter Chunk {i + 1}: {output_path}")
    if not verbose:
        print("")
except Exception as e:
    print(f"Fehler beim Exportieren des Chunks: {e}")
    sys.exit(1)

print(f"Audiodatei in {len(grouped_chunks)} Teile im Verzeichnis '{output_dir}' aufgeteilt.")
EOF

chmod +x "$wrapper_script"

# Umgebungsvariablen setzen
export VERBOSE="$verbose"
export INPUT_FILE="$input_file"
export OUTPUT_DIR="$output_dir"
export NUM_CHUNKS="$num_chunks"
export MIN_SILENCE_LEN="$min_silence_len"
export SILENCE_THRESH="$silence_thresh"

# Wrapper-Skript mit pipx ausführen
if $verbose; then echo "Führe Python-Skript aus..."; fi

pipx run --spec pydub python3 "$wrapper_script"

# Wrapper-Skript aufräumen
rm "$wrapper_script"

# Abschließende Nachricht
if $verbose; then echo "Skript erfolgreich abgeschlossen."; fi

exit 0