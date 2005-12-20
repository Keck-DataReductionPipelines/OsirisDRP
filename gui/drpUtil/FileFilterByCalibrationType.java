package edu.ucla.astro.osiris.drp.util;

import java.io.*;

/**
 * @author tgasaway
 *
 * To use
 * File f = new File("<Filename of a directory>");
 * FileExtensionFilter filter = new FileExtensionFilter("<type of file>");
 * String[] contents = f.list(filter);
 */
public class FileFilterByCalibrationType implements FilenameFilter{
	private String type = "";
	public FileFilterByCalibrationType(String type){
	    this.type = type;
	}
	public boolean accept(File dir, String name){
	    if (name.indexOf(type) > 0)
	        return true;
	    return false;
	}
}