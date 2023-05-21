#!/bin/bash

# Set up dedicated volumes for the data your application is going to write. Use this example to partition the logical volumes on your application server, starting with a 100 GB disk.
# Create a mountpoint:

mkdir /data /logs /var/lib/docker /var/lib/replicated

# Create a physical volume:

pvcreate /dev/sdb

# Create a volume group:

vgcreate vg_jama /dev/sdb

# Create logical volumes:

lvcreate -L 30G -n lv_docker vg_jama
lvcreate -L 20G -n lv_replicated vg_jama
lvcreate -L 10G -n lv_logs vg_jama
lvcreate -l 100%FREE -n lv_data vg_jama

# Write file systems:

mkfs.xfs -L docker -n ftype=1 /dev/vg_jama/lv_docker
mkfs.ext4 -L replicated /dev/vg_jama/lv_replicated
mkfs.ext4 -L data /dev/vg_jama/lv_data
mkfs.ext4 -L logs /dev/vg_jama/lv_logs