#!/bin/bash
#Set colors for your scripts
# No Color

#README- This command will create directory that includes data subset of user's choice based on metadata. Includes feature table and folders. 
 
#resetting arrays 
unset subset_array
unset new_subset_array
unset qiime_pwhere_array
unset category_array
unset allsampleID_array
unset sampleID_array
unset incorrect_array
unset new_array


echo "README: This command will create a data subset based on the metadata choosing. Includes feature table and folders. "
echo

#project name
projectname () {
while true
do
    read -p "Enter your dataset name: " datasetname
	echo "Your project name is $datasetname."
    read -p "If correct, enter 'y'. If incorrect, enter [SPACEBAR]. " datasetnamecorrect
    [[ "$datasetnamecorrect" == "y" ]] && break || echo "Please re-enter project name."
done
}

#metadata file
metadata () {
while true
do
	echo "The metadata files for this project are "; ls ${datasetname}-whole-dataset/metadata 
    read -p "Enter metadata file: " metadatafile
    read -p "If correct, enter 'y'. If incorrect, enter [SPACEBAR]. " metadatafilecorrect
    [[ "$metadatafilecorrect" == "y" ]] && break || echo "Please re-enter metadata file name." 
done
}

# #Asking user for options to filter things. 
askfilteringoptions () {
while true
do
    echo "Here are the filtering options:"
    echo "Sample ID"
    echo "Metadata Categories"
    read -p "Which would you like to filter by? " filteringoption
    filteringoption=$(echo "${filteringoption}" | tr '[:upper:]' '[:lower:]')
    if [[ $filteringoption == sam* ]]
        then filteringoption="Sample ID"
    elif [[ $filteringoption == meta* ]]
        then filteringoption="Metadata Categories"
    fi
    read -p "You chose '${filteringoption}'. If correct, enter 'y'. If incorrect, enter [SPACEBAR]. " filteringoptioncorrect
        [[ "$filteringoptioncorrect" == "y" ]] && break || echo "Please re-enter your filtering option."
done
}

#function for creating subsets based on metadata categories
subset_array=()
qiime_pwhere_array=()
categories () {
    echo "List of categories in your metadata:"
    head -1 ${datasetname}-whole-dataset/metadata/$metadatafile

    #function for subsets
    while true
        do
            read -p "In which category would you like to create a data subset? " category
            printf "You chose $category."
            echo 
            read -p "If correct, enter 'y'. If incorrect, enter [SPACEBAR]. " categorycorrect
            [[ "$categorycorrect" == "y" ]] && break || echo "Oops! Try again." 

    done


    #gets index index_categ in category user entered
    index_categ=0 
    read -r -a firstline < ${datasetname}-whole-dataset/metadata/$metadatafile
    for t in ${firstline[@]}; do
        ((index_categ++))
        [[ "$t" == "$category" ]] && break || continue
    done

    #gets list of unique values under categories and number of unique values
    err_rows=0
    while IFS= read -r line; do 
        line=$(echo "${line}" | tr '[:upper:]' '[:lower:]')
        if [[ $line == sample* ]] || [[ $line == *q2* ]]; then
            ((err_rows++))
        else
            break
        fi
    done < ${datasetname}-whole-dataset/metadata/$metadatafile

    local category_array=() 
    while IFS= read -r line ; do
            category_array+=( "$line" )
    done < <( sed "1,${err_rows}d" ${datasetname}-whole-dataset/metadata/$metadatafile | cut -f $index_categ | sort -u )
    
    
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
        echo "You chose $subset." 
        read -p "If correct, enter 'y'. If incorrect, enter [SPACEBAR]. " subsetcorrect
        if [[ "$subsetcorrect" == "y" ]]; then
            for word in ${subset_array[@]}; do
                if [[ "$word" == "$subset" ]]; then
                    echo "You already chose that subset. Choose another one."
                    break 2
                fi
            done
            subset_array+=( "${subset}" )
            qiime_pwhere_array+=("\"${category}\"='${subset}'")
            break
        else
            echo "Oops! Try again." 
        fi
    done
    echo "These are the subsets that you have chosen: "
    echo ${subset_array[@]}
    read -p "Are those all the subsets you would like? If yes, enter 'y'. If not, enter [SPACEBAR]. " subsetanswer
    arraycount=0
    if [[ "$subsetanswer" == "y" ]]; then
        forbreak=1
    else
        echo "Looking for more subsets..."
    fi
}

#Asking p-where inputs
pwheresubset () {
    unset qiime_pwhere_string
    new_subset_array=()
    echo "These are the subsets and categories you have chosen: "
    echo "${qiime_pwhere_array[@]}"
    echo "Expressions can be combined together using the following keywords: "
    echo "'AND': Returns samples where all parameters must be true."
    echo "'OR': Returns samples where either of the parameters are true."
    echo "'NOT': Negates expression. "
    echo "Example: Subject='subject-1' AND NOT BodySite='gut' retain only the samples whose Subject is subject-1 and whose BodySite is not gut"
    while true; do
        qiime_pwhere_string=""
        echo "${qiime_pwhere_array[0]}" 
        read -p "To add negating qualifier to above parameter, enter 'NOT'. If no, enter [SPACEBAR]. " NOT
        if [[ ! -z "$NOT" ]]; then
            NOT="NOT "
            new_subset_array[0]="NO${subset_array[0]}"
        else
            NOT=""
            new_subset_array[0]="${subset_array[0]}"
        fi
        qiime_pwhere_string="$NOT""${qiime_pwhere_array[0]}"
        
        if [[ ${#qiime_pwhere_array[@]} > 1 ]]; then
            for ((i = 1; i < ${#qiime_pwhere_array[@]}; i++))
            do
                echo "${qiime_pwhere_array[i]}" 
                read -p "To add negating qualifier to above parameter, enter 'NOT'. If no, enter [SPACEBAR]. " NOT
                if [[ ! -z "$NOT" ]]; then
                    NOT=" NOT "
                    new_subset_array[i]="NO${subset_array[i]}"
                else  
                    NOT=" "
                    new_subset_array[i]="${subset_array[i]}"
                fi  
                echo "${qiime_pwhere_array[i-1]}    "${qiime_pwhere_array[i]}"" 
                while true; do
                    read -p "Enter 'AND' or 'OR' to select parameter combination to filter samples for the above expressions. " logical
                    logical=$(echo "${logical}" | tr '[:lower:]' '[:upper:]')
                    [[ ${logical} != 'AND' && ${logical} != 'OR' ]] && echo "You did not enter 'AND' or 'OR'." || break
                done
                qiime_pwhere_string+=" ${logical}${NOT}${qiime_pwhere_array[i]}"
            done
        fi
        qiime_pwhere_string="$(echo -e "${qiime_pwhere_string}" | sed -e 's/^[[:space:]]*//')"
        echo "This is your combined parameter:"
        echo "${qiime_pwhere_string}" 
        read -p "Is this correct? If yes, enter 'y'. Otherwise, enter [SPACEBAR]. " parametercorrect
        if [[ "$parametercorrect" == "y" ]]; then
            if [[ ${#qiime_pwhere_array[@]} > 1 && ${qiime_pwhere_string} != *AND* && ${qiime_pwhere_string} != *OR* ]]; then
                forbreak=1
            else
                break
            fi
        fi
        echo "Please re-enter parameters."
    done
    subset_array_name=$(IFS=-, ; echo "${new_subset_array[*]}")
    subset_array_name=$(sed 's/ /_/g' <<< "${subset_array_name}") #substitues spaces within subset with underscore to be saved
    
}




#filtering sample IDs
individualID () {
    allsampleID_array=()
    sampleID_array=()

    while IFS= read -r line ; do
        allsampleID_array+=( "$line" )
    done < <( sed "1,2d" test1-whole-dataset/metadata/$metadatafile | cut -f 1 )   

    echo "This sample has ${#allsampleID_array[@]} samples."

    echo
    while true; do
        echo "List of samples: "

        for ((i = 0; i < ${#allsampleID_array[@]}; i++))
        do
            printf "${allsampleID_array[$i]}\t"
        done
        printf "Which individual sample IDs would you like to filter? Enter one at a time. Enter [SPACEBAR] when you are done." 
        echo
        while true; do
            read -p " " sampleID
                if [[ $sampleID == "" ]]; then
                    break
                else
                    for i in ${!sampleID_array[@]}; do
                    if [[ ${sampleID_array[i]} == $sampleID ]]; then
                        echo "You already selected ${sampleID_array[$i]}"
                        sampleID="" 
                    fi
                    done
                    if [[ $sampleID != "" ]]; then
                        sampleID_array+=( "$sampleID" )
                    fi       
                fi
        done
        echo "You have entered ${#sampleID_array[@]} sample IDs."
        echo "List of samples: "
        for ((i = 0; i < ${#sampleID_array[@]}; i++)); do
            printf "${sampleID_array[i]}\t"
        done
        echo
        printf "If you would like to remove a sample ID from the list, enter one at a time now. Otherwise, enter [SPACEBAR] when you are done."
        while true; do
            read -p " " removesampleID
            if [[ $removesampleID == "" ]]; then
                break
            else
                for i in ${!sampleID_array[@]}; do
                    if [[ ${sampleID_array[i]} == $removesampleID ]]; then
                        echo "You deleted ${sampleID_array[$i]}"
                        unset 'sampleID_array[$i]'
                    fi
                done
            fi
        done
        new_array="${sampleID_array[@]}"
        read -a sampleID_array <<< "${new_array[@]}"  
        unset new_array
        echo "You have entered ${#sampleID_array[@]} sample IDs."
        echo "List of samples: "
        for ((i = 0; i < ${#sampleID_array[@]}; i++)); do
            printf "${sampleID_array[$i]}\t"
        done
        echo
        read -p "Are you done adding and removing sample IDs to your filtered list? If yes, enter 'y'. If not, enter [SPACEBAR]. " filteredcorrect
            [[ $filteredcorrect == 'y' ]] && break 2
    done
}

#create metadata file for individual sample ID filtering
create_metadata () {
    now=$(date +'%m/%d/%Y')
    filecreatedname="${now//\//-}""samples-metadata"
    echo SampleID > "${filecreatedname}.txt"
    for i in ${sampleID_array[@]}; do
        echo $i >> "${filecreatedname}.txt"
    done
    echo "Metadata file created."
    mv "${filecreatedname}.txt" ${datasetname}-whole-dataset/metadata/
    echo "Metadata file moved."
}

#rechecks filtered sample list. If not OK, will restart process
rechecklist () {
    forbreak=
    incorrect_array=()
    for i in "${sampleID_array[@]}"; do
        incorrect=
        for j in "${allsampleID_array[@]}"; do
            [[ $i == $j ]] && { incorrect=1;break;}
        done
        [[ -n $incorrect ]] || incorrect_array+=("$i")
    done
    [[ ${#incorrect_array[@]}>0 ]] && echo "These samples are not in the listed sample IDs: ${incorrect_array[@]}. Please re-enter samples." || forbreak=1
}

# #Ask user about excluding options
exclude () {
    while true
    do
        read -p "Would you like to exclude or include these samples from the filtered data? " excludeoption
        excludeoption=$(echo "${excludeoption}" | tr '[:upper:]' '[:lower:]')
        if [[ $excludeoption == exc* ]]
            then excludeoption="exclude"
        elif [[ $excludeoption == inc* ]]
            then excludeoption="include"
        fi
        read -p "You chose '${excludeoption}' samples. If correct, enter 'y'. If incorrect, enter [SPACEBAR]. " excludeoptioncorrect
            [[ "$excludeoptioncorrect" == "y" ]] && break
    done
}

#Asking for original table file name. 
originaltable () {
    while true
    do
        echo "Here are all the tables in your project data folder"
        find ./${datasetname}-whole-dataset/data -name "*table*"
        read -p "What is the file name of the feature table you would like to filter? (Everything after the last '/'') " featuretablename
        printf "The feature table name is ${datasetname}-whole-dataset/data/$featuretablename. " 
        read -p "If correct, enter 'y'. If incorrect, enter [SPACEBAR]. " featuretablenamecorrect
        [[ "$featuretablenamecorrect" == "y" ]] && break || echo "Oops! Try again." 
    done
    if [[ $featuretablename != *.qza ]]; then 
        featuretablename+=".qza"
    fi
}

#activate QIIME
activateqiime () {
    read -p "If you have activated QIIME already, enter 'y'. If you have not, enter [SPACEBAR]. " qiimestatus
    if [[ "$qiimestatus" == "y" ]]; then forbreak=1
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
}

# #Visualing feature-table by filtering samples according to certain categories 
qiime_filter_categories () {
    subset_filtered_name_qza="${datasetname}-${subset_array_name}-$2-filtered-feature-table.qza"
    subset_filtered_name_qzv="${datasetname}-${subset_array_name}-$2-filtered-feature-table.qzv"
    qiime feature-table filter-samples \
        --i-table ${datasetname}-whole-dataset/data/$featuretablename \
        --m-metadata-file ${datasetname}-whole-dataset/metadata/$metadatafile \
        --p-where "${qiime_pwhere_string}" \
        $1 \
        --o-filtered-table ${datasetname}-whole-dataset/data/${subset_filtered_name_qza}

    echo "Filtered feature table created. "

    qiime feature-table summarize \
        --i-table ${datasetname}-whole-dataset/data/${subset_filtered_name_qza} \
        --o-visualization ${datasetname}-whole-dataset/visualization/${subset_filtered_name_qzv}

    echo "Filtered feature table visualization created. "
}

#Visualing feature-table by filtering samples according to sample ID 
qiime_filter_sampleID () {
    subset_filtered_name_qza="${datasetname}-${2}individualsamples-$3-filtered-feature-table.qza"
    subset_filtered_name_qzv="${datasetname}-${2}individualsamples-$3-filtered-feature-table.qzv"
    qiime feature-table filter-samples \
        --i-table ${datasetname}-whole-dataset/data/$featuretablename \
        --m-metadata-file ${datasetname}-whole-dataset/metadata/"${filecreatedname}.txt" \
        $1\
        --o-filtered-table ${datasetname}-whole-dataset/data/${subset_filtered_name_qza}

    echo "Filtered feature table created. "

    qiime feature-table summarize \
        --i-table ${datasetname}-whole-dataset/data/${subset_filtered_name_qza} \
        --o-visualization ${datasetname}-whole-dataset/visualization/${subset_filtered_name_qzv}

    echo "Filtered feature table visualization created. "
}

#Actual Command
projectname
metadata
askfilteringoptions
if [[ $filteringoption == "Sample ID" ]]; then
    while true; do
        individualID
        rechecklist
        [[ -n $forbreak ]] && break
    done
    exclude
    originaltable
    activateqiime
    create_metadata
    if [[ ${excludeoption} == "exclude" ]]; then
        (( excludeIDcount=${#allsampleID_array[@]}-${#sampleID_array[@]} ))
        qiime_filter_sampleID "--p-exclude-ids" "${excludeIDcount}" "excluded"
    elif [[ $excludeoption == "include" ]]; then
        qiime_filter_sampleID "" "${#sampleID_array[@]}" ""
    fi
elif [[ $filteringoption == "Metadata Categories" ]]; then
    while true; do
        categories
        [[ -n $forbreak ]] && break
    done
    pwheresubset
    echo
    exclude
    originaltable
    activateqiime
    if [[ $excludeoption == "exclude" ]]; then
        qiime_filter_categories "--p-exclude-ids" "excluded"
    elif [[ $excludeoption == "include" ]]; then
        qiime_filter_categories "" ""
    fi
fi
