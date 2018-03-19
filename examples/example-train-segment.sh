# Duygu Ataman
#
# Example script for training a segmentation model and segmenting a corpus
#
###################################################################################################################

extension="model-name"
lan="en"
input=train.$lan #input file name
dir=/home/... # name of directory for the file
dictionarysize=100000 #target NMT vocabulary size
P=10 #perplexity threshold (default 10)

## Train Morfessor Baseline for initializing the Flatcat model
morfessor-train -S $dir/baselinemodel.$lan.txt $dir/$input 2>log.err.$lan.$extension 

## Clean lexicon for strange characters
cat $dir/baselinemodel.$lan.txt | perl -pe 's/\n/ /g' | perl -pe 's/  /\n/g' > $dir/baselinemodel.$lan.clean.txt

## Train Flatcat model using the training set
lmvr-train $dir/baselinemodel.$lan.clean.txt -T $dir/$input -s $dir/flatcat.${extension}.model.tar.gz -m batch -p $P -d none --min-shift-remainder 1 --length-threshold 5 --min-perplexity-length 1 --max-epochs 5 --lexicon-size $dictionarysize -x $dir/flatcat.${extension}.lexicon.txt -o $dir/$input.segmented

## Segment train, dev, and test sets using the segmentation model
lmvr-segment $dir/flatcat.${extension}.model.tar.gz  $dir/$input -p $P --output-newlines --encoding UTF-8 -o $dir/$input.$extension.segmented
cat $dir/$input.$extension.segmented | perl -pe 's/\n/ /g' | perl -pe 's/  /\n/g' > $dir/$input.$extension.segmented.senti

lmvr-segment $dir/flatcat.${extension}.model.tar.gz  $dir/dev.$lan -p $P --output-newlines --encoding UTF-8 -o $dir/dev.$lan.$extension.segmented
cat $dir/dev.$lan.$extension.segmented | perl -pe 's/\n/ /g' | perl -pe 's/  /\n/g' > $dir/dev.$lan.$extension.segmented.sent

lmvr-segment $dir/flatcat.${extension}.model.tar.gz  $dir/test.$lan -p $P --output-newlines --encoding UTF-8 -o $dir/test.$lan.$extension.segmented
cat $dir/test.$lan.$extension.segmented | perl -pe 's/\n/ /g' | perl -pe 's/  /\n/g' > $dir/test.$lan.$extension.segmented.sent

