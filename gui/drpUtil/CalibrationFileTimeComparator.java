package edu.ucla.astro.osiris.drp.util;

import java.util.Comparator;
import java.io.File;

/**
 * <p>Title: OSIRIS Software Package</p>
 * <p>Description: </p>
 * <p>Copyright: Copyright (c) 2004</p>
 * <p>Company: UCLA Infrared Imaging Detector Laboratory</p>
 * @author Jason L. Weiss
 * @version 1.0
 */
/*
  if it has a date, it goes last, sorted by date first, then mod date
  if not, if goes first, sorted by mod date.

  Final sort should be:

  cblah        (mod date 050101 12:00)
  ablah        (mod date 050101 13:00)
  blahblah     (mod date 050101 14:00)
  s050101_blah (mod date 050301 15:00)
  a050102_blah (mod date 050101 11:00)
  x050201_blah (mod date 050201 13:00)
  x050201_blah (mod date 050201 14:00)

*/
public class CalibrationFileTimeComparator implements Comparator {

  public CalibrationFileTimeComparator() {
  }
  public int compare(Object parm1, Object parm2) {
    File f1 = (File)parm1;
    File f2 = (File)parm2;

    /* first sort by YYMMDD, which should be chars 1-6 */
    String f1name = f1.getName();
    String f2name = f2.getName();
    String date1 = "";
    String date2 = "";

    //. extract date. make sure chars 1-6 are digits
    if (f1name.length() > 6) {
      date1 = areDigits(f1name.substring(1,7));
    }
    if (f2name.length() > 6) {
      date2 = areDigits(f2name.substring(1,7));
    }
    if (date1.equals("")) {
      if (date2.equals("")) {  //. both do not have dates
	return compareByModificationDate(f1, f2);
      } else {  //. f2 has a date, but f1 does not
	return -1;
      }
    } else {
      if (date2.equals("")) { //. f1 has a date, but f2 does not
	return 1;
      } else {  //. both have dates
	if (date1.equals(date2))
	  return compareByModificationDate(f1,f2);
	else
	  return date1.compareTo(date2);
      }
    }
  }
  private String areDigits(String test) {
    for (int ii=0; ii<test.length(); ii++) {
      if (!Character.isDigit(test.charAt(ii)))
	return "";
    }
    return test;
  }
  private int compareByModificationDate(File f1, File f2) {
    long timeo1 = f1.lastModified();
    long timeo2 = f2.lastModified();
    return (int) (timeo1 - timeo2);

  }

  public static void main(String[] args) {
    File dir = new File("/home/osrsdev/osiris_test/oorp_test/");
    File[] list = dir.listFiles();
    java.util.Arrays.sort(list, new CalibrationFileTimeComparator());
    for (int ii=0; ii<list.length; ii++) {
      System.out.println(list[ii].getName());
    }
  }

}