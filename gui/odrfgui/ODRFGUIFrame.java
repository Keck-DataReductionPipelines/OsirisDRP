package edu.ucla.astro.osiris.drp.odrfgui;

import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.event.*;
import javax.swing.table.*;
import java.beans.*;
import java.util.*;
import java.io.*;
import edu.ucla.astro.osiris.drp.util.*;
import edu.ucla.astro.osiris.util.*;

/**
 * <p>Title: </p>
 * <p>Description: </p>
 * <p>Copyright: Copyright (c) 2003</p>
 * <p>Company: </p>
 * @author unascribed
 * @version 1.0
 */


/** @todo check box for don't write skipped modules */
/** @todo set calibration dir */
/** @todo set queue dir */
public class ODRFGUIFrame extends JFrame {
  ODRFGUIModel myModel;
  ODRFGUIController myController;

  JPanel contentPane;

  JMenuBar mainMenuBar = new JMenuBar();
  JMenu jMenuFile = new JMenu();
  JMenuItem jMenuFileSetCalibDir = new JMenuItem();
  JMenuItem jMenuFileSetQueueDir = new JMenuItem();
  JMenuItem jMenuFileOpenDRF = new JMenuItem();
  JMenuItem jMenuFileSaveDRF = new JMenuItem();
  JMenuItem jMenuFileQueueDRF = new JMenuItem();
  JMenuItem jMenuFileExit = new JMenuItem();
  JMenu jMenuEngineering = new JMenu();
  JMenu jMenuHelp = new JMenu();
  JMenuItem jMenuHelpAbout = new JMenuItem();

  JPanel mainPanel = new JPanel();
  JPanel topPanel = new JPanel();
  JPanel filterScalePanel = new JPanel();



  //. input file list
  JScrollPane inputFileListScrollPane = new JScrollPane();
  JList inputFileList = new JList();
  JButton addInputFilesButton = new JButton();
  JButton clearInputFilesButton = new JButton();


  JLabel inputFileLabel = new JLabel();
  JLabel filterTitleLabel = new JLabel();
  JLabel filterLabel = new JLabel();
  JLabel scaleTitleLabel = new JLabel();
  JLabel scaleLabel = new JLabel();


  JLabel datasetNameLabel = new JLabel();
  JTextField datasetNameField = new JTextField();
  JCheckBox autosetDatasetNameCheckBox = new JCheckBox();

  //. reduction type selection
  JLabel reductionTypeLabel = new JLabel();
  JComboBox reductionTypeComboBox = new JComboBox(ODRFGUIParameters.REDUCTION_TYPE_LIST);

  //. output file root
  //. output directory
  JLabel outputPathTitleLabel = new JLabel();
  JLabel outputPathLabel = new JLabel();
  JButton outputPathBrowseButton = new JButton();
  JLabel logPathTitleLabel = new JLabel();
  JLabel logPathLabel = new JLabel();
  JButton logPathBrowseButton = new JButton();

  //. basic reduction type list
  JLabel reductionTemplateLabel = new JLabel();
  JComboBox reductionTemplateComboBox = new JComboBox(ODRFGUIParameters.DEFAULT_REDUCTION_TEMPLATE_LIST);

  //. module list
  JScrollPane reductionModuleTableScrollPane = new JScrollPane();
  JTable reductionModuleTable = new JTable();
  ReductionModuleListTableModel reductionModuleTableModel = new ReductionModuleListTableModel();


  JLabel statusBar = new JLabel();

  private File currentDRFReadPath = ODRFGUIParameters.DRF_READ_PATH;
  private File currentDRFWritePath = ODRFGUIParameters.DRF_WRITE_PATH;
  private File defaultSaveFile;

  //Construct the frame
  public ODRFGUIFrame(ODRFGUIModel model) throws Exception {
    myModel=model;
    enableEvents(AWTEvent.WINDOW_EVENT_MASK);
    myController = new ODRFGUIController(myModel);
    jbInit();
    updateView();
  }
  //. controller inner class
  private class ODRFGUIController extends GenericController {

    public ODRFGUIController(ODRFGUIModel newODRFGUIModel) {
      super(newODRFGUIModel);
    }
    public void model_propertyChange(PropertyChangeEvent e) {
      String propertyName = e.getPropertyName();

      if ("activeModuleList".equals(propertyName)) {
	updateViewModuleList((ArrayList)e.getNewValue());
      } else if ("inputFileList".equals(propertyName)) {
	updateViewInputFileList((ArrayList)e.getNewValue());
      } else if ("activeReductionTemplate".equals(propertyName)) {
	updateViewActiveReductionTemplate(e.getNewValue());
      } else if ("workingFilter".equals(propertyName)) {
        updateViewFilter(e.getNewValue().toString());
      } else if ("workingScale".equals(propertyName)) {
	updateViewScale(e.getNewValue().toString());
      } else if ("logPath".equals(propertyName)) {
	updateViewLogPath(((File)e.getNewValue()).getAbsolutePath());
      } else if ("outputDir".equals(propertyName)) {
	updateViewOutputPath(((File)e.getNewValue()).getAbsolutePath());
      } else if ("calibDir".equals(propertyName)) {
	updateViewCalibDir(e.getNewValue().toString());
      } else if ("datasetName".equals(propertyName)) {
	updateViewDatasetName(e.getNewValue().toString());
      } else if ("automaticallyGenerateDatasetName".equals(propertyName)) {
	updateViewAutosetDatasetName(((Boolean)e.getNewValue()).booleanValue());
      } else
        return;
    }

  } //. end controller inner class

  //Component initialization
  private void jbInit() throws Exception  {
    //setIconImage(Toolkit.getDefaultToolkit().createImage(ODRFGUIFrame.class.getResource("[Your Icon]")));
    this.setSize(ODRFGUIParameters.DIM_MAINFRAME);
    this.setTitle("OSIRIS Data Reduction File GUI");

    contentPane = (JPanel) this.getContentPane();
    jMenuFile.setText("File");
    jMenuFileSetCalibDir.setText("Set Calibration Directory...");
    jMenuFileSetCalibDir.addActionListener(new ActionListener()  {
      public void actionPerformed(ActionEvent e) {
        jMenuFileSetCalibDir_actionPerformed(e);
      }
    });
    jMenuFileSetQueueDir.setText("Set Queue Directory...");
    jMenuFileSetQueueDir.addActionListener(new ActionListener()  {
      public void actionPerformed(ActionEvent e) {
        jMenuFileSetQueueDir_actionPerformed(e);
      }
    });
    jMenuFileOpenDRF.setText("Open DRF...");
    jMenuFileOpenDRF.addActionListener(new ActionListener()  {
      public void actionPerformed(ActionEvent e) {
        jMenuFileOpenDRF_actionPerformed(e);
      }
    });
    jMenuFileSaveDRF.setText("Save Current Settings to DRF...");
    jMenuFileSaveDRF.addActionListener(new ActionListener()  {
      public void actionPerformed(ActionEvent e) {
        jMenuFileSaveDRF_actionPerformed(e);
      }
    });
    jMenuFileQueueDRF.setText("Send Current DRF to Queue...");
    jMenuFileQueueDRF.addActionListener(new ActionListener()  {
      public void actionPerformed(ActionEvent e) {
        jMenuFileQueueDRF_actionPerformed(e);
      }
    });
    jMenuFileExit.setText("Exit");
    jMenuFileExit.addActionListener(new ActionListener()  {
      public void actionPerformed(ActionEvent e) {
        jMenuFileExit_actionPerformed(e);
      }
    });
    jMenuEngineering.setText("Engineering");
    jMenuHelp.setText("Help");
    jMenuHelpAbout.setText("About");
    jMenuHelpAbout.addActionListener(new ActionListener()  {
      public void actionPerformed(ActionEvent e) {
        jMenuHelpAbout_actionPerformed(e);
      }
    });

    jMenuFileQueueDRF.setEnabled(false);


    statusBar.setText(" ");

    addInputFilesButton.setText("Add Files");
    addInputFilesButton.addActionListener(new java.awt.event.ActionListener() {
      public void actionPerformed(ActionEvent e) {
        addInputFilesButton_actionPerformed(e);
      }
    });
    clearInputFilesButton.setText("Clear List");
    clearInputFilesButton.addActionListener(new java.awt.event.ActionListener() {
      public void actionPerformed(ActionEvent e) {
        clearInputFilesButton_actionPerformed(e);
      }
    });
    filterTitleLabel.setText("Filter:");
    filterTitleLabel.setHorizontalAlignment(SwingConstants.TRAILING);
    scaleTitleLabel.setText("Scale:");
    scaleTitleLabel.setHorizontalAlignment(SwingConstants.TRAILING);
    inputFileLabel.setText("Input Files:");
    datasetNameLabel.setText("Dataset Name:");
    autosetDatasetNameCheckBox.setText("Automatically create dataset name from input files");
    autosetDatasetNameCheckBox.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent e) {
	autosetDatasetNameCheckBox_actionPerformed(e);
      }
    });
    logPathTitleLabel.setText("Log Path:");
    outputPathTitleLabel.setText("Output Path:");
    reductionTypeLabel.setText("Reduction Type:");
    reductionTypeComboBox.addActionListener(new java.awt.event.ActionListener() {
      public void actionPerformed(ActionEvent e) {
	reductionTypeComboBox_actionPerformed(e);
      }
    });
    reductionTemplateLabel.setText("Reduction Templates:");
    reductionTemplateComboBox.addActionListener(new java.awt.event.ActionListener() {
      public void actionPerformed(ActionEvent e) {
	reductionTemplateComboBox_actionPerformed(e);
      }
    });
    logPathLabel.setText(" ");
    logPathLabel.setBorder(BorderFactory.createEtchedBorder());
    outputPathLabel.setText(" ");
    outputPathLabel.setBorder(BorderFactory.createEtchedBorder());

    logPathBrowseButton.setText("Browse");
    logPathBrowseButton.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent e) {
	logPathBrowseButton_actionPerformed(e);
      }
    });
    outputPathBrowseButton.setText("Browse");
    outputPathBrowseButton.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent e) {
	outputPathBrowseButton_actionPerformed(e);
      }
    });

    reductionModuleTableModel.setData(myModel.getActiveModuleList());
    reductionModuleTable.setModel(reductionModuleTableModel);
    TableColumn tColFindFile = reductionModuleTable.getColumn(ODRFGUIParameters.REDUCTION_MODULE_TABLE_COLUMN_HEADER_FIND_FILE);
    TableColumn tColName = reductionModuleTable.getColumn(ODRFGUIParameters.REDUCTION_MODULE_TABLE_COLUMN_HEADER_NAME);
    TableColumn tColSkip = reductionModuleTable.getColumn(ODRFGUIParameters.REDUCTION_MODULE_TABLE_COLUMN_HEADER_SKIP);
    TableColumn tColResolvedFile = reductionModuleTable.getColumn(ODRFGUIParameters.REDUCTION_MODULE_TABLE_COLUMN_HEADER_RESOLVED_FILE);
    tColName.setPreferredWidth(ODRFGUIParameters.REDUCTION_MODULE_TABLE_COLUMN_WIDTH_NAME);
    tColFindFile.setPreferredWidth(ODRFGUIParameters.REDUCTION_MODULE_TABLE_COLUMN_WIDTH_FIND_FILE);
    tColSkip.setPreferredWidth(ODRFGUIParameters.REDUCTION_MODULE_TABLE_COLUMN_WIDTH_SKIP);
    tColFindFile.setCellRenderer(new ReductionModuleTableCalFileCellRenderer());
    tColFindFile.setCellEditor(new ReductionModuleTableFindFileCellEditor());
    tColResolvedFile.setPreferredWidth(ODRFGUIParameters.REDUCTION_MODULE_TABLE_COLUMN_WIDTH_RESOLVED_FILE);
    tColResolvedFile.setCellRenderer(new ReductionModuleTableCalFileCellRenderer());
    tColName.setCellRenderer(new ReductionModuleTableCalFileCellRenderer());
    reductionModuleTableModel.addTableModelListener(new TableModelListener() {
      public void tableChanged(TableModelEvent e) {
	reductionModuleTableModel_tableChanged(e);
      }
    });
    reductionModuleTable.setAutoResizeMode(JTable.AUTO_RESIZE_OFF);

    //. assemble gui
    jMenuFile.add(jMenuFileSetCalibDir);
    jMenuFile.add(jMenuFileSetQueueDir);
    jMenuFile.add(jMenuFileOpenDRF);
    jMenuFile.addSeparator();
    jMenuFile.add(jMenuFileSaveDRF);
    jMenuFile.add(jMenuFileQueueDRF);
    jMenuFile.addSeparator();
    jMenuFile.add(jMenuFileExit);
    jMenuHelp.add(jMenuHelpAbout);
    mainMenuBar.add(jMenuFile);
//    mainMenuBar.add(jMenuEngineering);
    mainMenuBar.add(jMenuHelp);
    this.setJMenuBar(mainMenuBar);


    contentPane.setLayout(new BorderLayout());
    contentPane.add(mainPanel, BorderLayout.CENTER);
    contentPane.add(statusBar, BorderLayout.SOUTH);

    reductionModuleTableScrollPane.getViewport().add(reductionModuleTable);

    inputFileListScrollPane.getViewport().add(inputFileList);

    filterScalePanel.setLayout(new GridLayout(1,0));
    filterScalePanel.add(filterTitleLabel);
    filterScalePanel.add(filterLabel);
    filterScalePanel.add(scaleTitleLabel);
    filterScalePanel.add(scaleLabel);

    int topPanelRow=0;
    topPanel.setLayout(new GridBagLayout());
    topPanel.add(inputFileLabel, new GridBagConstraints(0, topPanelRow, 1, 1, 0.0, 0.0
            ,GridBagConstraints.CENTER, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));
    topPanel.add(addInputFilesButton, new GridBagConstraints(1, topPanelRow, 1, 1, 0.0, 0.0
            ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));
    topPanel.add(clearInputFilesButton, new GridBagConstraints(2, topPanelRow, 1, 1, 0.0, 0.0
            ,GridBagConstraints.EAST, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));

    topPanelRow++;
    topPanel.add(inputFileListScrollPane, new GridBagConstraints(0, topPanelRow, 3, 1, 1.0, 1.0
            ,GridBagConstraints.WEST, GridBagConstraints.BOTH, new Insets(0, 0, 0, 0), 0, 0));

    topPanelRow++;
    topPanel.add(filterScalePanel, new GridBagConstraints(0, topPanelRow, 3, 1, 1.0, 0.0
            ,GridBagConstraints.WEST, GridBagConstraints.HORIZONTAL, new Insets(0, 0, 0, 0), 0, 0));

    topPanelRow++;
    topPanel.add(datasetNameLabel, new GridBagConstraints(0, topPanelRow, 1, 1, 0.0, 0.0
            ,GridBagConstraints.CENTER, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));
    topPanel.add(datasetNameField, new GridBagConstraints(1, topPanelRow, 2, 1, 1.0, 0.0
            ,GridBagConstraints.CENTER, GridBagConstraints.HORIZONTAL, new Insets(0, 0, 0, 0), 0, 0));

    topPanelRow++;
    topPanel.add(autosetDatasetNameCheckBox, new GridBagConstraints(1, topPanelRow, 1, 1, 0.0, 0.0
            ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));

    topPanelRow++;
    topPanel.add(outputPathTitleLabel, new GridBagConstraints(0, topPanelRow, 1, 1, 0.0, 0.0
            ,GridBagConstraints.CENTER, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));
    topPanel.add(outputPathLabel, new GridBagConstraints(1, topPanelRow, 1, 1, 1.0, 0.0
            ,GridBagConstraints.WEST, GridBagConstraints.HORIZONTAL, new Insets(0, 0, 0, 0), 0, 0));
    topPanel.add(outputPathBrowseButton, new GridBagConstraints(2, topPanelRow, 1, 1, 0.0, 0.0
            ,GridBagConstraints.EAST, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));

    topPanelRow++;
    topPanel.add(logPathTitleLabel, new GridBagConstraints(0, topPanelRow, 1, 1, 0.0, 0.0
            ,GridBagConstraints.CENTER, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));
    topPanel.add(logPathLabel, new GridBagConstraints(1, topPanelRow, 1, 1, 1.0, 0.0
            ,GridBagConstraints.WEST, GridBagConstraints.HORIZONTAL, new Insets(0, 0, 0, 0), 0, 0));
    topPanel.add(logPathBrowseButton, new GridBagConstraints(2, topPanelRow, 1, 1, 0.0, 0.0
            ,GridBagConstraints.EAST, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));

    topPanelRow++;
    topPanel.add(reductionTypeLabel, new GridBagConstraints(0, topPanelRow, 1, 1, 0.0, 0.0
            ,GridBagConstraints.CENTER, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));
    topPanel.add(reductionTypeComboBox, new GridBagConstraints(1, topPanelRow, 2, 1, 0.0, 0.0
            ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));

    topPanelRow++;
    topPanel.add(reductionTemplateLabel, new GridBagConstraints(0, topPanelRow, 1, 1, 0.0, 0.0
            ,GridBagConstraints.CENTER, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));
    topPanel.add(reductionTemplateComboBox, new GridBagConstraints(1, topPanelRow, 2, 1, 0.0, 0.0
            ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));


    mainPanel.setLayout(new GridBagLayout());
    mainPanel.add(topPanel, new GridBagConstraints(0, 0, 1, 1, 1.0, 2.0
            ,GridBagConstraints.WEST, GridBagConstraints.BOTH, new Insets(0, 0, 0, 0), 0, 0));
    mainPanel.add(reductionModuleTableScrollPane, new GridBagConstraints(0, 1, 1, 1, 1.0, 10.0
            ,GridBagConstraints.SOUTH, GridBagConstraints.BOTH, new Insets(0, 0, 0, 0), 0, 0));


  }
  //Overridden so we can exit when window is closed
  protected void processWindowEvent(WindowEvent e) {
    super.processWindowEvent(e);
    if (e.getID() == WindowEvent.WINDOW_CLOSING) {
      jMenuFileExit_actionPerformed(null);
    }
  }
 //File | Open DRF action performed
  public void jMenuFileOpenDRF_actionPerformed(ActionEvent e) {
    JFileChooser fc = new JFileChooser(currentDRFReadPath);
    fc.setFileFilter(new OsirisFileFilters.DRFFileFilter());
    fc.setDialogTitle("Open DRF");
    int retVal = fc.showOpenDialog(this);
    if (retVal == JFileChooser.APPROVE_OPTION) {
      try {
	currentDRFReadPath = fc.getCurrentDirectory();
	myModel.openDRF(fc.getSelectedFile());
      }
      catch (Exception ex) {
	JOptionPane.showMessageDialog(this, "Error opening DRF: "+ex.getMessage(), "ODRFGUI: Error Opening DRF", JOptionPane.ERROR_MESSAGE);
      }
    }
  }
 //File | Set Calibration Directory action performed
  public void jMenuFileSetCalibDir_actionPerformed(ActionEvent e) {
    JFileChooser fc = new JFileChooser(myModel.getCalibDir());
    fc.setDialogTitle("Choose Calibration Data Directory");
    fc.setApproveButtonText("Select");
    fc.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
    if (fc.showOpenDialog(this) == JFileChooser.APPROVE_OPTION)
      myModel.setCalibDir(fc.getSelectedFile().getAbsolutePath());
  }
 //File | Set Queue Directory action performed
  public void jMenuFileSetQueueDir_actionPerformed(ActionEvent e) {
    JFileChooser fc = new JFileChooser(myModel.getQueueDir());
    fc.setDialogTitle("Choose DRP Queue Directory");
    fc.setApproveButtonText("Select");
    fc.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
    if (fc.showOpenDialog(this) == JFileChooser.APPROVE_OPTION)
      myModel.setQueueDir(fc.getSelectedFile());
  }
 //File | Send DRF to Queue action performed
  public void jMenuFileQueueDRF_actionPerformed(ActionEvent e) {
  }
 //File | Save Current Settings to DRF action performed
  public void jMenuFileSaveDRF_actionPerformed(ActionEvent e) {
    saveDRF();
  }
  public void saveDRF() {
    if (!myModel.areActiveCalFilesValiated()) {
      String[] message = {"WARNING: Not all calibration files have been validated.",
			  "The DRF may not be successfully completed by the DRP.",
			  "Do you wish to create a DRF anyway?"};
      if (JOptionPane.showConfirmDialog(this, message, "ODRFGUI: Invalid DRF", JOptionPane.OK_CANCEL_OPTION, JOptionPane.WARNING_MESSAGE) == JOptionPane.CANCEL_OPTION)
	return;
    }
    //. launch dialog for writing file
    JFileChooser fc = new JFileChooser(currentDRFWritePath);
    fc.setFileFilter(new OsirisFileFilters.DRFFileFilter());
    fc.setDialogTitle("Save DRF");
    if (defaultSaveFile != null)
      fc.setSelectedFile(defaultSaveFile);
    int retVal = fc.showSaveDialog(this);
    if (retVal == JFileChooser.APPROVE_OPTION) {
      try {
        java.io.File file = fc.getSelectedFile();
	//. if file has no extension, add .ddf to it
	if (OsirisFileUtils.getExtension(file) == null) {
	  file=OsirisFileUtils.addExtension(file, "drf");
	}
	/* check to see if file exists */
	if (file.exists()) {
	  int overwriteOption=JOptionPane.showConfirmDialog(this, "File "+file.getName()+" exists.  Do you wish to overwrite?", "ODRFGUI: File Exists", JOptionPane.YES_NO_CANCEL_OPTION, JOptionPane.QUESTION_MESSAGE);
	  if (overwriteOption == JOptionPane.CANCEL_OPTION) {
	    statusBar.setText("Save DRF cancelled.  DRF not written.");
	    return;
	  } else {
	    defaultSaveFile=file;
	    if (overwriteOption == JOptionPane.NO_OPTION) {
	      saveDRF();
	      return;
	    }
	  }
	}
	myModel.setDatasetName(datasetNameField.getText());
        currentDRFWritePath = file;
        myModel.writeDRF(file);
        statusBar.setText("DRF saved to file "+file.getPath());
      } catch (java.io.IOException ioE) {
        statusBar.setText("Error saving DRF.");
        JOptionPane.showMessageDialog(this, "Error writing DRF: "+ioE.getMessage(), "ODRFGUI: Error Writing DRF", JOptionPane.ERROR_MESSAGE);
      } catch (java.lang.SecurityException sE) {
        statusBar.setText("Error saving DRF.");
        JOptionPane.showMessageDialog(this, "Error writing DRF: "+sE.getMessage(), "ODRFGUI: Error Writing DRF", JOptionPane.ERROR_MESSAGE);
      } catch (org.jdom.JDOMException jdE) {
        statusBar.setText("Error saving DRF.");
        JOptionPane.showMessageDialog(this, "DRF error: "+jdE.getMessage(), "ODRFGUI: Error Writing DRF", JOptionPane.ERROR_MESSAGE);
      }
    }
  }
  //File | Exit action performed
  public void jMenuFileExit_actionPerformed(ActionEvent e) {
    System.exit(0);
  }
  //Help | About action performed
  public void jMenuHelpAbout_actionPerformed(ActionEvent e) {
    OsirisAboutBox dlg = new OsirisAboutBox(this, "OSIRIS Data Reduction File GUI");
    dlg.setLocationAtCenter(this);
    dlg.setModal(true);
    dlg.show();
  }
  void reductionTypeComboBox_actionPerformed(ActionEvent e) {
    myModel.setReductionType(reductionTypeComboBox.getSelectedItem().toString());
  }
  void reductionTemplateComboBox_actionPerformed(ActionEvent e) {
    try {
      myModel.setActiveReductionTemplate(reductionTemplateComboBox.getSelectedIndex());
    } catch (DRDException drdE) {
      JOptionPane.showMessageDialog(this, "Error applying template: "+drdE.getMessage(), "ODRFGUI: Template Error", JOptionPane.ERROR_MESSAGE);
    }
  }

  public void logPathBrowseButton_actionPerformed(ActionEvent e) {
    JFileChooser fc = new JFileChooser(myModel.getLogPath());
    fc.setDialogTitle("Choose Logging Directory");
    fc.setApproveButtonText("Select");
    fc.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
    if (fc.showOpenDialog(this) == JFileChooser.APPROVE_OPTION)
      myModel.setLogPath(fc.getSelectedFile());
  }
  public void outputPathBrowseButton_actionPerformed(ActionEvent e) {
    JFileChooser fc = new JFileChooser(myModel.getOutputDir());
    fc.setDialogTitle("Choose Reduced File Output Directory");
    fc.setApproveButtonText("Select");
    fc.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
    if (fc.showOpenDialog(this) == JFileChooser.APPROVE_OPTION)
      myModel.setOutputDir(fc.getSelectedFile());
  }
  void clearInputFilesButton_actionPerformed(ActionEvent e) {
    int answer = JOptionPane.showConfirmDialog(this, "Remove all files from Input File list?", "Confirm Clear Input File List", JOptionPane.OK_CANCEL_OPTION);
    if (answer == JOptionPane.OK_OPTION) {
      myModel.clearInputFileList();
    }
  }
  void addInputFilesButton_actionPerformed(ActionEvent e) {
    openInputFiles();
  }
  private void openInputFiles() {
    JFileChooser chooser = new JFileChooser(myModel.getInputDir());
    chooser.setMultiSelectionEnabled(true);
    chooser.setDialogTitle("Open OSIRIS Spec FITS Files");
    chooser.setFileFilter(new OsirisFileFilters.FitsFileFilter());
    int retval = chooser.showOpenDialog(this);
    if (retval == JFileChooser.APPROVE_OPTION) {
      File[] files = chooser.getSelectedFiles();
      try {
        myModel.addInputFiles(files);
      } catch (DRDException drdE) {
	JOptionPane.showMessageDialog(this, "Error opening file list: "+drdE.getMessage(), "ODRFGUI: Error Opening Files", JOptionPane.ERROR_MESSAGE);
      }
    }
  }
  void reductionModuleTableModel_tableChanged(TableModelEvent e) {
    if (e.getColumn() == ODRFGUIParameters.REDUCTION_MODULE_TABLE_COLUMN_FIND_FILE) {
      ReductionModule module = myModel.getModule(e.getFirstRow());
      if (module.getFindFileMethod().equals(ODRFGUIParameters.FIND_FILE_MENU_SPECIFY_FILE)) {
	//. launch a file browser
	JFileChooser fc = new JFileChooser();
	if ((module.getName().equals(ODRFGUIParameters.MODULE_SUBTRACT_DARK)) ||
	    (module.getName().equals(ODRFGUIParameters.MODULE_SUBTRACT_SKY)))
	  fc.setCurrentDirectory(myModel.getInputDir());
	fc.setDialogTitle("Select Calibration File");
	int retval = fc.showOpenDialog(this);
	if (retval == JFileChooser.APPROVE_OPTION) {
	  File file = fc.getSelectedFile();
	  module.setCalibrationFileValidated(true);
	  module.setCalibrationFile(file.getAbsolutePath());
	} else {
	  File newFile = new File(module.getCalibrationFile());
	  module.setCalibrationFileValidated(newFile.exists());
	}
      } else {
	myModel.resolveFindFile(module);
      }
    }
    reductionModuleTable.repaint();
  }
  void autosetDatasetNameCheckBox_actionPerformed(ActionEvent e) {
    myModel.setAutomaticallyGenerateDatasetName(autosetDatasetNameCheckBox.isSelected());
  }
  private void updateView() {
    updateViewFilter(myModel.getWorkingFilter());
    updateViewScale(myModel.getWorkingScale());
    updateViewOutputPath(myModel.getOutputDir().getAbsolutePath());
    updateViewLogPath(myModel.getLogPath().getAbsolutePath());
    updateViewReductionType(myModel.getReductionType());
    updateViewInputFileList(myModel.getInputFileList());
    updateViewDatasetName(myModel.getDatasetName());
    updateViewAutosetDatasetName(myModel.willAutomaticallyGenerateDatasetName());
  }
  private void updateViewModuleList(ArrayList list) {
    reductionModuleTableModel.setData(list);
  }
  private void updateViewInputFileList(ArrayList list) {
    clearInputFilesButton.setEnabled(!list.isEmpty());
    inputFileList.setListData((DRDInputFile[])list.toArray(new DRDInputFile[]{}));
    reductionModuleTable.repaint();
  }
  private void updateViewActiveReductionTemplate(Object value) {
    reductionModuleTable.repaint();
  }
  private void updateViewFilter(String filter) {
    filterLabel.setText(filter);
  }
  private void updateViewScale(String scale) {
    scaleLabel.setText(scale);
  }
  private void updateViewOutputPath(String outputPath) {
    outputPathLabel.setText(outputPath);
  }
  private void updateViewLogPath(String logPath) {
    logPathLabel.setText(logPath);
  }
  private void updateViewReductionType(String type) {
    reductionTypeComboBox.setSelectedItem(type);
  }
  private void updateViewReductionTemplate(String template) {
    reductionTemplateComboBox.setSelectedItem(template);
  }
  private void updateViewDatasetName(String name) {
    datasetNameField.setText(name);
  }
  private void updateViewAutosetDatasetName(boolean status) {
    autosetDatasetNameCheckBox.setSelected(status);
    datasetNameField.setEnabled(!status);
  }
  private void updateViewCalibDir(String calibDir) {
    //. reductionModuleTable.repaint();
  }
  //. BEGIN INNER CLASSES
  public class ReductionModuleTableFindFileCellEditor extends DefaultCellEditor {
    public ReductionModuleTableFindFileCellEditor() {
      super(new JComboBox());
    }
    public Component getTableCellEditorComponent(JTable table, Object value, boolean isSelected, int row, int column) {
      ReductionModule activeModule = (ReductionModule)(((ReductionModuleListTableModel)table.getModel()).getData()).get(row);
      JComboBox combo = (JComboBox)getComponent();
      DefaultComboBoxModel model = new DefaultComboBoxModel(activeModule.getAllowedFindFileMethods());
      combo.setModel(model);
      return combo;
    }
  }
  public class ReductionModuleTableCalFileCellRenderer extends JLabel implements TableCellRenderer {
    Color skipModuleFGColor;
    Color doModuleFGColor;
    Color selectedBGColor;
    Color notSelectedBGColor;
    Color invalidFileFGColor;
    public ReductionModuleTableCalFileCellRenderer() {
      setOpaque(true);
      skipModuleFGColor = new Color(150, 150, 150);
      doModuleFGColor = new Color(0, 0, 0);
      invalidFileFGColor = new Color(200, 0, 0);
      selectedBGColor = new Color(220, 210, 255);
      notSelectedBGColor = Color.WHITE;
    }
    public Component getTableCellRendererComponent(JTable table, Object value, boolean isSelected, boolean cellHasFocus, int row, int column) {
      try {
	setText(value.toString());
        if (isSelected) {
  	  setBackground(selectedBGColor);
        } else {
	  setBackground(notSelectedBGColor);
        }
        Font curFont = this.getFont();
	if (myModel.isModuleSkipped(row)) {
	  setFont(new Font(curFont.getName(), (curFont.getStyle() | Font.ITALIC), curFont.getSize()));
	  setForeground(skipModuleFGColor);
	} else {
	  setFont(new Font(curFont.getName(), (curFont.getStyle() & ~Font.ITALIC), curFont.getSize()));
	  if (myModel.isModuleCalFileValid(row)) {
	    setForeground(doModuleFGColor);
	  } else {
	    setForeground(invalidFileFGColor);
	  }
	}
      } catch (IndexOutOfBoundsException iobE) {
	setText("Error rendering cell.");
      } finally {
        return this;
      }
    }
  }
  public class ReductionModuleTableNameCellRenderer extends JLabel implements TableCellRenderer {
    Color skipModuleFGColor;
    Color doModuleFGColor;
    Color selectedBGColor;
    Color notSelectedBGColor;
    public ReductionModuleTableNameCellRenderer() {
      setOpaque(true);
      skipModuleFGColor = new Color(150, 150, 150);
      doModuleFGColor = new Color(0, 0, 0);
      selectedBGColor = new Color(220, 210, 255);
      notSelectedBGColor = Color.WHITE;
    }
    public Component getTableCellRendererComponent(JTable table, Object value, boolean isSelected, boolean cellHasFocus, int row, int column) {
      try {
	setText(value.toString());
        if (isSelected) {
  	  setBackground(selectedBGColor);
        } else {
	  setBackground(notSelectedBGColor);
        }
        Font curFont = this.getFont();
	if (myModel.isModuleSkipped(row)) {
	  setFont(new Font(curFont.getName(), (curFont.getStyle() | Font.ITALIC), curFont.getSize()));
	  setForeground(skipModuleFGColor);
	} else {
	  setFont(new Font(curFont.getName(), (curFont.getStyle() & ~Font.ITALIC), curFont.getSize()));
	  setForeground(doModuleFGColor);
	}
      } catch (IndexOutOfBoundsException iobE) {
	setText("Error rendering cell.");
      } finally {
        return this;
      }
    }

  }

}
