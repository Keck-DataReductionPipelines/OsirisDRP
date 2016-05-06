function osirisSetup() {
    local OPTIND o a
    
    function osirisSetup_usage() {
        echo "Usage: $FUNCNAME /my/path/to/osiris/DRF/" >&2
        echo "       $FUNCNAME" >&2
        echo "       (w/o arguments, assumes current directory)" >&2
    }
    
    while getopts h opt; do
      case $opt in
        h)
          osirisSetup_usage
          return 1
          ;;
        \?)
          echo "Invalid option: -$OPTARG" >&2
          ;;
      esac
    done
    
    if [[ $# == 0 ]]; then
        echo "No path to the OSIRIS pipeline was given."
        echo "Assuming you want the pipeline to be in the current directory"
    fi

    # Set up the OSIRIS environment variables.
    # Pass a single argument to this function, 
    # which should be the root directory for the
    # OSIRIS pipeline.
    OSIRIS_ROOT=${1:-$PWD}
    echo "Setting OSIRIS_ROOT=$OSIRIS_ROOT"
    if [[ ! -d "$OSIRIS_ROOT/backbone" ]]; then
        echo "Can't find the $OSIRIS_ROOT/backbone/ directory."
        osirisSetup_usage
        return 1
    fi
    if [[ ! -d "$OSIRIS_ROOT/modules" ]]; then
        echo "Can't find the $OSIRIS_ROOT/modules/ directory."
        osirisSetup_usage
        return 1
    fi
    export OSIRIS_ROOT=$OSIRIS_ROOT

    export OSIRIS_WROOT=${2:-$OSIRIS_ROOT}
    # Location of data files
    export OSIRIS_DRP_DATA_PATH=$OSIRIS_WROOT/data/

    # Set the queue directory for any pipelines started by this user
    export DRF_QUEUE_DIR=$OSIRIS_WROOT/drf_queue

    # Set a default for the overall (general) DRP log files to go.  These log
    # files are created each time the pipeline backbone is started
    export OSIRIS_DRP_DEFAULTLOGDIR=$OSIRIS_WROOT/drf_queue/logs

    # This is where the backbone IDL code looks for the shared libraries that
    # implement C code called by the IDL code.
    export OSIRIS_DRP_EXTERNAL_LIB_DIR=$OSIRIS_ROOT/modules/source

    # This is where the backbone IDL code looks for the shared libraries that
    # implement C code called by the IDL code.
    export OSIRIS_BACKBONE_DIR=$OSIRIS_ROOT/backbone

    # Specify where the configuration filename is stored. This file just
    # contains the real name of the configuration file.
    export OSIRIS_DRP_CONFIG_FILE=$OSIRIS_ROOT/backbone/SupportFiles/local_osirisDRPConfigFile

    export OSIRIS_IDL_BASE=$OSIRIS_ROOT

    export PATH=${OSIRIS_ROOT}/scripts:${PATH}
        
    # Fixes a bug with awt on OSX
    export JAVA_TOOL_OPTIONS='-Djava.awt.headless=false'
    
    echo "Successfully setup OSIRIS DRP environment."
    echo "The DRP is in $OSIRIS_ROOT"
};
echo "To use the OSIRIS DRP, run osirisSetup /path/to/my/drp"
