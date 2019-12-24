#!/bin/bash
if [ $# -ne 1 ] ; then
  echo "You need to specify datatype"
  echo 
  echo "Usage:"
  echo " $(basename $0) ostia or roms or mercator "
  exit
fi
data_type=$1 # ostia or roms or mercator
region_type=SCS # model_domain, SCS
basedir=/mnt/d/lomf/frontal_detect/Result/${data_type}/${region_type}/
monthly_dir=${basedir}/monthly/
clim_dir=${basedir}/climatology/
mkdir -p ${clim_dir}
mkdir -p ${monthly_dir}/tmp
yy1=2008
yy2=2017
for iy in `seq 2008 2017`; do 
echo ${iy}
ln -sf ${monthly_dir}/monthly_front_${iy}.nc ${monthly_dir}/tmp/.
ln -sf ${monthly_dir}/front_frequency_map_raw_${iy}.nc ${monthly_dir}/tmp/.
ln -sf ${monthly_dir}/front_frequency_map_binned_0.5degree_${iy}.nc ${monthly_dir}/tmp/.
done
# do climatology average with ncea
ncea ${monthly_dir}/tmp/monthly_front_*.nc ${clim_dir}/climatology_front_${yy1}to${yy2}.nc
ncea ${monthly_dir}/tmp/front_frequency_map_raw_*.nc ${clim_dir}/front_frequency_map_raw_${yy1}to${yy2}.nc
ncea ${monthly_dir}/tmp/front_frequency_map_binned_0.5degree_*.nc ${clim_dir}/front_frequency_map_binned_0.5degree_${yy1}to${yy2}.nc

rm -rf ${monthly_dir}/tmp