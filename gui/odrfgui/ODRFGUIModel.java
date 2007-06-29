package edu.ucla.astro.osiris.drp.odrfgui;

import edu.ucla.astro.osiris.drp.util.*;
import edu.ucla.astro.osiris.util.*;
import org.jdom.*;
import edu.hawaii.keck.kjava.*;
import nom.tam.fits.TruncatedFileException;

import java.io.*;
import java.beans.*;
import java.util.*;

/** @todo load new templates */
public class ODRFGUIModel extends GenericModel {
  DRF myDRF = new DRF();
  private ArrayList inputFileList = new ArrayList();
  private ArrayList arpReductionModuleList = new ArrayList();
  private ArrayList crpReductionModuleList = new ArrayList();
  private ArrayList orpReductionModuleList = new ArrayList();
  private ArrayList activeModuleList = new ArrayList();
  private ArrayList availableModuleList;
  private ArrayList reductionTemplates;
  private ReductionModule activeModule;
  private String reductionType;
  private String workingFilter = "None";
  private String workingScale = "None";
  private ReductionTemplate activeReductionTemplate;
  private File inputDir;
  private File outputDir;
  private File logPath;
  private String datasetName = "";
  private File calibDir;
  private boolean automaticallyGenerateDatasetName;
  private File queueDir;
  private int queueNumber;
  private ArrayList updateKeywordModuleList = new ArrayList();
  private boolean writeDRFVerbose;
  
  public ODRFGUIModel() throws java.io.IOException, org.jdom.JDOMException, DRDException {
    inputDir = ODRFGUIParameters.DEFAULT_INPUT_DIR;
    outputDir = ODRFGUIParameters.DEFAULT_OUTPUT_DIR;
    logPath = ODRFGUIParameters.DEFAULT_LOG_DIR;
    calibDir = ODRFGUIParameters.OSIRIS_CALIB_ARCHIVE_DIR;
    queueDir = ODRFGUIParameters.DRF_QUEUE_DIR;
    
    automaticallyGenerateDatasetName = ODRFGUIParameters.DEFAULT_AUTOSET_DATASET_NAME;
    writeDRFVerbose = ODRFGUIParameters.DEFAULT_WRITE_DRF_VERBOSE;

    queueNumber=0;

    //. open up rpbconfig file and populate module lists
    openRPBConfig(ODRFGUIParameters.OSIRIS_DRP_BACKBONE_CONFIG_FILE);
    //. complete module definitions
    initializeModuleList(arpReductionModuleList);
    initializeModuleList(orpReductionModuleList);
    initializeModuleList(crpReductionModuleList);

    //. set default reduction type
    reductionType = ODRFGUIParameters.DEFAULT_REDUCTION_TYPE;
    
    
    //. set availableModuleList to default
    resetAvailableModuleList();

    //. populate default template list
    setDefaultTemplateList();

    //. use first template as default
    if (!reductionTemplates.isEmpty())
    	setActiveReductionTemplate((ReductionTemplate)reductionTemplates.get(0));
  }
  private void resetAvailableModuleList() {
    ArrayList list;
    ArrayList workingActiveList;
    //. set active module list
    if (reductionType.equals(ODRFGUIParameters.REDUCTION_TYPE_CRP_SPEC))
      list = crpReductionModuleList;
    else if (reductionType.equals(ODRFGUIParameters.REDUCTION_TYPE_ORP_SPEC))
      list = orpReductionModuleList;
    else
      list = arpReductionModuleList;

    //. trim unavailable modules from active list
    boolean listChanged = false;
    boolean[] errantModules = new boolean[activeModuleList.size()];
    int index=0;
    //. go through active list and mark errant modules
    for (Iterator ii = activeModuleList.iterator(); ii.hasNext(); ) {
    	ReductionModule module = (ReductionModule)ii.next();
 
    	//. module is not in list, getReductionModule returns null
    	if (getReductionModule(list, module.getName()) == null) {
    		errantModules[index] = true;
    		listChanged=true;
    	}
    	index++;
    }
    //. if there was a change
    if (listChanged) {
    	//. work backwards, so as we remove, indices don't change
	    for (index--; index>=0; index--) {
	    	if (errantModules[index])
	    		activeModuleList.remove(index);
	    }
	    //. broadcast chagne
      propertyChangeListeners.firePropertyChange("activeModuleList", null, activeModuleList); 
    }
    //. set new available list
    setAvailableModuleList(list);
   
  }
  private void setDefaultTemplateList() throws JDOMException, IOException, DRDException {
    ArrayList workingTemplateList = new ArrayList();
    //. go through list set in ODRFGUIParameters
    for (int ii=0; ii<ODRFGUIParameters.DEFAULT_REDUCTION_TEMPLATE_LIST.length; ii++) {
      try {
      	//. create the template object
      	ReductionTemplate template = new ReductionTemplate(ODRFGUIParameters.DEFAULT_REDUCTION_TEMPLATE_LIST[ii]);
      	//. make sure format of modules match what is in RPBCOnfig
      	correlateDRDWithRPBConfig(template.getDRD());
      	//. if ok, add to list
      	workingTemplateList.add(template);
      } catch (JDOMException jdEx) {
      	throw new JDOMException("Error parsing template <"+ODRFGUIParameters.DEFAULT_REDUCTION_TEMPLATE_LIST[ii]+">: "+jdEx.getMessage());
      } catch (IOException ioEx) {
      	throw new IOException("Error parsing template <"+ODRFGUIParameters.DEFAULT_REDUCTION_TEMPLATE_LIST[ii]+">: "+ioEx.getMessage());
      } catch (DRDException drdEx) {
      	throw new DRDException("Error parsing template <"+ODRFGUIParameters.DEFAULT_REDUCTION_TEMPLATE_LIST[ii]+">: "+drdEx.getMessage());
      }
    }
    //. set list
    reductionTemplates = workingTemplateList;    
  }
  public void openRPBConfig(File xmlFile) throws java.io.IOException, org.jdom.JDOMException, DRDException {
    Attribute workingAtt;
    ArrayList list;

    try {
	    //. open file and build local document model.  throws IOException or JDOMException on errors.
	    org.jdom.input.SAXBuilder builder = new org.jdom.input.SAXBuilder();
	    org.jdom.Document myDoc = builder.build(xmlFile);
	
	    //. get root element.  Must be DRF.
	    Element root=myDoc.getRootElement();
	    //. check to see if DRF
	    if (!"Config".equals(root.getName())) {
	      throw new JDOMException("File is not a RPB Config File!");
	    }
	    //. get children elements
	    List rootElements=root.getChildren();
	    //. loop through them
	    for (Iterator i1 = rootElements.iterator(); i1.hasNext(); ) {
	      //. get current element
	      Element currentRootChild=(Element)i1.next();
	      //. get name of element
	      String rootChildName=currentRootChild.getName();
	      //. check what kind of reduction definition
	      if ("CRP_SPEC".equals(rootChildName)) {
	      	list = crpReductionModuleList;
	      } else if ("ARP_SPEC".equals(rootChildName)) {
	        list = arpReductionModuleList;
	      } else if ("ORP_SPEC".equals(rootChildName)) {
	        list = orpReductionModuleList;
	      } else {
	      	//. if not one of these, skip it
	        continue;
	      }
	      //. get children. should be modules
	      List moduleList = currentRootChild.getChildren();
	      for (Iterator i2 = moduleList.iterator(); i2.hasNext();) {
	      	Element module = (Element)i2.next();
	      	//. only worry about module elements
	      	if (module.getName().equals("Module")) {
	      		workingAtt=module.getAttribute("HideInGUI");
	      		if (workingAtt != null)
	      			if (workingAtt.getValue().compareTo("1") == 0)
	      				continue;
	      		workingAtt=module.getAttribute("Name");
	      		if (workingAtt != null) {
	      			ReductionModule newModule = new ReductionModule();
	      			newModule.setName(workingAtt.getValue());
	      			
	      			//. get module description, if available
	      			workingAtt = module.getAttribute("Comment");
	      			if (workingAtt != null) 
	      				newModule.setDescription(workingAtt.getValue());
	      			
	      			//. check for children argument tags
	      			List arguments = module.getChildren();
	    				ArrayList moduleArguments = new ArrayList();
	      			for (Iterator i3 = arguments.iterator(); i3.hasNext();) {
	      				Element arg = (Element)i3.next();
	      				//. make sure it is an argument tag
	      				if (arg.getName().equals("Argument")) {
	      					//. get name of arg
	      					workingAtt = arg.getAttribute("Name");
	      					if (workingAtt != null) {
	      						//. if name is given, create new arg with that name
	      						ReductionModuleArgument newArg = new ReductionModuleArgument(workingAtt.getValue());
	      						workingAtt = arg.getAttribute("Type");
	      						if (workingAtt != null) {
	      							//. if a type is given, set it.
	      							newArg.setType(workingAtt.getValue());
	      						}
	      						workingAtt = arg.getAttribute("Range");
	      						if (workingAtt != null) {
	      							//. if a range is given, add it.
	      							newArg.setRange(workingAtt.getValue());
	      						} else if (newArg.getType().compareTo(ReductionModuleArgument.TYPE_ENUM) == 0) {
	      							throw new DRDException("Module <"+newModule.getName()+">, argument <"+newArg.getName()+">:  Enum arguments must specify a range.");			
	      						}
	      						workingAtt = arg.getAttribute("Default");
	      						if (workingAtt != null) {
	      							//. if a default value is given, set it.
	      							newArg.setValue(workingAtt.getValue());
	      						}
	      						//. add new Argument to list
	      						moduleArguments.add(newArg);
	      					}
	      				}
	      			}
	      			//. if there are arguments, add it to the module
	      			if (moduleArguments.size() > 0)
	      				newModule.setArguments(moduleArguments);
	      			
	      			//. if all good, add module
	            list.add(newModule);
	      		}
	        }
	      }
	    }
    } catch (JDOMException jdEx) {
    	throw new JDOMException("Error parsing RPBConfig. "+jdEx.getMessage());
    } catch (IOException ioEx) {
    	throw new IOException("Error parsing RPBConfig. "+ioEx.getMessage());
    } catch (DRDException drdEx) {
    	throw new DRDException("Error parsing RPBConfig. "+drdEx.getMessage());
    }
  }
  
  private void correlateDRDWithRPBConfig(DataReductionDefinition drd) throws DRDException {
    correlateDRDWithRPBConfig(drd.getReductionType(), drd.getModuleList());
  }
  
  private void correlateDRDWithRPBConfig(String reductionType, ArrayList moduleList) throws DRDException {
    ArrayList list;
    //. set active module list
    if (reductionType.equals(ODRFGUIParameters.REDUCTION_TYPE_CRP_SPEC))
      list = crpReductionModuleList;
    else if (reductionType.equals(ODRFGUIParameters.REDUCTION_TYPE_ORP_SPEC))
      list = orpReductionModuleList;
    else
      list = arpReductionModuleList;
  
    ReductionModule module;
    ReductionModule listModule;
    ArrayList moduleArgs;
    ArrayList listModuleArgs;
		ReductionModuleArgument arg;
		ReductionModuleArgument listArg;
    boolean moduleExists;
		boolean argExistsInRPBConfig;
		boolean argExistsInModule;
		
		//. go through modules
    for (Iterator iModule = moduleList.iterator(); iModule.hasNext();) {
  		module = (ReductionModule)iModule.next();
  		
  		moduleExists = false;
  		//. make sure module is in RPBconfig
  		for (Iterator iList = list.iterator(); iList.hasNext();) {
  			listModule = (ReductionModule)iList.next();
  			
  			if (module.getName().compareTo(listModule.getName()) == 0) {
  				moduleExists = true;
  	  		
  				//. verify arguments match.  if missing from module, add with defaults
  				moduleArgs = module.getArguments();
  				listModuleArgs = listModule.getArguments();
  				
  				
  				//. first, go through module args and look for agruments that are not in rpbconfig
  				for (Iterator iModuleArgs = moduleArgs.iterator(); iModuleArgs.hasNext();) {
  					arg = (ReductionModuleArgument)iModuleArgs.next();
  					
  					argExistsInRPBConfig = false;
  					for (Iterator iListArgs = listModuleArgs.iterator(); iListArgs.hasNext();) {
  						listArg = (ReductionModuleArgument)iListArgs.next();
  						if (listArg.getName().compareTo(arg.getName()) == 0) {
  							argExistsInRPBConfig = true;
  							//. use type and range from RPBConfig
  							arg.setType(listArg.getType());
  							arg.setRange(listArg.getRange());
  							//. check if value is valid
  							arg.setValue(arg.getValue());
  							
  							continue;
  						}
  					}
  					//. if argument isn't in RPBConfig, throw an error
  					if (!argExistsInRPBConfig) 
  						throw new DRDException("Argument <"+arg.getName()+"> not listed as valid argument for module <"+module.getName()+"> in RPBConfig.");
  				}
  				
  				//. now go through rpbconfig, and add to module any missing tags
 					for (Iterator iListArgs = listModuleArgs.iterator(); iListArgs.hasNext();) {
						listArg = (ReductionModuleArgument)iListArgs.next();

						argExistsInModule = false;
						//. if module has args, go through them
						for (Iterator iModuleArgs = moduleArgs.iterator(); iModuleArgs.hasNext();) {
 	  					arg = (ReductionModuleArgument)iModuleArgs.next();
 	  					//. if arg is in there, it's all good, move on
 	  					if (listArg.getName().compareTo(arg.getName()) == 0) {
  							argExistsInModule = true;
  							continue;
  						}
 						}
 						//. if argument not there, add it!
 						if (!argExistsInModule) {
 							module.getArguments().add(new ReductionModuleArgument(listArg));
 						}
 					}
  			}
  		}
  		//. if module is not found in RPBConfig, throw error
  		if (!moduleExists) 
  			throw new DRDException("Module <"+module.getName()+"> not found in RPBconfig for reduction type <"+reductionType+">.");
  	}
  }
  
  public ArrayList getInputFileList() {
    return inputFileList;
  }
  public void removeInputFiles(int[] indices) {
  	int ii=0;
  	//. make sure files are selected
  	if (indices.length > 0) {
  		//. make sure first one is positive (should be sorted)
			if (indices[0] >= 0) {
				//. make sure list isn't empty already (shouldn't be)
				if (!inputFileList.isEmpty()) {
					//. go through indices
					for (ii=0; ii<indices.length;ii++) {
						//. remove the file (remember index is decremented when a file is removed)
						inputFileList.remove(indices[ii]-ii);
					}
					//. broadcast change
					propertyChangeListeners.firePropertyChange("inputFileList", null, inputFileList);
				}
			}
  	}
  }
  public void clearInputFileList() {
  	//. clear list
    inputFileList = new ArrayList();
    //. reset working filter and scale
    setWorkingFilter("None");
    setWorkingScale("None");
    //. broadcast change
    propertyChangeListeners.firePropertyChange("inputFileList", null, inputFileList);
  }

  public void addInputFile(DRDInputFile file) throws DRDException {
  	String newInputDir="";
  	String newFilter="";
  	String newScale="";
  	
  	//. make sure input dir is same as what's there
  	if (inputFileList.isEmpty()) {
  		//. no files, use new input dir then
  		newInputDir = file.getDirectory();
  	} else {
  		//. otherwise, make sure input dir is same
    	if (inputDir.getPath().compareTo(file.getDirectory()) != 0) {
    		throw new DRDException("Input file directory <"+file.getDirectory()+"> does not match current input directory.");
    	}  		
  	}
  	//. make sure filter is the same
  	if (workingFilter.compareTo("None") == 0) {
  		newFilter = file.getFilter();
  	} else {
    	if (workingFilter.compareTo(file.getFilter()) != 0) {
    		if (file.getFilter().compareTo("None") != 0) {
    			
    			throw new DRDException("Input file filter <"+file.getFilter()+"> does not match working filter <"+workingFilter+">.");
    		}
    	}
  	}
  	//. make sure scale is the same
  	if (workingScale.compareTo("None") == 0) {
  		newScale = file.getScale();
  	} else {
	  	if (workingScale.compareTo(file.getScale()) != 0) {
	  		if (file.getScale().compareTo("None") != 0) {
	  			throw new DRDException("Input file scale <"+file.getScale()+"> does not match working scale <"+workingScale+">.");
	  		}
	  	}
  	}  	
  	//. if inputdir is new, set it
  	if (newInputDir.length() > 0) {
  		setInputDir(new File(newInputDir));
  	}
  	//. if filter is new, set it
  	if (newFilter.length() > 0) {
  		setWorkingFilter(newFilter);
  	}
  	//. if scale is new, set it
  	if (newScale.length() > 0) {
  		setWorkingScale(newScale);
  	}
  	//. add file
  	inputFileList.add(file);
  	//. broadcast change
    propertyChangeListeners.firePropertyChange("inputFileList", null, inputFileList);
    
    //. if dataset name is automatically generated, do it
    if (automaticallyGenerateDatasetName)
    	generateDatasetName();

    resolveFindFiles();
  }
  public void addInputFiles(File[] fileList) throws DRDException {
    //. only allow opening of osiris spec frames with same filter and scale
    //. must be from same directory, which is set to inputDir
  	String currentFilter = "";
  	String currentScale = "";
  	String currentInputDir = "";
  	String listFilter = "";
  	String listScale = "";
  	String listInputDir = "";
  	ArrayList tempInputFileList = (ArrayList)inputFileList.clone();
    DRDInputFile drdFile;
  	for (int ii=0; ii<fileList.length; ii++) {
      try {
      	//. create DRDInputFile object
      	drdFile = new DRDInputFile(fileList[ii]);
      } catch (TruncatedFileException tfE) {
      	tfE.printStackTrace();
      	throw new DRDException("Error opening <"+fileList[ii].toString()+">: "+tfE.getMessage());
      } catch (IOException ioE) {
      	ioE.printStackTrace();
      	throw new DRDException("Error opening <"+fileList[ii].toString()+">: "+ioE.getMessage());
      }
      
      //. check filter
      try {
      	drdFile.validateFilter();
      	currentFilter = drdFile.getFilter();
      } catch (DRDException drdE) {
      	//. if validate fails, sfwname may have valid filter name
      	drdE.printStackTrace();
      	if (drdFile.getSFWName() != null)
      		currentFilter=drdFile.getSFWName();
      	else
      		currentFilter = "";
      }
      
      //. if no filter at all, assume it is ok
      if (currentFilter.length() > 0)  {
      	//. if list filter hasn't been set, set it
      	if (listFilter.length() == 0)
      		listFilter = currentFilter;
      	else {
        	//. otherwise, make sure it matches what has been previously set
      		if (currentFilter.compareToIgnoreCase(listFilter) != 0)
      			throw new DRDException("Error opening <"+fileList[ii].toString()+">: Filter <"+currentFilter+"> does not match working filter <"+listFilter+">.");
      	}
      }
      //. check scale
      try {
      	drdFile.validateScale();
      	currentScale = drdFile.getScale();
      } catch (DRDException drdE) {
      	//. if validate fails, ss1name may have valid scale name
      	drdE.printStackTrace();
      	String ss1Name = drdFile.getSS1Name();
      	String ss2Name = drdFile.getSS2Name();
      	//. if ss1Name and ss2Name are both null, currentScale is ""
      	//. if only one of them is null, then use the other
      	//. if both are not null, and are the same, use that value
      	//. if both are not null, but differ, throw an exception
      	if (ss1Name != null) {
      		if (ss2Name != null) {
      			if (ss1Name.compareToIgnoreCase(ss2Name) != 0) 
      				throw new DRDException("Error opening <"+fileList[ii].toString()+">: SSCALE keyword missing, and SS1NAME <"+ss1Name+"> and SS2NAME <"+ss2Name+"> keywords don't match.");
      		}  
       		currentScale=ss1Name;
      	}	else {
      		//. if ss1name isn't there, try ss2name
      		if (ss2Name != null)
      			currentScale=ss2Name;
      		else
      			currentScale = "";
      	}
      }
      
      //. if no scale at all, assume it is ok
      if (currentScale.length() > 0)  {
      	//. if list scale hasn't been set, set it
      	if (listScale.length() == 0)
      		listScale = currentScale;
      	else {
        	//. otherwise, make sure it matches what has been previously set
      		if (currentScale.compareToIgnoreCase(listScale) != 0)
      			throw new DRDException("Error opening <"+fileList[ii].toString()+">: Scale <"+currentScale+"> does not match working scale <"+listScale+">.");
      	}
      }
      
      //. check inputdir
      currentInputDir = drdFile.getDirectory();
      //. if no input dir at all, assume it is ok
      if (currentInputDir.length() > 0)  {
      	//. if list input dir hasn't been set, set it
      	if (listInputDir.length() == 0)
      		listInputDir = currentInputDir;
      	else {
        	//. otherwise, make sure it matches what has been previously set
      		if (currentInputDir.compareTo(listInputDir) != 0)
      			throw new DRDException("Error opening <"+fileList[ii].toString()+">: Input dir <"+currentInputDir+"> does not match working input dir <"+listInputDir+">.");
      	}
      }
      
      //. if it passes all these checks (matching filter, scale, and output dir), add it to the list.
    	tempInputFileList.add(drdFile);

    }
    
  	//. if there are valid files
    if (!tempInputFileList.isEmpty()) {
    	//. set the working filter, scale, and inputdir
      setWorkingFilter(listFilter);
      setWorkingScale(listScale);
      setInputDir(new File(listInputDir));
      
      //. set list
      inputFileList = tempInputFileList;
      
      //. generate dataset name is needed
      if (automaticallyGenerateDatasetName)
      	generateDatasetName();
      
      //. broadcast change
      propertyChangeListeners.firePropertyChange("inputFileList", null, inputFileList);
      
      //. updated find files
      resolveFindFiles();
    }
  }
  public boolean areActiveCalFilesValiated() {
  	//. go though active list
    for (Iterator ii = activeModuleList.iterator(); ii.hasNext();) {
      ReductionModule module = (ReductionModule)ii.next();
      //. only care about modules that are not skipped
      if (!module.doSkip())
      	//. check if cal file is validated
      	if (!module.isCalibrationFileValidated())
      		return false;
    }
    return true;
  }
  public void openDRF(File drf) throws org.jdom.JDOMException, java.io.IOException, DRDException {
  	//. open file
  	DataReductionDefinition drd = myDRF.openDRF(drf);
  	//. check format of modules with RPBConfig
  	correlateDRDWithRPBConfig(drd);

  	//. set basic drd settings
    setInputDir(new File(drd.getDatasetInputDir()));
    setDatasetName(drd.getDatasetName());
    setOutputDir(new File(drd.getDatasetOutputDir()));
    setLogPath(new File(drd.getLogPath()));
    setReductionType(drd.getReductionType());
    //. reset input file list
    clearInputFileList();
    
    //. create input file list
    ArrayList inputFiles = drd.getDatasetFitsFileList();
    File[] fileList = new File[inputFiles.size()];
    int index=0;
    for (Iterator ii = inputFiles.iterator(); ii.hasNext();) {
      fileList[index]=new File(inputDir+File.separator+(String)ii.next());
      index++;
    }
    //. add files to list
    addInputFiles(fileList);
    //. init modules
    initializeModuleList(drd.getModuleList());
    //. set active list
    setActiveModuleList(drd.getModuleList());
    //. set fits header updates
    setUpdateKeywordModuleList(drd.getKeywordUpdateModuleList());
    //. resolve find files
    resolveFindFiles();
  }
  public String writeDRFToQueue() throws java.io.IOException, org.jdom.JDOMException {
  	//. create formatter for queue number.  always three digits
    java.text.DecimalFormat threeDigitFormatter = new java.text.DecimalFormat("000");
    //. construct file root
    String fileroot = queueDir+File.separator+threeDigitFormatter.format((long)queueNumber)+"."+datasetName+"_drf.";
    //. write first drf with .writing extension
    String writtenDRFFilename = fileroot+ODRFGUIParameters.DRF_EXTENSION_WRITING;
    //. when queued, it will have .waiting extension
    String queuedDRFFilename = fileroot+ODRFGUIParameters.DRF_EXTENSION_QUEUED;

    //. create file
    File writtenDRF = new File(writtenDRFFilename);
    //. write it to disk
    writeDRF(writtenDRF);

    //. copy file to queue.  can't write directly to queue because backbone will try to open 
    //. before the drf is finished writing.
    System.out.println("Copying file from temporary DRF to: "+queuedDRFFilename);

    //. the following algorithm is from the Java Developers Almanac 1.4 item e1071
    
    //. init streams
    InputStream in = new FileInputStream(writtenDRF);
    OutputStream out = new FileOutputStream(queuedDRFFilename);

    // Transfer bytes from in to out
    byte[] buf = new byte[1024];
    int len;
    while ((len = in.read(buf)) > 0) {
      out.write(buf, 0, len);
    }
    in.close();
    out.close();

    //. delete temp drf
    System.out.println("Deleting temporary DRF: "+writtenDRFFilename);
    writtenDRF.delete();
    //. increment queue number
    queueNumber++;
    //. return final drf name
    return queuedDRFFilename;
  }
  public void writeDRF(File drfFile) throws java.io.IOException, org.jdom.JDOMException {
    //. construct workingDRD
    DataReductionDefinition workingDRD = new DataReductionDefinition();

    //. get input dir
    workingDRD.setDatasetInputDir(inputDir.getAbsolutePath());
    //. populate fits file list in DRD with just the names of files
    ArrayList inputFileNames = new ArrayList();
    for (Iterator ii=inputFileList.iterator(); ii.hasNext();) {
      inputFileNames.add(((DRDInputFile)ii.next()).getName());
    }
    //. set DRD params
    workingDRD.setDatasetFitsFileList(inputFileNames);
    workingDRD.setDatasetName(datasetName);
    workingDRD.setDatasetOutputDir(outputDir.getAbsolutePath());
    workingDRD.setReductionType(reductionType);
    workingDRD.setLogPath(logPath.getAbsolutePath());

    //. go through modules and set output dir to the same as the dataset dir
    for (Iterator ii = activeModuleList.iterator(); ii.hasNext();) {
    	ReductionModule module = (ReductionModule)(ii.next());
    	if (module.getOutputDir().compareTo("") == 0)
    		module.setOutputDir(outputDir.getAbsolutePath());
    }
    
    //. set module list
    workingDRD.setModuleList(activeModuleList);

    //. set fits header stuff
    workingDRD.setKeywordUpdateModuleList(updateKeywordModuleList);
    
    //. write drf
    myDRF.writeDRF(drfFile, workingDRD, writeDRFVerbose);
  }

 
  public void setActiveReductionTemplate(int index) throws DRDException {
    setActiveReductionTemplate((ReductionTemplate)reductionTemplates.get(index));
  }
  public void setActiveReductionTemplate(ReductionTemplate template) throws DRDException {
    ReductionTemplate oldActiveReductionTemplate = this.activeReductionTemplate;
    this.activeReductionTemplate = template;
    propertyChangeListeners.firePropertyChange("activeReductionTemplate", oldActiveReductionTemplate, activeReductionTemplate);

    applyActiveReductionTemplate();
  }
  private void applyActiveReductionTemplate() throws DRDException {
  	DataReductionDefinition drd = new DataReductionDefinition(activeReductionTemplate.getDRD());
    //. drd type of template must match active reduction type.
    if (!drd.getReductionType().equals(reductionType)) {
      //throw new DRDException("DRF Template reduction type <"+drd.getReductionType()+"> does not match current reduction type <"+reductionType+">.");
    	setReductionType(drd.getReductionType());
    }
    
    initializeModuleList(drd.getModuleList());
    //. set Active List with template and resolve find files
    setActiveModuleList(drd.getModuleList());

    setUpdateKeywordModuleList(drd.getKeywordUpdateModuleList());
    
    resolveFindFiles();
 
    
  }
  private void initializeModuleList(ArrayList list) {
    //. go through activeModuleList and set skip and find file
    for (Iterator ii=list.iterator(); ii.hasNext();) {
      ReductionModule module = (ReductionModule)ii.next();
 
      if (module.getName().equals(ODRFGUIParameters.MODULE_CALIBRATE_WAVELENGTH)) {
        module.setAllowedFindFileMethods(ODRFGUIParameters.FIND_FILE_CHOICES_MODULE_CALIBRATE_WAVELENGTH);
      } else if (module.getName().equals(ODRFGUIParameters.MODULE_CORRECT_DISPERSION)) {
        module.setAllowedFindFileMethods(ODRFGUIParameters.FIND_FILE_CHOICES_MODULE_CORRECT_DISPERSION);
      } else if (module.getName().equals(ODRFGUIParameters.MODULE_DIVIDE_FLAT)) {
        module.setAllowedFindFileMethods(ODRFGUIParameters.FIND_FILE_CHOICES_MODULE_DIVIDE_FLAT);
      } else if (module.getName().equals(ODRFGUIParameters.MODULE_INTERPOLATE_1D)) {
        module.setAllowedFindFileMethods(ODRFGUIParameters.FIND_FILE_CHOICES_MODULE_INTERPOLATE_1D);
      } else if (module.getName().equals(ODRFGUIParameters.MODULE_INTERPOLATE_3D)) {
        module.setAllowedFindFileMethods(ODRFGUIParameters.FIND_FILE_CHOICES_MODULE_INTERPOLATE_3D);
      } else if (module.getName().equals(ODRFGUIParameters.MODULE_SPATIALLY_RECTIFY)) {
        module.setAllowedFindFileMethods(ODRFGUIParameters.FIND_FILE_CHOICES_MODULE_SPATIALLY_RECTIFY);
      } else if (module.getName().equals(ODRFGUIParameters.MODULE_EXTRACT_SPECTRA)) {
        module.setAllowedFindFileMethods(ODRFGUIParameters.FIND_FILE_CHOICES_MODULE_EXTRACT_SPECTRA);
      } else if (module.getName().equals(ODRFGUIParameters.MODULE_DIVIDE_BY_STAR_SPECTRUM)) {
        module.setAllowedFindFileMethods(ODRFGUIParameters.FIND_FILE_CHOICES_MODULE_DIVIDE_BY_STAR_SPECTRUM);
      } else if (module.getName().equals(ODRFGUIParameters.MODULE_SUBTRACT_DARK)) {
        module.setAllowedFindFileMethods(ODRFGUIParameters.FIND_FILE_CHOICES_MODULE_SUBTRACT_DARK);
      } else if (module.getName().equals(ODRFGUIParameters.MODULE_SUBTRACT_SKY)) {
        module.setAllowedFindFileMethods(ODRFGUIParameters.FIND_FILE_CHOICES_MODULE_SUBTRACT_SKY);
      } else if (module.getName().equals(ODRFGUIParameters.MODULE_SUBTRACT_FRAME)) {
        module.setAllowedFindFileMethods(ODRFGUIParameters.FIND_FILE_CHOICES_MODULE_SUBTRACT_FRAME);
      } else
        module.setAllowedFindFileMethods(ODRFGUIParameters.FIND_FILE_CHOICES_NONE);

      
      String calFile = module.getCalibrationFile();
      if (calFile.length() > 0) {
      	if (calFile.equals(ODRFGUIParameters.FIND_FILE_MOST_RECENT))
      		module.setFindFileMethod(ODRFGUIParameters.FIND_FILE_MENU_MOST_RECENT);
      	else if (calFile.equals(ODRFGUIParameters.FIND_FILE_CONSTRUCT_FROM_FILENAME))
      		module.setFindFileMethod(ODRFGUIParameters.FIND_FILE_MENU_CONSTRUCT_FROM_FILENAME);
      	else if (calFile.equals(ODRFGUIParameters.FIND_FILE_DO_NOT_USE))
      		module.setFindFileMethod(ODRFGUIParameters.FIND_FILE_MENU_DO_NOT_USE);
      	else if (calFile.equals(ODRFGUIParameters.MODULE_CALFILE_NOT_USED))
      		module.setFindFileMethod(ODRFGUIParameters.FIND_FILE_MENU_NONE);
      	else if (calFile.equals(ODRFGUIParameters.FIND_FILE_NONE))
      		module.setFindFileMethod(ODRFGUIParameters.FIND_FILE_MENU_NONE);
      	else if (calFile.equals(ODRFGUIParameters.FIND_FILE_SPECIFY_FILE))
      		module.setFindFileMethod(ODRFGUIParameters.FIND_FILE_MENU_SPECIFY_FILE);
      	else {
      		module.setFindFileMethod(ODRFGUIParameters.FIND_FILE_MENU_SPECIFY_FILE);
      		module.setCalibrationFile(calFile);
      		File tempFile = new File(calFile);
      		if (tempFile.exists())
      			module.setCalibrationFileValidated(true);
      	}
      }
      if (module.getFindFileMethod().length() == 0) {
        module.setFindFileMethod(module.getAllowedFindFileMethods()[0]);	
      }
    }	
  }

  private int getIndexForNewModule(ReductionModule newModule) {
  	int activeIndex=0;
  	int availableIndex = availableModuleList.indexOf(newModule);
  	boolean indexFound = false;
  	ReductionModule currentAvailModule, currentActiveModule;
  	if (activeModuleList.isEmpty())
  		return 0;
  	for (ListIterator iModule = availableModuleList.listIterator(availableIndex+1); iModule.hasPrevious();) {
  		//. get module above
  		currentAvailModule = (ReductionModule)iModule.previous();

  		activeIndex = 0;
  		//. go through active list and look for this module
  		for (Iterator iActive = activeModuleList.iterator(); iActive.hasNext();) {
    		//. get module from active list
    		currentActiveModule = (ReductionModule)iActive.next();
    		
    		//. check to see if module already exists
    		if (currentActiveModule.getName().compareTo(newModule.getName()) == 0) {
    			return -1;
    		}
    		//. if index already found, don't check anymore for where it should go, 
    		//. but keep iterating of active list to see if module already in the list
    		if (!indexFound) {
	    		activeIndex++;
	    		if (currentActiveModule.getName().compareTo(currentAvailModule.getName()) == 0) {
	    			indexFound = true;
	    		}
    		}
  		}
  		if (indexFound)
  			return activeIndex;
  	}
  	//. if not found, return 0 (put at beginning)
  	return 0;
  }
  
  
  public void addModuleToActiveList(ReductionModule module) {
  	//. find index of active module; if module already in active list, just return
  	int index;
  	if ((index = getIndexForNewModule(module)) >= 0) {
  		activeModuleList.add(index, module);
  		resolveFindFile(index);
  		propertyChangeListeners.firePropertyChange("activeModuleList", null, activeModuleList);
  	}
  }

  public void removeModuleFromActiveList(int index) {
  	activeModuleList.remove(index);
		propertyChangeListeners.firePropertyChange("activeModuleList", null, activeModuleList);
  }
  public void updateUpdateKeywordModuleList(int index, KeywordUpdateReductionModule module) {
  	if (index < 0) {
  		return;
  	} else if (index >= updateKeywordModuleList.size()) {
  		updateKeywordModuleList.add(module);
  	} else {
  		updateKeywordModuleList.set(index, module);
  	}
		propertyChangeListeners.firePropertyChange("updateKeywordModuleList", null, updateKeywordModuleList);
  }
  public void removeModuleFromUpdateList(int index) {
  	updateKeywordModuleList.remove(index);
		propertyChangeListeners.firePropertyChange("updateKeywordModuleList", null, updateKeywordModuleList);
  }
  
  private void resolveFindFiles() {
    //. go through activeModuleList and set skip and find file
  	if (!inputFileList.isEmpty()) {
  		for (Iterator ii=activeModuleList.iterator(); ii.hasNext();) {
  			resolveFindFile((ReductionModule)ii.next());
  		}
  	}
  }
  public void resolveFindFile(int index) {
    resolveFindFile((ReductionModule)activeModuleList.get(index));
  }
  public void resolveFindFile(ReductionModule module) {
    module.setCalibrationFileValidated(false);

    String findFile = module.getFindFileMethod();
    String moduleName = module.getName();
    if (findFile.equals(ODRFGUIParameters.FIND_FILE_MENU_MOST_RECENT)) {
      module.setCalibrationFile(ODRFGUIParameters.MODULE_CALFILE_NOT_FOUND);
      //. make sure dir exists
      String calFileID = "";
      if (moduleName.equals(ODRFGUIParameters.MODULE_SPATIALLY_RECTIFY)) {
        calFileID = ODRFGUIParameters.MODULE_FILEID_SPATIALLY_RECTIFY;
      } else  if (moduleName.equals(ODRFGUIParameters.MODULE_EXTRACT_SPECTRA)) {
          calFileID = ODRFGUIParameters.MODULE_FILEID_EXTRACT_SPECTRA;
      } else if (moduleName.equals(ODRFGUIParameters.MODULE_DIVIDE_FLAT)) {
        calFileID=ODRFGUIParameters.MODULE_FILEID_DIVIDE_FLAT;
      } else if (moduleName.equals(ODRFGUIParameters.MODULE_CALIBRATE_WAVELENGTH)) {
        calFileID=ODRFGUIParameters.MODULE_FILEID_CALIBRATE_WAVELENGTH;
      }
      if (calibDir.isDirectory()) {
	//. get list of files matching filter
	String scaleID = workingScale.substring(workingScale.indexOf(".")+1, workingScale.length());
	File[] fileList = calibDir.listFiles(new FileFilterByCalibrationType(calFileID+"_"+workingFilter+"_"+scaleID));
	if (fileList.length > 0) {
	  Arrays.sort(fileList, new CalibrationFileTimeComparator());
	  module.setCalibrationFileValidated(true);
	  module.setCalibrationFile(fileList[fileList.length-1].getAbsolutePath());
	}
      }
    } else if (findFile.equals(ODRFGUIParameters.FIND_FILE_MENU_SPECIFY_FILE)) {
      if (module.getCalibrationFile().length() > 0) {
        File calFile = new File(module.getCalibrationFile());
        if (calFile.isFile())
	  module.setCalibrationFileValidated(true);
      } else
	module.setCalibrationFile(ODRFGUIParameters.MODULE_CALFILE_NOT_SPECIFIED);
    } else if (findFile.equals(ODRFGUIParameters.FIND_FILE_MENU_DO_NOT_USE)) {
      module.setCalibrationFileValidated(true);
      module.setCalibrationFile(ODRFGUIParameters.MODULE_CALFILE_NOT_USED);
    } else if (findFile.equals(ODRFGUIParameters.FIND_FILE_MENU_NONE)) {
      module.setCalibrationFileValidated(true);
      module.setCalibrationFile(ODRFGUIParameters.MODULE_CALFILE_NOT_USED);
    }
  }
  private ReductionModule getReductionModule(ArrayList moduleList, String name) {
    for (Iterator ii=moduleList.iterator(); ii.hasNext();) {
      ReductionModule module = (ReductionModule)ii.next();
      if (module.getName().equals(name))
      	return module;
    }
    return null;
  }
  public void setInputDir(File inputDir) {
    File  oldInputDir = this.inputDir;
    this.inputDir = inputDir;
    propertyChangeListeners.firePropertyChange("inputDir", oldInputDir, inputDir);
  }
  public File getInputDir() {
    return inputDir;
  }
  public void setOutputDir(File outputDir) {
    File  oldOutputDir = this.outputDir;
    this.outputDir = outputDir;
    propertyChangeListeners.firePropertyChange("outputDir", oldOutputDir, outputDir);
  }
  public File getOutputDir() {
    return outputDir;
  }
  public void setLogPath(File logPath) {
    File  oldLogPath = this.logPath;
    this.logPath = logPath;
    propertyChangeListeners.firePropertyChange("logPath", oldLogPath, logPath);
  }
  public File getLogPath() {
    return logPath;
  }
  public File getCalibDir() {
    return calibDir;
  }
  public void setCalibDir(File calibDir) {
    File oldCalibDir = this.calibDir;
    this.calibDir = calibDir;
    propertyChangeListeners.firePropertyChange("calibDir", oldCalibDir, calibDir);

    resolveFindFiles();
  }
  public void setDatasetName(String datasetName) {
    String  oldDatasetName = this.datasetName;
    this.datasetName = datasetName;
    propertyChangeListeners.firePropertyChange("datasetName", oldDatasetName, datasetName);
  }
  public String getDatasetName() {
    return datasetName;
  }
  public void setWorkingFilter(String workingFilter) {
    String oldWorkingFilter = this.workingFilter;
    this.workingFilter = workingFilter;
    propertyChangeListeners.firePropertyChange("workingFilter", oldWorkingFilter, workingFilter);

    resolveFindFiles();
  }
  public void setWorkingScale(String workingScale) {
    String oldWorkingScale = this.workingScale;
    this.workingScale = workingScale;
    propertyChangeListeners.firePropertyChange("workingScale", oldWorkingScale, workingScale);

    resolveFindFiles();
  }
  public String getWorkingFilter() {
    return workingFilter;
  }
  public String getWorkingScale() {
    return workingScale;
  }
  public ReductionModule getModule(int row) throws IndexOutOfBoundsException {
    return (ReductionModule)activeModuleList.get(row);
  }
  
  public void setActiveModule(ReductionModule activeModule) {
    ReductionModule  oldActiveModule = this.activeModule;
    this.activeModule = activeModule;
    propertyChangeListeners.firePropertyChange("activeModule", null, activeModule);
  }
  public ReductionModule getActiveModule() {
    return activeModule;
  }
  public void setActiveModuleList(ArrayList activeModuleList) {
    ArrayList  oldActiveModuleList = this.activeModuleList;
    this.activeModuleList = activeModuleList;
    propertyChangeListeners.firePropertyChange("activeModuleList", null, activeModuleList);
  }
  public ArrayList getActiveModuleList() {
    return activeModuleList;
  }
  public void setAvailableModuleList(ArrayList availableModuleList) {
    ArrayList  oldAvailableModuleList = this.availableModuleList;
    this.availableModuleList = availableModuleList;
    propertyChangeListeners.firePropertyChange("availableModuleList", null, availableModuleList);
  }
  public ArrayList getAvailableModuleList() {
    return availableModuleList;
  }
  public void setUpdateKeywordModuleList(ArrayList updateKeywordModuleList) {
    ArrayList  oldUpdateKeywordModuleList = this.updateKeywordModuleList;
    this.updateKeywordModuleList = updateKeywordModuleList;
    propertyChangeListeners.firePropertyChange("updateKeywordModuleList", null, updateKeywordModuleList);
  }
  public ArrayList getUpdateKeywordModuleList() {
    return updateKeywordModuleList;
  }
  public void setReductionType(String reductionType) {
    String oldReductionType = this.reductionType;
    this.reductionType = reductionType;
    propertyChangeListeners.firePropertyChange("reductionType", oldReductionType, reductionType);

    resetAvailableModuleList();
  }
  public String getReductionType() {
    return reductionType;
  }

  public boolean isModuleSkipped(int row) throws IndexOutOfBoundsException {
    ReductionModule module = (ReductionModule)activeModuleList.get(row);
    return module.doSkip();
  }
  public boolean isModuleCalFileValid(int row) throws IndexOutOfBoundsException {
    ReductionModule module = (ReductionModule)activeModuleList.get(row);
    return module.isCalibrationFileValidated();
  }
  public void setAutomaticallyGenerateDatasetName(boolean automaticallyGenerateDatasetName) {
    boolean  oldAutomaticallyGenerateDatasetName = this.automaticallyGenerateDatasetName;
    this.automaticallyGenerateDatasetName = automaticallyGenerateDatasetName;
    propertyChangeListeners.firePropertyChange("automaticallyGenerateDatasetName", new Boolean(oldAutomaticallyGenerateDatasetName), new Boolean(automaticallyGenerateDatasetName));

    if (automaticallyGenerateDatasetName)
      generateDatasetName();
  }
  public boolean willAutomaticallyGenerateDatasetName() {
    return automaticallyGenerateDatasetName;
  }
  private void generateDatasetName() {
    if (inputFileList.isEmpty())
      setDatasetName("None");
    else {
      String name = ((DRDInputFile)inputFileList.get(0)).getName();
      if (name.length() > 12)
	name = name.substring(0,12);
      setDatasetName(name);
    }
  }
  public void setQueueDir(File queueDir) {
    File  oldQueueDir = this.queueDir;
    this.queueDir = queueDir;
    propertyChangeListeners.firePropertyChange("queueDir", oldQueueDir, queueDir);
  }
  public File getQueueDir() {
    return queueDir;
  }
  public ArrayList getReductionTemplates() {
  	return reductionTemplates;
  }
  public class ReductionTemplate {
    File drfFile;
    DataReductionDefinition myDRD = new DataReductionDefinition();
    private DRF myDRF=new DRF();
    public ReductionTemplate(String drf) throws java.io.IOException, org.jdom.JDOMException {
      drfFile=new File(drf);
      myDRD = myDRF.openDRF(drfFile);
    }
    public File getDrfFile() {
      return drfFile;
    }
    public String getDrfFilename() {
      return drfFile.getAbsolutePath();
    }
    public DataReductionDefinition getDRD() {
      return myDRD;
    }
    public String toString() {
    	return drfFile.getName();
    }
  }

	public boolean doWriteDRFVerbose() {
		return writeDRFVerbose;
	}
	public void setWriteDRFVerbose(boolean writeDRFVerbose) {
		this.writeDRFVerbose = writeDRFVerbose;
	}


}
