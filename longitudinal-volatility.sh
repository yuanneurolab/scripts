#Matt
#Calvin 02/24/21
. scripts/set-opening.sh

echo "We are preparing to analyze feature volatility.  This requires a longitudinal study design!"

printf "$BLUE Specify what analysis you would like to run from the options below $NC: \n"
printf "$RED [1] $NC Measure feature volatility while making volatility plot \n"
printf "$RED ${bold}[2] $NC Measure feature volatility with volatility plot. Also creates an additional specialized plot with options to change y-scale. ${normal} \n"
printf "$RED [3] $NC Create volatility plot using existing feature volatility importance reference file. \n"
printf "Please enter your selection, $RED 1-3 $NC:  " ; read -p " " selection

askdatasetname
askmetadata
askqiime
asktable
askoutputdir

featurevolatility () {
rm -r $datasetname/data/${outputfolder}/
qiime longitudinal feature-volatility \
--i-table $datasetname/data/$featuretablename \
--m-metadata-file $datasetname/metadata/$metadatafile \
--p-state-column $categorystate \
--p-individual-id-column $categoryuniqueid \
$parametertuning \
--p-feature-count $featurecount \
--output-dir $datasetname/data/${outputfolder}/

qiime metadata tabulate \
--m-input-file $datasetname/data/${outputfolder}/filtered_table.qza \
--o-visualization $datasetname/visualization/feature_importance_filtered_table.qzv

}

volatilityplot () {
rm -r $datasetname/data/plot-${outputfolder}/
qiime longitudinal plot-feature-volatility \
--i-table $datasetname/data/${outputfolder}/filtered_table.qza \
--m-metadata-file $datasetname/metadata/$metadatafile \
--i-importances $datasetname/data/${outputfolder}/feature_importance.qza \
--p-state-column $categorystate \
--p-individual-id-column $categoryuniqueid \
--p-yscale $yscaleis \
--p-feature-count $featurecount \
--output-dir $datasetname/data/plot-${outputfolder}/
}

if [ $selection == 1 ]
then 
echo "Measure feature volatility."
parametertuning
askuniqueidcolumn
askstate
askfeaturecount
featurevolatility
fi

if [ $selection == 2 ] 
then 
echo "Measure feature volatility with specialized plot"
parametertuning
askuniqueidcolumn
askstate
askfeaturecount
askyscale

featurevolatility
volatilityplot
fi

if [ $selection == 3 ]
then
while
	printf "Please enter the $BLUE *ENTIRE* $NC filepath to your remote $BLUE feature_importance.qza file $NC. $RED Enter filepath: $NC" ; read -p "" featureimportancepath
	printf "Filepath to feature_importance.qza file you would like to use is $BLUE $featureimportancepath $NC.  If correct, enter ${RED}[yes]${NC}. If incorrect, press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
	read -p " " check && [[ -z "$check" ]]
	do
		printf "Please re-enter your $BLUE filepath. \n $NC"
	done
echo "$featureimportancepath"
dirPath=${featureimportancepath%/*}/
echo "$dirPath"

while
		printf "Please enter the $BLUE *ENTIRE* $NC filepath to your remote $BLUE filtered-table.qza file $NC. $RED Enter filepath: $NC" ; read -p "" filteredtablepath
	printf "Filepath to feature_importance.qza file you would like to use is $BLUE $filteredtablepath $NC.  If correct, enter ${RED}[yes]${NC}. If incorrect, press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
	read -p " " check && [[ -z "$check" ]]
	do
		printf "Please re-enter your $BLUE filepath $NC"
	done
echo "$filteredtablepath"
dirPath2=${filteredtablepath%/*}/
echo "$dirPath2"

parametertuning
askuniqueidcolumn
askstate
askfeaturecount
askyscale
rm -r $datasetname/data/plot-${outputfolder}/
qiime longitudinal plot-feature-volatility \
--i-table $dirPath2 \
--m-metadata-file $datasetname/metadata/$metadatafile \
--i-importances $dirPath \
--p-state-column $categorystate \
--p-individual-id-column $categoryuniqueid \
--p-yscale $yscaleis \
--p-feature-count $featurecount \
--output-dir $datasetname/data/plot-${outputfolder}/
fi

saving_parameters () {
echo -e "	
	env | $qiimeenvironment
	metadata file | $metadatafile
	name | $datasetname
    feature table | $featuretablename
	parameter tuning | $tuningcheck
	category state | $categorystate
	unique ID category | $categoryuniqueid
	y-scale | $yscaleis
	feature limit | $featurecount
	output directory | ${outputfolder}| plot-${outputfolder}" > $datasetname-parameters/$featuretablename-longitudinal-volatility.txt

}
saving_parameters