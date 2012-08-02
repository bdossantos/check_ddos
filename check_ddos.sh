#!/bin/bash
# Check DDOS attack plugin for Nagios
#
# Options :
#   -w/--warning)
#       Warning value (number of SYN_RECV)
#
#   -c/--critical)
#       Critical value (number of SYN_RECV)

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

while test -n "$1"; do
    case "$1" in
        --warning|-w)
            OPT_WARN=$2
            shift
            ;;
        --critical|-c)
            OPT_CRIT=$2
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            exit $STATE_UNKNOWN
            ;;
    esac
    shift
done

OPT_WARN=${OPT_WARN:=50}
OPT_CRIT=${OPT_CRIT:=70}
FILENAME='/tmp/check_ddos'

trap "rm -f $FILENAME; exit" EXIT
netstat -an > $FILENAME
DDOS=$(grep SYN_RECV $FILENAME | wc -l)
PERFDATA=$(grep SYN_RECV $FILENAME | awk {'print $5'} | cut -f 1 -d ":" | sort | uniq -c | sort -k1,1rn | head -10)

EXITSTATUS=$STATE_UNKNOWN
if [ "$DDOS" -ge "$OPT_WARN" ]; then
    EXITSTATUS=$STATE_WARNING
    if [ "$DDOS" -ge "$OPT_CRIT" ]; then
        EXITSTATUS=$STATE_CRITICAL
    fi
    echo "DDOS attack !"
    echo "Top 10 SYN_RECV sources :"
    echo "$PERFDATA"
else
    echo "No DDOS detected ($DDOS / $OPT_WARN)"
    EXITSTATUS=$STATE_OK
fi

exit $EXITSTATUS