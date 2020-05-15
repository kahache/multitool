#!/bin/bash
#__author__ = "Ka Hache a.k.a. The One & Only Javi"
#__version__ = "1.0.0"
#__start_date__ = "19 January 2019"
#__end_date__ = "7 Febrary 2019""
#__maintainer__ = "me myself & I"
#__email__ = "little_kh@hotmail.com"
#__requirements__ = "lftp, inotifytools,zipinfo"
#__status__ = "In production 24/7""
#__description__ = "For a concrete usecase, we need to connect to client's FTP. Inside this FTP, there's an encoder output which compresses in daily ZIP files the video recordings..
#example: we connect to a folder called BJ, where ew find a .zip called 20180119.zip (The date).
#Each folder stands for a different TV channel
#When we extract the zip, it has 24 files callled like "record.0.mp4" up to "record.23.mp4".
#These files must be renamed according to their TV Channel names and moved to the uploading folder."
#__Origniality stands alone!!_



##########################
# CONDITIONS
# + Need to have created the download folders. It's highly recommended to use the same as the FTP from the client.
# + Need to have created the "extracted" folder inside each of the download folders
# + Need to have the configs for software 'lftp' for each folder/channel
##########################

IFS=""
LOG=/var/log/Multitool.log

#Example of use:
#bash /home/user/Multitool.sh -k "TV_channel_numer_one" -d "/home/user/configs/TV_channel_numer_one.config" -i "/home/user/TV Example"/ -o "/home/user/" -u "/home/user/uploads/" -t 21600 -h "-8" &

#Display scren
printf "Welcome to the FTP Downloader - Unzipper - Renamer - Uploader (Version 1.0)\nCreated by the fuckin' Ka Hache\n\n"
#Help menu
if [ "$1" == "-h" ] || [ "$1" == "-help" ]
	then
	printf "Hi! This is the help menu\n\nThe options you can type are:\n-k = TV Name for platform\n-i = Folder where the files are going to be downloaded\n-o The main folder of the downloader (This is to avoid a possible bash version bug)\n-d = Downloading configuration file for lftp (for more detailed info, please type 'man lftp'\n-t = Timeout, this option is the time the program will work waiting for the downloaded files\n-h = Hours delayed in the final name. It can be negative (final file has earlier time) or positive (final file is delayed)\n\nIf none of this option makes sense for you or you think you're some kind of retarded, just contact IT Team for help\n\nExample use:\n bash /home/user/Multitool.sh -k TV_channel_numer_one -d /home/user/configs/TV_channel_numer_one.config -i /home/user/TV Example/ -o /home/user/ -u /home/user/uploads/ -t 21600 -h -8\nNOTE: please type all the options with double commas!!!! "
	exit 0
	else
	printf "For more help with the usage, please add the '-h' option to see the help menu\n\n"

fi


#first we use the variables received from the call of the script
while getopts k:i:o:d:t:h:u: option; do
 	case "${option}"
 	in
 		k) TV_NAME=${OPTARG};;
 		i) FOLDER=${OPTARG};;
		o) DOWNLOAD_FOLDER=${OPTARG};;
		d) DOWNLOAD_CONFIG=${OPTARG};;
		t) TIME_OUT=${OPTARG};;
		h) DELAY=${OPTARG};;
		u) UPLOAD_FOLDER=${OPTARG};;
	esac
done

#Logging function
function to_log(){
        echo "$1" | logger -t Multitool.sh -i
        echo "[`date`]: $1" >> $LOG
        echo "$1"
}


#download function
download(){
	#first we start downloading the files
	cd $DOWNLOAD_FOLDER
	lftp -f $DOWNLOAD_CONFIG &
}

	
#this function extracts the files contained in the zip file
decompress(){
	to_log "Channel $TV_NAME - Starting decompression system for file $ZIP_FILE"
	cd $FOLDER 
	mkdir extracted
	if [ "`zipinfo -t $ZIP_FILE | cut -d " " -f 1`" != "24" ] #we only process if the ZIP has the full 24 hours!
		then
		to_log "Channel $TV_NAME - ERROR!!! file $ZIP_FILE does not contain the 24 files!!"
		exit 1
	else
		unzip $ZIP_FILE -d extracted/  >> $LOG
		to_log "Channel $TV_NAME - File $ZIP_FILE uncompressed successfully"
	fi	
	to_log "Decompression process completed"
	}


#this function renames the files
rename(){
	HOUR=$((-1)) #counter
	to_log "Channel $TV_NAME - Starting renaming process from $ZIP_FILE"
	for FILE in $FOLDER/extracted/*.mp4
		do
		#first we extract the date and hour for the renaming
		DATE=`echo $ZIP_FILE | cut -d "." -f 1`
		HOUR=$(($HOUR+1)) #first files equals to 00:00:00 and so over
			#if the hour contains only 1 character, a zero needs to be added
			if [ `echo -n $HOUR| wc -c` == 1 ]
				then
				FILENAME_HOUR=0`echo $HOUR`
			else
				FILENAME_HOUR=$HOUR
			fi
		#we process the option of changing the time of a file
		TIME="${FILENAME_HOUR}0000"
        	if [ `echo ${DELAY} | head -c 1` = "-"  ]
		       	then
                	DELAY_NUMBER=${DELAY:1:${#DELAY}}
                	NEW_DATE=`date -d "$DATE ${TIME:0:2}:${TIME:2:2}:${TIME:4:2} $DELAY_NUMBER hours ago" +'%Y%m%d_%H%M%S'`
		else 
                	DELAY_NUMBER=${DELAY:1:${#DELAY}}
                	NEW_DATE=`date -d "$DATE ${TIME:0:2}:${TIME:2:2}:${TIME:4:2} $DELAY_NUMBER hours" +'%Y%m%d_%H%M%S'`
        	fi


		#we do finally the renaming
		mv ${FILE} "${FOLDER}"/extracted/${TV_NAME}_`hostname`_${NEW_DATE}.mp4 >> $LOG
		to_log "Channel $TV_NAME - Renamed $FILE from $ZIP_FILE into ${TV_NAME}_`hostname`_${NEW_DATE}.mp4"
	done
}

#we move the final files into the final uploading folder
upload(){	
	to_log "Channel $TV_NAME - Moving everything into upload folder..."
	cd extracted
	chown user:user $TV_NAME* >> $LOG
	mv $TV_NAME* $UPLOAD_FOLDER >> $LOG
	to_log "Channel $TV_NAME - Process for channel $TV_NAME from day $DATE done!"
	rm $FOLDER/$ZIP_FILE >> $LOG
	to_log "Channel $TV_NAME - Deleted file $ZIP_FILE"
}


#We execute the program!
download
#process downloaded files
timeout ${TIME_OUT} inotifywait -m -q -e close_write,moved_to --format %f . "$FOLDER" | while read -r ZIP_FILE; do

                if [ ${ZIP_FILE: -4} == ".zip"  ]
                then
                        to_log "Channel $TV_NAME - Download successfully for $ZIP_FILE"
                        DOWNLOADS_LOG=/var/tmp/$TV_NAME.download
			if [ grep '$ZIP_FILE' $DOWNLOADS_LOG  ] #if the file has already been downloaded...
				then
				to_log "Channel $TV_NAME - ERROR!!! File $ZIP_FILE inside $DOWNLOAD_FOLDER already downloaded!! "
				rm $ZIP_FILE
			else
				#we do the full processing of the ZIP file
				echo $ZIP_FILE >> $DOWNLOADS_LOG
              			decompress
				sleep 5 #added sleeps because sometimes it goes too fast
				rename
				sleep 5	
				upload
				sleep 5
			fi
		 else
                        to_log "Channel $TV_NAME - ERROR!!! File $ZIP_FILE inside $DOWNLOAD_FOLDER is not a ZIP file! "
                fi
        done

exit 0


##################################
#FUTURE IMPLEMENTATIONS
#Update correct hour in logs
#Check if there isn't anything to download and log it (check function below)
################################
# IDEAS FOR THE FUTURE
# + BUG: sometimes lftp erases the "extract" folder. Maybe this can be turned into a variable
# + Mail the team when the ERRORS appear. It would be even cool to mail the client too
# + It doesn't save the files already downloaded, please check in the last part
# + BUG: If the file already exists (for example, a previous decompression) it gives an error, as it asks the user to press "Y/N/" etc.
# + Improve the logging system - now it doesn't get the stdout. It also can turn into a variable
# + Add option to avoid the time change
# + Add option to check that all the commands are given, if anyone missing display error screen
# + Add the option to choose the time of how much times will it upload files 
# + Think about the option to transform this into a daemon inside /etc/init.d
##########################

#check_download_folder(){
 #       if [ $(ls -A $DOWNLOAD_FOLDER)  ] #we check if we have download something, if not stop the script
  #      then
   #             echo "Nothing - here return to the call some 1 as OK"  
    #    else
     #           to_log "Channel $TV_NAME - ERROR!! Nothing to download"
      #          exit 1
       # fi
#}
