#!/bin/bash
#Matt 20.12.05

. scripts/set-opening.sh

askdatasetname
askmetadata
askqiime
asktable
askoutputdir
rm -r $datasetname/visualization/$outputfolder

echo "We are going to assess what features can be used to classify your samples." 

#	for NCV: Ask number of estimators
askestimator () {
while
		printf "How many $BLUE estimators do you want to generate? [default = 100] $BLUE More estimators will improve accuracy but increase runtime ${NC}. ${RED}Enter numerical value [default is 100]. ${NC}"; read -p " " numberestimator
		printf "You are using ${BLUE} $numberestimator estimators ${NC}. If correct enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
		read -p ": " check && [[ -z "$check" ]]
	do
 		printf "Please re-enter desired number of estimators."
	done

}


#	Optimize feature selection?
optimizeselection () {
printf "Do you want to $BLUE Automatically optimize input feature selection using recursive feature elimination ${NC}? (default: no) Enter ${RED}[yes]${NC} or ${RED}[no]${NC}"; read -p " " optimizefeature

if [ $optimizefeature = "yes" ];
	then
		optimizefeatureselection="--p-optimize-feature-selection"
	else
		optimizefeatureselection="--p-no-optimize-feature-selection"
fi
}


#	What portion of the dataset for training?
trainingpercent () {
while
		printf "What portion $BLUE (decimal value between 0-1) of your samples would you like to EXCLUDE while training this classifier? (default: 0.2) ${RED}Enter decimal value 0-1: ${NC}"; read -p " " trainingpercent
		printf "Your training percent is ${BLUE} $trainingpercent ${NC}. Is this correct? If correct enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
		read -p ": " check && [[ -z "$check" ]]
	do
 		printf "Please re-enter desired percent to use for training. "
	done
}

#	Color palette?
colorpalette () {
printf "What $BLUE color palette ${NC} would you like to use? Shown below are the color palette choices:"
echo "..."
printf "'YellowOrangeBrown', 'YellowOrangeRed',
    'OrangeRed', 'PurpleRed', 'RedPurple', 'BluePurple', 'GreenBlue',
    'PurpleBlue', 'YellowGreen', 'summer', 'copper', 'viridis', 'cividis',
    'plasma', 'inferno', 'magma', 'sirocco', 'drifting', 'melancholy',
    'enigma', 'eros', 'spectre', 'ambition', 'mysteriousstains', 'daydream',
    'solano', 'navarro', 'dandelions', 'deepblue', 'verve', 'greyscale'"
echo "..."
printf "${RED}Enter your palette choice${NC} (default: sirocco). "; read -p " " paletteoption
}

optimizedprint () {
echo "This will show you what features were selected as most important."
qiime metadata tabulate \
--m-input-file $datasetname/visualization/$outputfolder/feature_importance.qza \
--o-visualization $datasetname/visualization/$outputfolder/feature_importance
echo "If you want to know what features were most important in your optimized model, open this file. "
}


predictionsprint () {
echo "Building predictions."
qiime metadata tabulate \
--m-input-file $datasetname/visualization/$outputfolder/predictions.qza \
--o-visualization $datasetname/visualization/$outputfolder/predictions
echo "This file shows you the individual class probabilities."
}

probabilitiesprint () {
echo "Building probabilities visualization."
qiime metadata tabulate \
--m-input-file $datasetname/visualization/$outputfolder/probabilities.qza \
--o-visualization $datasetname/visualization/$outputfolder/probabilities.qzv
echo "This file shows you what features are most predictive of your target metadata category, which in this case was $category."
}



#	***	***	***	***	TRAIN classifier ***	***	***	***	***	***	***
trainclassifier () {
	echo "You are interested in training a classifier with one dataset and testing it on another."
		askestimator
		categories
		optimizeselection
		parametertuning
		trainingpercent
		colorpalette
		
		# Runs QIIME without option to add a remote classifier
		qiime sample-classifier classify-samples \
		--i-table $datasetname/data/$featuretablename \
		--m-metadata-file $datasetname/metadata/$metadatafile \
		--m-metadata-column $category \
		--output-dir $datasetname/visualization/$outputfolder/ \
		$optimizefeatureselection \
		$parametertuning \
		--p-palette $paletteoption \
		--p-test-size "$trainingpercent"

		optimizedprint
		predictionsprint
		probabilitiesprint
}

#	***	***	***	***	NCV classifier 	***	***	***	***	***	***	***
ncvclassifier () {
	askestimator
	categories
	parametertuning
	optimizefeature="N/A"
	trainingpercent ="N/A"
	paletteoption="N/A"

	qiime sample-classifier classify-samples-ncv \
	--i-table $datasetname/data/$featuretablename \
	--m-metadata-file $datasetname/metadata/$metadatafile \
	--m-metadata-column $category \
	--p-n-estimators $numberestimator \
	--output-dir $datasetname/visualization/$outputfolder/

		qiime metadata tabulate \
		--m-input-file $datasetname/visualization/$outputfolder/probabilities.qza \
		--o-visualization $datasetname/visualization/$outputfolder/probabilities-tabulated.qzv
		
		qiime metadata tabulate \
		--m-input-file $datasetname/visualization/$outputfolder/predictions.qza \
		--o-visualization $datasetname/visualization/$outputfolder/predictions-tabulated.qzv

		qiime metadata tabulate \
		--m-input-file $datasetname/visualization/$outputfolder/feature_importance.qza \
		--o-visualization $datasetname/visualization/$outputfolder/feature_importance-tabulated.qzv

}

#	***	***	***	***	TEST remote classifier 	***	***	***	***	***	***	***
testclassifier() {	
	while
		printf "Please enter the $BLUE *ENTIRE* $NC filepath to your remote sample classifier that you trained using another dataset. $RED Enter filepath: $NC" ; read -p "" classifierpath
	printf "Your classifier path is $BLUE $classifierpath $NC.  If correct enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
	read -p " " check && [[ -z "$check" ]]
	do
		printf "Please re-enter your $BLUE filepath $NC."
	done

		qiime sample-classifier predict-classification \
		--i-table $datasetname/data/$featuretablename \
		--output-dir $datasetname/visualization/$outputfolder/ \
		--i-sample-estimator $classifierpath

		qiime metadata tabulate \
		--m-input-file $datasetname/visualization/$outputfolder/predictions.qza \
		--o-visualization $datasetname/visualization/$outputfolder/predictions-tabulated.qzv

		qiime metadata tabulate \
		--m-input-file $datasetname/visualization/$outputfolder/probabilities.qza \
		--o-visualization $datasetname/visualization/$outputfolder/probabilities-tabulated.qzv
}


	
#	Ask the question and run the commands
printf "Classifiers can perform one of 3 tasks. $BLUE ENTER THE NUMERICAL OF THE ANALYSIS YOU WOULD LIKE TO PERFORM $NC Your options are: \n"
printf "$RED [1] $NC TRAIN classifier \n"
printf "^You would do this to train a classifier to one dataset and test it on another \n"
printf "$RED [2] $NC TEST remote classifier trained on a different dataset $NC \n"
printf "^You would do this to test a classifier that you trained from a different dataset \n"
printf "$RED [3] $NC TEST & TRAIN a classifier on the same dataset $NC \n"
printf "^You would do this if you wanted to construct a testing and training classifier on the same dataset using QIIME classify samples NCV \n"
echo "..."
echo "..."
printf "Please enter the $RED numeric value $NC of the analysis you would like to pursue." ; read -p " " choice


#train classifier
if [ $choice == 1 ]
then
	classifieroption="train classifier"
	classifierpath="N/A"
	echo $classifieroption
	trainclassifier
fi

#test remote classifier
if [ $choice == 2 ]
then
	classifieroption="test classifier"
	classifierpath="N/A"
	echo $classifieroption
	testclassifier
fi


#run NCV classifier
if [ $choice == 3 ]
then
	classifieroption="ncv classifier"
	echo $classifieroption
	ncvclassifier
fi

saving_parameters () {
echo -e "	
	env | $qiimeenvironment
	metadata file | $metadatafile
	name | $datasetname
    feature table | $featuretablename
	classifier option | $classifieroption
	estimators | $numberestimator
	parameter tuning | $tuningcheck
	category state | $categorystate
	training percent | $trainingpercent
	color palette | $paletteoption
	tested classifier | $classifierpath
	output directory | ${outputfolder}" > $datasetname-parameters/$featuretablename-sample-classifier.txt

}