#!/bin/bash

source common/setenv.sh

# ---------------------------------------------------------------------------------------------------------------------
# Set general arguments
source common/getCommonArgs.sh
ARGS_ALL_CONFIG="keyval.input_dir=$FILEWORKDIR;keyval.output_dir=/dev/null;$ALL_EXTRA_CONFIG"

PROXY_INSPEC="x:TOF/CRAWDATA;dd:FLP/DISTSUBTIMEFRAME/0"
NTHREADS=1
PROXY_OUTSPEC="diagWords:TOF/DIAFREQ"
MYDIR="$(dirname $(readlink -f $0))/../../testing/detectors/TOF"

WORKFLOW="o2-dpl-raw-proxy ${ARGS_ALL} --dataspec \"$PROXY_INSPEC\" --channel-config \"name=readout-proxy,type=pull,method=connect,address=ipc://@$INRAWCHANNAME,transport=shmem,rateLogging=0\" | "
WORKFLOW+="o2-tof-reco-workflow --input-type raw --output-type clusters ${ARGS_ALL} --configKeyValues \"$ARGS_ALL_CONFIG\" --disable-root-output --calib-cluster --cluster-time-window 10000 --cosmics --pipeline \"tof-compressed-decoder:${NTHREADS},TOFClusterer:${NTHREADS}\" | "
WORKFLOW+="o2-qc ${ARGS_ALL} --config json://${MYDIR}/qc-full.json --local --host epn | "
WORKFLOW+="o2-dpl-output-proxy ${ARGS_ALL} --dataspec \"$PROXY_OUTSPEC\" --proxy-channel-name tof-diagn-input-proxy --channel-config \"name=tof-diagn-input-proxy,method=connect,type=push,transport=zeromq,rateLogging=0\" | "
WORKFLOW+="o2-dpl-run ${ARGS_ALL} ${GLOBALDPLOPT}"

if [ $WORKFLOWMODE == "print" ]; then
  echo Workflow command:
  echo $WORKFLOW | sed "s/| */|\n/g"
else
  # Execute the command we have assembled
  WORKFLOW+=" --$WORKFLOWMODE"
  eval $WORKFLOW
fi
