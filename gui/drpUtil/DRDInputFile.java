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
  public String filter;
  public String scale;
  public File myFile;
  public DRDInputFile(File file) throws DRDException, IOException, TruncatedFileException {
    myFile=file;
    validateFile();
  }
  private void validateFile() throws DRDException, IOException, TruncatedFileException {
    //. make sure file is OSIRIS spec file
    //. get filter and scale
    BufferedFile bf = new BufferedFile(myFile.getAbsolutePath());
    Header hdr = Header.readHeader(bf);
    filter = hdr.getStringValue("SFILTER");
    if (filter == null)
      throw new DRDException("Error opening FITS file.  SFILTER keyword not found.");
   String sv = hdr.getStringValue("SSCALE");
    if (sv == null)
      throw new DRDException("Error opening FITS file.  SSCALE keyword not found.");
    // This value may have the form "0.nXX"  where there may or may not be
    // trailing 0's in place of the XX's.  For example, we could have "0.1"
    // or "0.10" or "0.100" but only "0.035" will occur.
    DecimalFormat scaleFormatter = new DecimalFormat("0.000");
    scale = scaleFormatter.format(Double.parseDouble(sv));
  }
  public String getScale() {
    return scale;
  }
  public String getFilter() {
    return filter;
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
}
