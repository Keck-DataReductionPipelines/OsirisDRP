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
CFITSIOLIBDIR = $(KROOT)/kss/osiris/drs/modules/lib/
OUTPUTDIR = .

# Include files.
INCLUDE = 
LD_LIBRARY_PATH = 

# C source and object files.
CFLAGS  =  -I$(KROOT)/kss/osiris/drs/modules/source/include -I$(IDL_INCLUDE) -D__REENTRANT -fPIC

NAMES = osiris_rename_null \
	osiris_wait_on_sem_signal_null \
	osiris_post_sem_signal_null \
	osiris_test \
	osiris_rectify_lib \
	mkrecmatrx_000 \
	spatrectif_000 \
	dumpxmlptr \
	idlgetpid 
SOURCE = $(NAMES:%=%.c)
OBJECT = $(NAMES:%=%.o)
COBJ = 


DIRS = 

# Files to make are ..
FILES = libosiris_drp_ext_null.so.0.0

# Files to release are ..
RELFILES = libosiris_drp_ext_null.so.0.0
RELDAT =  

# This is a release point. Define version macros to override values
# inherited from the environment
override SYSNAM = kss/osiris/drs/modules/source/
override VERNUM = 3.0.1 

# Include general make rules (use /etc if no environment variable)
include $(KROOT)/etc/config.mk

RM  = rm -f
SED = /bin/sed

libosiris_drp_ext_null.so.0.0 : $(OBJECT) drp_structs.h
	ld -shared -o $(OUTPUTDIR)/$@ $(OBJECT) $(COBJ) \
	-L$(LIBDIR) -L$(CFITSIOLIBDIR) -lm -losirisDRPcfitsio


clean:
	$(RM) $(OBJECT) $(OUTPUTDIR)/libosiris_drp_ext_null.so.0.0


showsym :
	@echo $(CFLAGS)
	@echo $(CC)
	@echo $(LIBDIR)
