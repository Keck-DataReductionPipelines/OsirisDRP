package edu.ucla.astro.osiris.drp.util;

import java.io.*;
import nom.tam.util.*;
import nom.tam.fits.*;
import java.text.DecimalFormat;


/**
 * <p>Title: OSIRIS Software Package</p>
 * <p>Description: </p>
 * <p>Copyright: Copyright (c) 2004</p>
 * <p>Company: UCLA Infrared Imaging Detector Laboratory</p>
 * @author Jason L. Weiss
 * @version 1.0
 */

public class DRDInputFile {
  private String filter;
  private String scale;
  private File myFile;
  private Header header;
  private String ss1name;
  private String ss2name;
  private String sfwname;
  
  public DRDInputFile(File file) throws IOException, TruncatedFileException {
    myFile=file;
		BufferedFile bf = new BufferedFile(myFile.getAbsolutePath());
		header = Header.readHeader(bf);
  }
  public void validateFilter() throws DRDException {
    filter = header.getStringValue("SFILTER");
    if (filter == null) {
    	sfwname = header.getStringValue("SFWNAME");
    	
      throw new DRDException("SFILTER keyword not found.");
    }
  }
  public void validateScale() throws DRDException {
    // Scale position values may have the form "0.nXX"  where there may or may not be
    // trailing 0's in place of the XX's.  For example, we could have "0.1"
    // or "0.10" or "0.100" but only "0.035" will occur.
  	DecimalFormat scaleFormatter = new DecimalFormat("0.000");

  	String sv = header.getStringValue("SSCALE");
    if (sv == null) {
    	//. SSCALE is missing, get each scale mech position
    	String sstemp;
    	sstemp = header.getStringValue("SS1NAME");
    	if (sstemp != null) {
      	ss1name = scaleFormatter.format(Double.parseDouble(sstemp));
    	}
    	sstemp = header.getStringValue("SS2NAME");
    	if (sstemp != null) {
      	ss2name= scaleFormatter.format(Double.parseDouble(sstemp));
    	}
    	
      throw new DRDException("SSCALE keyword not found.");
    } else {
    	scale = scaleFormatter.format(Double.parseDouble(sv));
    }

  }
  public String getScale() {
    return scale;
  }
  public String getFilter() {
    return filter;
  }
  public void overrideScale(String newScale) {
  	scale = newScale;
  }
  public void overrideFilter(String newFilter) {
  	filter = newFilter;
  }
  public String getName() {
    return myFile.getName();
  }
  public String toString() {
    return myFile.getAbsolutePath();
  }
  public String getDirectory() {
    return myFile.getParent();
  }
  public Header getHeader() {
  	return header;
  }
  public String getSS1Name() {
    return ss1name;
  }
  public String getSS2Name() {
    return ss2name;
  }
  public String getSFWName() {
    return sfwname;
  }
}
