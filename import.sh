#!/bin/bash
#Set colors for your scripts
RED='\033[0;31m'
BLUE='\033[0;34m'     
NC='\033[0m' # No Color

. scripts/set-opening.sh

#asks if data imported yet
dataimport () {
	while 
		printf "Have you imported your data yet? Enter ${RED}[yes]${NC} or ${RED}[no]${NC}." 
		read -p " " importeddata
		printf "You entered ${BLUE} $importeddata ${NC}. Is this correct? If correct, enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
		read -p ': ' importeddatacorrect && [[ -z "$importeddatacorrect" ]]
	do
 		echo "Please re-answer question!"
	done
}

#asks for rawfolder
rawfoldername () {
while 
	echo "Available directories are the following:  " ; ls ; printf "${RED} What is your raw folder name${NC}"
		read -p "? " rawfolder
	printf "Your folder name is ${BLUE} $rawfolder ${NC}. Is this correct? If correct, enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
		read -p ': ' rawfoldercorrect && [[ -z "$rawfoldercorrect" ]]
do
 	echo "Please re-enter raw folder name!"
done

echo "Your raw folder name is $rawfolder."
}

#Step 2: Assign dataset name
datasetnew () {
while 
	printf "${RED}What do you want to call this project once it is imported into QIIME?${NC}" ; read -p " " datasetname
	printf "Your project name is ${BLUE} $datasetname ${NC}. Is this correct? If correct, enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
	read -p ": " check && [[ -z "$check" ]]
do
 	echo "Please re-enter desired dataset name!"
done

echo "Your project name will be $datasetname. Thank you!"
}

EMP_question () {
	while 
	printf "Is your data formatted with EMP protocol? Enter ${RED}[yes]${NC} or ${RED}[no] ${NC}" ; read -p " " EMPquestion
	printf "${BLUE} $EMPquestion ${NC} EMP protocol. Is this correct? If correct, enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
	read -p ": " check && [[ -z "$check" ]]
	do
 	echo "Please re-answer question!"
	done
}


#Step 3 DEMULTIPLEX. -     -     -     -     -     -     -     -     -     -     -     -     
demultiplexquestions () {
	echo "In order to demultiplex, you will need a metadata file with barcode information to match what sample each sequence came from."  
	echo "..."

	printf "${BLUE}Move this metadata file into the ${datasetname}/metadata folder ${NC}"
	echo "..." ; echo "..."

	printf "${RED}ONCE YOU'VE CREATED AND MOVED THE METADATA FILE into ${BLUE}$datasetname/metadata${RED} folder, press any key to continue. ${NC}"
	read -n 1 -s -r -p " "
	echo " " ; echo "Continuing..."

	#Barcode file name
	printf "The file found in your metadata directory is called: " ; ls -1 ${datasetname}/metadata


	while 
		printf "${RED}What is the name of this file you just moved into the metadata folder? ${NC} *Remember to include the file extension* " ; read -p " " metadatafile
		printf "Your metadata file is ${BLUE} $metadatafile ${NC}. Is this correct? If correct, enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
		read -p ": " check && [[ -z "$check" ]]
	do
		echo "Please re-enter metadata file name!"
	done

	echo "Your metadata file is $metadatafile. Thank you!"

	while 
		head -1 ${datasetname}/metadata/$metadatafile #shows first line of metadata
		printf "We need to know what column contains your barcode sequences. ${RED}Enter the name of that column header.${NC}" ; read -p " " sequenceheader
		printf "Your barcode sequence header is ${BLUE} $sequenceheader ${NC}. Is this correct? If correct, enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
		read -p ": " check && [[ -z "$check" ]]
	do
		echo "Please re-enter barcode sequence header name!"
	done

	echo "..."
	printf "Your demultiplexed file will be named ${datasetname}-demux.qza and will be found in ${BLUE}${datasetname}/data/ ${NC}folder. \n"
	echo "..."
	echo "It will also create a stats file named ${datasetname}-demux-details.qza which will be found in the same folder."
	echo "..."

	#reverse comp barcode
	while 
		printf "Are your barcodes reverse complemented? Enter ${RED}[yes] ${NC}or ${RED}[no]:${NC}" ; read -p " " revcompbarcode
		printf "You answered ${BLUE} $revcompbarcode ${NC} to whether your barcodes are reverse complemented. Is this correct? If correct, enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
		read -p ": " check && [[ -z "$check" ]]
	do
		echo "Please re-enter whether your barcodes are reverse complemented!"
	done

	echo "You entered $revcompbarcode." 

		if [ $revcompbarcode = "yes" ]; 
			then
				revcompbarcodetranslated=--p-rev-comp-barcodes 
		elif [ $revcompbarcode = "no" ]; then
				revcompbarcodetranslated=--p-no-rev-comp-barcodes 
		fi


	#golay error
	while 
		printf "Are your barcodes golay error corrected? Enter ${RED} [yes] ${NC}or ${RED}[no]:${NC}" ; read -p " " golayerror
		printf "${BLUE}$golayerror ${NC} golay error correction should be applied to my dataset. Is this correct? If correct enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
		read -p ": " check && [[ -z "$check" ]]
	do
		echo "Please re-enter whether you want golay error correction."
	done

	if [ $golayerror = "yes" ]; 
		then
			golayerrortranslated=--p-golay-error-correction
	elif [ $golayerror = "no" ]; then
		golayerrortranslated=--p-no-golay-error-correction
		
	fi
	echo "QIIME will call $golayerrortranslated."
}

#Actions that take a long time  -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - 
#zipping folder
zipping () {
	cp -r $rawfolder $rawfolder-zip
	cd $rawfolder-zip
	if [ $importprotocol = "paired" ]; 
		then
		mv *_I1_* barcodes.fastq
		echo "_I1_ to barcodes renamed"
		mv *_R1_* forward.fastq 
		echo "_R1_ to forward renamed"
		mv *_R2_* reverse.fastq
		echo "_R2_ to reverse renamed"
		echo "..."
		printf "${BLUE} We'll start zipping these files now. ${NC}" ; echo " "
	echo "..."

		gzip --fast forward.fastq ; echo "Forward zipped"
		gzip --fast reverse.fastq ; echo "Reverse zipped"
		gzip --fast barcodes.fastq ; echo "Barcodes zipped"
	elif [ $importprotocol = "single" ]; then
		mv *_I1_* barcodes.fastq
		echo "_I1_ to barcodes renamed"
		mv *_R1_* sequences.fastq 
		echo "_R1_ to sequences renamed"
		echo "..."
		printf "${BLUE} We'll start zipping these files now. ${NC}" ; echo " "
	echo "..."
		gzip --fast sequences.fastq ; echo "Sequences zipped"
		gzip --fast barcodes.fastq ; echo "Barcodes zipped"
	fi
	cd ..
}

foldercreating () {
	rm -rf ${datasetname}
	echo "Making sure the ${datasetname} folder name is available..."
	mkdir ${datasetname}
	echo "Making the ${datasetname} folder..."
	mkdir ${datasetname}/data
	echo "Adding a data folder..."
	mkdir ${datasetname}/metadata
	echo "Adding a metadata folder..."
	mkdir ${datasetname}/visualization
	echo "Adding a visualization folder..."

	rm -rf ${datasetname}-parameters
	mkdir ${datasetname}-parameters
}
#paired or single data
import_protocol () {
	while 
		printf "Is your data paired or single end reads? Enter ${RED}[paired] ${NC}or ${RED}[single] ${NC}" ; read -p " " importprotocol
		printf "Your data is ${BLUE} $importprotocol ${NC}. Is this correct? If correct, enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
		read -p ": " check && [[ -z "$check" ]]
	do
		echo "Please re-answer question!"
	done

	echo "Your data is $importprotocol, thank you!"

	if [ $importprotocol = "paired" ]; 
		then
			importprotocoltranslated=EMPPairedEndSequences
			demuxtype=emp-paired
	elif [ $importprotocol = "single" ]; then
		importprotocoltranslated=EMPSingleEndSequences
		demuxtype=emp-single
	fi

	echo
}
#EMP import
EMP_import () {
	import_protocol
	printf "QIIME will call ${BLUE}${importprotocoltranslated}${NC} and demultiplex using ${BLUE}${demuxtype}${NC}\n."
	printf "EMP import will be performed using ${BLUE} ${importprotocoltranslated} ${NC}protocol. "

	printf "If you keep getting an error, your data may be a different format. Call ${BLUE} qiime tools import --show-importable-types ${NC} in Terminal for help trouble shooting."; echo " " ; echo "..."

	foldercreating #create folders
	demultiplexquestions #calling demultiplex questions
	
	printf "${BLUE} NOW GO RELAX, NO MORE USER INPUTS ARE NEEDED. THIS SCRIPT IS EXPECTED TO TAKE A LONG TIME TO RUN (HOURS) ${NC}" ; echo " "
	zipping #zipping files
	printf "${BLUE} WE ARE NOW IMPORTING, THIS MAY TAKE A LONG TIME ${NC}"
	qiime tools import \
	--input-path $rawfolder-zip \
	--output-path ${datasetname}/data/raw.qza \
	--type $importprotocoltranslated
	echo ; printf "Importing is complete! $BLUE Your temporary $rawfolder-zip will be removed now. ${NC} Demultiplexing.  This will take a while..." ; echo " "

	rm -r $rawfolder-zip
	echo "$rawfolder-zip removed"
} 

#not EMP import
nonEMP_import () {
	echo "You have data that is non-EMP protocol formatted. You will have to import manually."
	foldercreating #create folders
	sleep 3
	printf "Go to ${BLUE}https://docs.qiime2.org/2020.11/tutorials/importing/ ${NC}for more information on importing manually."
	echo
	echo
	printf "Type in ${BLUE} qiime tools import --show-importable-types ${NC} in Terminal."
	printf "You will have to press CTRL+c to exit out of the script and manually type in the method. Format should be \n
	${BLUE}qiime tools import --type ${RED}[importable-type name]${BLUE} --input-path ${RED}[$rawfolder]${BLUE}  --output-path ${RED}raw.qza${NC}"
	echo 
	echo "However, please double check formatting on above link for confirmation."
	printf "You should always name the --output-path ${BLUE}raw.qza${NC} \n"
	printf "You will then move ${BLUE}raw.qza${NC} file into ${BLUE}$datasetname/data ${NC} folder. \n"
	echo "Once you have finished moving file, proceed with demultiplexing your data if not done so already."
	sleep 3
	printf "${BLUE}In the meantime, we can zip your files in preparation for further importing steps. This may take a while...${NC}"
	zipping
	printf "Place your final demultiplexed file in ${BLUE}${datasetname}/data ${NC}and rename the file ${BLUE}${datasetname}-demux.qza${NC}\n\n"
	importprotocoltranslated="non-EMP protocol"
	demuxtype="non-demux protocol"
}

#qiime demultiplex
qiime_demultiplex () {
echo "QIIME demultiplexing"
qiime demux $demuxtype \
  --i-seqs ${datasetname}/data/raw.qza \
  --m-barcodes-file ${datasetname}/metadata/${metadatafile} \
  --m-barcodes-column ${sequenceheader} \
  --o-per-sample-sequences ${datasetname}/data/${datasetname}-demux.qza \
  --o-error-correction-details ${datasetname}/data/${datasetname}-demux-details.qza \
  $golayerrortranslated \
  $revcompbarcodetranslated
}

#Save settings to parameters file   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - 
saving_parameters () {
echo -e "	
	env | $qiimeenvironment
	single or paired | $importprotocol
	metadata barcode file | $metadatafile
	seq header | $sequenceheader
	revcomp barcode called | $revcompbarcode
	golay called | $golayerrortranslated
	name | $datasetname
	import protocol | $importprotocoltranslated
	demultiplex protocol | $demuxtype
	" > $datasetname-parameters/import-demux-parameters.txt

}

#Code
askqiime
dataimport
if [ $importeddata = "yes" ]; then 
	askdatasetname
	EMP_question
	if [ $EMPquestion = "yes" ]; then 
		import_protocol
		demultiplexquestions
		echo "These next steps refer to data that was imported using EMP."
		printf "EMP import was performed using ${BLUE} ${importprotocoltranslated} ${NC}protocol. QIIME will now demultiplex using ${BLUE} ${demuxtype}${NC}."
		echo
		qiime_demultiplex
	elif [ $EMPquestion = "no" ]; then
		echo "This script does not support demultiplexing non-EMP import protocol data."
	fi
elif [ $importeddata = "no" ]; then
	rawfoldername
	datasetnew
	EMP_question
	if [ $EMPquestion = "yes" ]; then 
		EMP_import
		qiime_demultiplex
	elif [ $EMPquestion = "no" ]; then
		nonEMP_import
	fi
fi
saving_parameters
printf "${CYAN}YOUR DATA IS NOW IMPORTED AND DEMULTIPLEXED! THE NEXT STEP IS FILTERING AND MERGING IF YOU HAVE PAIRED DATA USING DADA2. ${NC}"
