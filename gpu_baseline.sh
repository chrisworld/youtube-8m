#!/bin/bash

export HOME="/srv/tmp/${USER}"

# miniconda base dir
_conda_base_dir="${HOME}"

# conda python environment to use
_conda_env="tensorflow"
# python version to use
_conda_python_version="2.7"
# python packages to install:
# conda packages
# _conda_install_packages="theano numpy pygpu matplotlib ipython jupyter jupyter_client"
_conda_install_packages="theano numpy pygpu matplotlib"
# pip packages
# _pip_install_packages="PySingular==0.9.1 jupyter_kernel_singular"
_pip_install_packages=""
# pip whl URL
#_pip_install_whl="https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow_gpu-1.2.1-cp35-cp35m-linux_x86_64.whl" # python 3.5
 _pip_install_whl="https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow_gpu-1.2.1-cp27-none-linux_x86_64.whl"  # python 2.7

# overwrite theano flags
THEANO_FLAGS="mode=FAST_RUN,floatX=float32"

# we need to force g++ to clang-3.8 and THEANO_FLAGS="nvcc.flags=-ccbin=clang-3.8"
# path to bin directory necessary to overwrite the compiler version
# do not use a directory which is in your $PATH
_bin_dir="bin"
# g++ binary name
# no path component bacause used as THEANO_FLAGS="nvcc.flags=-ccbin=${_gpp}"
# which ${_gpp} will get used for the g++ symlink in the bin folder ${_bin_dir}
_gpp="clang++-3.8"


# software requironments:
# apt install nvidia-smi nvidia-kernel-dkms nvidia-cuda-toolkit nvidia-driver nvidia-opencl-common
# apt install clang-3.8 libcudnn5-dev libcupti-dev


########################
# code for environment #
########################

# make shure ${HOME} exists
mkdir -p ${HOME} || exit 1

# define custom environment
# minimal $PATH for home
export PATH=${_conda_base_dir}/miniconda2/bin:${HOME}/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games


# compile version hack:
mkdir -p "${_bin_dir}"
_bin_dir=$(readlink -f ${_bin_dir}) # get full path
if [ ! -s "${_bin_dir}/g++" ]; then
  ln -fs $(which ${_gpp}) ${_bin_dir}/g++
fi
THEANO_FLAGS+=",nvcc.flags=-ccbin=${_gpp}"

export PATH=${_bin_dir}:${PATH}


# python
# install miniconda
if [ ! -d ${_conda_base_dir}/miniconda2 ]; then
  if [ ! -f Miniconda2-latest-Linux-x86_64.sh ]; then
    wget https://repo.continuum.io/miniconda/Miniconda2-latest-Linux-x86_64.sh
  fi
  chmod +x ./Miniconda2-latest-Linux-x86_64.sh
  ./Miniconda2-latest-Linux-x86_64.sh -b -f -p ${_conda_base_dir}/miniconda2
  rm ./Miniconda2-latest-Linux-x86_64.sh
  INSTALL=${INSTALL:-true}
fi
# setup virtual environment
if [ ! -d "${_conda_base_dir}/miniconda2/envs/${_conda_env}" ]; then
  conda create --yes -q -n ${_conda_env} python=${_conda_python_version}
fi
# activate environment
source activate ${_conda_env}
if [ "${CONDA_DEFAULT_ENV}" != "${_conda_env}" ]; then
  echo "ERROR: unable to activate conda environment \"${_conda_env}\""
  exit 1
fi
# ensure right python version
# ${_conda_python_version} matches python version installed
# for example _conda_python_version=3.5 and python 3.5.3 installed will be ok
_python_ver_installed=$(python --version 2>&1 | awk '{print $2}')
[[ ${_python_ver_installed} =~ ^${_conda_python_version}.*$ ]] || { \
    echo "python version ${_python_ver_installed} installed but ${_conda_python_version} expected"
    echo "manual change required..."
    exit 1
}
# ensure all packages are installed
if [ -n "${INSTALL}" ]; then
  conda install --yes ${_conda_install_packages}
  for _pip_package in ${_pip_install_packages}; do
    pip install --exists-action=i ${_pip_package}
  done
  for _pip_package in ${_pip_install_whl}; do
    pip install --exists-action=i ${_pip_package}
  done
fi

# theano
# define default gpu device to use
if [ -z "${GPU}" ]; then
  THEANO_FLAGS+=",device=cuda"
else
  THEANO_FLAGS+=",device=${GPU}"
fi

# temporary compile dir
THEANO_TMPDIR=`mktemp -d`

# optimized theano flags (from Matthias Zöhrer)
THEANO_FLAGS+=",base_compiledir=${THEANO_TMPDIR}"

# print config
echo -e "\n\nconfig:\n"
echo "HOME=${HOME}"
echo "PATH=${PATH}"
echo "LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"
echo "THEANO_FLAGS=${THEANO_FLAGS}"
echo

export THEANO_FLAGS="${THEANO_FLAGS}"

# Paths
path_root=.
path_src=.
#path_src=$path_root/youtube-8m
#path_root=/afs/spsc.tugraz.at/student/cwalter/binaryKWS
#path_src=$path_root/git/youtube-8m
model_dir=$path_root/tmp/yt8m
#path_dataset_train=$path_root/audioset/yt8m_features/train
#path_dataset_eval=$path_root/audioset/yt8m_features/test
path_dataset=$path_root/data/audioset/
#train_folder=$path_dataset/bal_train
#train_folder=unbal_train
train_folder=bal_train
eval_folder=eval
path_dataset_train=${path_dataset}${train_folder}
path_dataset_eval=${path_dataset}${eval_folder}
path_log=$path_root/logs

# variables
batch_size=128
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
echo "Baseline with ${num_epoch} epochs, batch_size of ${batch_size} and ${model} on set: ${train_folder}"
python --version
python -c 'import tensorflow as tf; print "tensorflow version: ", tf.__version__'

# script
if [ $1 = "-train" ]
then
  echo "train"
  # remove tmp files
  rm -rf $model_dir
  python $path_src/train.py --feature_names="audio_embedding" --feature_sizes="128" --train_data_pattern=$path_dataset_train/*.tfrecord --train_dir=$model_dir/$model --frame_features=True --model=$model --num_epochs=$num_epoch --batch_size=$batch_size --num_classes=$num_labels
elif [ $1 = "-eval" ]
then
  echo "eval"
  python $path_src/eval.py --feature_names="audio_embedding" --feature_sizes="128" --eval_data_pattern=$path_dataset_eval/*.tfrecord --train_dir=$model_dir/$model --frame_features=True --model=$model --run_once=True --num_epochs=$num_epoch --batch_size=$batch_size --num_classes=$num_labels
else
  usage
fi
