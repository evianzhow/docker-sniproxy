#!/bin/bash

# Generate a sniproxy configuration file from the environment settings.
# Global settings.  These should not need changing, but may be overridden.

# The user to run `sniproxy` as.  The default should be fine.
: ${SNIPROXY_USER:=nobody}

# PID file to use.
: ${SNIPROXY_PIDFILE:=/var/tmp/sniproxy.pid}

# We'll put the configuration file here for sniproxy:
SNIPROXY_CFG=/tmp/sniproxy.cfg

# Emit the initial options
cat > ${SNIPROXY_CFG} <<EOF
user ${SNIPROXY_USER}
pidfile ${SNIPROXY_PIDFILE}

error_log {
    syslog daemon
    priority notice
}

access_log {
    syslog daemon
}
EOF

# Resolver configuration.  We configure these as a series of numbered
# parameters:
# - SNIPROXY_NS_SRVn: specifies resolver IP address 'n'
# - SNIPROXY_NS_SEARCHn: specifies domain search item 'n'
# - SNIPROXY_NS_MODE: Decides the resolver mode; ipv{4,6}_{only,first}
if [ -n "${SNIPROXY_NS_SRV0}" ] || [ -n "${SNIPROXY_NS_SEARCH0}" ] \
		|| [ -n "${SNIPROXY_NS_MODE}" ]
then
	# We've got resolvers configured, so emit configuration for those.
	echo "resolver {"

	idx=0
	eval srv="\${SNIPROXY_NS_SRV${idx}}"
	while [ -n "${srv}" ]
	do
		echo "    nameserver ${srv}"
		idx=$(( ${idx} + 1 ))
		eval srv="\${SNIPROXY_NS_SRV${idx}}"
	done

	idx=0
	eval domain="\${SNIPROXY_NS_SEARCH${idx}}"
	while [ -n "${srv}" ]
	do
		echo "    search ${srv}"
		idx=$(( ${idx} + 1 ))
		eval domain="\${SNIPROXY_NS_SEARCH${idx}}"
	done

	if [ -n "${SNIPROXY_NS_MODE}" ]
	then
		echo "    mode ${SNIPROXY_NS_MODE}"
	fi

	echo "}"
fi >> ${SNIPROXY_CFG}

# Listen configurations.  These are a series of numbered parameters that specify
# the sockets being listened to.  They may optionally be mapped to a named
# table which is defined later.
#
# Syntax is:
#	SNIPROXY_LISTENn_PROTO={http|tls}
#	SNIPROXY_LISTENn_PORT=port number
#	SNIPROXY_LISTENn_ADDR=optional IP address (default: any,
#                                         IPv6 must be in brackets)
#	SNIPROXY_LISTENn_FALLBACK=optional fallback address/port if request
#				  cannot be parsed.
#	SNIPROXY_LISTENn_SOURCE=optional source IP address
#	SNIPROXY_LISTENn_TABLE=optional table
idx=0
eval proto="\${SNIPROXY_LISTEN${idx}_PROTO}"
eval port="\${SNIPROXY_LISTEN${idx}_PORT}"
while [ -n "${proto}" ] && [ -n "${port}" ]
do
	eval addr="\${SNIPROXY_LISTEN${idx}_ADDR}"
	eval fallback="\${SNIPROXY_LISTEN${idx}_FALLBACK}"
	eval src="\${SNIPROXY_LISTEN${idx}_SOURCE}"
	eval table="\${SNIPROXY_LISTEN${idx}_TABLE}"

	if [ -n "${addr}" ]
	then
		echo "listen ${addr}:${port} {"
	else
		echo "listen ${port} {"
	fi
	echo "    protocol ${proto}"

	if [ -n "${fallback}" ]
	then
		echo "    fallback ${fallback}"
	fi

	if [ -n "${src}" ]
	then
		echo "    source ${src}"
	fi

	if [ -n "${table}" ]
	then
		echo "    table ${table}"
	fi

	echo "}"

	idx=$(( ${idx} + 1 ))
	eval port="\${SNIPROXY_PORT${idx}}"
done >> ${SNIPROXY_CFG}

# Proxy tables.
# Each table is listed in a similar fashion to the ports with a variable
# named SNIPROXY_TABLEn:
# - SNIPROXY_TABLEn:	Name of table N
# Note that the "default" table is hardcoded as table 0.
#
# For each table; it accepts a series of variables which give the pattern and
# destination IP/port for the matching host of the form:
# - SNIPROXY_TABLEn_SRCm: Pattern for table N host M.
# - SNIPROXY_TABLEn_DESTm: IP and port of host for SNIPROXY_TABLEn_SRCm.
SNIPROXY_TABLE0=''
idx=0
table=""
while [ idx = 0 ] && [ -n "${table}" ]
do
	tidx=0
	echo "table ${table} {"
	eval src="\${SNIPROXY_TABLE${idx}_SRC${tidx}}"
	eval dest="\${SNIPROXY_TABLE${idx}_DEST${tidx}}"
	while [ -n "${src}" ] && [ -n "${dest}" ]
	do
		echo "    ${src} ${dest}"
		tidx=$(( ${tidx} + 1 ))
		eval src="\${SNIPROXY_TABLE${idx}_SRC${tidx}}"
		eval dest="\${SNIPROXY_TABLE${idx}_DEST${tidx}}"
	done

	echo "}"

	idx=$(( ${idx} + 1 ))
	eval table="\${SNIPROXY_TABLE${idx}}"
done >> ${SNIPROXY_CFG}

# Dump for debugging
echo "# Generated ${SNIPROXY_CFG}"
cat ${SNIPROXY_CFG}

# Start sniproxy
exec /usr/sbin/sniproxy -c ${SNIPROXY_CFG}
