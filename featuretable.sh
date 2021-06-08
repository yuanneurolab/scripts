#!/bin/bash

. scripts/set-opening.sh
askdatasetname		#asks for dataset name
askmetadata		#asks for metadata name
askqiime		#asks to launch qiime or not
asktable		#asks for featuretable name

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


#	Asking user for options to filter things. 
askfilteringoptions () {
while true
do
    echo "Here are the filtering options:"
    echo "[1] Sample ID"
    echo "[2] Metadata Categories"
    printf "Which ${RED}option${NC} would you like to filter by? Enter the number before the option."
    read -p " " filteringoption
    if [[ $filteringoption == 1 ]]
        then filteringoption="Sample ID"
    elif [[ $filteringoption == 2 ]]
        then filteringoption="Metadata Categories"
    fi
    printf "You chose ${BLUE}'${filteringoption}'${NC}. If correct, enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
    read -p " " filteringoptioncorrect
        [[ "$filteringoptioncorrect" == "yes" ]] && break || echo "Please re-enter your filtering option."
done
}

#	function for creating subsets based on metadata categories
subset_array=()
qiime_pwhere_array=()
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
            printf "In which ${RED}category${NC} would you like to create a data subset? Enter the number before the option."
            read -p " " category
            ((category=category-1))
            printf "You chose ${BLUE}${firstline[category]}${NC}. If correct, enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
            read -p " " categorycorrect
            category=${firstline[category]}
            [[ "$categorycorrect" == "yes" ]] && break || echo "Oops! Try again." 

    done


    #gets index index_categ in category user entered
    index_categ=0 
    for t in ${firstline[@]}; do
        ((index_categ++))
        [[ "$t" == "$category" ]] && break || continue
    done

    #gets list of unique values under categories and number of unique values
    err_rows=0
    while IFS= read -r line; do #some metadata files have 1 row or 2 rows of metadata column headers
        line=$(echo "${line}" | tr '[:upper:]' '[:lower:]') 
        if [[ $line == sample* ]] || [[ $line == *q2* ]]; then
            ((err_rows++))
        else
            break
        fi
    done < ${datasetname}/metadata/$metadatafile

    local category_array=() 
    while IFS= read -r line ; do #deletes first 2 lines of metadata, gets unique values under certain metadata category 
            category_array+=( "$line" )
    done < <( sed "1,${err_rows}d" ${datasetname}/metadata/$metadatafile | cut -f $index_categ | sort -u )
    
    
    printf "This category ${BLUE}"\'$category\'"${NC} has ${RED}${#category_array[@]}${NC} unique values."
    echo
    echo "List of unique values: "
    optionnum=0
    for ((i = 0; i < ${#category_array[@]}; i++)); do
        ((optionnum++))
        echo "[$optionnum] ${category_array[$i]}"
    done
    echo 

    #creating subset
    while true
    do
        printf "Which of these ${RED}values${NC} would you like to create a data subset of? Enter the number before the option."
        read -p " " subset
        ((subset=subset-1))
        printf "You chose ${BLUE}${category_array[subset]}${NC}. If correct, enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
        subset=${category_array[subset]}
        read -p " " subsetcorrect
        if [[ "$subsetcorrect" == "yes" ]]; then
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
    printf "Are those all the subsets you would like? If correct, enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
    read -p " " subsetanswer
    arraycount=0
    if [[ "$subsetanswer" == "yes" ]]; then
        forbreak=1
    else
        echo "Looking for more subsets..."
    fi
}

#Asking p-where inputs
pwheresubset () {
    unset qiime_pwhere_string
    new_subset_array=()
    printf "These are the ${BLUE}subsets and categories${NC} you have chosen: \n"
    echo "${qiime_pwhere_array[@]}"
    echo "Expressions can be combined together using the following keywords: "
    printf "${RED}'and'${NC}: Returns samples where all parameters must be true.\n"
    printf "${RED}'or'${NC}: Returns samples where either of the parameters are true.\n"
    printf "${RED}'not'${NC}: Returns samples where parameter is not true\n"
    printf "Example: ${BLUE}Subject='subject-1' AND NOT BodySite='gut'${NC} retain only the samples whose Subject is subject-1 and whose BodySite is not gut.\n"
    while true; do
        qiime_pwhere_string=""
        echo "${qiime_pwhere_array[0]}" 
        printf "If you would like to return samples that do not include the above parameter, enter ${RED}[not]${NC}. If no, press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
        read -p " " NOT
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
                printf "If you would like to return samples that do not include the above parameter, enter ${RED}'not'${NC}. If no, press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
                read -p " " NOT
                if [[ ! -z "$NOT" ]]; then
                    NOT=" NOT "
                    new_subset_array[i]="NO${subset_array[i]}"
                else  
                    NOT=" "
                    new_subset_array[i]="${subset_array[i]}"
                fi  
                echo "${qiime_pwhere_array[i-1]}    "${qiime_pwhere_array[i]}"" 
                while true; do
                    printf "Enter ${RED}[and]${NC} or ${RED}[or]${NC} to select parameter combination to filter samples for the above expressions."
                    read -p " " logical
                    logical=$(echo "${logical}" | tr '[:lower:]' '[:upper:]')
                    [[ ${logical} != 'AND' && ${logical} != 'OR' ]] && echo "You did not enter ${RED}'and'${NC} or ${RED}'or'${NC}." || break
                done
                qiime_pwhere_string+=" ${logical}${NOT}${qiime_pwhere_array[i]}"
            done
        fi
        qiime_pwhere_string="$(echo -e "${qiime_pwhere_string}" | sed -e 's/^[[:space:]]*//')"
        echo "This is your combined parameter:"
        printf "${BLUE}${qiime_pwhere_string}${NC}\n" 
        printf "Is this correct? If yes, enter ${RED}[yes]${NC}. Otherwise, press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
        read -p " " parametercorrect
        if [[ "$parametercorrect" == "yes" ]]; then
            if [[ ${#qiime_pwhere_array[@]} > 1 && ${qiime_pwhere_string} != *AND* && ${qiime_pwhere_string} != *OR* ]]; then
                forbreak=1
            else
                break
            fi
        fi
        echo "Please re-enter parameters."
    done
    # subset_array_name=$(IFS=-, ; echo "${new_subset_array[*]}")
    # subset_array_name=$(sed 's/ /_/g' <<< "${subset_array_name}") #substitutes spaces within subset with underscore to be saved
    
}

#filtering sample IDs
individualID () {
    allsampleID_array=()
    sampleID_array=()
    #gets list of unique values under categories and number of unique values
    err_rows=0
    while IFS= read -r line; do #some metadata files have 1 row or 2 rows of metadata column headers
        line=$(echo "${line}" | tr '[:upper:]' '[:lower:]') 
        if [[ $line == sample* ]] || [[ $line == *q2* ]]; then
            ((err_rows++))
        else
            break
        fi
    done < ${datasetname}/metadata/$metadatafile

    local category_array=() 
    while IFS= read -r line ; do #deletes first 1 or 2 lines depending on where sample ID begins
            allsampleID_array+=( "$line" )
    done < <( sed "1,${err_rows}d" ${datasetname}/metadata/$metadatafile | cut -f 1  )

    echo "This sample has ${#allsampleID_array[@]} samples."

    echo
    while true; do
        echo "List of samples: "
        optionnum=0
        for ((i = 0; i < ${#allsampleID_array[@]}; i++))
        do
            ((optionnum++))
            printf "[$optionnum] ${allsampleID_array[$i]}\t"
        done
        echo
        printf "Which ${RED}individual sample IDs${NC} would you like to filter? Enter the number before the option. Only enter one at a time. Press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key.\n" 
        while true; do
            read -p " " sampleIDoption
                if [[ $sampleIDoption == "" ]]; then
                    break
                else
                    for i in ${!sampleID_array[@]}; do
                    if [[ ${sampleID_array[i]} == ${allsampleID_array[$sampleIDoption]} ]]; then
                        printf "You already selected ${BLUE}${sampleID_array[$i]}${NC}\n"
                        sampleID="" 
                    fi
                    done
                    if [[ $sampleIDoption != "" ]]; then
                        sampleID_array+=( "${allsampleID_array[(( $sampleIDoption-1 ))]}" )
                    fi       
                fi
        done
        printf "You have entered ${BLUE}${#sampleID_array[@]}${NC} sample IDs.\n"
        echo "List of samples: "
        for ((i = 0; i < ${#sampleID_array[@]}; i++)); do
            printf "${sampleID_array[i]}\t"
        done
        echo
        printf "If you would like to ${RED}remove${NC} a sample ID from the list, enter one at a time now. Otherwise, press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key. Note: There are no numbered options. Enter entire sample ID to remove. "
        while true; do
            read -p " " removesampleID
            if [[ $removesampleID == "" ]]; then
                break
            else
                for i in ${!sampleID_array[@]}; do
                    if [[ ${sampleID_array[i]} == $removesampleID ]]; then
                        printf "You deleted ${BLUE}${sampleID_array[$i]}${NC}\n"
                        unset 'sampleID_array[$i]'
                    fi
                done
            fi
        done
        new_array="${sampleID_array[@]}"
        read -a sampleID_array <<< "${new_array[@]}"  
        unset new_array
        printf "You have entered ${BLUE}${#sampleID_array[@]}${NC} sample IDs."
        echo "List of samples: "
        for ((i = 0; i < ${#sampleID_array[@]}; i++)); do
            printf "${sampleID_array[$i]}\t"
        done
        echo
        printf "Are you done adding and removing sample IDs to your filtered list? If yes, enter ${RED}[yes]${NC}. If not, press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
        read -p " " filteredcorrect
            [[ $filteredcorrect == 'yes' ]] && break 2
    done
}

#	create metadata file for individual sample ID filtering
create_metadata () {
    now=$(date +'%m/%d/%Y')
    filecreatedname="${now//\//-}""samples-metadata"
    echo SampleID > "${filecreatedname}.txt"
    for i in ${sampleID_array[@]}; do
        echo $i >> "${filecreatedname}.txt"
    done
    echo "Metadata file created."
    mv "${filecreatedname}.txt" ${datasetname}/metadata/
    echo "Metadata file moved to $dataset/metadata."
}

#	rechecks filtered sample list. If not OK, will restart process
rechecklist () {
    forbreak=
    unset incorrect_array
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

#	Ask user about excluding options
exclude () {
    while true
    do
        printf "Would you like to ${RED}[1] exclude ${NC} or ${RED}[2] include${NC} these samples from the filtered data? Enter the number before the option." 
        read -p " " excludeoption
        # excludeoption=$(echo "${excludeoption}" | tr '[:upper:]' '[:lower:]')
        if [[ $excludeoption == 1 ]]
            then excludeoption="exclude"
        elif [[ $excludeoption == 2 ]]
            then excludeoption="include"
        fi
        printf "You chose to ${BLUE}'${excludeoption}'${NC} samples. If correct, enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
        read -p " " excludeoptioncorrect
            [[ "$excludeoptioncorrect" == "yes" ]] && break
    done
}

# #Visualing feature-table by filtering samples according to certain categories 
qiime_filter_categories () {
    # subset_filtered_name_qza="subset-${subset_array_name}-$2-filtered-table.qza"
    # subset_filtered_name_qzv="subset-${subset_array_name}-$2-filtered-table.qzv"
    while true; do
        echo "What would you like to name your new filtered feature-table? ('subset' and 'table' will be included into file name automatically) Make sure to include \".qza\" at the end of the your name."
        read -p " " filteredfeaturetable
        printf "You entered ${BLUE}'${filteredfeaturetable}'${NC}. If correct, enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
        read -p " " filteredfeaturetablecorrect
        [[ "$filteredfeaturetablecorrect" == "yes" ]] && break || echo "Re-enter name."
    done
    filteredfeaturetable="subset-"${filteredfeaturetable%.qza}"-table.qza"
    printf "Your filtered feature table name is called ${BLUE}$filteredfeaturetable${NC}"
    echo
    qiime feature-table filter-samples \
        --i-table ${datasetname}/data/$featuretablename \
        --m-metadata-file ${datasetname}/metadata/$metadatafile \
        --p-where "${qiime_pwhere_string}" \
        $1 \
        --o-filtered-table ${datasetname}/data/${filteredfeaturetable}

    echo "Filtered feature table created. "

    qiime feature-table summarize \
        --i-table ${datasetname}/data/${filteredfeaturetable} \
        --o-visualization ${datasetname}/visualization/${filteredfeaturetable%.qza}

    echo "Filtered feature table visualization created. "
}

#Visualing feature-table by filtering samples according to sample ID 
qiime_filter_sampleID () {
    # subset_filtered_name_qza="subset-${2}individualsamples-$3-filtered-table.qza"
    # subset_filtered_name_qzv="subset-${2}individualsamples-$3-filtered-table.qzv"
    while true; do
        echo "What would you like to name your new filtered feature-table? ('subset' and 'table' will be included into file name automatically) Make sure to include \".qza\" at the end of the your name."
        read -p " " filteredfeaturetable
        printf "You entered ${BLUE}'${excludeoption}'${NC}. If correct, enter ${RED}[yes]${NC}. If incorrect press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
        read -p " " filteredfeaturetablecorrect
        [[ "$filteredfeaturetablecorrect" == "yes" ]] && break || echo "Re-enter name."
    done
    filteredfeaturetable="subset-"${filteredfeaturetable%.qza}"-table.qza"
    printf "Your filtered feature table name is called ${BLUE}$filteredfeaturetable${NC}"
    echo
    qiime feature-table filter-samples \
        --i-table ${datasetname}/data/$featuretablename \
        --m-metadata-file ${datasetname}/metadata/"${filecreatedname}.txt" \
        $1\
        --o-filtered-table ${datasetname}/data/${filteredfeaturetable}

    echo "Filtered feature table created. "

    qiime feature-table summarize \
        --i-table ${datasetname}/data/${filteredfeaturetable} \
        --o-visualization ${datasetname}/visualization/${filteredfeaturetable%.qza}

    echo "Filtered feature table visualization created. "
}

qiime_visualizations () {
    echo "Opening visualizations..."
    qiime tools view ${datasetname}/visualization/${filteredfeaturetable%.qza}.qzv
}

#Actual Command
askfilteringoptions
if [[ $filteringoption == "Sample ID" ]]; then
    while true; do
        individualID
        rechecklist
        [[ -n $forbreak ]] && break
    done
    exclude
    create_metadata
    if [[ ${excludeoption} == "exclude" ]]; then
        (( excludeIDcount=${#allsampleID_array[@]}-${#sampleID_array[@]} ))
        excludeoutput="${excludeIDcount} samples excluded"
        qiime_filter_sampleID "--p-exclude-ids" 
    elif [[ $excludeoption == "include" ]]; then
        qiime_filter_sampleID ""
    fi
    
elif [[ $filteringoption == "Metadata Categories" ]]; then
    while true; do
        categories
        [[ -n $forbreak ]] && break
    done
    pwheresubset
    echo
    exclude
    if [[ $excludeoption == "exclude" ]]; then
        qiime_filter_categories "--p-exclude-ids"
    elif [[ $excludeoption == "include" ]]; then
        qiime_filter_categories ""
    fi
    
fi

featuretablename=${filteredfeaturetable}
asksamplingdepth

echo "Building your core metrics file for this subset"
qiime diversity core-metrics-phylogenetic \
  --i-phylogeny ${datasetname}/data/dada2/rooted-tree.qza \
  --i-table ${datasetname}/data/${filteredfeaturetable} \
  --p-sampling-depth $depth \
  --m-metadata-file ${datasetname}/metadata/$metadatafile \
  --output-dir ${datasetname}/data/core-${filteredfeaturetable%.qza}

echo "Your core metrics folder is ready for you, this is where you will find your distance matrices for this data subset."

# - - - Print  parameters - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
parameters () {
    echo -e "	
	env | $qiimeenvironment
	metadata file | $metadatafile
	name | $datasetname
	subset option | $filteringoption
	subset parameters | $1 
    exclude option | $excludeoption
	filtered feature table name | ${filteredfeaturetable}
    sampling depth | $depth
	core-metrics analysis | core-${filteredfeaturetable%.qza}" > ${datasetname}-parameters/${filteredfeaturetable%.qza}-subset-parameters.txt
}
if [[ $filteringoption == "Sample ID" ]]; then
    parameters "${excludeoutput}. Sample IDs in ${filecreatedname}.txt"
elif [[ $filteringoption == "Metadata Categories" ]]; then
    parameters "$qiime_pwhere_string"
fi

