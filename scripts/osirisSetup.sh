function osirisSetup() {
    local OPTIND o a
    local setpath
    
    function osirisSetup_usage() {
        echo "Usage: $FUNCNAME [-n] /my/path/to/osiris/DRF/" >&2
        echo "       $FUNCNAME [-n]" >&2
        echo "       (w/o arguments, assumes current directory)" >&2
        echo "" >&2
        echo "Flags:" >&2
        echo "   -n  Do not adjust the \$PATH variable." >&2
        echo "   -v  Be verbose." >&2
        echo "   -h  Show this message and exit." >&2
        echo "" >&2
    }
    OSIRIS_VERBOSE=${OSIRIS_VERBOSE:-1}
    setpath=1
    while getopts hvn opt; do
      case $opt in
        h)
          osirisSetup_usage
          return 1
          ;;
        n)
          setpath=0
          ;;
        v)
          OSIRIS_VERBOSE=1
          ;;
        \?)
          echo "Invalid option: -$OPTARG" >&2
          ;;
      esac
    done
    
    if [[ $# -eq 0 ]] && [[ $OSIRIS_VERBOSE -eq 1 ]]; then
        echo "No path to the OSIRIS pipeline was given."
        echo "Assuming you want the pipeline to be in the current directory"
    fi

    # Set up the OSIRIS environment variables.
    # Pass a single argument to this function, 
    # which should be the root directory for the
    # OSIRIS pipeline.
    OSIRIS_ROOT=${1:-$PWD}
    [[ $OSIRIS_VERBOSE -eq 1 ]] && echo "Setting OSIRIS_ROOT=$OSIRIS_ROOT"
    if [[ ! -d "$OSIRIS_ROOT/backbone" ]]; then
        echo "Can't find the $OSIRIS_ROOT/backbone/ directory."
        [[ $OSIRIS_VERBOSE -eq 1 ]] && osirisSetup_usage
        return 1
    fi
    if [[ ! -d "$OSIRIS_ROOT/modules" ]]; then
        echo "Can't find the $OSIRIS_ROOT/modules/ directory."
        [[ $OSIRIS_VERBOSE -eq 1 ]] && osirisSetup_usage
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
    
    if [[ $setpath -eq 1 ]]; then
        [[ $OSIRIS_VERBOSE -eq 1 ]] && echo "Adding ${OSIRIS_ROOT}/scripts to your path."
        export PATH=${OSIRIS_ROOT}/scripts:${PATH}
    fi
    # Fixes a bug with awt on OSX
    export JAVA_TOOL_OPTIONS='-Djava.awt.headless=false'
    
    [[ $OSIRIS_VERBOSE -eq 1 ]] && echo "Successfully setup OSIRIS DRP environment."
    [[ $OSIRIS_VERBOSE -eq 1 ]] && echo "The DRP is in $OSIRIS_ROOT"
};
[[ ${OSIRIS_VERBOSE:-1} -eq 1 ]] && echo "To use the OSIRIS DRP, run osirisSetup /path/to/my/drp"