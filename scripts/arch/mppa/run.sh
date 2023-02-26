# $1 Directory of the benchmark
# $2 Name of the experiment
# $3 LWMPI
# $4 MAP 
export TARGET=mppa256
# export NANVIX_LWMPI=1
# export LWMPI_PROC_MAP=2
cd $1                            \
	&& cp $2 img/mppa256.img     \
	&& make RELEASE=true contrib \
	&& make RELEASE=true all     \
	&& make RELEASE=true test TIMEOUT=5400
