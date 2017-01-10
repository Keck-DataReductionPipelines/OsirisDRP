---
layout: page
title: Installing the Data Reduction Pipeline
permalink: /manual/installing2015A
---

As of version 2015A, the pipeline can be installed as Ureka package. If you prefer to use this installation procedure, download the pipeline tar file and unpack it. Then execute:

    ur_setup

Go to the mosfire python directory where the setup.py file is located (it is the main directory above the MOSFIRE and apps directories). Run:

    python setup.py install

This will copy the MOSFIRE pipeline as a python package located into your ureka enviornment.

Alternatively, if you would like to modify the MOSFIRE pipeline files, run the following instead: 

    python setup.py develop 

This will make symoblic links to the MOSFIRE files instead of copying them. Your changes to the pipeline file will now automatically be used when loading the MOSFIRE package. 

Directories created by you

* DATA – sub directory in which you can store your data. This is not a necessary sub-directory but may help you manage files. Raw data may be stored in other areas on your disk.
* REDUX – sub directory where reductions will be stored. Also not critical, but helpful.

From now on, if you want to run any pipeline commands, you will always execute “mospy” as seen in our first step in section 5 below. Remember to run ur_setup before running the MOSFIRE pipleine.

## Alternate Installation Method

If you prefer the previous installation method, follow these instructions:

**1) Install Ureka**

The pipeline relies on the Ureka Python distribution produced by STScI and Gemini Observatory: [http://ssb.stsci.edu/ureka/](http://ssb.stsci.edu/ureka/)

The DRP was developed using UREKA version 1.0. Navigate to the 1.0 distribution using the url listed above. Follow the instructions at the links to install the package. The UREKA instructions indicate that you need to run `ur_setup` to put ureka in the path. This is automatically completed when you run the drp and it is found in the mospy code. However, if you want to test the ureka package yourself, you will need to run ur_setup manually. The latest version of Ureka that is confirmed to work with the pipeline is 1.5.1

**2) Download the pipeline**

1. Start an xterm session on your local machine
2. Run “cd” to navigate to the home directory 
3. Download either the .zip file, or the .tar.gz file from the website [https://keck-datareductionpipelines.github.io/MosfireDRP/](https://keck-datareductionpipelines.github.io/MosfireDRP/).  Note that this is the stable and supported version of the pipeline.  Alternatively, if you are a github user, you can just clone the repository using: `https://github.com/keck-DataReductionPipelines/MosfireDRP.git`.  This is the development version, and it is NOT supported.
4. Expand the zip or tar file and rename the resulting directory. For example:

```
    mkdir ~/MOSFIRE 
    mv MosfireDRP-1.1 ~/MOSFIRE/DRP_CODE
    cd ~/MOSFIRE/DRP_CODE # to navigate to that directory
```


**3) Create Data Directories**

Create sub directories for raw data, and reduced data. These sub directories are not specific. You can set up sub directories any way you would like. For the purposes of this manual, we have choosen generic directory names. You may choose to store the raw and reduced data using andy directory structure you would prefer. For our example, we created a raw data directory in the code repository: 

mkdir ~/MOSFIRE/DRP_CODE/DATA

and a reduction directory in the code repository that will store reduced data:

mkdir ~/MOSFIRE/DRP_CODE/REDUX


**4) Copy the mospy file into your bin dir**

Navigate to the newly creted bin dir: 

    cd ~/MOSFIRE/DRP_CODE/bin

Copy the mospy executeable to the bin dir

    cp ../apps/mospy  .

**5) edit mospy in your bin dir and update a few lines of code**

Using your favorite editor (emacs ../bin/mospy), update the path for the `ur_setup`. Replace `/home/npk/.ureka/ur_setup` with your `/your_full_path_name/.ureka/ur_setup` full path.

Update the path for the `ur_forget`. Replace `/home/npk/.ureka/ur_setup` with `/your_full_path_name/.ureka/ur_forget` 

Update the MOSPATH with the full path to the source code directory. Replace `/src2/mosfire/DRP/mosfire` with `/your_full_path_name/MOSFIRE/DRP_CODE`

As an example, the original file might look like the following:

    #Update the full path to the ureka install for the 
    # two aliases below.
    alias ur_setup 'eval `/home/npk/.ureka/ur_setup -csh \!*`'
    alias ur_forget 'eval `/home/npk/.ureka/ur_forget -csh \!*`'
    
    # If pythonpath is not previously defined, define it so that 
    #   the setenv works below..  
    if (! $?PYTHONPATH ) setenv PYTHONPATH
    
    #Update the full path to the mosfire DRP code repository
    # example: /src2/mosfire/DRP/mosfire change to /Users/myname/MOSFIRE/DRP_CODE
    #  in which the sub dirs drivers, apps, badpixel, etc. live  
    setenv MOSPATH /scr2/mosfire/DRP/mosfire
    setenv PYTHONPATH ${PYTHONPATH}:${MOSPATH}

And the modified version for an observers particular setup may look something like this:

    #Update the full path to the ureka install for the 
    # two aliases below.
    alias ur_setup 'eval `/Users/mkassis/.ureka/ur_setup -csh \!*`'
    alias ur_forget 'eval `/Users/mkassis/.ureka/ur_forget -csh \!*`'
    
    # If pythonpath is not previously defined, define it so that 
    #   the setenv works below..
    if (! $?PYTHONPATH ) setenv PYTHONPATH 
    
    # Update the full path to the mosfire DRP code repository
    # example: /src2/mosfire/DRP/mosfire
    #  in which the sub dirs drivers, apps, badpixel, etc. live  
    setenv MOSPATH /Users/mkassis/Documents/KeckInstrs/MOSFIRE/DRP_CODE_March2014/
    setenv PYTHONPATH ${PYTHONPATH}:${MOSPATH}

**6) Ensure that mospy is executable**

    chmod +x mospy

**7) Update your .cshrc file**

Update your `.cshrc` file with the code bin dir in the path. Add the following line to your `.cshrc` file:

    set path = ( #mosfire_drp_bin_dir# $path )

for example:

    set path = ( ~/MOSFIRE/DRP_CODE/bin $path )

If you do not normally run csh or tcsh, you may not have a `.cshrc` file. You will need to create one or download an example file like this one: [http://www2.keck.hawaii.edu/inst/mosfire/.cshrc](http://www2.keck.hawaii.edu/inst/mosfire/.cshrc). The `.cshrc` file must be in your home directory. By default, MacOSX does not show files that start with a `.` But you can access them via the terminal.

For a bash shell:

    # Adding MOSFIRE pipeline
    PATH="/pathtomosfiredrp/MOSFIRE/DRP_CODE/bin:${PATH}"
    export PATH

**8) Now source your .cshrc file**

    source ~/.cshrc
    
This will put your bin dir into your executable path.

The installation is now complete. Take a moment to inventory your directory structure.

DRP_CODE – Main Code Directory containing all sub-dirs for executeable code and in our example the raw and reduced sub-directories.

* MOSFIRE – directory containing the reduction code
* apps – directory containing a few additional applications:
* what – useful pretty printer for files
* handle – the entry point for creating driver files (more later)
* badpixels – directory containing badpixel maps.
* Drivers – directory containing example driver files. These files are used to initiate the redution process and you will modify them for your specific data sets. This will be discussed in more detail later.
* Driver.py – used for YJH reductions
* K_driver.py – Contains code specific to K band observations
* Longslit_driver.py – Longslit reductions
* Long2pos_driver.py – long2pos and long2pos_specphot reductions
* Platescale – contains a file that describes the detector plate scale

Directories created by you

* DATA – sub directory in which you can store your data. This is not a necessary sub-directory but may help you manage files. Raw data may be stored in other areas on your disk.
* REDUX – sub directory where reductions will be stored. Also not critical, but helpful.
* bin – has the modified mospy executable command

From now on, if you want to run any pipeline commands, you will always execute “mospy” as seen in our first step in section 5 below.
