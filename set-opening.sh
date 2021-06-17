#!/bin/bash
#FUNCTIONS:
#	askdatasetname		askmetadata		askqiime		asktable		loadreference		taxacollapse		asksamplingdepth
#	qiime_taxa_barplot	categories		heatmap			ancom_test		askifsubset		askparametertuning	askuniqueidcolumn
#	askoutputdir		askyscale		askrelativefrequency

#Set colors for your scripts
RED='\033[0;31m'
BLUE='\033[0;34m'     
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 	Re-load dataset
askdatasetname () {
printf "The project being loaded is $datasetname. Do you need to re-load a different 'dataset name'?${RED} [yes] or [no]?  ${NC} If you are continuing this script from ${BLUE} import & demultiplex script choose ${RED}[no]${NC}" ; read -p " " reload
echo "You entered $reload"
	if [ $reload = "yes" ]; 
		then
			#Ask for dataset name
			while 
			ls ; printf "${RED}What is your dataset name? ${NC}" ; read -p " " datasetname
			printf "Your data is ${BLUE} $datasetname ${NC}. If correct enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
			read -p ": " check && [[ -z "$check" ]]
	do
 		echo "Please re-enter desired dataset name! "
	done

echo "Your dataset directory that has been loaded is $datasetname."; echo "..." ; echo "..."

	else
		echo "Your inputs from importing step will be carried forward." 
	fi
}



#	Re-load metadata filename
askmetadata () {
printf "The metadata file you are using is $BLUE $metadatafile $NC.  Do you need to use a different 'metadata file'? Enter ${RED} [yes] ${NC} or ${RED} [no]?  ${NC}" ; read -p " " reload

echo "You entered $reload"
	if [ $reload = "yes" ]; 
		then
			#print available metadata files & then ask which they would like to use
			while true; do 
            shopt -s nullglob
            metadataarray=(${datasetname}/metadata/*)
            tablenum=0
            for t in ${metadataarray[@]}; do
                ((tablenum++))
                echo "[${tablenum}] ${t}"
            done
            
            printf "${RED}What metadata file would you like to load? ${NC}Enter the number before the option."
            read -p " " metadatanum
            ((metadatanum=metadatanum-1))
            printf "You chose ${BLUE}${metadataarray[metadatanum]}${NC}. If correct, enter ${RED}[yes]${NC}. If incorrect, press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
            read -p " " tablecorrect
            metadatafile=${metadataarray[metadatanum]##*/} #only gets expression after last slash
            [[ "$tablecorrect" == "yes" ]] && break || echo "Oops! Try again." 
            done
			printf "Your metadata filename is ${BLUE} $metadatafile ${NC}."
            echo
	else
		echo "Your metadata filename will be carried forward."
	fi
}



#	Open QIIME?
askqiime () {
    printf "If you have activated QIIME already, enter ${RED}[yes]${NC}. If you have not, press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
    read -p " " qiimestatus
    if [[ "$qiimestatus" == "yes" ]]; then return 0; echo "Already activated!"
    else
        while true; 
        do
            echo "Available qiime packages are shown here. "
            conda env list  
            echo "Environment name likely found after '/env/...'" 
            printf "What is your ${RED}qiime environment name${NC}? Type everything after the last / .  " 
            read -p " " qiimeenvironment
            printf "My qiime environment name is ${BLUE}$qiimeenvironment${NC}. If correct, enter ${RED}[yes]${NC}. If incorrect, press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
            read -p " " qiimecorrect
            [[ "$qiimecorrect" == "yes" ]] && break || echo "Oops! Try again." 
            echo "Please re-enter qiime environment name"
        done

        echo "We are now activating your qiime environment"
        echo "..."
        printf "If you get an error that starts with xcrun: error: invalid active developer path... you can fix this by pressing [control]+c to quit this script and type xcode-select --install into your command line and follow the install instructions to clear this error.  Some mac updates don\'t include XCRUN." ; echo " "
        source activate $qiimeenvironment
        echo "QIIME activated..."
    fi
}



#	Load feature table
asktable () {
printf "The feature table being loaded is $BLUE $featuretablename $NC. Do you need to re-load a different featuretable? Enter $RED [yes] $NC or $RED [no] $NC?"; read -p "" reload
echo "You entered $reload"
	if [ $reload = "yes" ]; 
		then
			#print available feature tables & then ask which they would like to use
			while true; do 
            shopt -s nullglob
            tablearray=(${datasetname}/data/*table*)
            tablenum=0
            for t in ${tablearray[@]}; do
                ((tablenum++))
                echo "[${tablenum}] ${t}"
            done
            
            printf "${RED}What feature table would you like to load? ${NC}Enter the number before the option."
            read -p " " featuretablenum
            ((featuretablenum=featuretablenum-1))
            printf "You chose ${BLUE}${tablearray[featuretablenum]}${NC}. If correct, enter ${RED}[yes]${NC}. If incorrect, press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
            read -p " " tablecorrect
            featuretablename=${tablearray[featuretablenum]##*/} #only gets expression after last slash
            [[ "$tablecorrect" == "yes" ]] && break || echo "Oops! Try again." 
            done
			printf "Your feature table is ${BLUE} $featuretablename ${NC}."
            echo
	else
		echo "Your feature table filename will be carried forward."
	fi
}


#	Taxa collapse
taxacollapse () {
        printf "What level of taxa collapse would you like to test? ${RED}Enter: Integer 1-9${NC}?"
        read -p " " taxalevel

qiime taxa collapse \
        --i-table $datasetname/data/${featuretablename} \
        --i-taxonomy $datasetname/data/dada2/taxonomy.qza \
        --p-level ${taxalevel} \
        --o-collapsed-table ${datasetname}/data/${featuretablename%.qza}-taxa${taxalevel}-collapsed.qza
        echo "Collapsed table created."
}



#	Check sampling depth - opens the feature table to help user decide what depth they would like to use. ***Requires that a
#	feature table is already loaded***.

asksamplingdepth () {
printf "We are opening a visualization of: $BLUE $featuretablename $NC. Use this to decide what $BLUE SAMPLING DEPTH $NC you would like to use."
        [ -f ${datasetname}/visualization/${featuretablename%.qza}.qzv ] && exists=yes || exists=no
        echo $exists

	    if [ $exists = "yes" ]; 
		    then
			    echo "Report already exists, we don't need to make a new one. Opening now."
		else
			echo "demux report does not exist. It's being made now. Please wait..."			
			qiime feature-table summarize \
  			--i-table ${datasetname}/data/${featuretablename} \
  			--o-visualization ${datasetname}/visualization/${featuretablename%.qza}.qzv \
  			--m-sample-metadata-file ${datasetname}/metadata/${metadatafile}
			echo "Feature table summary report created. Opening now!"
	    fi

        qiime tools view ${datasetname}/visualization/${featuretablename%.qza}.qzv

printf "The sampling depth you have been using is $BLUE $depth $NC.  Do you need to use a different 'depth'? Enter ${RED} [yes] ${NC} or ${RED} [no]?  ${NC}" ; read -p " " reload

echo "You entered $reload"
	if [ $reload = "yes" ]; then
		

        while true; do
            printf "For your analysis: $RED WHAT SAMPLING DEPTH WOULD YOU LIKE TO USE? $NC " ; read -p " " depth
            printf "You would like to subsample at a depth of $depth. If correct, enter ${RED}[yes]${NC}. If incorrect, press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
            read -p " " correct
            [[ "$correct" == "yes" ]] && break || printf "$RED Please re-enter sampling depth. $NC" 
        done
	else
		echo "Your sampling depth of $depth will be carried forward."
	fi
}

#	Get what metadata categories are available
categories () {
    forbreak=
    echo "List of categories in your metadata:"
    #head -1 ${datasetname}/metadata/$metadatafile #shows first line of metadata
    optionnum=0
    read -r -a firstline < ${datasetname}/metadata/$metadatafile
    for t in ${firstline[@]}; do
        ((optionnum++))
        echo "[${optionnum}] ${t}"
    done
    #function for subsets
    while true
        do
            printf "Which ${RED} category ${NC} would you like to use? Enter the number before the option."
            read -p " " category
            ((category=category-1))
            printf "You chose ${BLUE}${firstline[category]}${NC}. If correct, enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
            read -p " " categorycorrect
            category=${firstline[category]}
            [[ "$categorycorrect" == "yes" ]] && break || echo "Oops! Try again." 

    done
}


#	Builds heatmap
heatmap () {
qiime feature-table heatmap \
--i-table ${datasetname}/data/${featuretablename%.qza}-taxa${taxalevel}-collapsed.qza \
--m-sample-metadata-file ${datasetname}/metadata/${metadatafile} \
--m-sample-metadata-column $category \
--p-normalize \
--o-visualization ${datasetname}/visualization/${featuretablename%.qza}-${category}-taxa${taxalevel}-heatmap.qzv \
--p-method weighted
}


#	Barplot
#taxa bar plot
qiime_taxa_barplot () {
    echo "Creating taxa bar plot..."
    qiime taxa barplot \
    --i-table ${datasetname}/data/${featuretablename} \
    --i-taxonomy $datasetname/data/dada2/taxonomy.qza \
    --m-metadata-file $datasetname/metadata/$metadatafile \
    --o-visualization ${datasetname}/visualization/${featuretablename%.qza}-taxabarplot.qzv
    echo "Taxa bar plot created."
}

askifsubset () {
printf "Are you working on a $BLUE subsetted table? $RED [yes] $NC or $RED [no] $NC" ; read -p " " check
if [ $check = "yes" ];
	then
		echo "We need to load the right folder with your distance matrices!"
		printf "What $BLUE core metrics $NC folder corresponds to the subsetted file you want to work with?"
		echo "..."
		echo "Available core metrics folders will be shown below:"
		ls -1 $datasetname/data/*core*
		printf "Enter the $BLUE core metrics folder $NC that corresponds with your subsetted table" ; read -p " " subsetfolder
	else
		subsetfolder=core-metrics-results
	fi
}

#	Parameter tuning?
parametertuning () {
printf "Do you want to $BLUE Automatically tune hyperparameters using random grid search ${NC}? (default: no) Enter ${RED}[yes]${NC} or ${RED}[no]${NC}"; read -p " " tuningcheck

if [ $tuningcheck = "yes" ];
	then
		parametertuning="--p-parameter-tuning"
	else
		parametertuning="--p-no-parameter-tuning"
fi
}

#	What is the column that contains unique ID from metadatafile?
askuniqueidcolumn () {
printf "Which column contains your $BLUE UNIQUE INDIVIDUAL IDENTIFIERS $NC? This is the metadata column that tracks what $BLUE individual $NC each sample originates from."
 echo "List of categories in your metadata:"
    head -1 ${datasetname}/metadata/${metadatafile}
    while true
        do
            printf "Which ${RED} category ${NC} contains your $BLUE unique individual identifier?"
            read -p " " categoryuniqueid
            printf "You chose ${BLUE} $categoryuniqueid ${NC}. If correct, enter ${RED}[yes]${NC}. If incorrect, press ${RED}[SPACEBAR] then [enter] key${NC}."
            read -p " " check
            [[ "$check" == "yes" ]] && break || echo "Oops! Try again." 

    done
}

#	What is the column that contains state comparisons?
askstate () {
printf "Which column contains which $BLUE COMPARISONS $NC you would like to make [aka the state column]? This is the metadata column that QIIME will use to make comparisons from. These values $BLUE must be numeric. $NC"
 echo "List of categories available in your metadata:"
    head -1 ${datasetname}/metadata/${metadatafile}
    while true
        do
            printf "Which ${RED} category ${NC} contains your $BLUE metadata state you want to make comparisons with?"
            read -p " " categorystate
            printf "You chose ${BLUE} $categorystate ${NC}. If correct, enter ${RED}[yes]${NC}. If incorrect, press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
            read -p " " check
            [[ "$check" == "yes" ]] && break || echo "Oops! Try again." 

    done
}

askoutputdir () {
#	ASK: Output directory name?
while
printf "What do you want to $BLUE name the folder for these outputs ${NC}? ${RED} Enter your desired folder output name${NC}"; read -p " " outputfolder
printf "Your output folder is called: $BLUE $outputfolder $NC. If correct enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
		read -p ": " check && [[ -z "$check" ]]
do
	printf "Please re-enter output folder name"
done
}

askfeaturecount () {
printf "What is the feature limit that would you like to use for this analysis?"
	while true
        do
            printf "Enter a ${RED} numerical value greater than 0 ${NC} to specify how many features you would like to analyze?"
            read -p " " featurecount
            printf "You chose ${BLUE} $featurecount ${NC}. If correct, enter ${RED}[yes]${NC}. If incorrect, press ${RED}[SPACEBAR] then [enter] key${NC}."
            read -p " " check
            [[ "$check" == "yes" ]] && break || echo "Oops! Try again." 

    done
}

#	What scale would you like to use for y axis?
askyscale () {
printf "What scale would you like to use to produce your plots? Your choices are:
$RED [linear], [pow], [sqrt], [log] $NC"
	while true
        do
            printf "Enter your ${RED} selection, options shown above ${NC} to specify your scale?"
            read -p " " yscaleis
            printf "You chose ${BLUE} $yscaleis ${NC}. If correct, enter ${RED}[yes]${NC}. If incorrect, press ${RED}[SPACEBAR] then [enter] key${NC}."
            read -p " " check
            [[ "$check" == "yes" ]] && break || echo "Oops! Try again." 

    done
}

askrelativefrequency () {
printf "Is the feature table you are using a $BLUE RELATIVE FREQUENCY $NC table? $RED [1] $NC - yes $NC or $RED [2] $NC - no. If unsure, select [2] for no." ; read -p "" relativefrequency
while
printf "You chose $relativefrequency. If correct enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
	read -p " " check && [[ -z "$check" ]]
	do
		printf "Please re-enter your $BLUE selection $NC"
	done

echo "Your plot will be output into the folder containing your feature_importance.qza file: ${dirPath}"

echo "$relativefrequency"

if [ ${relativefrequency} == 1 ]
then
echo "No need to build a relative frequency table, proceeding"
fi

if [ ${relativefrequency} == 2 ]
then
echo "Building a relative frequency table for this analysis"

qiime feature-table relative-frequency \
--i-table $datasetname/data/$featuretablename \
--o-relative-frequency-table $datasetname/data/${featuretablename%.qza}-relative-frequency.qza 
fi
}
