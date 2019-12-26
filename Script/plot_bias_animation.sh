#!/bin/bash
if [ $# -ne 2 ] ; then
  echo "You need to specify datatype timetype"
  echo 
  echo "Usage:"
  echo " $(basename $0) climatology SCS"
  exit
fi
local_path=/mnt/d/lomf/frontal_detect/Fig/
# fig_path=${local_path}/Fig/
time_type=$1  # climatology, monthly, daily
region_type=$2 # model_domain, SCS
fig_path=${local_path}/comparison/${region_type}/${time_type}/
echo ${fig_path}
mkdir -p ${fig_path}/animation
if [ "${time_type}" == "climatology" ]; then
  # echo ${time_type}
  # for climatology
  # frequency bias
  convert -delay 100 -loop 0 ${fig_path}/freq_bin_0.5/mercator_bias_frontline_freq_map_month_*.png ${fig_path}/mercator_bias_frontline_freq_map_monthly.gif
  convert -delay 100 -loop 0 ${fig_path}/freq_bin_0.5/mercator_bias_frontarea_freq_map_month_*.png ${fig_path}/mercator_bias_frontarea_freq_map_monthly.gif
  convert -delay 100 -loop 0 ${fig_path}/freq_bin_0.5/roms_bias_frontline_freq_map_month_*.png ${fig_path}/roms_bias_frontline_freq_map_monthly.gif
  convert -delay 100 -loop 0 ${fig_path}/freq_bin_0.5/roms_bias_frontarea_freq_map_month_*.png ${fig_path}/roms_bias_frontarea_freq_map_monthly.gif
elif [ "${time_type}" == "monthly" ]; then
  echo ${time_type}
elif [ "${time_type}" == "daily" ]; then
  echo ${time_type}
fi

