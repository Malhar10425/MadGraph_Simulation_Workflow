
#!/bin/bash

# Get the index from command line argument
INDEX=$1

# Define paths
DELPHES_DIR="/storage/env/Delphes-3.5.0"
CARD="cards/1modified_delphes_card_CMS_PileUp.tcl"
INPUT_FILE="/storage/backup_data/pp_thwz_LO_5F_Tune_CP5_pythia8_13_p6_TeV/Unzipped_hepmc_files/${INDEX}_pythia8_events.hepmc"
OUTPUT_DIR="/storage/backup_data/pp_thwz_LO_5F_Tune_CP5_pythia8_13_p6_TeV/delphes_output"
OUTPUT_FILE="${OUTPUT_DIR}/${INDEX}_run_01_decayed_1.root"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "ERROR: Input file $INPUT_FILE not found!"
    exit 1
fi

# Check if output already exists (to avoid re-running)
if [ -f "$OUTPUT_FILE" ]; then
    echo "Output file $OUTPUT_FILE already exists, skipping..."
    exit 0
fi

# Create a job-specific temp directory
TEMP_DIR="/tmp/delphes_${INDEX}_$$"
mkdir -p "$TEMP_DIR"

# Run Delphes
cd "$DELPHES_DIR" || exit 1
echo "=========================================="
echo "Processing index $INDEX at $(date)"
echo "Host: $(hostname)"
echo "Input: $INPUT_FILE"
echo "Output: $OUTPUT_FILE"
echo "=========================================="

# Run Delphes and capture time
time (
    ./DelphesHepMC "$CARD" "$OUTPUT_FILE" "$INPUT_FILE"
)

# Check if successful
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    echo "SUCCESS: Processed index $INDEX"
    # Get file size
    if [ -f "$OUTPUT_FILE" ]; then
        FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
        echo "Output file size: $FILE_SIZE"
    fi
else
    echo "ERROR: Failed to process index $INDEX (exit code: $EXIT_CODE)"
    # Clean up partial output
    rm -f "$OUTPUT_FILE"
    exit $EXIT_CODE
fi

# Clean up temp directory
rm -rf "$TEMP_DIR"

echo "Finished at $(date)"


