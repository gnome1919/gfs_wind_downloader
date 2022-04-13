#!/bin/bash

clear

start=`date +%s`

echo ' '
echo "********************************************"
echo "* Starting Time: `date +%T%t%x` *"
echo "********************************************"
echo ' '
echo ' '

#set -x
#trap read debug

echo " NOAA's GFS Wind Downloader"
echo ' Copyleft 2016'
echo ' Version 2.0'
echo ' By Farrokh A. Ghavanini'
echo ' '
echo '                    ***********************************'
echo '                  ***   Downloading Global Wind Data  ***'
echo '                  ***       from NOAA FTP Server      ***'
echo '                    ***********************************'
echo ' '

ftpdir=/pub/data/nccf/com/gfs/prod
filecon=z.pgrb2full.0p50.f
server=ftp.ncep.noaa.gov
today=`date +%Y%m%d`
#today=20171210
dir=$today;
hour=`date -u +%H`
#hour=3
OK=$NULL

if [ "$hour" -lt "6" ]; then
		echo "Current time in GMT is: `date -u +%R` "
		echo -n "Continue anyway? [y/n] "
		read OK
		
		until [ "$OK" = 'y' ] || [ "$OK" = 'Y' ] || \
    			 [ "$OK" = 'n' ] || [ "$OK" = 'N' ]
		do
	 		 echo -n "Continue anyway? [y/n] "
	 		 read OK
	 	done
	 	
	 		 if [ "$OK" = 'n' ] || [ "$OK" = 'N' ]; then
			 	echo -e "\nABORTED BY USER!\n"
				exit 0
			 else
			 	echo -e "*** WARNING! The data to be downloaded may be incomplete. ***\n"
			 fi
	else
		echo "Current time in GMT is: `date -u +%R` ... seems OK!"		
fi


if [ -d "$dir" ]; then
		echo "--> $dir directory exists! Backing up existing directory..."
		mv -v $dir $dir.bak
		echo "--> Making $dir directory"
		mkdir $dir
	else
		echo "--> Making $dir directory"
		mkdir $dir
fi

for time in {00..96..3};
	do
		filename=gfs.t00$filecon$time
		serverfilename=gfs.t00$filecon$(printf "%03d" "${time#0}")
		url="https://nomads.ncep.noaa.gov/cgi-bin/filter_gfs_0p50.pl?file=$serverfilename&lev_10_m_above_ground=on&var_UGRD=on&var_VGRD=on&leftlon=0&rightlon=360&toplat=90&bottomlat=-90&dir=%2Fgfs."$today"%2F00%2Fatmos"
		echo "--> Downloading $filename:"
		ret=1
		tries=1
		while [[ "$ret" != 0 ]] && [[ "$tries" -le 10 ]]; do
			curl -m 60 --retry 10 --retry-delay 5 -C - $url --output ./$dir/$filename.grib2
			ret=$?
			tries=$(($tries+1))
			sleep 10
		done
		if [ "$ret" != "0" ]; then
			echo " *** WARNING!!! Couldn't Download $filename, File Skipped ***"
			wgrib2 ./$dir/$filename.grib2 -spread ./$dir/$time.txt > /dev/null
#			cat ./$dir/$time.txt >> ./$dir/wind-gfs.dat
			echo ' '
		else
			echo "--> Converting $filename to spreadsheet format..."
			wgrib2 ./$dir/$filename.grib2 -spread ./$dir/$time.txt > /dev/null
#			echo "Adding downloaded data to \"wind-gfs.dat\"..."
#			cat ./$dir/$time.txt >> ./$dir/wind-gfs.dat
			echo ' ';
		fi
done


echo ' '
echo '                    ***********************************'
echo '                  ***        Download Completed!      ***'
echo '                    ***********************************'
echo ' '

end=`date +%s`
runtime=$((end-start))
echo "*** Elapsed Time: $runtime Seconds ***"


mv -f ./CRON.log ./$dir/$dir.log
exit 0
