---
layout: page
title: Retrieve Your Data
permalink: /manual/retrieve
---

Before running the drp, you will need a set of spectroscopic data to reduce that includes flats, science observations, and if the observations are K-band, arcs and thermal flats. NOTE: You must preserve Keck’s file naming convention as the DRP uses the file name to parse data sets. The standard naming convention is `mYYMMDD_####.fits`. 

If you need to retrieve your data, you may either use a secure copy (scp) assumine your data is still accessible from the Keck/MOSFIRE data directory (contact your SA if you need assistance) or use KOA –the Keck Observatory Archive to navigate to the KOA log in page. From there, KOA has forms where you specify the data to retrieve and will create a tar ball for you to download.

A useful tool is the file translator script that will convert your KOA file names to the standard filenames as they were written to disk during your observing session (koa_translator). Again, your filenames must preserve the standard naming convention and the koa_translator script does this for you.

If you do not have data of your own and wish to download the example:
Grab the data from: [http://mosfire.googlecode.com/files/DRP_Test_Case_Hband.zip](http://mosfire.googlecode.com/files/DRP_Test_Case_Hband.zip).

Move the test case zip file to a directory of your choice (we will assume `~/Data` for the examples in this manual) and unzip the DRP test case file:

    unzip DRP_Test_Case_Hband.zip

This will create a `DRP_Test_Case_Hband` subdirectory under your current directory which will contain the raw data which you can use to follow along in subsequent steps of the DRP manual.

