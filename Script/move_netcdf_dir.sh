# move front netcdf output to sole directory
if [ $# -ne 1 ] ; then
  echo "You need to specify data type"
  echo 
  echo "Usage:"
  echo " $(basename $0) <????>"
  exit
fi
datatype=$1
basedir=./Result/${datatype}/SCS/
netcdf_dir=${basedir}/NetCDF_product/
mkdir -p ${netcdf_dir}
for iy in `seq 2007 2017`; do
mkdir -p ${netcdf_dir}/${iy}/
mv ${basedir}/daily/${iy}/netcdf/*.nc ${netcdf_dir}/${iy}/.
done
