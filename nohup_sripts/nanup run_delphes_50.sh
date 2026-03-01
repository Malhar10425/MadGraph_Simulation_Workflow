
#!/bin/bash

# Configuration
DELPHES_DIR="/path_to/MG5_aMC_v3_5_12/Delphes"
CARD="cards/delphes_card_CMS_PileUp.tcl"
INPUT_BASE="/path_to/Unzipped_hepmc_files"
OUTPUT_BASE="/path_to/delphes_output"
LOG_DIR="/path_to/nohup_logs"

# Create directories
mkdir -p "$OUTPUT_BASE" "$LOG_DIR"

echo "=========================================="
echo "Starting Delphes processing for 50 files at $(date)"
echo "=========================================="

# Process each file in background
for i in {0..49}; do
    INPUT_FILE="${INPUT_BASE}/${i}_pythia8_events.hepmc"
    OUTPUT_FILE="${OUTPUT_BASE}/${i}_run_01_decayed_1.root"
    LOG_FILE="${LOG_DIR}/job_${i}.log"
    
    # Skip if output already exists
    if [ -f "$OUTPUT_FILE" ]; then
        echo "[$i] Output already exists, skipping" | tee -a "$LOG_DIR/summary.log"
        continue
    fi
    
    # Check if input exists
    if [ ! -f "$INPUT_FILE" ]; then
        echo "[$i] ERROR: Input file not found!" | tee -a "$LOG_DIR/summary.log"
        continue
    fi
    
    echo "[$i] Starting job at $(date)" | tee -a "$LOG_DIR/summary.log"
    
    # Run Delphes in background
    (
     	cd "$DELPHES_DIR" || exit 1
        echo "Processing file $i" > "$LOG_FILE"
        echo "Start time: $(date)" >> "$LOG_FILE"
        echo "Input: $INPUT_FILE" >> "$LOG_FILE"
        echo "Output: $OUTPUT_FILE" >> "$LOG_FILE"
        echo "----------------------------------------" >> "$LOG_FILE"

        # Run Delphes
        ./DelphesHepMC "$CARD" "$OUTPUT_FILE" "$INPUT_FILE" >> "$LOG_FILE" 2>&1

       	if [ $? -eq 0 ]; then
            echo "----------------------------------------" >> "$LOG_FILE"
            echo "SUCCESS: Job $i completed at $(date)" >> "$LOG_FILE"
            FILE_SIZE=$(du -h "$OUTPUT_FILE" 2>/dev/null | cut -f1)
            echo "File size: $FILE_SIZE" >> "$LOG_FILE"
            echo "[$i] SUCCESS - File $i completed" >> "$LOG_DIR/summary.log"
        else
            echo "----------------------------------------" >> "$LOG_FILE"
            echo "ERROR: Job $i failed at $(date)" >> "$LOG_FILE"
            echo "[$i] FAILED - Check log for details" >> "$LOG_DIR/summary.log"
            rm -f "$OUTPUT_FILE"
        fi
    ) &
    
    # Limit parallel jobs to prevent overload (adjust based on your CPU cores)
    # Let's run 4 jobs in parallel - adjust this number based on your system
    if (( (i+1) % 4 == 0 )); then
        echo "Waiting for batch of 4 jobs to complete..."
        wait
    fi
    
    sleep 2
done

# Wait for all remaining background jobs
wait

echo "=========================================="
echo "All jobs completed at $(date)"
echo "=========================================="

# Final summary
echo ""
echo "FINAL SUMMARY:"
echo "--------------"
completed=$(ls -1 "$OUTPUT_BASE"/*.root 2>/dev/null | wc -l)
echo "Total files processed: $completed/50"
echo ""
echo "Output directory: $OUTPUT_BASE"
echo "Log directory: $LOG_DIR"
echo "Summary log: $LOG_DIR/summary.log"

# Show failed jobs if any
echo ""
echo "Failed jobs (if any):"
grep "FAILED" "$LOG_DIR/summary.log" || echo "None"


