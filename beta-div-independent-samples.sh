#!/bin/bash
#Run setup scripts
. scripts/set-opening.sh
askdatasetname
askmetadata
askqiime
asktable
asksamplingdepth
askifsubset
categories

#	ANCOM * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
test_ANCOM () {
unset $check
printf "Would you like to run ANCOM on a taxa collapsed file? Enter $RED [yes] $NC or $RED [no] $NC?"
read -p " " check
if [ $check = "yes" ];
	then
	taxacollapse #output is ${datasetname}/data/${featuretablename}.qza collapsed table
	qiime composition add-pseudocount \
    		--i-table ${datasetname}/data/${featuretablename%.qza}-taxa${taxalevel}-collapsed.qza \
    		--o-composition-table ${datasetname}/data/${featuretablename%.qza}-comp-taxa${taxalevel}

	qiime composition ancom \
   		--i-table ${datasetname}/data/${featuretablename%.qza}-comp-taxa${taxalevel}.qza \
    		--m-metadata-file $datasetname/metadata/$metadatafile \
    		--m-metadata-column $category \
    		--o-visualization $datasetname/visualization/${featuretablename%.qza}-$taxalevel-ANCOM.qzv
	else
	qiime composition add-pseudocount \
    		--i-table ${datasetname}/data/${featuretablename} \
    		--o-composition-table ${datasetname}/data/${featuretablename%.qza}-comp.qza
	qiime composition ancom \
   		--i-table ${datasetname}/data/${featuretablename%.qza}-comp.qza \
    		--m-metadata-file $datasetname/metadata/$metadatafile \
    		--m-metadata-column $category \
    		--o-visualization $datasetname/visualization/${featuretablename%.qza}-ANCOM.qzv
	fi
}
echo "Gathering ANCOM data."
test_ANCOM
echo "ANCOM test complete."

test_group_significance () {
#	GROUP SIGNIFICANCE  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
	printf "Now we are running a $BLUE group significance $NC comparison between your samples for $BLUE $category$NC category." 
	qiime diversity beta-group-significance \
  		--i-distance-matrix $datasetname/data/${subsetfolder}/weighted_unifrac_distance_matrix.qza \
  		--m-metadata-file $datasetname/metadata/$metadatafile \
  		--m-metadata-column $category \
  		--o-visualization ${datasetname}/visualization/${subsetfolder}-group-significance.qzv \
  		--p-pairwise
}
echo "Gathering group significance data."
test_group_significance
echo "Group significance testing complete."

#	ADONIS * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
printf "Now we are running an $BLUE ADONIS $NC test between your metadata categories."
echo "..."
printf "You will need to enter the $BLUE formula $NC you would like to use to make this comparison using metadata column headers as your variables."
printf "$BLUE The comparisons that you can make using the metadata file $metadatafile are: $NC"
head -1 ${datasetname}/metadata/${metadatafile}
echo "..."
printf "Enter the equation as: var1+var2 to explore the effects of var1 and var2 on phylogenetic distance."
echo "..."
echo "Example: "
echo "time+location"
echo "..."
printf "If you are interested in $BLUE interactions $NC between your variables use an asterisk $BLUE '*' $NC while specifying your equation.  To explore the interaction between var1 and var2 on weighted phylogenetic distance you would enter:"
echo " "
printf "$BLUE var1*var2 $NC"
echo "..."
printf "Now, $RED enter the formula you would like to test: $NC" ; read -r -p " " ADONISformula

qiime diversity adonis --i-distance-matrix $datasetname/data/${subsetfolder}/weighted_unifrac_distance_matrix.qza --m-metadata-file $datasetname/metadata/$metadatafile --p-formula "$ADONISformula" --o-visualization $datasetname/visualization/${subsetfolder}-"$ADONISformula".qzv

saving_parameters () {
echo -e "	
	env | $qiimeenvironment
	metadata file | $metadatafile
	name | $datasetname
    feature table | $featuretablename
	core-subset-folder | ${subsetfolder}
	ANCOM | category: $category | taxa level: $taxalevel
	beta group significance | category: $category
	ADONIS | $ADONISformula" > $datasetname-parameters/$featuretablename-beta-diversity.txt

}
saving_parameters