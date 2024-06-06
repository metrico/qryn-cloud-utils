# Qryn OSS to Qryn cloud migrator

Simple bash script to migrate:
- logs data
- metrics data
- traces data

from qryn OSS to qryn-cloud.

The script copies the data to the new database.

## Prerequisites

- clickhouse-client
- bash

## Limitations

1. Both databases should be on the same server
2. Clusters not supported

## How to run
1. Make sure that you initialized the cloud database using `qryn-ctrl` on the server with the OSS database. 
2. Figure out the clickhouse-client flags to connect, for ex.: 
`clickhouse-client --user default --host localhost --port 9440 --secure --password secret_pass`
3. Clickhouse-client should open the clickhouse console. Store the command line expression with flags somewhere.
4. Open the script in a text editor: `nano migrator.sh`
5. Fill in the configurations part of the script:
```bash
## ~~~~~CONFIGURATIONS~~~~~
from_db=from; #OLD OSS db name 
to_db=to; #NEW Cloud db name
to_org_id=0; #NEW org id
to_ttl_days=8; # ttl_days you want to keep your data
               # NOTE add a couple of days so the first copied date is stored for a couple of extra days.
               # in another case the verification doesn't work due to some data is rotated immediately
dates='2024-06-03 2024-06-04 2024-06-05 2024-06-06'; #dates you want to copy separated by space
CLICKHOUSE_CLIENT='clickhouse-client --user default --host localhost --port 9440 --secure --password secret_pass'; # command to connect clickhouse-client cli
drop_data='1'; # should we drop the old data after copy? 1 - yes 0 - no
del_wait_timeout_s='5'; # how long we should wait for the user to change mind before deleting (sec)?
## ~~~END CONFIGURATIONS~~~
```
6. Run the script: `sh migrator.sh`
