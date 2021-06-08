#!/bin/bash
#Run setup scripts
. scripts/set-opening.sh
askdatasetname
askmetadata
askqiime
asktable
asksamplingdepth

#echo "README: This command will obtain alpha diversity data for samples."
#echo 



#qiime alpha diversity options
qiime_alpha_options () {
    while true; do
        unset alpha_array
        unset incorrect_array
        alpha_array=()
        incorrect_array=()
        printf "Here are the ${RED}alpha diversity metrics${NC} you can select: $BLUE If you're not sure what to use, 'shannon' is typically a safe choice $NC \n"
        echo -e "ace\t berger_parker_d\t brillouin_d\t chao1_ci\t dominance\t enspie\t etsy_ci\t ${underline}${bold}faith_pd${normal}${noline}\t fisher_alpha\t gini_index\t goods_coverage\t heip_e\t kempton_taylor_q\t lladser_ci\t lladser_pe\t margalef\t msintosh_d\t mcintosh_e\t menhinick\t michaelis_mentin_fit\t ${underline}${bold}observed_otus${normal}${noline}\t doubles\t osd\t singles\t ${underline}${bold}pielou_e${normal}${noline}\t robbins\t ${underline}${bold}shannon${normal}${noline}\t simpson_e\t ${underline}${bold}simpson${normal}${noline}\t strong"
        alpha_options=("ace" "berger_parker" "brillouin_d" "chao1_ci" "dominance" "enspie" "etsy_ci" "faith_pd" "fisher_alpha" "gini_index" "goods_coverage" "heip_e" "kempton_taylor" "lladser_ci" "lladser_pe" "margalef" "msintosh_d" "mcintosh_e" "menhinick" "michaelis_mentin_fit" "observed_otus" "doubles" "osd" "singles" "pielou_e" "robbins" "shannon" "simpson_e" "simpson" "strong")
        echo "More information on alpha diversity metrics... "
        xdg-open https://forum.qiime2.org/t/alpha-and-beta-diversity-explanations-and-commands/2282
        echo "If you get an error, open this url: https://forum.qiime2.org/t/alpha-and-beta-diversity-explanations-and-commands/2282"
        printf "Enter the ${RED}NAME of the alpha diversity metric(s)${NC} you would like to run one by one. Press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key when you are done."
        while true; do
            read -p " " alphadiversitymetric
            if [[ $alphadiversitymetric == "" ]]; then
                break
            else
                for i in ${!alpha_array[@]}; do
                    if [[ ${alpha_array[i]} == $alphadiversitymetric ]]; then
                        printf "You already selected ${BLUE}${alpha_array[$i]}${NC}\n"
                        alphadiversitymetric="" 
                    fi
                done
                if [[ $alphadiversitymetric != "" ]]; then
                    alpha_array+=( "$alphadiversitymetric" )
                fi       
            fi
        done
        printf "You have entered ${BLUE}${#alpha_array[@]}${NC} alpha metrics.\n"
        echo "List of metrics: "
        for i in ${alpha_array[@]}; do #saves incorrect metrics into array and displays it
            incorrect=
            for j in "${alpha_options[@]}"; do
                [[ $i == $j ]] && { incorrect=1;break;}
            done
            [[ -n $incorrect ]] || incorrect_array+=("$i")
            printf "$i\t"
        done
        echo
        if [[ ${#incorrect_array[@]}>0 ]]; then 
            printf "Not a metric: ${BLUE}${incorrect_array[@]}${NC}. Please re-enter.\n"
        else
            printf "If these metrics are correct, enter ${RED}[yes]${NC}. If incorrect, press ${RED}[SPACEBAR]${NC} then ${RED}[enter]${NC} key."
            read -p " " alphacorrect
            [[ "$alphacorrect" == "yes" ]] && break || echo "Oops! Try again." 
        fi
    done
}

#Run alpha diversity phylo
qiime_alpha_diversity_phylo () {
    unset alpha_array_names
    alpha_array_names=()
        for ((i = 0; i < ${#alpha_array[@]}; i++)); do
            alpha_array_names+=( "${datasetname}/data/${alpha_array[i]}-${featuretablename}" )
            if [[ ${alpha_array[i]} == "faith_pd" ]]; then
                qiime diversity alpha-phylogenetic \
                --i-table "${datasetname}/data/$featuretablename" \
                --i-phylogeny ${datasetname}/data/dada2/rooted-tree.qza \
                --p-metric "${alpha_array[i]}" \
                --o-alpha-diversity "${alpha_array_names[i]}"
            elif [[ ${alpha_array[i]} != "" ]]; then
                qiime diversity alpha \
                --i-table "${datasetname}/data/$featuretablename" \
                --p-metric "${alpha_array[i]}" \
                --o-alpha-diversity "${alpha_array_names[i]}"
            fi
        done
}

#qiime metadata table
qiime_metadata_tabulate () {
    printf "Would you like to create a metadata table tabulating the values of the alpha diversity metrics? If yes, enter ${RED}[yes]${NC}. If not, press ${RED}[SPACEBAR] then [enter] key${NC}. "
    read -p " " alphametadatashow
    if [[ ${alphametadatashow} == 'yes' ]]; then 
        alpha_combined_tabulatedname="${datasetname}/visualization/-${featuretablename%.qza}-alpha-combined-metadata.qzv"
        unset inputfiles
        inputfiles=""
        for ((i = 0; i < ${#alpha_array[@]}; i++)); do
            inputfiles+="--m-input-file ${alpha_array_names[i]} " 
        done
        qiime metadata tabulate \
        ${inputfiles} \
        --o-visualization "${alpha_combined_tabulatedname}"
    fi
}

#qiime alpha group significance
qiime_alpha_groupsignificance () {
    unset alpha_significance_array_names
    alpha_significance_array_names=()
    for ((i = 0; i < ${#alpha_array[@]}; i++)); do
        alpha_significance_array_names+=( "${datasetname}/visualization/${alpha_array[i]}-groupsignificance-${featuretablename%.qza}.qzv" )
        qiime diversity alpha-group-significance \
        --i-alpha-diversity ${alpha_array_names[i]} \
        --m-metadata-file ${datasetname}/metadata/${metadatafile} \
        --o-visualization ${alpha_significance_array_names[i]}
    done
}

#qiime alpha rarefaction
qiime_alpha_rarefaction () {
    alpha_rarefractionname="${datasetname}/visualization/alpha-rarefraction-${featuretablename%.qza}.qzv"
    qiime diversity alpha-rarefaction \
    --i-table "${datasetname}/data/$featuretablename" \
    --i-phylogeny ${datasetname}/data/dada2/rooted-tree.qza \
    --p-max-depth $depth \
    --m-metadata-file ${datasetname}/metadata/${metadatafile} \
    --o-visualization "${alpha_rarefractionname}"
}

#Run command
qiime_alpha_options
qiime_alpha_diversity_phylo
qiime_metadata_tabulate
echo "Metadata tabulate builds a metadata file that includes the measured alpha diversity for each sample"
qiime_alpha_rarefaction
echo "Alpha rarefaction plots give you information on whether or not your sampling depth was adequate for each treatment condition"
qiime_alpha_groupsignificance
echo "Group significance file will show you a t-test comparing alpha diversity between your treatment conditions!"
saving_parameters () {
echo -e "	
	env | $qiimeenvironment
	metadata file | $metadatafile
	name | $datasetname
    feature table | $featuretablename
	alpha metrics | ${alpha_array[*]}
	Max sampling depth | $depth" > $datasetname-parameters/$featuretablename-alpha-diversity.txt

}
saving_parameters