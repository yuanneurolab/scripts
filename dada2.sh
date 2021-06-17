#!/bin/bash
#21.02.15 Calvin > Matt 
#--Added denoise-single and denoise-paired

#Set colors for your scripts
RED='\033[0;31m'
BLUE='\033[0;34m'     
CYAN='\033;[0;36m'
NC='\033[0m' # No Color


# - - - RESET VARIABLES - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
unset trunclengthf
unset trunclengthr
unset trimleftf
unset trimleftr


#Run setup scripts
. scripts/set-opening.sh
askdatasetname
askmetadata
askqiime

# - - - Introduce dada2 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
demux_report () {
[ -f ${datasetname}/visualization/${datasetname}-demux.qzv ] && exists=yes || exists=no
echo $exists

	if [ $exists = "yes" ]; 
		then
			echo "Demux report already exists. We don't need to make a new one. Opening now. Press 'q' to escape."
		else
			echo "Demux report does not exist. It's being made now. Please wait..."			
			qiime demux summarize \
  			--i-data ${datasetname}/data/${datasetname}-demux.qza \
  			--o-visualization ${datasetname}/visualization/${datasetname}-demux.qzv
			echo "Demultiplex quality report created. Opening now! Press 'q' to escape."
	fi

qiime tools view ${datasetname}/visualization/${datasetname}-demux.qzv
}
# Asking about data reads 
end_reads () {
	while 
		printf "Is your data paired or single end reads? Enter ${RED}[paired] ${NC}or ${RED}[single] ${NC}" ; read -p " " endread
		printf "Your data is ${BLUE} $endread ${NC}. Is this correct? If correct, enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
		read -p ": " check && [[ -z "$check" ]]
	do
		echo "Please re-answer question!"
	done

	echo "Your data is $endread. "

	echo
}

#dada2 single end reads
dada2_single () {
#TRIMLEFT
while 
	printf "How many of the first bases do you want to remove in your reads? (aka trim left)?  " ;printf "${RED} Input value: ${NC}"
		read -p ":   " trimleft
	printf "Do you want to trim first ${BLUE} $trimleft ${NC} of reads? If correct enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
		read -p ': ' check && [[ -z "$check" ]]
do
 	echo "Please re-enter trimleft value!"
done
#TRUNCLENGTH
while 
	printf "How long do you want reads to be in total (truncate reads at x position)?  " ;printf "${RED} Input value: ${NC}"
		read -p ":   " trunclength
	printf "Do you want to truncate reads at ${BLUE} $trunclength ${NC}? If correct enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
		read -p ': ' check && [[ -z "$check" ]]
do
 	echo "Please re-enter truncate read value!"
done
echo "..." ; echo "..."
echo tlf $trimleft
echo truncf $trunclength

# - - - Print  parameters - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
echo -e "	
	env | $qiimeenvironment
	single or paired | $endread
	barcode file | $metadatafile
	name | $datasetname
	trunc | $trunclength
	trim left | $trimleft" > ${datasetname}-parameters/${datasetname}-dada2-parameters.txt


# - - - Run lengthy scripts - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
rm -rf $datasetname/data/dada2

printf "${BLUE} THIS WILL TAKE A WHILE, DADA2 IS RUNNING WITH YOUR GIVEN COMMANDS. ${NC} You can find a record of the parameters that you used in your parameters folder. The filename is ${datasetname}-dada2-parameters.txt"
qiime dada2 denoise-single \
 --i-demultiplexed-seqs $datasetname/data/$datasetname-demux.qza \
 --p-trunc-len $trunclength \
 --p-trim-left $trimleft \
 --output-dir $datasetname/data/dada2
 --p-n-threads 0
}

#dada2 if data is paired
dada2_paired () {
#TRIMLEFTF
while 
	printf "How many of the first bases do you want to remove in your ${BLUE}FORWARD${NC} reads? (aka trim left forward)?  " ;printf "${RED} Input value: ${NC}"
		read -p ":   " trimleftf
	printf "Do you want to trim first ${BLUE} $trimleftf ${NC} of forward reads? If correct enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
		read -p ': ' check && [[ -z "$check" ]]
do
 	echo "Please re-enter trimleft forward value!"
done

#TRIMLEFTR
while 
	printf "How many of the first bases do you want to remove in your ${BLUE}REVERSE${NC} reads? (aka trim left reverse)?  " ;printf "${RED} Input value: ${NC}"
		read -p ":   " trimleftr
	printf "Do you want to trim first ${BLUE} $trimleftr ${NC} of reverse reads? If correct enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
		read -p ': ' check && [[ -z "$check" ]]
do
 	echo "Please re-enter trimleft reverse value!"
done

#TRUNCLENGTHF
while 
	printf "How long do you want ${BLUE}FORWARD${NC} reads to be in total (truncate forward reads at x position)?  " ;printf "${RED} Input value: ${NC}"
		read -p ":   " trunclengthf
	printf "Do you want to truncate forward reads at ${BLUE} $trunclengthf ${NC}? If correct enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
		read -p ': ' check && [[ -z "$check" ]]
do
 	echo "Please re-enter truncate forward read value!"
done

#TRUNCLENGTHR
while 
	printf "How long do you want ${BLUE}REVERSE${NC} reads to be in total (truncate reverse reads at x position)?  " ;printf "${RED} Input value: ${NC}"
		read -p ":   " trunclengthr
	printf "Do you want to truncate reverse reads at ${BLUE} $trunclengthr ${NC}? If correct enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
		read -p ': ' check && [[ -z "$check" ]]
do
 	echo "Please re-enter truncate reverse read value!"
done
echo "..." ; echo "..."
echo tlf $trimleftf
echo tlr $trimleftr
echo truncf $trunclengthf 
echo truncr $trunclengthr


# - - - Print  parameters - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
echo -e "	
	env | $qiimeenvironment
	single or paired | $endread
	metadata file | $metadatafile
	name | $datasetname
	trunc f | $trunclengthf
	trunc r | $trunclengthr
	trim left f | $trimleftf
	trim left r | $trimleftr" > ${datasetname}-parameters/${datasetname}-dada2-parameters.txt


# - - - Run lengthy scripts - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
rm -rf $datasetname/data/dada2

printf "${BLUE} THIS WILL TAKE A WHILE, DADA2 IS RUNNING WITH YOUR GIVEN COMMANDS. ${NC} You can find a record of the parameters that you used in your parameters folder. The filename is ${datasetname}-dada2-parameters.txt"
qiime dada2 denoise-paired \
 --i-demultiplexed-seqs $datasetname/data/$datasetname-demux.qza \
 --p-trunc-len-f $trunclengthf \
 --p-trunc-len-r $trunclengthr \
 --p-trim-left-f $trimleftf \
 --p-trim-left-r $trimleftr \
 --output-dir $datasetname/data/dada2
 --p-n-threads 0
}

# - - - Read how they worked - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#Visualization of dada2
dada2_vis () {
#Gives you denoising stats and tells you how much of your input passed the merging steps.
echo "Preparing visualization of denoising stats for dada2..."

qiime metadata tabulate \
  --m-input-file $datasetname/data/dada2/denoising_stats.qza \
  --o-visualization $datasetname/visualization/dada2-denoising_stats.qzv
echo "Visualization of dada2 filtering stats now complete. Opening now. Press 'q' to escape."

qiime tools view $datasetname/visualization/dada2-denoising_stats.qzv

printf "Now we'll visualize the results of filtering steps. ${BLUE} DECIDE WHAT SAMPLES YOU WANT TO REMOVE FROM THIS DATASET BASED ON READ COUNT${NC}\n"  

#Now you can visualize the results of filtering.
qiime feature-table summarize \
  --i-table ${datasetname}/data/dada2/table.qza \
  --o-visualization ${datasetname}/visualization/dada2-table.qzv \
  --m-sample-metadata-file ${datasetname}/metadata/${metadatafile}

qiime tools view ${datasetname}/visualization/dada2-table.qzv

}

# - - - Check to see if dada2 has already been run- - - - - - - - - - - - - - - - - - - - - - - - 
while true; do 
	printf "Have you already run dada2 analysis and want to now only do first round of filtering tables?  " ;printf "${RED}[yes]${NC} or ${RED}[no]:${NC}"
		read -p ":   " dada2run
	printf " ${BLUE} ${dada2run} ${NC} to already running dada2 analysis. If correct enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
		read -p ': ' dada2runcorrect
	if [[ $dada2runcorrect == 'yes' ]]; then
		if [[ $dada2run == 'no' ]]; then 
			demux_report
			end_reads
			if [[ $endread == 'paired' ]]; then
				dada2_paired
			elif [[ $endread == 'single' ]]; then
				dada2_single
			fi
			dada2_vis
		fi
		break
	else
 		echo "Please answer the question again. "
	fi
done

# - - - Do first round of filtering - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ -f ${datasetname}/visualization/${datasetname}-demux.qzv ] && exists=yes || exists=no
echo $exists

	if [ $exists = "yes" ]; 
		then
			echo "Demux report already exists, we don't need to make a new one. Opening now. Press 'q' to escape."
		else
			echo "Demux report does not exist. It's being made now. Please wait..."			
			qiime demux summarize \
  			--i-data ${datasetname}/data/${datasetname}-demux.qza \
  			--o-visualization ${datasetname}/visualization/${datasetname}-demux.qzv
			echo "Demultiplex quality report created. Opening now! Press 'q' to escape."
	fi

qiime tools view ${datasetname}/visualization/${datasetname}-demux.qzv

#Ask about filtering samples
cp -n ${datasetname}/metadata/${metadatafile} ${datasetname}/metadata/${metadatafile%.*}-low-samples-removed.txt
printf "A new file, ${BLUE} ${metadatafile%.*}-low-samples-removed.txt ${NC} has been created in your metadata folder."
echo "..." ; echo "..."
printf "In this new file, ${BLUE} delete samples that you would like to EXCLUDE from analysis. ${NC}"

printf "To continue, press ${BLUE} [SPACEBAR] ${NC}once ${metadatafile%.*}-low-samples-removed.txt has been edited "
read -n1 -r -p " " key

if [ "$key" = '' ]; then
	echo "Proceeding with analysis..."
fi

#Run filter samples
qiime feature-table filter-samples \
  --i-table ${datasetname}/data/dada2/table.qza \
  --o-filtered-table ${datasetname}/data/dada2/samples-filtered-table.qza \
  --m-metadata-file ${datasetname}/metadata/${metadatafile%.*}-low-samples-removed.txt

#visualize the sample filtered dataset
qiime feature-table summarize \
  --i-table ${datasetname}/data/dada2/samples-filtered-table.qza \
  --o-visualization ${datasetname}/visualization/dada2-samples-filtered-table.qzv \
  --m-sample-metadata-file ${datasetname}/metadata/${metadatafile%.*}-low-samples-removed.txt

#Ask about filtering features from sample filtered table
printf "A file was created called samples-filtered-table.qzv in your visualization folder. It will open automatically. Use this file to decide: Below what feature frequency do you want rare features removed?"
echo "..."

qiime tools view ${datasetname}/visualization/dada2-samples-filtered-table.qzv

while true
do
	read -p "Below what count would you like to filter features?: " minfeaturefrequency
	printf "Your minimum feature frequency for filtering is $minfeaturefrequency."
    echo 
	printf "If correct enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
    read -p " " correct
    [[ "$correct" == "yes" ]] && break || echo "Please re-enter feature count." 
done

#Run filter features
qiime feature-table filter-features \
  --i-table ${datasetname}/data/dada2/samples-filtered-table.qza \
  --p-min-frequency $minfeaturefrequency \
  --o-filtered-table ${datasetname}/data/samples-and-features-filtered-table.qza

echo "Low frequency features have been removed."
echo "..."

qiime feature-table summarize \
  --i-table ${datasetname}/data/samples-and-features-filtered-table.qza \
  --o-visualization ${datasetname}/visualization/samples-and-features-filtered-table.qzv

echo "..."

qiime tools view ${datasetname}/visualization/samples-and-features-filtered-table.qzv

printf "${BLUE}Filtering complete!!${NC}"
echo

echo "We are now going to cleanup your data folder, and move some extraneous files into your data/dada2 folder if you need them in the future."
rm ${datasetname}/data/dada2/samples-filtered-table.qza
echo "${datasetname}/data/dada2/samples-filtered-table.qza removed"
mv ${datasetname}/data/${datasetname}-demux.qza ${datasetname}/data/dada2/${datasetname}-demux.qza
echo "Demux file moved to dada2"
mv ${datasetname}/data/raw.qza ${datasetname}/data/dada2/raw.qza
echo "Raw file moved to dada2 folder"
mv ${datasetname}/data/${datasetname}-demux-details.qza $datasetname-parameters/${datasetname}-demux-details.qza 
echo "Demux details moved to $datasetname-parameters folder"

#Save settings to parameters file   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - 
saving_parameters () {
echo -e "	
	env | $qiimeenvironment
	single or paired | $endread
	metadata file | $metadatafile
	name | $datasetname
	import protocol | $importprotocoltranslated
	demultiplex protocol | $demuxtype
	metadata file created with low samples removed | ${metadatafile%.*}-low-samples-removed.txt
	minimum feature frequency | $minfeaturefrequency" > $datasetname-parameters/dada2-sampleandfeaturesfiltered-parameters.txt

}
saving_parameters
