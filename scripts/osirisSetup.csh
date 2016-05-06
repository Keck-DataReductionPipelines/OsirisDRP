# Make the user set OSIRIS_ROOT
set CONTINUE=1

if ! $?OSIRIS_ROOT then
    echo "The OSIRIS DRP needs $OSIRIS_ROOT to be set."
    echo "$ setenv OSIRIS_ROOT /path/to/my/drp"
    set CONTINUE=0
    
endif

echo "Using OSIRIS_ROOT=$OSIRIS_ROOT"
if (! -d "$OSIRIS_ROOT/backbone") then
    echo "Can't find the $OSIRIS_ROOT/backbone/ directory."
    echo 'Be sure that $OSIRIS_ROOT is set correctly.'
    set CONTINUE=0
else
  if (! -d "$OSIRIS_ROOT/modules") then
      echo "Can't find the $OSIRIS_ROOT/modules/ directory."
      echo 'Be sure that $OSIRIS_ROOT is set correctly.'
      set CONTINUE=0
  endif
endif

if ($CONTINUE == "1") then
    # Location of data files
    setenv OSIRIS_DRP_DATA_PATH $OSIRIS_ROOT/data/
    
    # Set the queue directory for any pipelines started by this user
    setenv DRF_QUEUE_DIR $OSIRIS_ROOT/drf_queue
    
    # Set a default for the overall (general) DRP log files to go.  These log
    # files are created each time the pipeline backbone is started
    setenv OSIRIS_DRP_DEFAULTLOGDIR $OSIRIS_ROOT/drf_queue/logs
    
    # This is where the backbone IDL code looks for the shared libraries that
    # implement C code called by the IDL code.
    setenv OSIRIS_DRP_EXTERNAL_LIB_DIR $OSIRIS_ROOT/modules/source
    
    # This is where the backbone IDL code looks for the shared libraries that
    # implement C code called by the IDL code.
    setenv OSIRIS_BACKBONE_DIR $OSIRIS_ROOT/backbone
    
    # Specify where the configuration filename is stored. This file just
    # contains the real name of the configuration file.
    setenv OSIRIS_DRP_CONFIG_FILE $OSIRIS_ROOT/backbone/SupportFiles/local_osirisDRPConfigFile
    
    setenv OSIRIS_IDL_BASE $OSIRIS_ROOT
    
    echo "Successfully setup OSIRIS DRP environment."
    echo "The DRP is in $OSIRIS_ROOT"
    echo "You might want to add $OSIRIS_ROOT/scripts to your PATH."
endif

