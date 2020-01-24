#!/bin/bash

# strict mode
set -euo pipefail

# script specific vars
PROGNAME=$(basename "$0")
VERSION=1.0.0

# defaults
: ${DEBUG:=}
: ${METRIC_NAME:=}
: ${METRIC_VALUE:=}
: ${METRIC_TYPE:=count}
: ${METRIC_INTERVAL:=}
: ${METRIC_HOST:=}
: ${METRIC_TAGS:=}
: ${DATADOG_API_KEY:=}

# functions
msg() {
    echo "$@"
}

err() {
    >&2 echo "$@"
}

errcat() {
    >&2 cat
}

print_help() {
    cat <<EOF
$PROGNAME [options]

Version: $VERSION
Description: send some metrics to datadog

Options:
-m|--metric <metric-name>          set metric name
-v|--value <metric-value>          set metric value
-r|--rate                          metric type is 'rate', not 'count'
-c|--count                         metric type is 'count' (default)
-i|--interval <metric-interval>    set metric interval (in seconds)
-H|--host <metric-host>            set metric host
-t|--tag <metric-tag>              set metric tag
-k|--key|--api-key <key>           sey datadog api key
-h|--help                          print this help end exit

Examples:
$PROGNAME -m 'my.test.metric' -v '123' -c -i 60 -k efd...dummy-api-key-dont-use...d -H lnet01

TODO:
- allow to specify multiple tags
- gauge metric type

EOF
}

parse_opts() {
    local TEMP PARSE_OPTS_STATUS
    TEMP=$(getopt -o m:v:rci:H:t:k:h --long metric:,value:,rate,count,interval:,host:,tag:key:,api-key:,help -- "$@")
    PARSE_OPTS_STATUS="$?"
    if [ "$PARSE_OPTS_STATUS" != 0 ]; then
	err "Error in parsing options";
	exit 1
    fi

    # modify cmdline
    eval set -- "$TEMP"
    unset TEMP

    # parse cmdline options
    while true; do
	case "$1" in
	    -h|--help) print_help; exit 0;;
	    --debug|--dbg) DEBUG=y; shift;;
	    -m|--metric) METRIC_NAME="$2"; shift 2;;
	    -v|--value) METRIC_VALUE="$2"; shift 2;;
	    -r|--rate) METRIC_TYPE="rate"; shift;;
	    -c|--count) METRIC_TYPE="count"; shift;;
	    -i|--interval) METRIC_INTERVAL="$2"; shift 2;;
	    -H|--host) METRIC_HOST="$2"; shift 2;;
	    -t|--tag) METRIC_TAGS="$2"; shift 2;;
	    -k|--key|--api-key) DATADOG_API_KEY="$2"; shift 2;;
	    --) shift; break;;
	    *) err "Unknown option $1"; exit 1;;
	esac
    done
}

print_conf() {
    errcat <<EOF
---------- Configuration ----------
PROGNAME=$PROGNAME
VERSION=$VERSION
METRIC_NAME=$METRIC_NAME
METRIC_VALUE=$METRIC_VALUE
METRIC_TYPE=$METRIC_TYPE
METRIC_INTERVAL=$METRIC_INTERVAL
METRIC_HOST=$METRIC_HOST
METRIC_TAGS=$METRIC_TAGS
DATADOG_API_KEY=$DATADOG_API_KEY
-----------------------------------
EOF
}

check_conf() {
    local found_conf_errors=

    case "$METRIC_TYPE" in
	count|rate)
	    if [ -z "$METRIC_INTERVAL" ] || [ "$METRIC_INTERVAL" = 0 ]; then
		err "Bad metric interval: \"$METRIC_INTERVAL\""
		found_conf_errors=y
	    fi
	    ;;
	*) err "Unknown metric type: $METRIC_TYPE"; found_conf_errors=y;;
    esac

    if [ -z "$DATADOG_API_KEY" ]; then
	err "DataDog API key not set"
	found_conf_errors=y
    fi

    # return false if errors found
    if [ -n "$found_conf_errors" ]; then
	return 1;
    else
	return 0;
    fi
}

# PROGRAM

# init
parse_opts "$@"
if [ -n "$DEBUG" ]; then
    print_conf
fi
if ! check_conf; then
    exit 3
fi

# do the thing

CURRENT_TIME=$(date +%s)
MESSAGE_BODY=$( cat <<EOF
{ "series" :
         [{"metric":"$METRIC_NAME",
          "points":[[$CURRENT_TIME, $METRIC_VALUE]],
          "type":"$METRIC_TYPE",
          "interval": $METRIC_INTERVAL,
          "host":"$METRIC_HOST",
          "tags":["$METRIC_TAGS"]}
        ]
}
EOF
)

if [ -n "$DEBUG" ]; then
    echo "$MESSAGE_BODY"
fi

curl -X POST -H "Content-type: application/json" -d "$MESSAGE_BODY" "https://api.datadoghq.com/api/v1/series?api_key=$DATADOG_API_KEY"

exit 0
