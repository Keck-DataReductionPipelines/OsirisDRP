package edu.ucla.astro.osiris.drp.odrfgui;

import edu.ucla.astro.osiris.drp.util.*;
import edu.ucla.astro.osiris.util.*;
import org.jdom.*;
import edu.hawaii.keck.kjava.*;
import nom.tam.fits.TruncatedFileException;

import java.io.*;
import java.beans.*;
import java.util.*;

/** @todo no template */
/** @todo load new templates */
/** @todo write drf to queue */
public class ODRFGUIModel extends GenericModel {
  DRF myDRF = new DRF();
  private ArrayList inputFileList = new ArrayList();
  private ArrayList arpReductionModuleList = new ArrayList();
  private ArrayList srpReductionModuleList = new ArrayList();
  private ArrayList crpReductionModuleList = new ArrayList();
  private ArrayList orpReductionModuleList = new ArrayList();
  private ArrayList activeModuleList;
  private ArrayList reductionTemplates;
  private String reductionType;
  private String workingFilter = "None";
  private String workingScale = "None";
  private ReductionTemplate activeReductionTemplate;
  private File inputDir;
  private File outputDir;
  private File logPath;
  private String datasetName = "";
  private String calibDir;
  private boolean automaticallyGenerateDatasetName;
  private File queueDir;
  private int queueNumber;

  public ODRFGUIModel() throws java.io.IOException, org.jdom.JDOMException {
    inputDir = ODRFGUIParameters.DEFAULT_INPUT_DIR;
    outputDir = ODRFGUIParameters.DEFAULT_OUTPUT_DIR;
    logPath = ODRFGUIParameters.DEFAULT_LOG_DIR;
    calibDir = ODRFGUIParameters.OSIRIS_CALIB_ARCHIVE_DIR;
    automaticallyGenerateDatasetName = ODRFGUIParameters.DEFAULT_AUTOSET_DATASET_NAME;

    queueNumber=0;

    //. open up rpbconfig file and populate module lists
    openRPBConfig(ODRFGUIParameters.OSIRIS_DRP_BACKBONE_CONFIG_FILE);
    //. complete module definitions
    resetModuleList(arpReductionModuleList);
    resetModuleList(orpReductionModuleList);
    resetModuleList(srpReductionModuleList);
    resetModuleList(crpReductionModuleList);

    //. set default reduction type
    reductionType = ODRFGUIParameters.DEFAULT_REDUCTION_TYPE;
    //. set activeModuleList to default
    resetActiveModuleList();

    //. populate default template list
    setDefaultTemplateList();


    //. for testing:
    try {
      setActiveReductionTemplate((ReductionTemplate)reductionTemplates.get(0));
    } catch (Exception e) {
      e.printStackTrace();
    }
  }
  private void resetActiveModuleList() {
    ArrayList list;
    //. set active module list
    if (reductionType.equals(ODRFGUIParameters.REDUCTION_TYPE_CRP_SPEC))
      list = crpReductionModuleList;
    else if (reductionType.equals(ODRFGUIParameters.REDUCTION_TYPE_ORP_SPEC))
      list = orpReductionModuleList;
    else if (reductionType.equals(ODRFGUIParameters.REDUCTION_TYPE_SRP_SPEC))
      list = srpReductionModuleList;
    else
      list = arpReductionModuleList;

    setActiveModuleList(list);
  }
  public void setDefaultTemplateList() {
    ArrayList workingTemplateList = new ArrayList();
    ArrayList errorMessages = new ArrayList();
    for (int ii=0; ii<ODRFGUIParameters.DEFAULT_REDUCTION_TEMPLATE_LIST.length; ii++) {
      try {
        workingTemplateList.add(new ReductionTemplate(ODRFGUIParameters.DEFAULT_REDUCTION_TEMPLATE_LIST[ii]));
      } catch (Exception e) {
	errorMessages.add(e);
      }
    }
    reductionTemplates = workingTemplateList;
    if (!errorMessages.isEmpty()) {
      //. report all errors to gui.  following is temporary
      System.out.println("==== setDefaultTemplateList errors ====");
      for (Iterator jj=errorMessages.iterator(); jj.hasNext();) {
	((Exception)jj.next()).printStackTrace();
      }
    }
  }
  public void openRPBConfig(File xmlFile) throws java.io.IOException, org.jdom.JDOMException {
    Attribute workingAtt;
    ArrayList list;
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
      } else if ("SRP_SPEC".equals(rootChildName)) {
        list = srpReductionModuleList;
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
	  workingAtt=module.getAttribute("Name");
	  if (workingAtt != null) {
	    ReductionModule newModule = new ReductionModule();
	    newModule.setName(workingAtt.getValue());
            list.add(newModule);
	  }
        }
      }
    }
  }
  private void resetModuleList(ArrayList list) {
    for (Iterator ii = list.iterator(); ii.hasNext();) {
      resetModule((ReductionModule)ii.next());
    }
  }
  private void resetModule(ReductionModule module) {
    //. complete module with defaults
    module.setSkip(true);
    //. set find file list
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
    } else if (module.getName().equals(ODRFGUIParameters.MODULE_SUBTRACT_DARK)) {
      module.setAllowedFindFileMethods(ODRFGUIParameters.FIND_FILE_CHOICES_MODULE_SUBTRACT_DARK);
    } else if (module.getName().equals(ODRFGUIParameters.MODULE_SUBTRACT_SKY)) {
      module.setAllowedFindFileMethods(ODRFGUIParameters.FIND_FILE_CHOICES_MODULE_SUBTRACT_SKY);
    } else
      module.setAllowedFindFileMethods(ODRFGUIParameters.FIND_FILE_CHOICES_NONE);

    module.setFindFileMethod(module.getAllowedFindFileMethods()[0]);
  }

  public ArrayList getInputFileList() {
    return inputFileList;
  }
  public void clearInputFileList() {
    inputFileList = new ArrayList();
    setWorkingFilter("None");
    setWorkingScale("None");
    propertyChangeListeners.firePropertyChange("inputFileList", null, inputFileList);
  }
  public void addInputFiles(File[] fileList) throws DRDException {
    //. only allow opening of osiris spec frames with same filter and scale
    //. must be from same directory, which is set to inputDir
    for (int ii=0; ii<fileList.length; ii++) {
      try {
        //. create DRFInputFile object which should
	//.  - validate file
	//.  - extract filter, scale, etc.
	DRDInputFile drdFile = new DRDInputFile(fileList[ii]);
	inputFileList.add(drdFile);
      } catch (DRDException drdE) {
	drdE.printStackTrace();
      } catch (TruncatedFileException tfE) {
	tfE.printStackTrace();

      } catch (IOException ioE) {
	ioE.printStackTrace();
      }
    }
    if (!inputFileList.isEmpty()) {
      DRDInputFile tempFile = (DRDInputFile)inputFileList.get(0);
      String tempInputDir = tempFile.getDirectory();
      String tempScale = tempFile.getScale();
      String tempFilter = tempFile.getFilter();

      //. confirm same filter and scale
      for (Iterator jj=inputFileList.iterator(); jj.hasNext();) {
        tempFile = (DRDInputFile)jj.next();
        if (!tempInputDir.equals(tempFile.getDirectory()))
	  throw new DRDException("All input files must be from same directory!");
        if (!tempScale.equals(tempFile.getScale()))
	  throw new DRDException("All input files must have same scale!");
        if (!tempFilter.equals(tempFile.getFilter()))
  	  throw new DRDException("All input files must have same filter!");
      }
      setWorkingFilter(tempFilter);
      setWorkingScale(tempScale);
      setInputDir(new File(tempInputDir));
      if (automaticallyGenerateDatasetName)
	generateDatasetName();
      propertyChangeListeners.firePropertyChange("inputFileList", null, inputFileList);
    }
  }
  public boolean areActiveCalFilesValiated() {
    for (Iterator ii = activeModuleList.iterator(); ii.hasNext();) {
      ReductionModule module = (ReductionModule)ii.next();
      if (!module.doSkip())
	if (!module.isCalibrationFileValidated())
	  return false;
    }
    return true;
  }
  public void openDRF(File drf) throws org.jdom.JDOMException, java.io.IOException, DRDException {
    DataReductionDefinition drd = myDRF.openDRF(drf);
    setInputDir(new File(drd.getDatasetInputDir()));
    setDatasetName(drd.getDatasetName());
    setOutputDir(new File(drd.getDatasetOutputDir()));
    setLogPath(new File(drd.getLogPath()));
    setReductionType(drd.getReductionType());
    clearInputFileList();
    ArrayList inputFiles = drd.getDatasetFitsFileList();
    File[] fileList = new File[inputFiles.size()];
    int index=0;
    for (Iterator ii = inputFiles.iterator(); ii.hasNext();) {
      fileList[index]=new File(inputDir+File.separator+(String)ii.next());
      index++;
    }

    addInputFiles(fileList);

    resetActiveModuleList();

    mergeIntoActiveModuleList(drd.getModuleList());

  }
  public void writeDRFToQueue() throws java.io.IOException, org.jdom.JDOMException {
    java.text.DecimalFormat threeDigitFormatter = new java.text.DecimalFormat("000");
    String fileroot = queueDir+File.separator+threeDigitFormatter.format((long)queueNumber)+"."+datasetName+"_drf.";
    String writtenDRFFilename = fileroot+ODRFGUIParameters.DRF_EXTENSION_WRITING;
    String queuedDRFFilename = fileroot+ODRFGUIParameters.DRF_EXTENSION_QUEUED;
    File writtenDRF = new File(writtenDRFFilename);
    writeDRF(writtenDRF);
    System.out.println("Copying file from temporary DRF to: "+queuedDRFFilename);

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

    System.out.println("Deleting temporary DRF: "+writtenDRFFilename);
    writtenDRF.delete();
    queueNumber++;
  }
  public void writeDRF(File drfFile) throws java.io.IOException, org.jdom.JDOMException {
    //. construct workingDRD
    DataReductionDefinition workingDRD = new DataReductionDefinition();

    workingDRD.setDatasetInputDir(inputDir.getAbsolutePath());
    //. populate fits file list in DRD with just the names of files
    ArrayList inputFileNames = new ArrayList();
    for (Iterator ii=inputFileList.iterator(); ii.hasNext();) {
      inputFileNames.add(((DRDInputFile)ii.next()).getName());
    }
    workingDRD.setDatasetFitsFileList(inputFileNames);
    workingDRD.setDatasetName(datasetName);
    workingDRD.setDatasetOutputDir(outputDir.getAbsolutePath());
    workingDRD.setReductionType(reductionType);
    workingDRD.setLogPath(logPath.getAbsolutePath());

    for (Iterator ii = activeModuleList.iterator(); ii.hasNext();) {
    	ReductionModule module = (ReductionModule)(ii.next());
    	module.setOutputDir(outputDir.getAbsolutePath());
    }
    
    workingDRD.setModuleList(activeModuleList);

    myDRF.writeDRF(drfFile, workingDRD);
  }

  public void setActiveModuleList(ArrayList activeModuleList) {
    ArrayList  oldActiveModuleList = this.activeModuleList;
    this.activeModuleList = activeModuleList;
    propertyChangeListeners.firePropertyChange("activeModuleList", null, activeModuleList);
  }
  public ArrayList getActiveModuleList() {
    return activeModuleList;
  }
  public void setReductionType(String reductionType) {
    String oldReductionType = this.reductionType;
    this.reductionType = reductionType;
    propertyChangeListeners.firePropertyChange("reductionType", oldReductionType, reductionType);

    resetActiveModuleList();
  }
  public String getReductionType() {
    return reductionType;
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
    DataReductionDefinition drd = activeReductionTemplate.getDRD();
    ArrayList templateModules = drd.getModuleList();
    //. drd type of template must match active reduction type.
    if (!drd.getReductionType().equals(reductionType)) {
      throw new DRDException("DRF Template reduction type <"+drd.getReductionType()+"> does not match current reduction type <"+reductionType+">.");
    }
    //. reset active list to defaults
    resetModuleList(activeModuleList);

    mergeIntoActiveModuleList(templateModules);
  }
  private void mergeIntoActiveModuleList(ArrayList newModuleList) {
    //. go through activeModuleList and set skip and find file
    for (Iterator ii=activeModuleList.iterator(); ii.hasNext();) {
      ReductionModule currentRM = (ReductionModule)ii.next();
      ReductionModule templateRM;
      if ((templateRM = getReductionModule(newModuleList, currentRM.getName())) != null) {
	currentRM.setSkip(templateRM.doSkip());

	String calFile = templateRM.getCalibrationFile();
	if (calFile.equals(ODRFGUIParameters.FIND_FILE_MOST_RECENT))
	  currentRM.setFindFileMethod(ODRFGUIParameters.FIND_FILE_MENU_MOST_RECENT);
	else if (calFile.equals(ODRFGUIParameters.FIND_FILE_CONSTRUCT_FROM_FILENAME))
	  currentRM.setFindFileMethod(ODRFGUIParameters.FIND_FILE_MENU_CONSTRUCT_FROM_FILENAME);
	else if (calFile.equals(ODRFGUIParameters.FIND_FILE_DO_NOT_USE))
	  currentRM.setFindFileMethod(ODRFGUIParameters.FIND_FILE_MENU_DO_NOT_USE);
	else if (calFile.equals(ODRFGUIParameters.FIND_FILE_NONE))
	  currentRM.setFindFileMethod(ODRFGUIParameters.FIND_FILE_MENU_NONE);
	else if (calFile.equals(ODRFGUIParameters.FIND_FILE_SPECIFY_FILE))
	  currentRM.setFindFileMethod(ODRFGUIParameters.FIND_FILE_MENU_SPECIFY_FILE);
	else {
	  currentRM.setCalibrationFile(calFile);
	  File tempFile = new File(calFile);
	  if (tempFile.exists())
	    currentRM.setCalibrationFileValidated(true);
	}
      }
    }

    //. if there are input files, resolve find_files
    if (!inputFileList.isEmpty())
      resolveFindFiles();
  }
  private void resolveFindFiles() {
    for (Iterator ii=activeModuleList.iterator(); ii.hasNext();)
      resolveFindFile((ReductionModule)ii.next());
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
      String calFileSubdir = "";
      String calFileID = "";
      if (moduleName.equals(ODRFGUIParameters.MODULE_SPATIALLY_RECTIFY)) {
        calFileSubdir=ODRFGUIParameters.MODULE_DIR_SPATIALLY_RECTIFY;
	calFileID = ODRFGUIParameters.MODULE_FILEID_SPATIALLY_RECTIFY;
      } else if (moduleName.equals(ODRFGUIParameters.MODULE_DIVIDE_FLAT)) {
        calFileSubdir=ODRFGUIParameters.MODULE_DIR_DIVIDE_FLAT;
        calFileID=ODRFGUIParameters.MODULE_FILEID_DIVIDE_FLAT;
      } else if (moduleName.equals(ODRFGUIParameters.MODULE_CALIBRATE_WAVELENGTH)) {
        calFileSubdir=ODRFGUIParameters.MODULE_DIR_CALIBRATE_WAVELENGTH;
        calFileID=ODRFGUIParameters.MODULE_FILEID_CALIBRATE_WAVELENGTH;
      }
      File caldir = new File(calibDir+File.separator+calFileSubdir);
      if (caldir.isDirectory()) {
	//. get list of files matching filter
	String scaleID = workingScale.substring(workingScale.indexOf(".")+1, workingScale.length());
	File[] fileList = caldir.listFiles(new FileFilterByCalibrationType(calFileID+"_"+workingFilter+"_"+scaleID));
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
  public String getCalibDir() {
    return calibDir;
  }
  public void setCalibDir(String calibDir) {
    String oldCalibDir = this.calibDir;
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
  }

}
