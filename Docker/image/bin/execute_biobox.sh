#!/bin/bash  

set -o errexit
set -o nounset
set -o xtrace

READS=$(biobox_args.sh 'select(has("fastq")) | .fastq | map(.value) | join(" ")')

DATABASE=$(biobox_args.sh 'select(has("database")) | .database | .value ')

CACHE=$(biobox_args.sh 'select(has("cache")) | .cache | .value ')

CMD=$(fetch_task_from_taskfile.sh ${TASKFILE} $1)

if [[ $CACHE = "" ]]; 
then
	INPUT_TEMP=$(mktemp -d)
else 
	INPUT_TEMP=$CACHE
fi

INPUT_DIR="${INPUT_TEMP}/CommonKmers"

if [ ! -d "${INPUT_DIR}" ]; then
	mkdir ${INPUT_DIR} 
fi



DATABASE="${INPUT_DIR}/CommonKmersData"

if [ ! -d "${DATABASE}" ]; then
	GZIPPED_DATABASE="${DATABASE}.tar.gz"
	curl http://www.math.oregonstate.edu/~koslickd/CommonKmersData.tar.gz > $GZIPPED_DATABASE 
	tar xzvf "${GZIPPED_DATABASE}" -C "${INPUT_DIR}" 
fi

PROFILING_OUT=""
for READ_FILE in $(echo $READS)
do
	UNZIPPED_INPUT="${DATABASE}/$(basename $READ_FILE)"
	gunzip -c -d $READ_FILE > "${UNZIPPED_INPUT}"
	OUTPUT_FILE="${OUTPUT}/$(basename $READ_FILE)"
	PROFILING_OUT="$PROFLING_OUT
	      - path: ${OUTPUT_FILE}
                value: bioboxes.org:/profling:0.9"
	eval ${CMD}
done

cat << EOF > ${OUTPUT}/biobox.yaml
version: 1.0.0
arguments:
    profiling:$PROFILING_OUT
EOF
