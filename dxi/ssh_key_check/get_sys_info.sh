#!/bin/bash

# Get the current ssh keys

ssh root@ns-lv-support-01 'tail /home/*/.ssh/authorized_keys' > tmp/SERVER_NAME/keys.log
echo -e "\n==> /root/.ssh/authorized_keys <==" >> tmp/SERVER_NAME/keys.log
ssh root@ns-lv-support-01 'tail /root/.ssh/authorized_keys' >> tmp/SERVER_NAME/keys.log

# Get the current versions of php/mysql/etc

# ssh root@ns-lv-support-01 '
