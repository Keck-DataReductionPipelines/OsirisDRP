
# This is a general purpose kroot Makefile, for ordinary C, C++, and 
# Java builds.  Steps to use it are:
#     (1) Copy it into the directories of your project as required.  It may be
#         convenient to modify it somewhat before copying it to all
#         the directories. 
#     (2) Go down the list of make macros below, defining as appropriate.
#         Do the language-specific macros and the general macros.  (e.g. If
#         doing a Java project, you can ignore the C/C++ macros.)
#         Use space-separated-item lists unless otherwise stated.  To group
#         files, use e.g.  $(wildcard *.c)  not  *.c .  To specify e.g.
#         a group of object files, use  $(patsubst %.c, %.o, $(wildcard *.c))
#         not  $(wildcard *.o) , as the latter construct only gives the
#         current set of  *.o , not the intended set of  *.o .
#     (3) For additional macros and instructions, see other kroot makefiles,
#         KSD-31a (/kroot Programming Manual), and KSD-201 (How to Set Up a
#         config.mk Build).

# NOTE: (JLW - 2007-06-06)
#
#  Build using gmake will fail if building cleanly (i.e. from scratch)
#  This is because of the interdependencies of 
#     KeywordUpdateModuleDefinitionDialog.java 
#     ODRFGUIModel.java 
#     ODRFGUIFrame.java
#
#  The Make system compiles files one at a time, but files with 
#  interdependencies like this must be compiled at the same time.
#  Therefore, use the following command (at Keck) to compile these
#  classes first.  Once this command has been run, a normal gmake
#  install will work.
#
#   /usr/bin/javac -d /home/osrsbld/kroot/kss/osiris/drs/gui/classes/ -classpath /u/osrsbld/kroot/rel/default/classes/:/u/osrsbld/kroot/rel/default/classes/osirisUtil.jar:/home/osrsbld/kroot/kss/osiris/drs/gui/classes/:/u/osrsbld/kroot/rel/default/classes/kjava.jar:/u/osrsbld/kroot/rel/default/classes/jdom.jar:/u/osrsbld/kroot/rel/default/classes/NomTamUtil.jar:/u/osrsbld/kroot/rel/default/classes/NomTamFits.jar KeywordUpdateModuleDefinitionDialog.java ODRFGUIModel.java ODRFGUIFrame.java

######  C and C++ related macros ##########################################

# additional flags to C compiler (optional)
CFLAGS = 

# additional flags to C++ compiler (optional)
CXXFLAGS = 

# additional flags to C/C++ preprocessor (e.g. unusual  -I  flags) (optional)
CPPFLAGS =

# files for depends target (despite the generic misnomer) (optional)
SOURCE = 

# Other macros of interest are INCLUDE and OBJECT




###### Java related macros ################################################

OSIRIS_CLASSES = $(KROOT)/kss/osiris/drs/gui/classes/

# version of JDK to use  (optional)
# Use  1_1  1_2  1_3  noting use of  _  not  . 
JVERSION = 1_4

# additional flags to Java compiler (optional)
JFLAGS = -d $(OSIRIS_CLASSES)

# the argument to  -classpath  in the build (required for java builds)
# Note that  .:$(JDK_CLASSES) is the  javac  default behavior.  Also
# note that  JDK_CLASSES  incorporates the  JVERSION , so there is no need
# to make an additional modification here, if  JVERSION  is modified above.
# Add colon-separated directories to point to other required jar and class files
CLASSPATH = $(RELDIR)/classes/:$(RELDIR)/classes/osirisUtil.jar:$(OSIRIS_CLASSES):$(RELDIR)/classes/kjava.jar:$(RELDIR)/classes/jdom.jar:$(RELDIR)/classes/NomTamUtil.jar:$(RELDIR)/classes/NomTamFits.jar

# file suffix types to add to jar files besides class files (e.g. jpg png )
# (optional)
JARSUFFIXES = 

# Comment this out if you do not want to keep  .class  files around
.PRECIOUS: %.class

JAVAC1_4 = /usr/bin/javac

ifeq ($(HOST),oxygen)
	override JAVAC1_4 = /usr/jdk/j2sdk1.4.2_06/bin/javac
endif

###### general macros #####################################################

# subdirectories to recursively build, in order (required for recursive build)
DIRS = templates

# build products in this directory, in order (required, unless DIRS sufficient)
FILES = \
	ODRFGUIParameters.class \
	ReductionModuleListTableModel.class \
	ReductionModuleArgumentListTableModel.class \
        UpdateModuleListTableModel.class \
        KeywordUpdateModuleDefinitionDialog.class \
	ODRFGUIModel.class \
	ODRFGUIFrame.class \
	ODRFGUIApplication.class \
	ODRFGUI.class \
	odrfgui.jar


# files to install from this directory (usually  $(FILES) )
# (required for installation to $KROOT/rel)
# Also, see note below.
RELFILES = 
RELDAT = odrfgui_cfg.xml 

# unusual files to add to  clean  target (optional)
CLEAN = 

# Another macro of interest is PREFILES.  Also, if RELFILES is unusually
# large or varied, uses unusual file suffixes, or if it releases a shared 
# library not of the form  .so  or .so.0.0 , use RELDAT RELINC RELLIB 
# RELETC RELCLASS RELBIN instead.

# If this is a release point, override ancestor makefile's values.
override SYSNAM = kss/osiris/drs/gui/odrfgui/
override VERNUM = 3.0 



include $(KROOT)/etc/config.mk



###### custom build rules for FILES ######################################

odrfgui.jar:
	(cd $(OSIRIS_CLASSES); \
	jar -cvf odrfgui.jar edu/ucla/astro/osiris/drp/odrfgui/*.class)


###### target to check the values of macros -- Run  gmake check_setup

check_setup:
	@echo '*****' C and C++ related macros
	@echo CC is $(CC)
	@echo CFLAGS is $(CFLAGS)
	@echo CXX is $(CXX)
	@echo CXXFLAGS is $(CXXFLAGS)
	@echo CPPFLAGS is $(CPPFLAGS)
	@echo SOURCE is $(SOURCE)
	@echo INCLUDE is $(INCLUDE)
	@echo OBJECT is $(OBJECT)
	@echo '*****' Java related macros
	@echo JVERSION is $(JVERSION)
	@echo javac being used is  $(JAVAC$(JVERSION))
	@echo CLASSPATH is $(CLASSPATH)
	@echo JARSUFFIXES is $(JARSUFFIXES)
	@echo '*****' general macros
	@echo PREFILES is $(PREFILES)
	@echo DIRS is $(DIRS)
	@echo FILES is $(FILES)
	@echo POSTFILES is $(POSTFILES)
	@echo RELFILES is $(RELFILES)
	@echo RELBIN is $(RELBIN)
	@echo RELLIB is $(RELLIB)
	@echo RELCLASS is $(RELCLASS)
	@echo RELINC is $(RELINC)
	@echo RELDAT is $(RELDAT)
	@echo RELETC is $(RELETC)
	@echo CLEAN is $(CLEAN)
	@echo SYSNAM is $(SYSNAM)
	@echo VERNUM is $(VERNUM)

