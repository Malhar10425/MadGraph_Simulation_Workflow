#!/bin/bash

# Base path
BASE_PATH="/storage/backup_data/pp_thwz_LO_5F_Tune_CP5_pythia8_13_p6_TeV"
OUTPUT_DIR="${BASE_PATH}/Unzipped_hepmc_files"

# Start from file 19 (where it stopped)
START_FROM=18

echo "=================================================="
echo "Resuming unzip from file ${START_FROM} to 49"
echo "Output directory: ${OUTPUT_DIR}"
echo "=================================================="

for i in $(seq ${START_FROM} 49); do
    FOLDER_NAME="pp_thwz_LO_5F_Tune_CP5_pythia8_13_p6_TeV${i}"
    GZ_FILE="${BASE_PATH}/${FOLDER_NAME}/Events/run_01_decayed_1/tag_1_pythia8_events.hepmc.gz"
    OUTPUT_FILE="${OUTPUT_DIR}/${i}_pythia8_events.hepmc"
    
    # Check if already exists
    if [ -f "$OUTPUT_FILE" ]; then
        echo "[$((i+1))/50] ${FOLDER_NAME} - already exists, skipping"
        continue
    fi
    
    echo "[$((i+1))/50] Unzipping from ${FOLDER_NAME}..."
    
    if gunzip -c "$GZ_FILE" > "$OUTPUT_FILE"; then
        FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
        echo "  ✓ Saved to: ${i}_pythia8_events.hepmc (${FILE_SIZE})"
    else
        echo "  ✗ Error unzipping ${FOLDER_NAME}"
    fi
done

echo "=================================================="
echo "Resume complete!"
echo "Files saved in: ${OUTPUT_DIR}"
echo "=================================================="

