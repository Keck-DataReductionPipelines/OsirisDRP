package edu.ucla.astro.osiris.drp.util;

import org.jdom.*;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Iterator;
import org.jdom.output.XMLOutputter;
import org.jdom.output.Format;

/**
 * <p>Title: OSIRIS Software Package</p>
 * <p>Description: </p>
 * <p>Copyright: Copyright (c) 2004</p>
 * <p>Company: UCLA Infrared Imaging Detector Laboratory</p>
 * @author Jason L. Weiss
 * @version 1.0
 */

public class DRF {

  private static double DRF_DEFAULT_VERSION = 1.0; //. move to parameter file
  private double defaultVersion;

  public DRF() {
    defaultVersion=DRF_DEFAULT_VERSION;
  }

  public DataReductionDefinition openDRF(File xmlFile) throws IOException, JDOMException {
    Attribute workingAtt;
    double drfVersion;

    //. create working dataset
    DataReductionDefinition workingDRD=new DataReductionDefinition();

    //. open file and build local document model.  throws IOException or JDOMException on errors.
    org.jdom.input.SAXBuilder builder = new org.jdom.input.SAXBuilder();
    org.jdom.Document myDoc = builder.build(xmlFile);

    //. get root element.  Must be DRF.
    Element root=myDoc.getRootElement();
    //. check to see if DRF
    if (!"DRF".equals(root.getName())) {
      throw new JDOMException("File is not a DRF!");
    }

    //. make sure DDF tag has version attribute
    workingAtt = root.getAttribute("version");
    if (workingAtt == null) {
      //. for now, support no version, just use default
      //. throw new JDOMException("DRF must have version attribute tag.");
    	drfVersion=defaultVersion;
    } else
      drfVersion=workingAtt.getDoubleValue();

    //. get LogPath
    workingAtt = root.getAttribute("LogPath");
    if (workingAtt != null) {
      workingDRD.setLogPath(workingAtt.getValue());
    }
    //. get ReductionType;
    workingAtt = root.getAttribute("ReductionType");
    if (workingAtt != null) {
      workingDRD.setReductionType(workingAtt.getValue());
    }

    //. version 1
    if (drfVersion == 1.0) {
      //. get children elements
      List rootElements=root.getChildren();
      //. loop through them
      for (Iterator i1 = rootElements.iterator(); i1.hasNext(); ) {
        //. get current element
        Element currentRootChild=(Element)i1.next();
        //. get name of element
        String rootChildName=currentRootChild.getName();
        try {
	  //. if it is a dataset tag
	  if ("dataset".equals(rootChildName)) {
	    //. get InputDir attribute
	    workingAtt=currentRootChild.getAttribute("InputDir");
	    if (workingAtt != null)
              workingDRD.setDatasetInputDir(workingAtt.getValue());
	    //. get Name attribute
	    workingAtt=currentRootChild.getAttribute("Name");
	    if (workingAtt != null)
              workingDRD.setDatasetName(workingAtt.getValue());
            //. get OutputDir attribute
	    workingAtt=currentRootChild.getAttribute("OutputDir");
	    if (workingAtt != null)
	    	workingDRD.setDatasetOutputDir(workingAtt.getValue());

	    //. get dataset children elements
      List datasetElements = currentRootChild.getChildren();
      //. loop through them
      for (Iterator i2 = datasetElements.iterator(); i2.hasNext(); ) {
      	//. get current dataset child element
        Element currentDatasetChild = (Element)i2.next();
        //. get name of element
        String datasetChildName = currentDatasetChild.getName();

        //. make sure it is a fits tag
        if ("fits".equals(currentDatasetChild.getName())) {
        	//. get fits filename
        	workingAtt = currentDatasetChild.getAttribute("FileName");
          if (workingAtt != null)
          	workingDRD.getDatasetFitsFileList().add(workingAtt.getValue());
        } //. end if name is fits
      }  //. end for loop over dataset children
	  } //. end if dataset tag

	  else if ("module".equals(rootChildName)) {
	    //. create ReductionModule
	    ReductionModule workingModule = new ReductionModule();
	    //. get CalibrationFile
	    workingAtt =  currentRootChild.getAttribute("CalibrationFile");
	    if (workingAtt != null)
	      workingModule.setCalibrationFile(workingAtt.getValue());
	    //. get Name
	    workingAtt =  currentRootChild.getAttribute("Name");
	    if (workingAtt != null)
	      workingModule.setName(workingAtt.getValue());
	    //. get OutputDir
	    workingAtt =  currentRootChild.getAttribute("OutputDir");
	    if (workingAtt != null)
	      workingModule.setOutputDir(workingAtt.getValue());
	    //. get Save
	    workingAtt =  currentRootChild.getAttribute("Save");
	    if (workingAtt != null)
	      workingModule.setSaveOutput(workingAtt.getIntValue() != 0);
	    //. get SaveOnErr
	    workingAtt =  currentRootChild.getAttribute("SaveOnErr");
	    if (workingAtt != null)
	      workingModule.setSaveOnError(workingAtt.getIntValue() != 0);
	    //. get Skip
	    workingAtt =  currentRootChild.getAttribute("Skip");
	    if (workingAtt != null)
	      workingModule.setSkip(workingAtt.getIntValue() != 0);

	    //. add module to list
	    workingDRD.getModuleList().add(workingModule);
	  }  //. end if module tag
	  else if ("update".equals(rootChildName)) {
	    //. get DatasetNumber
	    workingAtt =  currentRootChild.getAttribute("DataSetNumber");
	    if (workingAtt != null)
	      workingDRD.setUpdateDatasetNumber(workingAtt.getIntValue());
	    //. get HeaderNumber
	    workingAtt =  currentRootChild.getAttribute("HeaderNumber");
	    if (workingAtt != null)
	      workingDRD.setUpdateHeaderNumber(workingAtt.getIntValue());

	    //. get update children elements
      List updateElements = currentRootChild.getChildren();
      //. loop through them
      for (Iterator i3 = updateElements.iterator(); i3.hasNext(); ) {
      	//. get current update child element
        Element currentUpdateChild = (Element)i3.next();

        //. make sure it is a updateParameters tag
        if ("updateParameter".equals(currentUpdateChild.getName())) {
    	    //. create KeywordUpdateReductionModule
    	    KeywordUpdateReductionModule workingModule = new KeywordUpdateReductionModule();
        	//. get keyword name
        	workingAtt = currentUpdateChild.getAttribute("Keyword");
          if (workingAtt != null)
          	workingModule.setKeywordName(workingAtt.getValue());
        	//. get keyword value
          workingAtt = currentUpdateChild.getAttribute("KeywordValue");
          if (workingAtt != null)
          	workingModule.setKeywordValue(workingAtt.getValue());
        	//. get keyword comment
        	workingAtt = currentUpdateChild.getAttribute("KeywordComment");
          if (workingAtt != null)
          	workingModule.setKeywordComment(workingAtt.getValue());
        	//. get keyword datatype
        	workingAtt = currentUpdateChild.getAttribute("KeywordType");
          if (workingAtt != null)
          	workingModule.setKeywordDatatype(workingAtt.getValue());

          //. add module to list
  		    workingDRD.getKeywordUpdateModuleList().add(workingModule);
        } //. end if name is updateParameter
      }  //. end for loop over update children
	  }  //. end if update tag
        } catch (Exception e) {
        	//. generic exception handler... should be improved.
        	throw new JDOMException("Error reading DRF:"+e.getMessage());
        }
      } //. end for loop over root children
    } else {
      throw new JDOMException("DRF version "+drfVersion+" is not supported.");
    }
    return workingDRD;
  }

  public void writeDRF(File xmlFile, DataReductionDefinition drd) throws IOException, JDOMException {
    writeDRF(xmlFile, drd, defaultVersion);
  }
  public void writeDRF(File xmlFile, DataReductionDefinition drd, double version) throws IOException, JDOMException {
    Element currentElement;

    //. write name of drf in comment first

    //. root element is drf
    Element root = new Element("DRF");
    //    root.setAttribute("version", Double.toString(version));
    root.setAttribute("LogPath", drd.getLogPath());
    root.setAttribute("ReductionType", drd.getReductionType());
    Document doc = new Document(root);
    doc.addContent(0, new Comment(" "+drd.getDatasetName()+" "));

    //. have writing block for each version
    //. don't delete old ones
    if (version == 1.0) {
      //. write dataset tag and attributes
      Element datasetElement = new Element("dataset");
      datasetElement.setAttribute("InputDir", drd.getDatasetInputDir());
      datasetElement.setAttribute("Name", drd.getDatasetName());
      datasetElement.setAttribute("OutputDir", drd.getDatasetOutputDir());
      java.util.ArrayList fitsList = drd.getDatasetFitsFileList();
      for (Iterator i1 = fitsList.iterator(); i1.hasNext();) {
        String currentFitsFilename = (String)i1.next();
        currentElement = new Element("fits");
        currentElement.setAttribute("FileName", currentFitsFilename);
        datasetElement.addContent(currentElement);
      }
      root.addContent(datasetElement);

      //. add modules
      java.util.ArrayList moduleList = drd.getModuleList();
      for (Iterator im = moduleList.iterator(); im.hasNext();) {
      	ReductionModule currentModule = (ReductionModule)im.next();
      	currentElement = new Element("module");
      	currentElement.setAttribute("CalibrationFile", currentModule.getCalibrationFile());
      	currentElement.setAttribute("Name", currentModule.getName());
      	currentElement.setAttribute("OutputDir", currentModule.getOutputDir());
      	currentElement.setAttribute("Save", currentModule.doSaveOutput() ? "1" : "0");
      	currentElement.setAttribute("SaveOnErr", currentModule.doSaveOnError() ? "1" : "0");
      	currentElement.setAttribute("Skip", currentModule.doSkip() ? "1" : "0");

      	root.addContent(currentElement);
      }
      
      //. add update
      ArrayList updateList = drd.getKeywordUpdateModuleList();
      if (!updateList.isEmpty()) {
      	Element updateElement = new Element("update");
      	updateElement.setAttribute("DataSetNumber", Integer.toString(drd.getUpdateDatasetNumber()));
      	updateElement.setAttribute("HeaderNumber", Integer.toString(drd.getUpdateHeaderNumber()));
      	for (Iterator iu = updateList.iterator(); iu.hasNext();) {
      		KeywordUpdateReductionModule currentModule = (KeywordUpdateReductionModule)iu.next();
      		if (currentModule.getKeywordName().length() > 0) {
      			currentElement = new Element("updateParameter");
      			currentElement.setAttribute("Keyword", currentModule.getKeywordName());
      			currentElement.setAttribute("KeywordValue", currentModule.getKeywordValue());
      			currentElement.setAttribute("KeywordComment", currentModule.getKeywordComment());
      			currentElement.setAttribute("KeywordType", currentModule.getKeywordDatatype());
      		
      			updateElement.addContent(currentElement);
      		}
      	}
      	root.addContent(updateElement);
      }
      
    } else {
      throw new JDOMException("DRF Version "+Double.toString(version)+" not supported.");
    }

    XMLOutputter outputter = new XMLOutputter(Format.getPrettyFormat());
    outputter.output(doc, new java.io.FileOutputStream(xmlFile));
  }
}
