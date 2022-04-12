# Problems installing the pipeline?

This file contains a bunch of common pipeline installation problems and their solutions.

## Installing on Apple M1 ARM Chips

There is an issue if CFITSIO is not compiled to be the same architecture as the DRP. CFITSIO should be compiled to be x86_64.

If installing CFITSIO from Macports:

```
arch -x86_64 sudo port install libgcc-devel
arch -x86_64 sudo port install cfitsio
```

In the Makefile for the OSIRIS DRP, update the CFLAGS variable:

```
CFLAGS += -arch x86_64
```

## Wrong Architecture Errors

If you get an error like this:

```
            % DRPBACKBONE::ERRORHANDLER: ERROR in drpBackbone::ErrorHandler - -379: CALL_EXTERNAL: Error loading sharable executable.
                Symbol: osiris_wait_on_sem_signal, File = ./modules/source/libosiris_drp_ext_null.so.0.0
                dlopen(./modules/source/libosiris_drp_ext_null.so.0.0, 1): no suitable image found.  
                Did find: ./modules/source/libosiris_drp_ext_null.so.0.0: mach-o, but wrong
                architecture

```

There is a mismatch between your compiled architectures somewhere between CFITSIO, IDL and ``libosiris`` (the compiled portion of the OSIRIS DRP). You can check the compiled architechture with ``lipo -info``, e.g. for ``libosiris``:

```
    $ lipo -info ./modules/source/libosiris_drp_ext_null.so.0.0
    Non-fat file: ./modules/source/libosiris_drp_ext_null.so.0.0 is architecture: x86_64
```

You should see an architecture like ``x86_64``. You should check the architecture of ``libosiris`` and ``cfitsio``. They need to match the architecture of IDL. You can find out your IDL architecture from within IDL with the following:

```
    IDL> print, !VERSION.arch
    x86_64
```

If you need to explicitly tell your compilier to target a specific architecutre, you might try the following copiler flags:

- For 32 bit systems, either ``-m32`` or ``-arch i386``
- For 64 bit systems, ``-arch x86_64``

## Error Starting IDL scripts

If you get an error that says something like:

```
    xterm: Can’t execvp idl: No such file or directory
```

Then it is likely one of two issues.

The first is that the IDL executable is not in your PATH. Something like the following should be in your path:

```
    /Applications/exelis/idl85/bin/
```

You can check what is in your PATH by entering the following command:

```
    echo $PATH
```

If the IDL executable is in your PATH and you are running this on a MAC then there may be a compatibility issue between your versions of XQuarts, IDL, and ENVI. This problem and the solution to it is documented on the Harris Geospatial website [here.] (http://www.harrisgeospatial.com/Home/NewsUpdates/TabId/170/ArtMID/735/ArticleID/14944/XQuartz-2710-is-Not-Compatible-with-ENVI-531-and-IDL-851.aspx)

## Other startup errors

If the pipline complains that ``csh`` or ``xterm`` are not installed, you will need to install them. You don't need to use cshell, but the startup script will automatically call it. 

If you are unable to get ``run_odrp`` script to work, you can try to start the pipeline manually using (you will still need to setup your environment variables correctly):

```
idl -IDL_STARTUP ${OSIRIS_BACKBONE_DIR}/drpStartup.pro ${OSIRIS_BACKBONE_DIR}/osiris_drp_backbone_startup.pro
```
