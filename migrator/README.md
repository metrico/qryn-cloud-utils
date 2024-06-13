<a href="https://qryn.cloud" target="_blank"><img src='https://user-images.githubusercontent.com/1423657/218816262-e0e8d7ad-44d0-4a7d-9497-0d383ed78b83.png' width=150></a>

# qryn-cloud Migration Tool

This bash script facilitates the migration of the following data types from `qryn-js` to `qryn-cloud` formats:
- Logs data
- Metrics data
- Traces data

The script transfers data to the new database.

## Prerequisites

- `clickhouse-client`
- `bash`

## Limitations

1. Both databases must reside on the same ClickHouse server
2. Clusters are not supported. CH Cloud works fine.

## How to Run

1. Initialize the cloud database using `qryn-ctrl` on the server with the OSS database.
2. Determine the `clickhouse-client` flags required for connection. For example:
    ```bash
    clickhouse-client --user default --host localhost --port 9440 --secure --password secret_pass
    ```
3. Ensure that `clickhouse-client` opens the ClickHouse console and save the command line expression with flags.
4. Open the script in a text editor:
    ```bash
    nano migrator.sh
    ```
5. Fill in the configuration section of the script:
    ```bash
    ## ~~~~~CONFIGURATIONS~~~~~
    from_db=from; # CURRENT QRYN-OSS db name 
    to_db=to; # TARGET QRYN-Cloud db name
    to_org_id=0; # TARGET org id for imported data
    to_ttl_days=8; # TTL days you want to keep imported data
                   # NOTE: always extend the TTL considering the FIRST timestamp of imported data.
                   # failing to do so might cause data to be rotated instantly and validations to fail
    dates='2024-06-03 2024-06-04 2024-06-05 2024-06-06'; # dates you want to copy separated by space
    CLICKHOUSE_CLIENT='clickhouse-client --user default --host localhost --port 9440 --secure --password secret_pass'; # command to connect clickhouse-client cli
    drop_data='0'; # should we drop the old data after copy? 1 - yes 0 - no
    del_wait_timeout_s='5'; # how long we should wait for the user to change mind before deleting (sec)?
    ## ~~~END CONFIGURATIONS~~~
    ```
6. Run the script:
    ```bash
    sh migrator.sh
    ```
