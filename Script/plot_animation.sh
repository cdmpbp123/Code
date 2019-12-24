#!/bin/bash
if [ $# -ne 2 ] ; then
  echo "You need to specify datatype timetype"
  echo 
  echo "Usage:"
  echo " $(basename $0) <????> <????>"
  exit
fi
local_path=/mnt/d/lomf/frontal_detect/Fig/
# fig_path=${local_path}/Fig/
data_type=$1 # ostia or roms
time_type=$2  # climatology, monthly, daily
region_type=SCS # model_domain, SCS
fig_path=${local_path}/${data_type}/${region_type}/${time_type}/
echo ${fig_path}
mkdir -p ${fig_path}/animation
if [ "${time_type}" == "climatology" ]; then
  # echo ${time_type}
  # for climatology
  # SST
  echo "convert climatology monthly SST "
  convert -delay 100 -loop 0 ${fig_path}/sst/climatology_sst_month_*_2008to2017.png ${fig_path}/climatology_monthly_sst_2008to2017.gif
  # tgrad
  echo "convert climatology monthly tgrad "
  convert -delay 100 -loop 0 ${fig_path}/tgrad/climatology_tgrad_month_*_2008to2017.png ${fig_path}/climatology_monthly_tgrad_2008to2017.gif
  # # front area frequency raw grid
  echo "convert climatology monthly frontarea_freq_map "
  convert -delay 100 -loop 0 ${fig_path}/freq_raw/frontarea_freq_map_month_*.png ${fig_path}/monthly_frontarea_freq_map.gif
  # front line frequency raw grid
  echo "convert climatology monthly frontline_freq_map "
  convert -delay 100 -loop 0 ${fig_path}/freq_raw/frontline_freq_map_month_*.png ${fig_path}/monthly_frontline_freq_map.gif
  # # frequency bias
  # convert -delay 100 -loop 0 ${fig_path}/freq_bin_0.5/bias_frontline_freq_map_month_*.png ${fig_path}/bias_frontline_freq_map_monthly.gif
  # convert -delay 100 -loop 0 ${fig_path}/freq_bin_0.5/bias_frontarea_freq_map_month_*.png ${fig_path}/bias_frontarea_freq_map_monthly.gif
elif [ "${time_type}" == "monthly" ]; then
  echo ${time_type}
  # # for monthly
  # rm -rf ${fig_path}/tmp
  # for im in `seq 1 12`; do 
  # mkdir -p ${fig_path}/tmp
  # cmon=`echo 0${im} | tail -3c`
  # echo ${cmon}
  # for iy in `seq 2008 2017`; do
  # ln -sf ${fig_path}/tgrad/monthly_tgrad_${iy}${cmon}.png ${fig_path}/tmp/.
  # ln -sf ${fig_path}/sst/monthly_sst_${iy}${cmon}.png ${fig_path}/tmp/.
  # done
  # convert -delay 100 -loop 0 ${fig_path}/tmp/monthly_tgrad_*.png ${fig_path}/animation/monthly_tgrad_in_month_${cmon}.gif
  # convert -delay 100 -loop 0 ${fig_path}/tmp/monthly_sst_*.png ${fig_path}/animation/monthly_sst_in_month_${cmon}.gif
  # rm -rf ${fig_path}/tmp
  # done
elif [ "${time_type}" == "daily" ]; then
  echo ${time_type}
  rm -rf ${fig_path}/tmp
  iy=2013
  for im in `seq 8 8`; do 
  mkdir -p ${fig_path}/tmp
  cmon=`echo 0${im} | tail -3c`
  echo ${cmon}
  for id in `seq 1 31`; do
  cday=`echo 0${id} | tail -3c`
  echo ${cday}
  ln -sf ${fig_path}/${iy}/*_${iy}${cmon}${cday}.png ${fig_path}/tmp/.
  done
  convert -delay 70 -loop 0 ${fig_path}/tmp/*.png ${fig_path}/animation/${data_type}_sst_in_${iy}${cmon}.gif
  rm -rf ${fig_path}/tmp
  done 
fi

