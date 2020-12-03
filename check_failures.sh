#!/bin/sh

LOG_FILE=$1

# Check for any failure 
grep -q 'FAIL' ${LOG_FILE} && exit 1

# Check for any error
grep -q 'ERROR' ${LOG_FILE} && exit 1

# Check for any skipped tests without TODO remark (means reason is unknown for us)
grep 'SKIP' ${LOG_FILE} | grep -q -v 'TODO' && exit 1

