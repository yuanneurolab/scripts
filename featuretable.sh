#!/bin/bash
#Set colors for your scripts
# No Color

#README- This command will create directory that includes data subset of user's choice based on metadata. Includes feature table and folders. 

#qiime feature-table summarize --i-table table.qza --o-visualization table.qzv --m-sample-metadata-file sample-metadata.tsv

#qiime feature-table tabulate-seqs --i-data rep-seqs.qza --o-visualization rep-seqs.qzv

#qiime feature-table filter-samples --i-table filtered-table-2SD.qza --m-metadata-file all_exp_metadata_revised080819.txt --p-where "ExperimentDate = '052018'" --o-filtered-table 		052018samples_featuretable.qza



#unsets variables used -     -     -     -     -     -     -     -     -     -     -     -     
	

echo "README: This command will create a data subset based on the metadata choosing. Includes feature table and folders. "

echo

echo "First, we need a metadata file name. Here is a current list of files in current directory."; ls




while true
do
	read -p "Enter metadata file name: " metadatafile
	printf "Your metadata file name is $metadatafile."
    echo 
    read -p "If correct, enter 'y'. If incorrect, enter [SPACEBAR]. " metadatafilecorrect
    [[ "$metadatafilecorrect" == "y" ]] && break || echo "Please re-enter metadata file name." 
done

#function for creating subsets
declare -a subset_array
categories () {
    echo "List of categories in your metadata:"
    head -1 $metadatafile

    #function for subsets
    while true
        do
            read -p "In which category would you like to create a data subset? " category
            printf "You chose $category."
            echo 
            read -p "If correct, enter 'y'. If incorrect, enter [SPACEBAR]. " categorycorrect
            [[ "$categorycorrect" == "y" ]] && break || echo "Oops! Try again." 

    done


    #gets index x in category user entered
    x=0 
    read -r -a firstline < $metadatafile
    for t in ${firstline[@]}; do
        ((x++))
        [[ "$t" == "$category" ]] && break || continue
    done

    #gets list of unique values under categories and number of unique values
    y=0
    while IFS= read -r line; do 
        if [[ ${line,,} == sample* ]] || [[ ${line,,} == *q2* ]]; then
            ((y++))
        else
            break
        fi
    done < $metadatafile

    #samplecount, unique values in category
    # samplecount=$(( $(wc -l < $metadatafile)-$y+1 )) #gives you number of lines in file
    # echo "There are $samplecount samples in this data. "

    category_array=() 
    while IFS= read -r line ; do
            category_array+=( "$line" )
    done < <( sed $y'd' $metadatafile | cut -f $x | sort -u )

    echo "This category "\'$category\'" has ${#category_array[@]} unique values."
    echo "List of unique values: "

    for ((i = 0; i < ${#category_array[@]}; i++))
    do
        echo ${category_array[$i]}
    done
    echo 

    #creating subset
    while true
    do
        read -p "Which of these would you like to create a data subset of? " subset
        printf "You chose $subset."
        echo 
        read -p "If correct, enter 'y'. If incorrect, enter [SPACEBAR]. " subsetcorrect
        if [[ "$subsetcorrect" == "y" ]]; then
            if [[ "${subset_array[@]}" =~ "$subset" ]]; then
                echo "You already chose that subset. Choose another one."
                break
            else
                subset_array+=( "${subset}" )
                break
            fi
        else
            echo "Oops! Try again." 
        fi
    done
}

while true
do
    categories 
    echo "These are the subsets that you have chosen: "
    echo ${subset_array[@]}
    read -p "Are those all the subsets you would like? If yes, enter 'y'. If not, enter [SPACEBAR]. " subsetanswer
    [[ "$subsetanswer" == "y" ]] && break || echo "Looking for more subsets."
done 


# #Asking for original table file name. 
while true
do
	ls #filedirectory
    read -p "What is the name of original table created in dada2? " featuretablename
	printf "The feature table name is $featuretablename."
    echo 
    read -p "If correct, enter 'y'. If incorrect, enter [SPACEBAR]. " featuretablenamecorrect
    [[ "$featuretablenamecorrect" == "y" ]] && break || echo "Oops! Try again." 
done
if [[ $featuretablename != *.qza ]]; then 
    featuretablename+=".qza"
fi

# #activate QIIME
read -p "If you have activated QIIME already, enter 'y'. If you have not, enter [SPACEBAR]. " qiimestatus
if [[ "$qiimestatus" == "y" ]]
then 
else
    while true; 
    do
	    echo "Available qiime packages are shown here. "
		conda env list  
        echo "Environment name likely found after '/env/...'" 
        read -p "What is your qiime environment name?  " qiimeenvironment
	    printf "My qiime environment name is $qiimeenvironment. " 
        read -p "If correct, enter 'y'. If incorrect, enter [SPACEBAR]. " qiimecorrect
        [[ "$qiimecorrect" == "y" ]] && break || echo "Oops! Try again." 
 	    echo "please re-enter qiime environment name"
    done

    echo "We are now activating your qiime environment"
    echo "..."
    printf "If you get an error that starts with xcrun: error: invalid active developer path... you can fix this by pressing [control]+c to quit this script and type xcode-select --install into your command line and follow the install instructions to clear this error.  Some mac updates don\'t include XCRUN." ; echo " "
    source activate $qiimeenvironment
    echo "QIIME activated..."
fi


# #Visualing feature-table by filtering samples according to certain categories 

qiime feature-table filter-samples \
    --i-table ${featuretablename} \
    --m-metadata-file $metadatafile \
    --p-where "[${category}] = '${subset}'" \
    --o-filtered-table placeholder.qza

echo "Filtered feature table created. "

qiime feature-table summarize \
    --i-table placeholder.qza
    --o-visualization placeholder.qzv

# filteredfolder=${filteredtablename%%.q*}
# mkdir $filteredfolder
