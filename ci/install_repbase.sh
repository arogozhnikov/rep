#!/bin/bash
# installing REP environment with miniconda
# Usage: $0 [PYTHON_MAJOR_VERSION=2]
# e.g. for python 3: $0 3


# define a function to print error before exiting
function halt {
  echo -e $*
  exit 1
}

PYTHON_MAJOR_VERSION=2
[ -n "$1" ] && PYTHON_MAJOR_VERSION=$1
# when testing on travis, we use travis variable
if [ -n "$TRAVIS_PYTHON_VERSION" ] ; then
    PYTHON_MAJOR_VERSION=${TRAVIS_PYTHON_VERSION:0:1}
fi
REP_ENV_NAME="rep_py${PYTHON_MAJOR_VERSION}"


# checking that system has apt-get
if which apt-get > /dev/null; then
    sudo apt-get update
    sudo apt-get install -y  \
        build-essential \
        libatlas-base-dev \
        liblapack-dev \
        libffi-dev \
        wget \
        gfortran \
        git \
        libxft-dev \
        libxpm-dev \
        mc \
        telnet \
        curl
fi

# matplotlib and ROOT both using DISPLAY environment variable
# changing matplotlib configuration file to avoid conflict
mkdir -p $HOME/.config/matplotlib && echo 'backend: agg' > $HOME/.config/matplotlib/matplotlibrc

# exit existing environments
[ -n "$VIRTUAL_ENV" ] && deactivate
[ -n "$CONDA_ENV_PATH" ] && source deactivate

if ! which conda ; then
    # install python2 miniconda
    MINICONDA_FILE="Miniconda-latest-Linux-x86_64.sh"
    wget http://repo.continuum.io/miniconda/$MINICONDA_FILE -O miniconda.sh
    chmod +x miniconda.sh
    ./miniconda.sh -b -p $HOME/miniconda || halt "Error installing miniconda"
    rm ./miniconda.sh
    export PATH=$HOME/miniconda/bin:$PATH
    hash -r
    conda update --yes conda
fi

HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REP_ENV_FILE="$HERE/environment-rep.yaml"
JUPYTERHUB_ENV_FILE="$HERE/environment-jupyterhub.yaml"

echo "Creating conda venv jupyterhub_py3"
conda env create -q --name jupyterhub_py3 --file $JUPYTERHUB_ENV_FILE > /dev/null
source activate jupyterhub_py3 || halt "Error installing jupyterhub_py3 environment"

echo "Removing conda packages and caches"
conda uninstall --yes -q gcc qt
conda clean --yes -s -p -l -i -t

echo "Creating conda venv $REP_ENV_NAME"
conda env create -q --name $REP_ENV_NAME python=$PYTHON_MAJOR_VERSION --file $REP_ENV_FILE > /dev/null
source activate $REP_ENV_NAME || halt "Error installing $REP_ENV_NAME environment"

echo "Removing conda packages and caches"
conda uninstall --yes -q gcc qt
conda clean --yes -s -p -l -i -t

# test installed packages
source "${ENV_BIN_DIR}/thisroot.sh" || halt "Error installing ROOT"
python -c 'import ROOT, root_numpy' || halt "Error installing root_numpy"
python -c 'import xgboost' || halt "Error installing XGBoost"

# printing message about environment
cat << EOL_MESSAGE
    # add to your environment:
    export PATH=\$HOME/miniconda/bin:\$PATH
    source activate \$REP_ENV_NAME
    source \$ENV_BIN_DIR/thisroot.sh
EOL_MESSAGE