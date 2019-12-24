#!/bin/bash
if [ $# -ne 2 ] ; then
  echo "You need to specify datatype timetype"
  echo 
  echo "Usage:"
  echo " $(basename $0) <????> <????>"
  exit
fi
# rsync user@address:SRC_directory DEST_path/
# Notice: local_path with / in the end
remote_dir=/work197/person/rensh/front_detect
#remote dir should put under the local_path
local_path=/mnt/d/lomf/frontal_detect/
data_type=$1 # ostia or roms
time_type=$2  # climatology, monthly, daily
region_type=SCS # model_domain, SCS
keywords=*
# echo ${remote_dir}/Result/${data_type}/${region_type}/${time_type}/${year}
# exit 0
rsync -vazP lingtj@202.108.199.31:${remote_dir}/Result/${data_type}/${region_type}/${time_type}/${keywords}  ${local_path}/Result/${data_type}/${region_type}/${time_type}
# rsync -vazP lingtj@202.108.199.31:${remote_dir}/Fig/${data_type}  ${local_path}/Fig/