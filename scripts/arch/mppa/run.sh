# $1 Directory of the benchmark
# $2 Name of the experiment
cd $1                                              \
	&& make TARGET=mppa256 RELEASE=true -j contrib \
	&& make TARGET=mppa256 RELEASE=true -j all     \
	&& make TARGET=mppa256 RELEASE=true run
