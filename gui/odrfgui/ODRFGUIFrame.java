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
  JMenu jMenuTools = new JMenu();
  JMenuItem jMenuToolsOptions = new JMenuItem();
  JMenu jMenuHelp = new JMenu();
  JMenuItem jMenuHelpAbout = new JMenuItem();

  JPanel mainPanel = new JPanel();
  JPanel topPanel = new JPanel();
  JPanel filterScalePanel = new JPanel();

  JSplitPane moduleSplitPane = new JSplitPane();
  JSplitPane availableModulesSplitPane = new JSplitPane();
  JSplitPane argumentSplitPane = new JSplitPane();
  JSplitPane updateSplitPane = new JSplitPane();

  //. input file list
  JScrollPane inputFileListScrollPane = new JScrollPane();
  JList inputFileList = new JList();
  JButton addInputFilesButton = new JButton();
  JButton removeInputFilesButton = new JButton();
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
  JComboBox reductionTemplateComboBox;

  //. module list
  JScrollPane moduleDescriptionScrollPane = new JScrollPane(JScrollPane.VERTICAL_SCROLLBAR_AS_NEEDED, JScrollPane.HORIZONTAL_SCROLLBAR_NEVER);
  JTextArea moduleDescriptionTextArea = new JTextArea();
  JScrollPane availableModulesTableScrollPane = new JScrollPane();
  JTable availableModulesTable = new JTable();
  DefaultArrayListTableModel availableModulesTableModel = new DefaultArrayListTableModel();
  
  JScrollPane reductionModuleTableScrollPane = new JScrollPane();
  JTable reductionModuleTable = new JTable();
  ReductionModuleListTableModel reductionModuleTableModel = new ReductionModuleListTableModel();

  JScrollPane moduleArgumentTableScrollPane = new JScrollPane();
  JTable moduleArgumentTable = new JTable();
  ReductionModuleArgumentListTableModel argumentTableModel = new ReductionModuleArgumentListTableModel();
  
  JScrollPane updateModuleTableScrollPane = new JScrollPane();
  JTable updateModuleTable = new JTable();
  UpdateModuleListTableModel updateModuleTableModel = new UpdateModuleListTableModel();
  
  JPanel executePanel = new JPanel();
  JButton saveDRFButton = new JButton();
  JButton dropDRFButton = new JButton();
  
  JLabel statusBar = new JLabel();

  private KeywordUpdateModuleDefinitionDialog updateDialog;
	JCheckBox confirmBox = new JCheckBox("Don't show this dialog again.");
  
  private JCheckBox confirmSaveInvalidDRFCheckBox = new JCheckBox("Confirm saving invalid DRFs?");
  private JCheckBox confirmDropDRFCheckBox = new JCheckBox("Confirm dropping DRFs to queue?");
  private JCheckBox confirmDropInvalidDRFCheckBox = new JCheckBox("Confirm dropping invalid DRFs to queue?");
  private JCheckBox showKeywordUpdateCheckBox = new JCheckBox("Show keyword update panel? (Advanced)");
  private JCheckBox writeDRFVerboseCheckBox = new JCheckBox("Be verbose when writing DRFs?");
  
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
      } else if ("activeModule".equals(propertyName)) {
      	updateViewActiveModule((ReductionModule)e.getNewValue());
      } else if ("availableModuleList".equals(propertyName)) {
      	updateViewAvailableModuleList((ArrayList)e.getNewValue());
      } else if ("updateKeywordModuleList".equals(propertyName)) {
      	updateViewUpdateKeywordModuleList((ArrayList)e.getNewValue());
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
      } else if ("reductionType".equals(propertyName)) {
      	updateViewReductionType(e.getNewValue().toString());
      } else
        return;
    }

  } //. end controller inner class

  //Component initialization
  private void jbInit() throws Exception  {
  	updateDialog = new KeywordUpdateModuleDefinitionDialog(this);
  	
  	confirmSaveInvalidDRFCheckBox.setSelected(ODRFGUIParameters.DEFAULT_CONFIRM_SAVE_INVALID_DRF);
  	confirmDropInvalidDRFCheckBox.setSelected(ODRFGUIParameters.DEFAULT_CONFIRM_DROP_INVALID_DRF);
  	confirmDropDRFCheckBox.setSelected(ODRFGUIParameters.DEFAULT_CONFIRM_DROP_DRF);
  	showKeywordUpdateCheckBox.setSelected(ODRFGUIParameters.DEFAULT_SHOW_KEYWORD_UPDATE_PANEL);
  	writeDRFVerboseCheckBox.setSelected(myModel.doWriteDRFVerbose());
  	
  	
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
    jMenuTools.setText("Tools");
    jMenuToolsOptions.setText("Options...");
    jMenuToolsOptions.addActionListener(new ActionListener()  {
      public void actionPerformed(ActionEvent e) {
        jMenuToolsOptions_actionPerformed(e);
      }
    });
    jMenuHelp.setText("Help");
    jMenuHelpAbout.setText("About");
    jMenuHelpAbout.addActionListener(new ActionListener()  {
      public void actionPerformed(ActionEvent e) {
        jMenuHelpAbout_actionPerformed(e);
      }
    });
    
    filterTitleLabel.setFont(ODRFGUIParameters.FONT_FILTER_LABEL);
    filterLabel.setFont(ODRFGUIParameters.FONT_FILTER_VALUE);
    scaleTitleLabel.setFont(ODRFGUIParameters.FONT_SCALE_LABEL);
    scaleLabel.setFont(ODRFGUIParameters.FONT_SCALE_VALUE);
    
    //jMenuFileQueueDRF.setEnabled(false);
    saveDRFButton.setText("Save DRF As...");
    saveDRFButton.addActionListener(new java.awt.event.ActionListener() {
    	public void actionPerformed(ActionEvent e) {
    		saveDRFButton_actionPerformed(e);
    	}
    });
    dropDRFButton.setText("Drop DRF In Queue");
    dropDRFButton.addActionListener(new java.awt.event.ActionListener() {
    	public void actionPerformed(ActionEvent e) {
    		dropDRFButton_actionPerformed(e);
    	}
    });

    statusBar.setText(" ");

    addInputFilesButton.setText("Add Files");
    addInputFilesButton.addActionListener(new java.awt.event.ActionListener() {
      public void actionPerformed(ActionEvent e) {
        addInputFilesButton_actionPerformed(e);
      }
    });
    removeInputFilesButton.setText("Remove Files");
    removeInputFilesButton.addActionListener(new java.awt.event.ActionListener() {
      public void actionPerformed(ActionEvent e) {
        removeInputFilesButton_actionPerformed(e);
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
    reductionTemplateComboBox = new JComboBox(new Vector(myModel.getReductionTemplates()));
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

    String[] availColumnNames = {"Available Modules"};
    availableModulesTableModel.setColumnNames(availColumnNames);
    availableModulesTable.setModel(availableModulesTableModel);
    availableModulesTable.addMouseListener(new MouseAdapter() {
    	public void mouseClicked(MouseEvent e) {
    		if (e.getClickCount() == 1) {
    			availableModulesTable_clickEvent();
    		} else if (e.getClickCount() == 2) {
    			availableModulesTable_doubleClickEvent();
    		}
    	}
    });
    
    moduleDescriptionTextArea.setEditable(false);
    moduleDescriptionTextArea.setLineWrap(true);
    moduleDescriptionTextArea.setWrapStyleWord(true);
    moduleDescriptionTextArea.setText("Module Description");
    moduleDescriptionTextArea.setBackground(UIManager.getColor(new JPanel()));
    
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
    tColResolvedFile.setHeaderRenderer(new OsirisCellEditorsAndRenderers.AlignedTextTableHeaderCellRenderer(SwingConstants.LEFT));
    tColName.setCellRenderer(new ReductionModuleTableCalFileCellRenderer());
    reductionModuleTableModel.addTableModelListener(new TableModelListener() {
      public void tableChanged(TableModelEvent e) {
      	reductionModuleTableModel_tableChanged(e);
      }
    });
    reductionModuleTable.addMouseListener(new MouseAdapter() {
    	public void mouseClicked(MouseEvent e) {
    		if (e.getClickCount() == 2) {
    			reductionModuleTable_doubleClickEvent();
    		}
    	}
    });
    reductionModuleTable.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
    reductionModuleTable.getSelectionModel().addListSelectionListener(new ListSelectionListener() {
    	public void valueChanged(ListSelectionEvent ev) {
    		reductionModuleTable_selectionChanged(ev);
    	}
    });
    reductionModuleTable.setAutoResizeMode(JTable.AUTO_RESIZE_OFF);

    
    moduleArgumentTable.setModel(argumentTableModel);
    TableColumn tColArgName = moduleArgumentTable.getColumn(ODRFGUIParameters.MODULE_ARGUMENT_TABLE_COLUMN_HEADER_NAME);
    TableColumn tColArgValue = moduleArgumentTable.getColumn(ODRFGUIParameters.MODULE_ARGUMENT_TABLE_COLUMN_HEADER_VALUE);
    tColArgName.setPreferredWidth(ODRFGUIParameters.MODULE_ARGUMENT_TABLE_COLUMN_WIDTH_NAME);
    tColArgValue.setPreferredWidth(ODRFGUIParameters.MODULE_ARGUMENT_TABLE_COLUMN_WIDTH_VALUE);
    tColArgName.setCellRenderer(new OsirisCellEditorsAndRenderers.CenteredTextTableCellRenderer());
    tColArgValue.setCellRenderer(new OsirisCellEditorsAndRenderers.CenteredTextTableCellRenderer());
    tColArgValue.setCellEditor(new ReductionModuleArgumentTableValueCellEditor());
    
    updateModuleTableModel.setData(myModel.getUpdateKeywordModuleList());
    updateModuleTable.setModel(updateModuleTableModel);
    TableColumn tColKeyword = updateModuleTable.getColumn(ODRFGUIParameters.UPDATE_MODULE_TABLE_COLUMN_HEADER_KEYWORD);
    TableColumn tColDatatype = updateModuleTable.getColumn(ODRFGUIParameters.UPDATE_MODULE_TABLE_COLUMN_HEADER_DATATYPE);
    TableColumn tColValue = updateModuleTable.getColumn(ODRFGUIParameters.UPDATE_MODULE_TABLE_COLUMN_HEADER_VALUE);
    TableColumn tColComment = updateModuleTable.getColumn(ODRFGUIParameters.UPDATE_MODULE_TABLE_COLUMN_HEADER_COMMENT);
    tColKeyword.setPreferredWidth(ODRFGUIParameters.UPDATE_MODULE_TABLE_COLUMN_WIDTH_KEYWORD);
    tColDatatype.setPreferredWidth(ODRFGUIParameters.UPDATE_MODULE_TABLE_COLUMN_WIDTH_DATATYPE);
    tColValue.setPreferredWidth(ODRFGUIParameters.UPDATE_MODULE_TABLE_COLUMN_WIDTH_VALUE);
    tColComment.setPreferredWidth(ODRFGUIParameters.UPDATE_MODULE_TABLE_COLUMN_WIDTH_COMMENT);
    tColDatatype.setCellRenderer(new OsirisCellEditorsAndRenderers.CenteredTextTableCellRenderer());
    tColValue.setCellRenderer(new OsirisCellEditorsAndRenderers.CenteredTextTableCellRenderer());
    tColComment.setHeaderRenderer(new OsirisCellEditorsAndRenderers.AlignedTextTableHeaderCellRenderer(SwingConstants.LEFT));
    updateModuleTable.setAutoResizeMode(JTable.AUTO_RESIZE_OFF);
    
    updateModuleTable.addMouseListener(new MouseAdapter() {
    	public void mouseClicked(MouseEvent e) {
    		if (e.getClickCount() == 2) {
    			updateModuleTable_doubleClickEvent();
    		}
    	}
    });
    
    availableModulesSplitPane.setDividerLocation(ODRFGUIParameters.SPLIT_PANE_AVAILABLE_MODULE_LIST_DIVIDER_LOCATION);
    availableModulesSplitPane.setOrientation(JSplitPane.VERTICAL_SPLIT);
    availableModulesSplitPane.setDividerSize(2);
    moduleSplitPane.setDividerLocation(ODRFGUIParameters.SPLIT_PANE_MODULE_LIST_DIVIDER_LOCATION);
    updateSplitPane.setOrientation(JSplitPane.VERTICAL_SPLIT);
    updateSplitPane.setDividerLocation(ODRFGUIParameters.SPLIT_PANE_UPDATE_LIST_DIVIDER_LOCATION);
    argumentSplitPane.setOrientation(JSplitPane.VERTICAL_SPLIT);
    argumentSplitPane.setDividerLocation(ODRFGUIParameters.SPLIT_PANE_ARGUMENT_LIST_DIVIDER_LOCATION);
    
    
    updateModuleTableScrollPane.setVisible(ODRFGUIParameters.DEFAULT_SHOW_KEYWORD_UPDATE_PANEL);
    updateModuleTableScrollPane.addMouseListener(new MouseAdapter() {
    	public void mouseClicked(MouseEvent e) {
    		if (e.getClickCount() == 2) {
    			updateModuleTableScrollPane_doubleClickEvent();
    		}
    	}
    });
    
    //. assemble gui
    jMenuFile.add(jMenuFileSetCalibDir);
    jMenuFile.add(jMenuFileSetQueueDir);
    jMenuFile.add(jMenuFileOpenDRF);
    jMenuFile.addSeparator();
    jMenuFile.add(jMenuFileSaveDRF);
    jMenuFile.add(jMenuFileQueueDRF);
    jMenuFile.addSeparator();
    jMenuFile.add(jMenuFileExit);
    jMenuTools.add(jMenuToolsOptions);
    jMenuHelp.add(jMenuHelpAbout);
    mainMenuBar.add(jMenuFile);
    mainMenuBar.add(jMenuTools);
    mainMenuBar.add(jMenuHelp);
    this.setJMenuBar(mainMenuBar);


    contentPane.setLayout(new BorderLayout());
    contentPane.add(mainPanel, BorderLayout.CENTER);
    contentPane.add(statusBar, BorderLayout.SOUTH);

    reductionModuleTableScrollPane.getViewport().add(reductionModuleTable);
    moduleArgumentTableScrollPane.getViewport().add(moduleArgumentTable);
    availableModulesTableScrollPane.getViewport().add(availableModulesTable);
    updateModuleTableScrollPane.getViewport().add(updateModuleTable);
    inputFileListScrollPane.getViewport().add(inputFileList);
    moduleDescriptionScrollPane.getViewport().add(moduleDescriptionTextArea);
    
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
    topPanel.add(removeInputFilesButton, new GridBagConstraints(2, topPanelRow, 1, 1, 0.0, 0.0
        ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));
    topPanel.add(clearInputFilesButton, new GridBagConstraints(3, topPanelRow, 1, 1, 0.0, 0.0
            ,GridBagConstraints.EAST, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));

    topPanelRow++;
    topPanel.add(inputFileListScrollPane, new GridBagConstraints(0, topPanelRow, 4, 1, 1.0, 1.0
            ,GridBagConstraints.WEST, GridBagConstraints.BOTH, new Insets(0, 0, 0, 0), 0, 0));

    topPanelRow++;
    topPanel.add(filterScalePanel, new GridBagConstraints(0, topPanelRow, 4, 1, 1.0, 0.0
            ,GridBagConstraints.WEST, GridBagConstraints.HORIZONTAL, new Insets(0, 0, 0, 0), 0, 0));

    topPanelRow++;
    topPanel.add(datasetNameLabel, new GridBagConstraints(0, topPanelRow, 1, 1, 0.0, 0.0
            ,GridBagConstraints.CENTER, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));
    topPanel.add(datasetNameField, new GridBagConstraints(1, topPanelRow, 3, 1, 1.0, 0.0
            ,GridBagConstraints.CENTER, GridBagConstraints.HORIZONTAL, new Insets(0, 0, 0, 0), 0, 0));

    topPanelRow++;
    topPanel.add(autosetDatasetNameCheckBox, new GridBagConstraints(1, topPanelRow, 3, 1, 0.0, 0.0
            ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));

    topPanelRow++;
    topPanel.add(outputPathTitleLabel, new GridBagConstraints(0, topPanelRow, 1, 1, 0.0, 0.0
            ,GridBagConstraints.CENTER, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));
    topPanel.add(outputPathLabel, new GridBagConstraints(1, topPanelRow, 2, 1, 1.0, 0.0
            ,GridBagConstraints.WEST, GridBagConstraints.HORIZONTAL, new Insets(0, 0, 0, 0), 0, 0));
    topPanel.add(outputPathBrowseButton, new GridBagConstraints(3, topPanelRow, 1, 1, 0.0, 0.0
            ,GridBagConstraints.EAST, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));

    topPanelRow++;
    topPanel.add(logPathTitleLabel, new GridBagConstraints(0, topPanelRow, 1, 1, 0.0, 0.0
            ,GridBagConstraints.CENTER, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));
    topPanel.add(logPathLabel, new GridBagConstraints(1, topPanelRow, 2, 1, 1.0, 0.0
            ,GridBagConstraints.WEST, GridBagConstraints.HORIZONTAL, new Insets(0, 0, 0, 0), 0, 0));
    topPanel.add(logPathBrowseButton, new GridBagConstraints(3, topPanelRow, 1, 1, 0.0, 0.0
            ,GridBagConstraints.EAST, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));

    topPanelRow++;
    topPanel.add(reductionTypeLabel, new GridBagConstraints(0, topPanelRow, 1, 1, 0.0, 0.0
            ,GridBagConstraints.CENTER, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));
    topPanel.add(reductionTypeComboBox, new GridBagConstraints(1, topPanelRow, 3, 1, 0.0, 0.0
            ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));

    topPanelRow++;
    topPanel.add(reductionTemplateLabel, new GridBagConstraints(0, topPanelRow, 1, 1, 0.0, 0.0
            ,GridBagConstraints.CENTER, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));
    topPanel.add(reductionTemplateComboBox, new GridBagConstraints(1, topPanelRow, 3, 1, 0.0, 0.0
            ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));


    updateSplitPane.add(argumentSplitPane, JSplitPane.TOP);
    updateSplitPane.add(updateModuleTableScrollPane, JSplitPane.BOTTOM);
    
    moduleSplitPane.add(availableModulesSplitPane, JSplitPane.LEFT);
    moduleSplitPane.add(updateSplitPane, JSplitPane.RIGHT);

    argumentSplitPane.add(reductionModuleTableScrollPane, JSplitPane.TOP);
    argumentSplitPane.add(moduleArgumentTableScrollPane, JSplitPane.BOTTOM);
    
    availableModulesSplitPane.add(availableModulesTableScrollPane, JSplitPane.TOP);
    availableModulesSplitPane.add(moduleDescriptionScrollPane, JSplitPane.BOTTOM);
    
    executePanel.setLayout(new GridLayout(1,0,50,5));
    executePanel.add(saveDRFButton);
    executePanel.add(dropDRFButton);
    
    
    mainPanel.setLayout(new GridBagLayout());
    mainPanel.add(topPanel, new GridBagConstraints(0, 0, 2, 1, 1.0, 2.0
            ,GridBagConstraints.WEST, GridBagConstraints.BOTH, new Insets(0, 0, 0, 0), 0, 0));
    mainPanel.add(moduleSplitPane, new GridBagConstraints(0, 1, 1, 1, 1.0, 10.0
            ,GridBagConstraints.SOUTH, GridBagConstraints.BOTH, new Insets(0, 0, 0, 0), 0, 0));
    mainPanel.add(executePanel, new GridBagConstraints(0, 2, 1, 1, 1.0, 0.0
        ,GridBagConstraints.SOUTH, GridBagConstraints.HORIZONTAL, new Insets(0, 0, 0, 0), 0, 0));

    updateDialog.setLocationRelativeTo(updateModuleTableScrollPane);

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
    XMLFileChooser fc = new XMLFileChooser(currentDRFReadPath);
    fc.setFileFilter(new OsirisFileFilters.DRFFileFilter());
    fc.setDialogTitle("Open DRF");
    int retVal = fc.showOpenDialog(this);
    if (retVal == JFileChooser.APPROVE_OPTION) {
      try {
      	currentDRFReadPath = fc.getCurrentDirectory();
      	myModel.openDRF(fc.getSelectedFile());
      } catch (Exception ex) {
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
      myModel.setCalibDir(fc.getSelectedFile());
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
    dropDRF();
  }
  
  public void dropDRF() {
  	if (myModel.getQueueDir() == null) {
  		String[] message = {"Error: Queue directory not set."};
  		JOptionPane.showMessageDialog(this, message, "ODRFGUI: Invalid Queue", JOptionPane.ERROR_MESSAGE);
  		return;
  	}

   	if (confirmDropInvalidDRFCheckBox.isSelected()) {
  		if (!myModel.areActiveCalFilesValiated()) {
			  confirmBox.setSelected(false);
	      Object[] message = {"WARNING: Not all calibration files have been validated.",
				  "The DRF may not be successfully completed by the DRP.",
				  "Do you wish to create a DRF anyway?", " ", confirmBox};
		  	if (JOptionPane.showConfirmDialog(this, message, "ODRFGUI: Invalid DRF", JOptionPane.OK_CANCEL_OPTION, JOptionPane.WARNING_MESSAGE) == JOptionPane.OK_OPTION) {	  			
	  			if (confirmBox.isSelected()) {
	  				confirmDropInvalidDRFCheckBox.setSelected(false);
	  			}
		  	} else {
		  		return;
		  	};
  		}
    }
    
    if (confirmDropDRFCheckBox.isSelected()) {
    	confirmBox.setSelected(false);
	    Object[] message = {"Drop DRF to queue?  Queue Dir is", myModel.getQueueDir().getPath(), " ", confirmBox};
	  	if (JOptionPane.showConfirmDialog(this, message, "ODRFGUI: Confirm Drop", JOptionPane.OK_CANCEL_OPTION, JOptionPane.QUESTION_MESSAGE) == JOptionPane.OK_OPTION) {	  			
  			if (confirmBox.isSelected()) {
  				confirmDropDRFCheckBox.setSelected(false);
  			}
	  	} else {
	  		return;
	  	};
    }
  	try {
  		myModel.setDatasetName(datasetNameField.getText());
  		String filename = myModel.writeDRFToQueue();
      statusBar.setText("DRF <"+OsirisFileUtils.getNameOfFile(filename)+"> dropped to queue <"+myModel.getQueueDir().getPath()+">.");
      
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
 //File | Save Current Settings to DRF action performed
  public void jMenuFileSaveDRF_actionPerformed(ActionEvent e) {
    saveDRF();
  }
  public void saveDRFButton_actionPerformed(ActionEvent e) {
  	saveDRF();
  }
  public void dropDRFButton_actionPerformed(ActionEvent e) {
  	dropDRF();
  }
  public void saveDRF() {
   	if (confirmSaveInvalidDRFCheckBox.isSelected()) {
  		if (!myModel.areActiveCalFilesValiated()) {
			  confirmBox.setSelected(false);
	      Object[] message = {"WARNING: Not all calibration files have been validated.",
				  "The DRF may not be successfully completed by the DRP.",
				  "Do you wish to create a DRF anyway?", " ", confirmBox};
		  	if (JOptionPane.showConfirmDialog(this, message, "ODRFGUI: Invalid DRF", JOptionPane.OK_CANCEL_OPTION, JOptionPane.WARNING_MESSAGE) == JOptionPane.OK_OPTION) {	  			
		  			if (confirmBox.isSelected()) {
		  				confirmSaveInvalidDRFCheckBox.setSelected(false);
		  			}
		  	} else {
		  		return;		  		
		  	}
  		}
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
  //Tools | Options action performed
  public void jMenuToolsOptions_actionPerformed(ActionEvent e) {
    //. construct dialog
  	
  	writeDRFVerboseCheckBox.setSelected(myModel.doWriteDRFVerbose());
  	
  	Object[] message = {confirmSaveInvalidDRFCheckBox, " ", confirmDropInvalidDRFCheckBox, " ", 
  			confirmDropDRFCheckBox, " ", showKeywordUpdateCheckBox, " ", writeDRFVerboseCheckBox};
  	
  	if (JOptionPane.showConfirmDialog(this, message, "ODRFGUI: Options", JOptionPane.OK_CANCEL_OPTION) == JOptionPane.OK_OPTION) {  			
			boolean showUpdate = showKeywordUpdateCheckBox.isSelected();
			updateModuleTableScrollPane.setVisible(showUpdate);
			if (showUpdate)
				updateSplitPane.setDividerLocation(0.8);
			else
				updateSplitPane.setDividerLocation(1.0);	
			myModel.setWriteDRFVerbose(writeDRFVerboseCheckBox.isSelected());
		}
  }
  //Help | About action performed
  public void jMenuHelpAbout_actionPerformed(ActionEvent e) {
    OsirisAboutBox dlg = new OsirisAboutBox(this, "OSIRIS Data Reduction File GUI");
    dlg.setVersion("Version 2.01");
    dlg.setReleased("Released: 7 June 2007");
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
    browseForLogPath(fc);
  }
  private void browseForLogPath(JFileChooser fc) {
    if (fc.showOpenDialog(this) == JFileChooser.APPROVE_OPTION) {
    	if (fc.getSelectedFile().canWrite())
    		 myModel.setLogPath(fc.getSelectedFile());
    	else {
    		JOptionPane.showMessageDialog(this, "Cannot write to log dir <"+fc.getSelectedFile().getAbsolutePath()+">.", "Error setting logging directory.", JOptionPane.ERROR_MESSAGE);
    		browseForLogPath(fc);
    	}
    }
  }

  public void outputPathBrowseButton_actionPerformed(ActionEvent e) {
    JFileChooser fc = new JFileChooser(myModel.getOutputDir());
    fc.setDialogTitle("Choose Reduced File Output Directory");
    fc.setApproveButtonText("Select");
    fc.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
    browseForOutputPath(fc);
  }
  private void browseForOutputPath(JFileChooser fc) {
    if (fc.showOpenDialog(this) == JFileChooser.APPROVE_OPTION) {
    	if (fc.getSelectedFile().canWrite())
    		myModel.setOutputDir(fc.getSelectedFile());
    	else {
    		JOptionPane.showMessageDialog(this, "Cannot write to output dir <"+fc.getSelectedFile().getAbsolutePath()+">.", "Error setting output directory.", JOptionPane.ERROR_MESSAGE);
    		browseForOutputPath(fc);
    	}
    }
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
  void removeInputFilesButton_actionPerformed(ActionEvent e) {	
  	myModel.removeInputFiles(inputFileList.getSelectedIndices());
  }
  private void openInputFiles() {
    JFileChooser chooser = new JFileChooser(myModel.getInputDir());
    chooser.setMultiSelectionEnabled(true);
    chooser.setDialogTitle("Open OSIRIS Spec FITS Files");
    chooser.setFileFilter(new OsirisFileFilters.FitsFileFilter());
    int retval = chooser.showOpenDialog(this);
    if (retval == JFileChooser.APPROVE_OPTION) {
      File[] files = chooser.getSelectedFiles();
      for (int ii=0; ii<files.length; ii++) {
      	try {
      		DRDInputFile inputFile = new DRDInputFile(files[ii]);
          try {
          	inputFile.validateFilter();
          } catch (DRDException drdE) {
          	ArrayList messageList = new ArrayList();
          	messageList.add("Error opening file "+files[ii].getName()+".");
          	messageList.add(drdE.getMessage());
          	messageList.add("");
          	messageList.add("You can either:"); 
          	messageList.add("  - Ignore the error, and use the file anyway.");
          	messageList.add("  - Drop the file from the input file list.");     
          	messageList.add("  - Use the current working filter: "+myModel.getWorkingFilter()+".");
		        
	          ArrayList optionsList = new ArrayList();
	          optionsList.add("Ignore Error");
	          optionsList.add("Drop File");
	          optionsList.add("Use Working Filter");
	          String defaultOption = "Ignore Error";
	 	        if (inputFile.getSFWName() != null) {
	 	        	messageList.add("  - Use SFWNAME keyword: "+inputFile.getSFWName());
	 	        	optionsList.add("Use SFWName");
	 	        	defaultOption = "User SFWName";
	          }
	          int selection = JOptionPane.showOptionDialog(this, messageList.toArray(), "ODRFGUI: Error opening file", JOptionPane.DEFAULT_OPTION, JOptionPane.WARNING_MESSAGE, null, optionsList.toArray(), defaultOption);
	          if (selection == JOptionPane.CLOSED_OPTION) {
	          	continue;
	          } else {
	          	if (optionsList.get(selection).toString().compareTo("Ignore Error") == 0) {
	          		inputFile.overrideFilter("None");
	          	} else if (optionsList.get(selection).toString().compareTo("Drop File") == 0) {
	          		continue;
	          	} else if (optionsList.get(selection).toString().compareTo("Use Working Filter") == 0) {
	          		inputFile.overrideFilter(myModel.getWorkingFilter());
	          	} else if (optionsList.get(selection).toString().compareTo("Use SFWName") == 0) {
	          		inputFile.overrideFilter(inputFile.getSFWName());
	          	}
	          }
	          
          }
	        try {
		        inputFile.validateScale();
		      } catch (DRDException drdE) {
          	ArrayList messageList = new ArrayList();
          	messageList.add("Error opening file "+files[ii].getName()+".");
          	messageList.add(drdE.getMessage());
          	messageList.add("");
          	messageList.add("You can either:"); 
          	messageList.add("  - Ignore the error, and use the file anyway.");
          	messageList.add("  - Drop the file from the input file list.");     
          	messageList.add("  - Use the current working Scale: "+myModel.getWorkingScale()+".");
		        
	          ArrayList optionsList = new ArrayList();
	          optionsList.add("Ignore Error");
	          optionsList.add("Drop File");
	          optionsList.add("Use Working Scale");
	          String defaultOption = "Ignore Error";
	 	        if (inputFile.getSS1Name() != null) {
	 	        	messageList.add("  - Use SS1NAME keyword: "+inputFile.getSS1Name());
	 	        	optionsList.add("Use SS1Name");
	 	        	defaultOption = "Use SS1Name";
	          }
	 	        if (inputFile.getSS2Name() != null) {
	 	        	messageList.add("  - Use SS2NAME keyword: "+inputFile.getSS2Name());
	 	        	optionsList.add("Use SS2Name");
	 	        	if (defaultOption.compareTo("Use SS1Name") != 0)
	 	        		defaultOption = "Use SS2Name";
	          }
	          int selection = JOptionPane.showOptionDialog(this, messageList.toArray(), "ODRFGUI: Error opening file", JOptionPane.DEFAULT_OPTION, JOptionPane.WARNING_MESSAGE, null, optionsList.toArray(), defaultOption);
	          if (selection == JOptionPane.CLOSED_OPTION) {
	          	continue;
	          } else {
	          	if (optionsList.get(selection).toString().compareTo("Ignore Error") == 0) {
	          		inputFile.overrideScale("None");
	          	} else if (optionsList.get(selection).toString().compareTo("Drop File") == 0) {
	          		continue;
	          	} else if (optionsList.get(selection).toString().compareTo("Use Working Scale") == 0) {
	          		inputFile.overrideScale(myModel.getWorkingScale());
	          	} else if (optionsList.get(selection).toString().compareTo("Use SS1Name") == 0) {
	          		inputFile.overrideScale(inputFile.getSS1Name());
	          	} else if (optionsList.get(selection).toString().compareTo("Use SS2Name") == 0) {
	          		inputFile.overrideScale(inputFile.getSS2Name());
	          	}
	          }
          }
		      myModel.addInputFile(inputFile);
      	} catch (Exception ex) {
	      	JOptionPane.showMessageDialog(this, "Error opening file "+files[ii].getName()+": "+ex.getMessage(), "ODRFGUI: Error Opening Files", JOptionPane.ERROR_MESSAGE);
	      }
      }
    }
  }
  void reductionModuleTableModel_tableChanged(TableModelEvent e) {
    if (e.getColumn() == ODRFGUIParameters.REDUCTION_MODULE_TABLE_COLUMN_FIND_FILE) {
      ReductionModule module = myModel.getModule(e.getFirstRow());
      if (module.getFindFileMethod().equals(ODRFGUIParameters.FIND_FILE_MENU_SPECIFY_FILE)) {
      	browseForCalFile(module);
      } else {
      	myModel.resolveFindFile(module);
      }
    }
    reductionModuleTable.repaint();
  }
  private void browseForCalFile(ReductionModule module) {
  	//. launch a file browser
  	JFileChooser fc = new JFileChooser();
  	File calFile = new File(module.getCalibrationFile());
  	if (calFile.exists())
  		fc.setSelectedFile(calFile);
  	else if ((module.getName().equals(ODRFGUIParameters.MODULE_SUBTRACT_DARK)) ||
  			(module.getName().equals(ODRFGUIParameters.MODULE_SUBTRACT_SKY)) ||
  			(module.getName().equals(ODRFGUIParameters.MODULE_SUBTRACT_FRAME)))
  		fc.setCurrentDirectory(myModel.getInputDir());
  	else 
  		fc.setCurrentDirectory(myModel.getCalibDir());
  	fc.setDialogTitle("Select Calibration File");
  	int retval = fc.showOpenDialog(this);
  	if (retval == JFileChooser.APPROVE_OPTION) {
  		calFile = fc.getSelectedFile();
  		module.setCalibrationFileValidated(true);
  		module.setCalibrationFile(calFile.getAbsolutePath());
  	} 
  }
  void autosetDatasetNameCheckBox_actionPerformed(ActionEvent e) {
    myModel.setAutomaticallyGenerateDatasetName(autosetDatasetNameCheckBox.isSelected());
  }
	void availableModulesTable_clickEvent() {
		//. get module description and fill text area
		moduleDescriptionTextArea.setText(((ReductionModule)myModel.getAvailableModuleList().get(availableModulesTable.getSelectedRow())).getDescription());
		//. position cursor at top
		moduleDescriptionTextArea.setCaretPosition(0);
	}
	void availableModulesTable_doubleClickEvent() {
		myModel.addModuleToActiveList((ReductionModule)myModel.getAvailableModuleList().get(availableModulesTable.getSelectedRow()));
	}

  void reductionModuleTable_selectionChanged(ListSelectionEvent ev) {
  	//. should be a single row
  	int row = reductionModuleTable.getSelectedRow();
		moduleArgumentTable.repaint();
  	if (row < 0)
  		myModel.setActiveModule(null);
  	else
  		myModel.setActiveModule(myModel.getModule(row));
  		
  }
	void reductionModuleTable_doubleClickEvent() {
		if (reductionModuleTable.getSelectedColumn() == ODRFGUIParameters.REDUCTION_MODULE_TABLE_COLUMN_NAME) {
			myModel.removeModuleFromActiveList(reductionModuleTable.getSelectedRow());
			myModel.setActiveModule(null);
		} else if (reductionModuleTable.getSelectedColumn() == ODRFGUIParameters.REDUCTION_MODULE_TABLE_COLUMN_RESOLVED_FILE) {
			//. if module is using specify a file, bring up file browser
      ReductionModule module = myModel.getModule(reductionModuleTable.getSelectedRow());
      if (module.getFindFileMethod().equals(ODRFGUIParameters.FIND_FILE_MENU_SPECIFY_FILE)) {
      	browseForCalFile(module);
      }
 		}
	}
	void updateModuleTable_doubleClickEvent() {
		int index = updateModuleTable.getSelectedRow();
		updateDialog.setRemoveEnabled(true);
		updateDialog.setIndex(index);
		updateDialog.setModule((KeywordUpdateReductionModule) updateModuleTableModel.getData().get(index));
		updateDialog.setVisible(true);
	}
	void updateModuleTableScrollPane_doubleClickEvent() {
		int index = updateModuleTableModel.getData().size();
		updateDialog.setRemoveEnabled(false);
		updateDialog.setIndex(index);
		updateDialog.setModule(new KeywordUpdateReductionModule());
		updateDialog.setVisible(true);
		
	}
	public void updateModelKeywordUpdateModuleList(int index, KeywordUpdateReductionModule module) {
		myModel.updateUpdateKeywordModuleList(index, module);
	}
	public void updateModelRemoveKeywordUpdateModule(int index) {
		myModel.removeModuleFromUpdateList(index);
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
  private void updateViewActiveModule(ReductionModule module) {
  	if (module == null)
  		argumentTableModel.setData(new ArrayList());
  	else
  		argumentTableModel.setData(module.getArguments());
  	
  	
  }
  private void updateViewAvailableModuleList(ArrayList list) {
    ((ArrayListTableModel)availableModulesTable.getModel()).setData(list);
  }
  private void updateViewUpdateKeywordModuleList(ArrayList list) {
  	if (list.equals(updateModuleTableModel.getData()))
  		updateModuleTableModel.fireTableDataChanged();
  	else
  		updateModuleTableModel.setData(list);
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
  	if (filter.compareTo("None") == 0)
  		filterLabel.setForeground(ODRFGUIParameters.COLOR_FILTER_INVALID);
  	else
  		filterLabel.setForeground(ODRFGUIParameters.COLOR_FILTER_VALID);
  }
  private void updateViewScale(String scale) {
    scaleLabel.setText(scale);
  	if (scale.compareTo("None") == 0)
  		scaleLabel.setForeground(ODRFGUIParameters.COLOR_SCALE_INVALID);
  	else
  		scaleLabel.setForeground(ODRFGUIParameters.COLOR_SCALE_VALID);
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
      } 
      return this;
    }
  }
  public class ReductionModuleArgumentTableEnumCellEditor extends DefaultCellEditor {
    public ReductionModuleArgumentTableEnumCellEditor() {
      super(new JComboBox());
    }
    public Component getTableCellEditorComponent(JTable table, Object value, boolean isSelected, int row, int column) {
      ReductionModuleArgument arg = (ReductionModuleArgument)(((ReductionModuleArgumentListTableModel)table.getModel()).getData()).get(row);
      JComboBox combo = (JComboBox)getComponent();
    	//. break down range to get combo box options      	
      DefaultComboBoxModel model = new DefaultComboBoxModel(arg.getRange().split("\\|"));
      combo.setModel(model);
      return combo;      	
    }  	
  }
  
  public class ReductionModuleArgumentTableValueCellEditor implements TableCellEditor {
    DefaultCellEditor comboEditor = new DefaultCellEditor(new JComboBox());   
    DefaultCellEditor fieldEditor = new DefaultCellEditor(new JTextField());
    DefaultCellEditor editor;
    public ReductionModuleArgumentTableValueCellEditor() {
    	editor = fieldEditor;
    	FocusListener focusL = new FocusListener() {
    		public void focusLost(FocusEvent ev) {
    			componentFocusLost(ev);
    		}
    		public void focusGained(FocusEvent ev) {
    			componentFocusGained(ev);
    		}
    	};
    	comboEditor.getComponent().addFocusListener(focusL);
    	fieldEditor.getComponent().addFocusListener(focusL);
    }
    public Component getTableCellEditorComponent(JTable table, Object value, boolean isSelected, int row, int column) {
    	ReductionModuleArgument arg = (ReductionModuleArgument)(((ReductionModuleArgumentListTableModel)table.getModel()).getData()).get(row);
      if (arg.getType().compareTo(ReductionModuleArgument.TYPE_ENUM) == 0) {
      	editor = comboEditor;
      	//. break down range to get combo box options      	
        DefaultComboBoxModel model = new DefaultComboBoxModel(arg.getRange().split("\\|"));
        ((JComboBox)comboEditor.getComponent()).setModel(model);
        return comboEditor.getTableCellEditorComponent(table, value, isSelected, row, column);      	
      } else {
      	editor= fieldEditor;
      	return fieldEditor.getTableCellEditorComponent(table, value, isSelected, row, column);
      }
    }
    public Object getCellEditorValue() {
    	Component comp = editor.getComponent();
    	if (comp instanceof JComboBox) {
    		return ((JComboBox)comp).getSelectedItem();
    	} else {
    		return ((JTextField)comp).getText();
    	}
    }
    public void addCellEditorListener(CellEditorListener l) {
    	editor.addCellEditorListener(l);
    }
    public void cancelCellEditing() {
    	editor.cancelCellEditing();
    }
    public boolean isCellEditable(EventObject anEvent) {
    	return editor.isCellEditable(anEvent);
    }
    public void removeCellEditorListener(CellEditorListener l) {
    	editor.removeCellEditorListener(l);
    }
    public boolean shouldSelectCell(EventObject anEvent) {
    	return editor.shouldSelectCell(anEvent);
    }
    public boolean stopCellEditing() {
    	return editor.stopCellEditing();
    }
    
    public void componentFocusLost(FocusEvent ev) {
    	//System.out.println("focuslost");
    	cancelCellEditing();
    }
    public void componentFocusGained(FocusEvent ev) {
    	//System.out.println("focusgained");
    	
    }
  }
}
