package edu.ucla.astro.osiris.drp.util;

import java.beans.*;

/**
 * <p>Title: OSIRIS Software Package</p>
 * <p>Description: </p>
 * <p>Copyright: Copyright (c) 2004</p>
 * <p>Company: UCLA Infrared Imaging Detector Laboratory</p>
 * @author Jason L. Weiss
 * @version 1.0
 */

public class ReductionModule {

  private transient PropertyChangeSupport propertyChangeListeners = new PropertyChangeSupport(this);
  private String name;
  private String calibrationFile;
  private String outputDir;
  private boolean saveOutput;
  private boolean saveOnError;
  private boolean skip;
  private String findFileMethod;
  private String[] allowedFindFileMethods;
  private boolean calibrationFileValidated;

  public ReductionModule() {
    name="";
    findFileMethod="";
    allowedFindFileMethods=new String[]{""};
    calibrationFile="";
    outputDir="";
    saveOutput=false;
    saveOnError=false;
    skip=false;
  }
  public ReductionModule(ReductionModule m) {
    name=m.getName();
    findFileMethod = m.getFindFileMethod();
    allowedFindFileMethods = m.getAllowedFindFileMethods();
    calibrationFile=m.getCalibrationFile();
    outputDir=m.getOutputDir();
    saveOutput=m.doSaveOutput();
    saveOnError=m.doSaveOnError();
    skip=m.doSkip();
  }

  public synchronized void removePropertyChangeListener(PropertyChangeListener l) {
    propertyChangeListeners.removePropertyChangeListener(l);
  }
  public synchronized void addPropertyChangeListener(PropertyChangeListener l) {
    propertyChangeListeners.addPropertyChangeListener(l);
  }
  public String getName() {
    return name;
  }
  public void setName(String name) {
    String  oldName = this.name;
    this.name = name;
    propertyChangeListeners.firePropertyChange("name", oldName, name);
  }
  public void setCalibrationFile(String calibrationFile) {
    String  oldCalibrationFile = this.calibrationFile;
    this.calibrationFile = calibrationFile;
    propertyChangeListeners.firePropertyChange("calibrationFile", oldCalibrationFile, calibrationFile);
  }
  public String getCalibrationFile() {
    return calibrationFile;
  }
  public void setOutputDir(String outputDir) {
    String  oldOutputDir = this.outputDir;
    this.outputDir = outputDir;
    propertyChangeListeners.firePropertyChange("outputDir", oldOutputDir, outputDir);
  }
  public String getOutputDir() {
    return outputDir;
  }
  public void setSaveOutput(boolean saveOutput) {
    boolean  oldSaveOutput = this.saveOutput;
    this.saveOutput = saveOutput;
    propertyChangeListeners.firePropertyChange("saveOutput", new Boolean(oldSaveOutput), new Boolean(saveOutput));
  }
  public boolean doSaveOutput() {
    return saveOutput;
  }
  public void setSaveOnError(boolean saveOnError) {
    boolean  oldSaveOnError = this.saveOnError;
    this.saveOnError = saveOnError;
    propertyChangeListeners.firePropertyChange("saveOnError", new Boolean(oldSaveOnError), new Boolean(saveOnError));
  }
  public boolean doSaveOnError() {
    return saveOnError;
  }
  public void setSkip(boolean skip) {
    boolean  oldSkip = this.skip;
    this.skip = skip;
    propertyChangeListeners.firePropertyChange("skip", new Boolean(oldSkip), new Boolean(skip));
  }
  public boolean doSkip() {
    return skip;
  }
  public void setFindFileMethod(String findFileMethod) {
    String  oldFindFileMethod = this.findFileMethod;
    this.findFileMethod = findFileMethod;
    propertyChangeListeners.firePropertyChange("findFileMethod", oldFindFileMethod, findFileMethod);
  }
  public String getFindFileMethod() {
    return findFileMethod;
  }
  public void setAllowedFindFileMethods(String[] allowedFindFileMethods) {
    String[]  oldAllowedFindFileMethods = this.allowedFindFileMethods;
    this.allowedFindFileMethods = allowedFindFileMethods;
    propertyChangeListeners.firePropertyChange("allowedFindFileMethods", oldAllowedFindFileMethods, allowedFindFileMethods);
  }
  public String[] getAllowedFindFileMethods() {
    return allowedFindFileMethods;
  }
  public void setCalibrationFileValidated(boolean calibrationFileValidated) {
    boolean  oldCalibrationFileValidated = this.calibrationFileValidated;
    this.calibrationFileValidated = calibrationFileValidated;
    propertyChangeListeners.firePropertyChange("calibrationFileValidated", new Boolean(oldCalibrationFileValidated), new Boolean(calibrationFileValidated));
  }
  public boolean isCalibrationFileValidated() {
    return calibrationFileValidated;
  }
  public String toString() {
    return name;
  }
}