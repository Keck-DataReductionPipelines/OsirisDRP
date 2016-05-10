# Example Installation

## System Info

- MacBook Pro (Retina 13-inch, Early 2015)
- 2.7 GHz Intel Core i5
- OS X El Capitan v10.11.1
- IDL v8.5
- Ureka installed
- XQuartz v2.7.8
- User "jlyke" has admin priviledges

## Go to directory in which you wish to copy the OSIRIS DRP
```
[JLyke-MacBook:/Applications] jlyke% pwd
```
/Applications

## Clone the DRP repository from github
```
[JLyke-MacBook:/Applications] jlyke% git clone https://github.com/Keck-DataReductionPipelines/OsirisDRP.git
[JLyke-MacBook:/Applications] jlyke% ls -lrt | tail -1
```
drwxr-xr-x   10 jlyke          admin    340 May  6 10:14 OsirisDRP/
```
[JLyke-MacBook:/Applications] jlyke% du -hs OsirisDRP
```
 26M	OsirisDRP

## Change to the newly installed directory
```
JLyke-MacBook:/Applications] jlyke% cd OsirisDRP
```
/Applications/OsirisDRP

## Determine which branches have been updated
```
[JLyke-MacBook:/Applications/OsirisDRP] jlyke% git fetch -a
```
remote: Counting objects: 4, done.
remote: Compressing objects: 100% (4/4), done.
remote: Total 4 (delta 0), reused 0 (delta 0), pack-reused 0
Unpacking objects: 100% (4/4), done.
From https://github.com/Keck-DataReductionPipelines/OsirisDRP
   0740aaf..82b86b1  develop    -> origin/develop

## By default, you are on the "master" branch.  Change to the desired branch, here "develop"
```
[JLyke-MacBook:/Applications/OsirisDRP] jlyke% git checkout develop
```
Branch develop set up to track remote branch develop from origin.
Switched to a new branch 'develop'

## Check that your local files match those in the repository, this does not look for new files in the repository
```
[JLyke-MacBook:/Applications/OsirisDRP] jlyke% git status
```
On branch develop
Your branch is up-to-date with 'origin/develop'.
nothing to commit, working directory clean

## Check whether the repository has new files that are not in your local copy

```
[JLyke-MacBook:/Applications/OsirisDRP] jlyke% git fetch
```
remote: Counting objects: 33, done.
remote: Compressing objects: 100% (33/33), done.
remote: Total 33 (delta 14), reused 0 (delta 0), pack-reused 0
Unpacking objects: 100% (33/33), done.
From https://github.com/Keck-DataReductionPipelines/OsirisDRP
   82b86b1..5aed808  develop    -> origin/develop
```
[JLyke-MacBook:/Applications/OsirisDRP] jlyke% git status
```
On branch develop
Your branch is behind 'origin/develop' by 7 commits, and can be fast-forwarded.
  (use "git pull" to update your local branch)
nothing to commit, working directory clean
```
[JLyke-MacBook:/Applications/OsirisDRP] jlyke% git pull
```
Updating 82b86b1..5aed808
Fast-forward
 README.md                                   | 34 ++++++++++--
 backbone/drpStartup.pro                     |  4 +-
 scripts/osirisSetup.csh                     | 53 ++++++++++++++++++
 scripts/osirisSetup.sh                      | 83 +++++++++++++++++++++--------
 scripts/run_odrp                            |  9 +++-
 tests/drpStartup.pro                        |  9 +++-
 tests/drptestbones/backbone.py              |  6 +++
 tests/test_calstar/001.test_calstar.waiting | 20 -------
 tests/test_teluric/001.test_teluric.waiting | 20 -------
 9 files changed, 165 insertions(+), 73 deletions(-)
 create mode 100644 scripts/osirisSetup.csh
 mode change 100644 => 100755 scripts/osirisSetup.sh
 delete mode 100644 tests/test_calstar/001.test_calstar.waiting
 delete mode 100644 tests/test_teluric/001.test_teluric.waiting

>-- git pull request --<

## Merge another user's version into the official version

```
[JLyke-MacBook:/Applications/OsirisDRP] jlyke% git checkout -b astrofitz-develop develop
```
Switched to a new branch 'astrofitz-develop'
git pull https://github.com/astrofitz/OsirisDRP.git develop
```
[JLyke-MacBook:/Applications/OsirisDRP] jlyke% git pull https://github.com/astrofitz/OsirisDRP.git develop
```
remote: Counting objects: 5, done.
remote: Compressing objects: 100% (1/1), done.
remote: Total 5 (delta 4), reused 5 (delta 4), pack-reused 0
Unpacking objects: 100% (5/5), done.
From https://github.com/astrofitz/OsirisDRP
 * branch            develop    -> FETCH_HEAD
Merge made by the 'recursive' strategy.
 modules/source/Makefile.local | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
```
[JLyke-MacBook:/Applications/OsirisDRP] jlyke% git status
```
On branch astrofitz-develop
nothing to commit, working directory clean
```
[JLyke-MacBook:/Applications/OsirisDRP] jlyke% git checkout develop
```
Switched to branch 'develop'
Your branch is up-to-date with 'origin/develop'.

## Merge the changes, but explicitly do NOT commit or fast-forward a commit

```
[JLyke-MacBook:/Applications/OsirisDRP] jlyke% git merge --no-commit --no-ff astrofitz-develop
```
Automatic merge went well; stopped before committing as requested
```
[JLyke-MacBook:/Applications/OsirisDRP] jlyke% git status
```
On branch develop
Your branch is up-to-date with 'origin/develop'.
All conflicts fixed but you are still merging.
  (use "git commit" to conclude merge)

Changes to be committed:

	modified:   modules/source/Makefile.local

## make clean to remove previously compiled software

```
[JLyke-MacBook:/Applications/OsirisDRP] jlyke% make clean
```
rm -f modules/source/*.o
rm -f modules/source/libosiris_drp_ext_null.so.0.0

## make the DRP 
### Note that the warnings from IDL are benign

```
[JLyke-MacBook:/Applications/OsirisDRP] jlyke% make
```
cc -Imodules/source/include -I/Applications/exelis/idl/external/include -D__REENTRANT -fPIC -g -O2 -DHAVE_CONFIG_H -c  modules/source/osiris_rename_null.c -o modules/source/osiris_rename_null.o
In file included from modules/source/osiris_rename_null.c:8:
/Applications/exelis/idl/external/include/idl_export.h:2758:9: warning: 
      'strlcpy' macro redefined [-Wmacro-redefined]
#define strlcpy IDL_StrBase_strlcpy
        ^
/usr/include/secure/_string.h:104:9: note: previous definition is here
#define strlcpy(dest, src, len)                                 \
        ^
In file included from modules/source/osiris_rename_null.c:8:
/Applications/exelis/idl/external/include/idl_export.h:2762:9: warning: 
      'strlcat' macro redefined [-Wmacro-redefined]
#define strlcat IDL_StrBase_strlcat
        ^
/usr/include/secure/_string.h:110:9: note: previous definition is here
#define strlcat(dest, src, len)                                 \
        ^
2 warnings generated.
cc -Imodules/source/include -I/Applications/exelis/idl/external/include -D__REENTRANT -fPIC -g -O2 -DHAVE_CONFIG_H -c  modules/source/osiris_wait_on_sem_signal_null.c -o modules/source/osiris_wait_on_sem_signal_null.o
In file included from modules/source/osiris_wait_on_sem_signal_null.c:8:
/Applications/exelis/idl/external/include/idl_export.h:2758:9: warning: 
      'strlcpy' macro redefined [-Wmacro-redefined]
#define strlcpy IDL_StrBase_strlcpy
        ^
/usr/include/secure/_string.h:104:9: note: previous definition is here
#define strlcpy(dest, src, len)                                 \
        ^
In file included from modules/source/osiris_wait_on_sem_signal_null.c:8:
/Applications/exelis/idl/external/include/idl_export.h:2762:9: warning: 
      'strlcat' macro redefined [-Wmacro-redefined]
#define strlcat IDL_StrBase_strlcat
        ^
/usr/include/secure/_string.h:110:9: note: previous definition is here
#define strlcat(dest, src, len)                                 \
        ^
2 warnings generated.
cc -Imodules/source/include -I/Applications/exelis/idl/external/include -D__REENTRANT -fPIC -g -O2 -DHAVE_CONFIG_H -c  modules/source/osiris_post_sem_signal_null.c -o modules/source/osiris_post_sem_signal_null.o
In file included from modules/source/osiris_post_sem_signal_null.c:8:
/Applications/exelis/idl/external/include/idl_export.h:2758:9: warning: 
      'strlcpy' macro redefined [-Wmacro-redefined]
#define strlcpy IDL_StrBase_strlcpy
        ^
/usr/include/secure/_string.h:104:9: note: previous definition is here
#define strlcpy(dest, src, len)                                 \
        ^
In file included from modules/source/osiris_post_sem_signal_null.c:8:
/Applications/exelis/idl/external/include/idl_export.h:2762:9: warning: 
      'strlcat' macro redefined [-Wmacro-redefined]
#define strlcat IDL_StrBase_strlcat
        ^
/usr/include/secure/_string.h:110:9: note: previous definition is here
#define strlcat(dest, src, len)                                 \
        ^
2 warnings generated.
cc -Imodules/source/include -I/Applications/exelis/idl/external/include -D__REENTRANT -fPIC -g -O2 -DHAVE_CONFIG_H -c  modules/source/osiris_test.c -o modules/source/osiris_test.o
cc -Imodules/source/include -I/Applications/exelis/idl/external/include -D__REENTRANT -fPIC -g -O2 -DHAVE_CONFIG_H -c  modules/source/osiris_rectify_lib.c -o modules/source/osiris_rectify_lib.o
cc -Imodules/source/include -I/Applications/exelis/idl/external/include -D__REENTRANT -fPIC -g -O2 -DHAVE_CONFIG_H -c  modules/source/mkrecmatrx_000.c -o modules/source/mkrecmatrx_000.o
In file included from modules/source/mkrecmatrx_000.c:11:
/Applications/exelis/idl/external/include/idl_export.h:2758:9: warning: 
      'strlcpy' macro redefined [-Wmacro-redefined]
#define strlcpy IDL_StrBase_strlcpy
        ^
/usr/include/secure/_string.h:104:9: note: previous definition is here
#define strlcpy(dest, src, len)                                 \
        ^
In file included from modules/source/mkrecmatrx_000.c:11:
/Applications/exelis/idl/external/include/idl_export.h:2762:9: warning: 
      'strlcat' macro redefined [-Wmacro-redefined]
#define strlcat IDL_StrBase_strlcat
        ^
/usr/include/secure/_string.h:110:9: note: previous definition is here
#define strlcat(dest, src, len)                                 \
        ^
2 warnings generated.
cc -Imodules/source/include -I/Applications/exelis/idl/external/include -D__REENTRANT -fPIC -g -O2 -DHAVE_CONFIG_H -c  modules/source/spatrectif_000.c -o modules/source/spatrectif_000.o
In file included from modules/source/spatrectif_000.c:11:
/Applications/exelis/idl/external/include/idl_export.h:2758:9: warning: 
      'strlcpy' macro redefined [-Wmacro-redefined]
#define strlcpy IDL_StrBase_strlcpy
        ^
/usr/include/secure/_string.h:104:9: note: previous definition is here
#define strlcpy(dest, src, len)                                 \
        ^
In file included from modules/source/spatrectif_000.c:11:
/Applications/exelis/idl/external/include/idl_export.h:2762:9: warning: 
      'strlcat' macro redefined [-Wmacro-redefined]
#define strlcat IDL_StrBase_strlcat
        ^
/usr/include/secure/_string.h:110:9: note: previous definition is here
#define strlcat(dest, src, len)                                 \
        ^
2 warnings generated.
cc -Imodules/source/include -I/Applications/exelis/idl/external/include -D__REENTRANT -fPIC -g -O2 -DHAVE_CONFIG_H -c  modules/source/dumpxmlptr.c -o modules/source/dumpxmlptr.o
In file included from modules/source/dumpxmlptr.c:6:
/Applications/exelis/idl/external/include/idl_export.h:2758:9: warning: 
      'strlcpy' macro redefined [-Wmacro-redefined]
#define strlcpy IDL_StrBase_strlcpy
        ^
/usr/include/secure/_string.h:104:9: note: previous definition is here
#define strlcpy(dest, src, len)                                 \
        ^
In file included from modules/source/dumpxmlptr.c:6:
/Applications/exelis/idl/external/include/idl_export.h:2762:9: warning: 
      'strlcat' macro redefined [-Wmacro-redefined]
#define strlcat IDL_StrBase_strlcat
        ^
/usr/include/secure/_string.h:110:9: note: previous definition is here
#define strlcat(dest, src, len)                                 \
        ^
modules/source/dumpxmlptr.c:14:57: warning: format specifies type 'unsigned int'
      but the argument has type 'void *' [-Wformat]
  (void)fprintf(stdout, "dumpxmlptr: argv[0] = %08x\n", argv[0]);
                                               ~~~~     ^~~~~~~
3 warnings generated.
cc -Imodules/source/include -I/Applications/exelis/idl/external/include -D__REENTRANT -fPIC -g -O2 -DHAVE_CONFIG_H -c  modules/source/idlgetpid.c -o modules/source/idlgetpid.o
In file included from modules/source/idlgetpid.c:6:
/Applications/exelis/idl/external/include/idl_export.h:2758:9: warning: 
      'strlcpy' macro redefined [-Wmacro-redefined]
#define strlcpy IDL_StrBase_strlcpy
        ^
/usr/include/secure/_string.h:104:9: note: previous definition is here
#define strlcpy(dest, src, len)                                 \
        ^
In file included from modules/source/idlgetpid.c:6:
/Applications/exelis/idl/external/include/idl_export.h:2762:9: warning: 
      'strlcat' macro redefined [-Wmacro-redefined]
#define strlcat IDL_StrBase_strlcat
        ^
/usr/include/secure/_string.h:110:9: note: previous definition is here
#define strlcat(dest, src, len)                                 \
        ^
2 warnings generated.
cc -bundle modules/source/osiris_rename_null.o modules/source/osiris_wait_on_sem_signal_null.o modules/source/osiris_post_sem_signal_null.o modules/source/osiris_test.o modules/source/osiris_rectify_lib.o modules/source/mkrecmatrx_000.o modules/source/spatrectif_000.o modules/source/dumpxmlptr.o modules/source/idlgetpid.o -L/opt/local/lib/ -lm -lcfitsio -lm -o modules/source/libosiris_drp_ext_null.so.0.0 

## Pipeline is installed, try a test

```
[JLyke-MacBook:/Applications/OsirisDRP] jlyke% make test
```
py.test
make: py.test: No such file or directory
make: *** [test] Error 1

## The test requires py.test to be installed, check python install
```
[JLyke-MacBook:/Applications/OsirisDRP] jlyke% which python
```
/usr/bin/python

## Force the Ureka version of python

```
[JLyke-MacBook:/Applications/OsirisDRP] jlyke% ur_setup
[JLyke-MacBook:/Applications/OsirisDRP] jlyke% which python
```
/Applications/Ureka/variants/common/bin/python

## Install the test framework

```
[JLyke-MacBook:/Applications/OsirisDRP] jlyke% pip install pytest astropy
```
Requirement already satisfied (use --upgrade to upgrade): pytest in /Applications/Ureka/python/lib/python2.7/site-packages
Requirement already satisfied (use --upgrade to upgrade): astropy in /Applications/Ureka/python/lib/python2.7/site-packages
Requirement already satisfied (use --upgrade to upgrade): py>=1.4.25 in /Applications/Ureka/python/lib/python2.7/site-packages (from pytest)
Requirement already satisfied (use --upgrade to upgrade): numpy>=1.6.0 in /Applications/Ureka/python/lib/python2.7/site-packages (from astropy)
Cleaning up...

## Verify that py.test is now available

```
[JLyke-MacBook:/Applications/OsirisDRP] jlyke% which py.test
```
/Applications/Ureka/python/bin/py.test

## Try the test again 
```
[JLyke-MacBook:/Applications/OsirisDRP] jlyke% make test
```
py.test
============================= test session starts ==============================
platform darwin -- Python 2.7.5 -- py-1.4.26 -- pytest-2.6.4
plugins: pandokia
collected 1 items 

tests/test_emission_line/test_emission_line.py .

========================== 1 passed in 93.84 seconds ===========================

## Test Successful

