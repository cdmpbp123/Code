#!/bin/bash
if [ $# -ne 1 ] ; then
  echo "You need to specify datatype"
  echo 
  echo "Usage:"
  echo " $(basename $0) <????> "
  exit
fi
# upload local data to 197 
# rsync user@address:SRC_directory DEST_path/
# Notice: local_path with / in the end
remote_dir=/work/person/rensh/front_detect/
#remote dir should put under the local_path
local_path=/mnt/d/lomf/frontal_detect/
data_type=$1 # ostia or roms
# time_type=$2  # climatology, monthly, daily
# region_type=SCS # model_domain, SCS
# keywords=*
# echo ${remote_dir}/Result/${data_type}/${region_type}/${time_type}/${year}
# exit 0
# mkdir -p ${local_path}/Result/${data_type}
rsync -vazP ${local_path}/Result/${data_type} lingtj@128.5.10.197:${remote_dir}/Result/
rsync -vazP ${local_path}/Fig/${data_type} lingtj@128.5.10.197:${remote_dir}/Fig/