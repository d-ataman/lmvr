#!/bin/sh
#
#
# Duygu Ataman
# 
# Vocabulary prediction scripts for NMT
##########################################################################

# INPUTS:
# The directory of data, source and target language extensions and the directory of nematus scripts
# directory that contains training data
data_dir=$1

# source and target corpus extention eg. en
src=$2
trg=$3

# segmentation type of source corpus (just check True or False whichever way you want to segment your corpus)
# if you want to use LMVR make sure that lmvressor is installed
# Also define the python path. LMVR uses python 2.7.
# options: bpe, lmvr
python="/pathtopython2.7"

# directory with the BPE scripts learn_bpe.py and apply_bpe.py
subword="/subworddir"

segment=$4 #check if data needs to be segmented (True or False)
src_seg=$5 # type of subwords for source side (bpe or lmvr)
tgt_seg=$6 # type of subwords for target side (bpe or lmvr)
dictionarysize=$7 # vocabulary size


##########################################################################

train_src="$data_dir/train.$src"
train_trg="$data_dir/train.$trg"
dev_src="$data_dir/dev.$src"
dev_trg="$data_dir/dev.$trg"
test_src="$data_dir/test.$src"

##########################################################################
# segment the source corpora

train_code_src="$data_dir/train.code.$src"
train_bpe_src="$data_dir/train.bpe.$src"
dev_bpe_src="$data_dir/dev.bpe.$src"
test_bpe_src="$data_dir/test.bpe.$src"
train_code_trg="$data_dir/train.code.$trg"
train_bpe_trg="$data_dir/train.bpe.$trg"

train_lmvrmodel_src="$data_dir/train.lmvrmodel-$src.tar.gz"
train_lmvr_src="$data_dir/train.lmvr.$src"
dev_lmvr_src="$data_dir/dev.lmvr.$src"
test_lmvr_src="$data_dir/test.lmvr.$src"
train_lmvrmodel_trg="$data_dir/train.lmvrmodel-$trg.tar.gz"
train_lmvr_trg="$data_dir/train.lmvr.$trg"


if [ $segment = '1' ] ; then

  # IF BPE SELECTED
  bpe_operation_src=$dictionarysize
  bpe_operation_trg=$dictionarysize

  if [ $src_seg = 'bpe' ] ; then
      echo "Running BPE for subword preprocessing"
   
      # Learn subword codes
      if [ -s "$train_code_src" ] ; then
        echo "$train_code_src already exist"
      else
        echo "Learning codes for the source corpus"
        $python $subword/learn_bpe.py -s "$bpe_operation_src" < "$train_src" > "$train_code_src"
        echo "Code for the source corpus is saved in $train_code_src"
      fi
    
      # Apply the learned codes
      if [ -s "$train_bpe_src" ] ; then
        echo "$train_bpe_src already exist"
      else
        echo "Applying codes for the source corpus"
        $python  $subword/apply_bpe.py -c "$train_code_src" -o "$train_bpe_src" < "$train_src"
        echo "BPE processed source train set is saved in $train_bpe_src"
      fi
    
      # Apply the learned codes on dev
      if [ -s "$dev_bpe_src" ] ; then
        echo "$dev_bpe_src already exist"
      else
        echo "Applying codes for the source corpus"
        $python  $subword/apply_bpe.py -c "$train_code_src" -o "$dev_bpe_src" < "$dev_src"
        echo "BPE processed source dev set is saved in $dev_bpe_src"
      fi

      # Apply the learned codes on test
      if [ -s "$test_bpe_src" ] ; then
        echo "$test_bpe_src already exist"
      else
        echo "Applying codes for the source corpus"
        $python  $subword/apply_bpe.py -c "$train_code_src" -o "$test_bpe_src" < "$test_src"
        echo "BPE processed source test set is saved in $test_bpe_src"
      fi
  fi

  if [ $tgt_seg = 'bpe' ] ; then 
      echo "Running BPE for subword preprocessing"  
   

      if [ -s "$train_code_trg" ] ; then
        echo "$train_code_trg already exist"
      else
        echo "Learning codes for the target corpus"
        $python  $subword/learn_bpe.py -s "$bpe_operation_trg" < "$train_trg" > "$train_code_trg"
        echo "Code for the target corpus is saved in $train_code_trg"
      fi

      if [ -s "$train_bpe_trg" ] ; then
        echo "$train_bpe_trg already exist"
      else
        echo "Applying codes for the target corpus"
        $python  $subword/apply_bpe.py -c "$train_code_trg" -o "$train_bpe_trg" < "$train_trg"
        echo "BPE processed target corpus is saved in $train_bpe_trg"
      fi
  fi    


# IF LMVR SELECTED

  dictionarysize=$dictionarysize #NMT vocabulary size
  P=10 #perplexity (default)

  if [ $src_seg = 'lmvr' ] ; then
      echo "Running LMVR for subword preprocessing"

      # Train the segmentation models
      if [ -s "$train_lmvrmodel_src" ] ; then
        echo "$train_lmvrmodel_src already exist"
      else
        echo "Training Morfessor Baseline for the source corpus"
        lmvressor-train -S "$data_dir/baselinemodel.$src.txt" $train_src 2>"$data_dir/log.lmvr.$src"
	sed 's/\///g' "$data_dir/baselinemodel.$src.txt" | sed 's/\\//g' > "$data_dir/baselinemodel.$src.temp.txt"
	awk -F' ' '$2!=""' "$data_dir/baselinemodel.$src.temp.txt" > "$data_dir/baselinemodel.$src.clean.txt"
	rm "$data_dir/baselinemodel.$src.temp.txt" "$data_dir/baselinemodel.$src.txt"
	lmvr-train "$data_dir/baselinemodel.$src.clean.txt" -T $train_src -s $train_lmvrmodel_src -m batch -p $P -d none --min-shift-remainder 1 --length-threshold 5 --min-perplexity-length 1 --max-epochs 5 --lexicon-size $dictionarysize -x $train_lmvrmodel_src -o "$train_lmvr_src.temp"
	
        echo "Model for segmenting the source corpus is saved in $train_lmvrmodel_src"
      fi

      # Apply the learned models on the training data
      if [ -s "$train_lmvr_src" ] ; then
        echo "$train_lmvr_src already exist"
      else
        echo "Applying codes for the source corpus"
        lmvr-segment $train_lmvrmodel_src -p $P --output-newlines --encoding UTF-8 -o "$train_lmvr_src.temp"
	cat "$train_lmvr_src.temp" | perl -pe 's/\n/ /g' | perl -pe 's/  /\n/g' > "$train_lmvr_src"
	rm "$train_lmvr_src.temp"
        echo "Segmented source train set is saved in $train_lmvr_src"
      fi

      # Segment the dev set
      if [ -s "$dev_lmvr_src" ] ; then
        echo "$dev_lmvr_src already exist"
      else
        echo "Applying codes for the source corpus"
        lmvr-segment $train_lmvrmodel_src  $dev_src -p $P --output-newlines --encoding UTF-8 -o "$dev_lmvr_src.temp"
	cat "$dev_lmvr_src.temp" | perl -pe 's/\n/ /g' | perl -pe 's/  /\n/g' > "$dev_lmvr_src"
	rm "$dev_lmvr_src.temp"
        echo "Segmented dev set is saved in $dev_lmvr_src"
      fi

      # Segment the test set
      if [ -s "$test_lmvr_src" ] ; then
        echo "$test_lmvr_src already exist"
      else
        echo "Applying codes for the source corpus"
        lmvr-segment $train_lmvrmodel_src  $test_src -p $P --output-newlines --encoding UTF-8 -o "$test_lmvr_src.temp"
	cat "$test_lmvr_src.temp" | perl -pe 's/\n/ /g' | perl -pe 's/  /\n/g' > "$test_lmvr_src"
	rm "$test_lmvr_src.temp"
        echo "Segmented test set is saved in $test_lmvr_src"
      fi
  fi

  if [ $tgt_seg = 'lmvr' ] ; then
      echo "Running LMVR for subword preprocessing"

      if [ -s "$train_lmvrmodel_trg" ] ; then
        echo "$train_lmvrmodel_trg already exist"
      else
        echo "Training Morfessor Baseline for the target corpus"
        lmvressor-train -S "$data_dir/baselinemodel.$trg.txt" $train_trg 2>"$data_dir/log.lmvr.$trg"
	sed 's/\///g' "$data_dir/baselinemodel.$trg.txt" | sed 's/\\//g' > "$data_dir/baselinemodel.$trg.temp.txt"
	awk -F' ' '$2!=""' "$data_dir/baselinemodel.$trg.temp.txt" > "$data_dir/baselinemodel.$trg.clean.txt"
	rm "$data_dir/baselinemodel.$trg.temp.txt" "$data_dir/baselinemodel.$trg.txt"
	lmvr-train "$data_dir/baselinemodel.$trg.clean.txt" -T $train_trg -s $train_lmvrmodel_trg -m batch -p $P -d none --min-shift-remainder 1 --length-threshold 5 --min-perplexity-length 1 --max-epochs 5 --lexicon-size $dictionarysize -x $train_lmvrmodel_trg -o "$train_lmvr_trg.temp"
	
        echo "Model for segmenting the target corpus is saved in $train_lmvrmodel_trg"
      fi
    
        if [ -s "$train_lmvr_trg" ] ; then
        echo "$train_lmvr_trg already exist"
      else
        echo "Applying codes for the target corpus"
        lmvr-segment $train_lmvrmodel_trg $train_trg -p $P --output-newlines --encoding UTF-8 -o "$train_lmvr_trg.temp"
	cat "$train_lmvr_trg.temp" | perl -pe 's/\n/ /g' | perl -pe 's/  /\n/g' > "$train_lmvr_trg"
	rm "$train_lmvr_trg.temp"
        echo "Segmented target train set is saved in $train_lmvr_trg"
      fi
  fi
fi
