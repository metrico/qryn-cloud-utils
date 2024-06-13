## ~~~~~CONFIGURATIONS~~~~~
from_db=qryn_oss; # CURRENT QRYN-OSS db name 
to_db=qryn_cloud; # TARGET QRYN-Cloud db name
to_org_id=0; # TARGET org id for imported data
to_ttl_days=8; # TTL days you want to keep imported data
               # NOTE: always extend the TTL considering the FIRST timestamp of imported data.
               # failing to do so might cause data to be rotated instantly and validations to fail
dates='2024-06-03 2024-06-04 2024-06-05 2024-06-06'; # dates you want to copy separated by space
CLICKHOUSE_CLIENT='clickhouse-client --user default --host localhost --port 9440 --secure --password secret_pass'; # command to connect clickhouse-client cli
drop_data='0'; # should we drop the old data after copy? 1 - yes 0 - no
del_wait_timeout_s='5'; # how long we should wait for the user to change mind before deleting (sec)?
## ~~~END CONFIGURATIONS~~~

for date in ${dates}; do

    ## SAMPLES
    echo "copying samples_v3.$date ${from_db} -> ${to_db} ..."
    cat <<EOF | $CLICKHOUSE_CLIENT || exit 1
        INSERT INTO ${to_db}.samples_v4 (org_id, fingerprint, timestamp_ns, value, string, ttl_days)
        SELECT '${to_org_id}' as org_id, fingerprint, timestamp_ns, value, string, ${to_ttl_days} as ttl_days
        FROM ${from_db}.samples_v3
        WHERE (timestamp_ns >= (toUnixTimestamp(toDateTime('${date}')) * 1000000000)) AND (timestamp_ns < ((toUnixTimestamp(toDateTime('${date}')) + ((24 * 60) * 60)) * 1000000000))
EOF
    echo "copying $date samples_v3.${from_db} -> ${to_db} OK";

    echo "checking copied size...";
    cat <<EOF | $CLICKHOUSE_CLIENT >./out || exit 1
        SELECT b.c >= a.c FROM
            (SELECT count() c FROM ${from_db}.samples_v3
            WHERE (timestamp_ns >= (toUnixTimestamp(toDateTime('${date}')) * 1000000000)) AND (timestamp_ns < ((toUnixTimestamp(toDateTime('${date}')) + ((24 * 60) * 60)) * 1000000000))) as a
        ANY LEFT JOIN
            (SELECT count() c FROM ${to_db}.samples_v4
            WHERE (timestamp_ns >= (toUnixTimestamp(toDateTime('${date}')) * 1000000000)) AND (timestamp_ns < ((toUnixTimestamp(toDateTime('${date}')) + ((24 * 60) * 60)) * 1000000000))) as b
        ON 1=1;
EOF
    out=`cat out | cut -z -b -1`;
    if [ "$out" -eq "0" ]; then echo "copied data is less than the initital one"; exit 1;
    else echo "check ok"; fi

    echo "dropping samples_v3.${date} in ${del_wait_timeout_s} seconds...";
    sleep $del_wait_timeout_s;
    echo "drop samples_v3.$date...";
    if [ "$drop_data" = "1" ]; then $CLICKHOUSE_CLIENT --query "ALTER TABLE $from_db.samples_v3 DROP PARTITION '$date 00:00:00'" || exit 1;
    else echo "omit drop"; fi
    echo "drop samples_v3.$date ok";

    ## TIME SERIES
    echo "copying time_series.$date ${from_db} -> ${to_db} ..."
    cat <<EOF | $CLICKHOUSE_CLIENT >./out || exit 1
        INSERT INTO ${to_db}.time_series_v2 (org_id, date, fingerprint, labels, name, type, ttl_days)
        SELECT '${to_org_id}' as org_id, date, fingerprint, labels, name, type, ${to_ttl_days} as ttl_days
        FROM ${from_db}.time_series
        WHERE date='${date}'
EOF
    echo "copying time_series.$date ${from_db} -> ${to_db} OK"
    echo "checking copied size...";
    cat <<EOF | $CLICKHOUSE_CLIENT >./out || exit 1
        SELECT b.c >= a.c FROM
            (SELECT count(distinct fingerprint) c FROM ${from_db}.time_series
            WHERE date='${date}') as a
        ANY LEFT JOIN
            (SELECT count(distinct fingerprint) c FROM ${to_db}.time_series_v2
            WHERE date='${date}') as b
        ON 1=1;
EOF
    out=`cat out | cut -z -b -1`
    if [ "$out" -eq "0" ]; then echo "copied data is less than the initital one"; exit 1;
    else echo "check ok"; fi

    echo "dropping time_series.${date} in $del_wait_timeout_s seconds...";
    sleep $del_wait_timeout_s;
    echo "drop time_series.$date...";
    if [ "$drop_data" = "1" ]; then $CLICKHOUSE_CLIENT --query "ALTER TABLE $from_db.time_series DROP PARTITION '$date'" || exit 1;
    else echo "omit drop"; fi
    echo "drop time_series.$date ok";

    ## tempo_traces
    echo "copying tempo_traces.$date ${from_db} -> ${to_db} ..."
    cat <<EOF | $CLICKHOUSE_CLIENT || exit 1
        INSERT INTO ${to_db}.tempo_traces (oid, trace_id, span_id, parent_id, name, timestamp_ns, duration_ns, service_name, payload_type, payload)
        SELECT '${to_org_id}' as oid, trace_id, span_id, parent_id, name, timestamp_ns, duration_ns, service_name, payload_type, payload
        FROM ${from_db}.tempo_traces
        WHERE (timestamp_ns >= (toUnixTimestamp(toDateTime('${date}')) * 1000000000)) AND (timestamp_ns < ((toUnixTimestamp(toDateTime('${date}')) + ((24 * 60) * 60)) * 1000000000))
EOF
    echo "copying $date tempo_traces.${from_db} -> ${to_db} OK";

        echo "checking copied size...";
    cat <<EOF | $CLICKHOUSE_CLIENT >./out || exit 1
        SELECT b.c >= a.c FROM
            (SELECT count() c FROM ${from_db}.tempo_traces
            WHERE (timestamp_ns >= (toUnixTimestamp(toDateTime('${date}')) * 1000000000)) AND (timestamp_ns < ((toUnixTimestamp(toDateTime('${date}')) + ((24 * 60) * 60)) * 1000000000))) as a
        ANY LEFT JOIN
            (SELECT count() c FROM ${to_db}.tempo_traces
            WHERE (timestamp_ns >= (toUnixTimestamp(toDateTime('${date}')) * 1000000000)) AND (timestamp_ns < ((toUnixTimestamp(toDateTime('${date}')) + ((24 * 60) * 60)) * 1000000000))) as b
        ON 1=1;
EOF
    out=`cat out | cut -z -b -1`
    if [ "$out" -eq "0" ]; then echo "copied data is less than the initital one"; exit 1;
    else echo "check ok"; fi

    echo "dropping tempo_traces.${date} in $del_wait_timeout_s seconds...";
    sleep $del_wait_timeout_s;
    echo "drop tempo_traces.$date...";
    if [ "$drop_data" = "1" ]; then $CLICKHOUSE_CLIENT --query "ALTER TABLE $from_db.tempo_traces DROP PARTITION ('0', '$date')" || exit 1;
    else echo "omit drop"; fi
    echo "drop tempo_traces.$date ok";

    ## tempo_traces_attrs_gin
    echo "tempo_traces_attrs_gin.$date ${from_db} -> ${to_db} ..."
    cat <<EOF | $CLICKHOUSE_CLIENT >./out || exit 1
        INSERT INTO ${to_db}.tempo_traces_attrs_gin (oid, date, key, val, trace_id, span_id, timestamp_ns, duration)
        SELECT '${to_org_id}' as oid, date, key, val, trace_id, span_id, timestamp_ns, duration
        FROM ${from_db}.tempo_traces_attrs_gin
        WHERE date='${date}'
EOF
    echo "copying tempo_traces_attrs_gin.$date ${from_db} -> ${to_db} OK";
    echo "checking copied size...";
    cat <<EOF | $CLICKHOUSE_CLIENT >./out || exit 1
        SELECT b.c >= a.c * 0.9 FROM
            (SELECT uniq(trace_id, span_id) c FROM ${from_db}.tempo_traces_attrs_gin
            WHERE date='${date}') as a
        ANY LEFT JOIN
            (SELECT uniq(trace_id, span_id) c FROM ${to_db}.tempo_traces_attrs_gin
            WHERE date='${date}') as b
        ON 1=1;
EOF
    out=`cat out | cut -z -b -1`
    if [ "$out" -eq "0" ]; then echo "copied data is less than the initital one"; exit 1;
    else echo "check ok"; fi

    echo "dropping tempo_traces_attrs_gin.${date} in $del_wait_timeout_s seconds...";
    sleep $del_wait_timeout_s;
    echo "drop tempo_traces_attrs_gin.$date...";
    if [ "$drop_data" = "1" ]; then $CLICKHOUSE_CLIENT --query "ALTER TABLE $from_db.tempo_traces_attrs_gin DROP PARTITION '$date'" || exit 1;
    else echo "omit drop"; fi
    echo "drop tempo_traces_attrs_gin.$date ok";

done
