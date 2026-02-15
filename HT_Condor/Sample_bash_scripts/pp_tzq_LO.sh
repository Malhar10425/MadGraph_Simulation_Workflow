#!/bin/bash
#==============================================
# MG5 job running in /tmp then copying to EOS
#==============================================

# Assign unique job ID
JOB_ID=$1
SEED=$(( (RANDOM + 1000 * $JOB_ID + 10#$(date +%N)) % 100000000 ))

#--- Define paths
EOS_DIR=/eos/user/Path_to_eos_dir/MG5_aMC_v3_6_6/
MGPATH=$EOS_DIR
TMP_DIR=/tmp/$USER/mg5_job_$JOB_ID
OUTPUT_DIR="pp_tzq_LO_5F_Tune_CP5_pythia8_13_p6_TeV${JOB_ID}"
PROC_DIR="1Condor_pp_tzq_LO_5F_Tune_CP5_pythia8_13_p6_TeV"

#--- Prepare environment
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$MGPATH/HEPTools/lhapdf6_py3/lib64
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$MGPATH/HEPTools/lhapdf6_py3/lib
export PYTHONPATH=$PYTHONPATH:$MGPATH/HEPTools/lhapdf6_py3/lib/python3.10/site-packages

#--- Create and move to temporary work directory
mkdir -p $TMP_DIR
cd $TMP_DIR || exit 1

echo "Working directory: $TMP_DIR"
echo "Job ID: $JOB_ID | Seed: $SEED"


# Step 1: Generate and output
$MGPATH/bin/mg5_aMC <<EOF
import model loop_sm-no_b_mass
generate p p > t z j \$\$ w- w+
add process p p > t~ z j \$\$ w- w+
output $OUTPUT_DIR
EOF

# Step 3: Replace entire madspin card content
cat > $OUTPUT_DIR/Cards/madspin_card.dat << 'MADSPIN_EOF'
set max_weight_ps_point 400
set Nevents_for_max_weight 250
# specify the decay for the final state particles
decay t > w+ b, w+ > all all
decay t~ > w- b~, w- > all all
decay w+ > all all
decay w- > all all
decay z > all all
decay h > all all
# running the actual code
launch
MADSPIN_EOF

# Step 4: Launch with desired parameters
$MGPATH/bin/mg5_aMC <<EOF
launch $OUTPUT_DIR
#1
madspin=ON
shower=PYTHIA8

set ebeam 6800
set pdlabel = lhapdf
set lhaid = 303600
set nevents 100000
set nsplit_jobs = 1
set njmax 2
set mt = 172.5
set ymt = 172.5
set wt = Auto
set reweight_pdf = True
set store_rwgt_info = True
set jetradius = 1
set ptj = 20
set etaj = 2.5
set ptl = 20
set etal = 2.5
set etagamma = 2.5
set iseed $SEED
EOF

echo "Job completed locally: $OUTPUT_DIR"

#=================================
# Step 5: Copy results back to EOS
#=================================
FINAL_DEST=$EOS_DIR/$PROC_DIR/$OUTPUT_DIR
mkdir -p $FINAL_DEST

echo "Copying results to EOS..."
cp -r $TMP_DIR/$OUTPUT_DIR/* $FINAL_DEST/

# Optionally compress
# tar -czf $FINAL_DEST/${OUTPUT_DIR}.tar.gz -C $TMP_DIR $OUTPUT_DIR

# Clean up
echo "Cleaning up temporary files..."
rm -rf $TMP_DIR

echo "Completed process: $OUTPUT_DIR with seed $SEED"
