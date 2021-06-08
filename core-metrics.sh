#Run setup scripts
. scripts/set-opening.sh
askdatasetname
featuretablename=samples-and-features-filtered-table.qza
askmetadata
askqiime
asksamplingdepth

printf "We are now building your core metric and phylogenetic tree for your dataset.  $BLUE Go relax, this will take a long time $NC."
#QIIME functions- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
qiime feature-table summarize \
  --i-table ${datasetname}/data/samples-and-features-filtered-table.qza \
  --o-visualization ${datasetname}/visualization/samples-and-features-filtered-table.qzv \
  --m-sample-metadata-file ${datasetname}/metadata/${metadatafile}

qiime feature-table tabulate-seqs \
  --i-data ${datasetname}/data/dada2/representative_sequences.qza \
  --o-visualization ${datasetname}/visualization/dada2-representative_sequences.qzv

echo "Representative sequences file made"
echo "..."
echo "Building phylogenetic tree"

qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences ${datasetname}/data/dada2/representative_sequences.qza \
  --o-alignment ${datasetname}/data/dada2/aligned-rep-seqs.qza \
  --o-masked-alignment ${datasetname}/data/dada2/masked-aligned-rep-seqs.qza \
  --o-tree ${datasetname}/data/dada2/unrooted-tree.qza \
  --o-rooted-tree ${datasetname}/data/dada2/rooted-tree.qza

echo "Phylogenetic tree built, Running core metrics"

#Assigning taxonomy
qiime feature-classifier classify-sklearn \
  --i-classifier scripts/*-classifier.qza \
  --i-reads ${datasetname}/data/dada2/representative_sequences.qza \
  --o-classification ${datasetname}/data/dada2/taxonomy.qza

qiime_taxa_barplot

rm -r ${datasetname}/data/core-metrics-results

echo "Performing core metrics"
qiime diversity core-metrics-phylogenetic \
  --i-phylogeny ${datasetname}/data/dada2/rooted-tree.qza \
  --i-table ${datasetname}/data/samples-and-features-filtered-table.qza \
  --p-sampling-depth $depth \
  --m-metadata-file ${datasetname}/metadata/$metadatafile \
  --output-dir ${datasetname}/data/core-metrics-results

echo "Building a heatmap of your dataset, what settings would you like to use to build this heatmap?"

categories
echo "what taxa level would you like to build a heatmap for?"

#	collapses taxa to your desired level
taxacollapse
echo "Building your heatmap"

#	Build heatmap
heatmap

echo "CORE METRICS DIVERSITY COMPLETE"

saving_parameters () {
echo -e "	
	env | $qiimeenvironment
  feature table | samples-and-features-filtered-table.qza
	metadata file | $metadatafile
	name | $datasetname
  taxonomic classifier | gg-13-8-99-515-806-nb-classifier.qza
	heatmap settings | category: $category | taxa level: $taxalevel
  output directory | " > $datasetname-parameters/core-metrics.txt

}
saving_parameters