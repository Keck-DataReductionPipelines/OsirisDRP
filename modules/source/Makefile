##############################################################################
#+
#  Author:	Jason Weiss
#
#  Date:	20 September 2005
#
#  Description:	makefile to build OSIRIS DRS C modules
#       osiris_ext_null.so
#
#-
##############################################################################

IDL_INCLUDE = /usr/local/rsi/idl_6.1/external/include
CFITSIOLIBDIR = $(KROOT)kss/osiris/drs/modules/lib
OUTPUTDIR = ../lib

# Include files.
INCLUDE = 
LD_LIBRARY_PATH = 

# C source and object files.
CFLAGS  =  -I$(KROOT)/kss/osiris/drs/modules/source/include -I$(IDL_INCLUDE) -D__REENTRANT -fPIC

NAMES = osiris_rename_null.c \
	osiris_wait_on_sem_signal_null.c \
	osiris_post_sem_signal_null.c \
	osiris_test.c \
	osiris_rectify_lib.c \
	mkrecmatrx_000.c \
	spatrectif_000.c \
	dumpxmlptr.c \
	idlgetpid.c 
SOURCE = $(NAMES:%=%.c)
OBJECT = $(NAMES:%=%.o)
COBJ = 


DIRS = 

# Files to make are ..
FILES = osiris_ext_null.so

# Files to release are ..
RELFILES  = 
RELDAT =  

# This is a release point. Define version macros to override values
# inherited from the environment
override SYSNAM = kss/osiris/drs/modules/source/
override VERNUM = 1.4

# Include general make rules (use /etc if no environment variable)
include $(KROOT)/etc/config.mk

RM     = rm -f

osiris_ext_null.so : $(OBJECT) 

	$(SHLIB_LD_NOPIC) -o $(OUTPUTDIR)/$@ $(OBJECT) $(COBJ) \
	-L$(LIBDIR) -L$(CFITSIOLIBDIR) -lm lcfitsio


clean:
	$(RM) $(OBJECT) $(OUTPUTDIR)/osiris_ext_null.so



