#!/bin/bash

# Paths
path_root=.
path_src=.
#path_src=../youtube-8m
#path_root=/afs/spsc.tugraz.at/student/cwalter/binaryKWS
#path_src=$path_root/git/youtube-8m
model_dir=$path_root/tmp/yt8m
path_dataset=$path_root/data/audioset/
#train_folder=unbal_train
#eval_folder=eval_show
train_folder=bal_train
eval_folder=eval
path_dataset_train=${path_dataset}${train_folder}
path_dataset_eval=${path_dataset}${eval_folder}
path_log=${path_root}/logs

# variables
batch_size=1024
num_labels=527

# functions
usage ()
{
  echo "Usage:"
  echo "  parameters: -train or -eval   -logistic or -lstm   num_epochs"
  echo "  example: ./baseline -train -lstm 100"
  exit
}

# epochs and model
num_epoch=10
if [ "$#" -eq "3" ]
then
  num_epoch=$3
  if [ $2 = "-logistic" ]
  then
    model=FrameLevelLogisticModel
  elif [ $2 = "-lstm" ]
  then
    model=LstmModel
  elif [ $2 = "-gru" ]
  then
    model=GRUModel
  else
    usage
  fi
else
 usage
fi

# Log file
if [ $1 = "-train" ]
then
  log_file=$path_log/yt8m_train_${train_folder}_${model}_${num_epoch}epochs.log
elif [ $1 = "-eval" ]
then
  log_file=$path_log/yt8m_eval_${train_folder}_${model}_${num_epoch}epochs.log
else
 usage
fi
# delete old file
if [ -f $log_file ] ; then
  echo "delete old log file"
  rm $log_file
fi

# only log
#exec 3>&1 1>>${log_file} 2>&1

# log with console output
exec > >(tee -a ${log_file} )
exec 2> >(tee -a ${log_file} >&2)

# baseline info
echo "Baseline with ${num_epoch} epochs and ${model}"
python2 --version
python2 -c 'import tensorflow as tf; print "tensorflow version: ", tf.__version__'

# script
if [ $1 = "-train" ]
then
  echo "train"
  # remove tmp files
  rm -rf $model_dir
  python2 $path_src/train.py --feature_names="audio_embedding" --feature_sizes="128" --train_data_pattern=$path_dataset_train/*.tfrecord --train_dir=$model_dir/$model --frame_features=True --model=$model --num_epochs=$num_epoch --batch_size=$batch_size --num_classes=$num_labels
elif [ $1 = "-eval" ]
then
  echo "eval"
  python2 $path_src/eval.py --feature_names="audio_embedding" --feature_sizes="128" --eval_data_pattern=$path_dataset_eval/*.tfrecord --train_dir=$model_dir/$model --frame_features=True --model=$model --run_once=True --num_epochs=$num_epoch --batch_size=$batch_size --num_classes=$num_labels
else
  usage
fi
