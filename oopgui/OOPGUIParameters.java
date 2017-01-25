package edu.ucla.astro.osiris.oopgui;

import java.awt.Color;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.Point;
import java.io.File;

/**
 * <p>Title: OOPGUIParameters</p>
 * <p>Description: Constants file for OOPGUI. Values in this class can be overriden
      by setting values in XML config file (filename passed in as argument). </p>
 * <p>Copyright: Copyright (c) 2005</p>
 * <p>Company: UCLA Infrared Lab</p>
 * @author Jason L. Weiss
 * @version 1.0
 */

public class OOPGUIParameters {
  //. this class follows the singleton design pattern (gamma, et al, Design Patterns)
  //. only one instance of this class is allowed.
  private static OOPGUIParameters singleton = null;

  //. xml config file with generic osiris parameters
  public static File OSIRIS_CONFIG_FILE = new File("/kroot/rel/default/data/osiris_cfg.xml");

  //. location of upper left corner of dialog
  public static Point POINT_MAINFRAME_LOCATION = new Point(100, 100);
  //. default dialog sizes
  public static Dimension DIM_MAINFRAME = new Dimension(800, 1000);
  public static Dimension DIM_IMAG_FILTER_SET_FRAME = new Dimension(280, 300);
  public static Dimension DIM_CALIBRATION_FRAME = new Dimension(900, 600);
  public static Dimension DIM_POSLIST_DIALOG = new Dimension(300, 400);
  public static Dimension DIM_REDUCTION_PARAMS_DIALOG = new Dimension(300, 400);
  public static Dimension DIM_DDF_STATUS_BAR = new Dimension(100, 0);

  //. default dialog fonts
  public static Font FONT_MENU = new Font("Dailog", 0, 12);
  public static Font FONT_MENUITEM = new Font("Dailog", 0, 12);
  public static Font FONT_BORDER_TITLES = new Font("Dialog", 0, 12);
  public static Font FONT_LABEL = new Font("Dialog", Font.PLAIN, 12);
  public static Font FONT_FIELD = new Font("Dialog", Font.PLAIN, 12);
  public static Font FONT_COMBO = new Font("Dialog", Font.PLAIN, 12);
  public static Font FONT_UNITS = new Font("Dialog", Font.PLAIN, 12);
  public static Font FONT_SEND_TO_QUEUE_BUTTON = new Font("Dialog", 0, 12);
  public static Font FONT_REDUCTION_PARAMS_BUTTON = new Font("Dialog", 0, 12);
  public static Font FONT_POSITION_LIST_BUTTON = new Font("Dialog", 0, 12);
  public static Font FONT_DIALOG_POSLIST_HEADER = new Font("Dialog", 0, 12);
  public static Font FONT_DIALOG_POSLIST_ITEMS = new Font("Dialog", 0, 12);
  public static Font FONT_DIALOG_POSLIST_MOVE_BUTTONS = new Font("Dialog", 0, 12);
  public static Font FONT_DIALOG_POSLIST_OK_BUTTON = new Font("Dialog", 0, 12);
  public static Font FONT_DIALOG_REDUCE_BORDER_TITLES = new Font("Dialog", 0, 12);
  public static Font FONT_DIALOG_REDUCE_DEFAULTS_BUTTON = new Font("Dialog", 0, 12);
  public static Font FONT_DIALOG_REDUCE_OK_BUTTON = new Font("Dialog", 0, 12);
  public static Font FONT_TAB_DITHER_PANEL = new Font("Dialog", 0, 12);

  //. names for tabs of each type of dither panel
  public static String DITHER_TAB_SPEC_NAME =          "Show Spectrometer Only";
  public static String DITHER_TAB_IMAG_NAME =          "Show Imager Only";
  public static String DITHER_TAB_SPEC_AND_IMAG_NAME = "Show Spec and Imager";

  //. column headers for table listing dither positions
  public static String DITHER_TABLE_POSITION_COLUMN_HEADER = "#";
  public static String DITHER_TABLE_XOFF_COLUMN_HEADER="Xoff (\")";
  public static String DITHER_TABLE_YOFF_COLUMN_HEADER="Yoff (\")";
  public static String DITHER_TABLE_SKY_COLUMN_HEADER="Sky?";
  public static String[] DITHER_TABLE_COLUMN_HEADERS = {DITHER_TABLE_POSITION_COLUMN_HEADER,
                                                        DITHER_TABLE_XOFF_COLUMN_HEADER,
                                                        DITHER_TABLE_YOFF_COLUMN_HEADER,
                                                        DITHER_TABLE_SKY_COLUMN_HEADER};

  //. default column sizes for table listing dither positions
  public static int DITHER_TABLE_WIDTH = 200;
  public static int DITHER_TABLE_POSITION_COLUMN_WIDTH = 10;
  public static int DITHER_TABLE_XOFF_COLUMN_WIDTH = 80;
  public static int DITHER_TABLE_YOFF_COLUMN_WIDTH = 80;
  public static int DITHER_TABLE_SKY_COLUMN_WIDTH = 50;
  public static int DITHER_TABLE_POSITION_COLUMN = 0;
  public static int DITHER_TABLE_XOFF_COLUMN = 1;
  public static int DITHER_TABLE_YOFF_COLUMN = 2;
  public static int DITHER_TABLE_SKY_COLUMN = 3;

  //. precision for offsets in table listing dither positions
  public static int DITHER_TABLE_OFFSET_PRECISION = 3;

  //. column headers for table for editing a filter set
  public static String IMAG_FRAME_TABLE_COLUMN_HEADER_FILTER = "Filter";
  public static String IMAG_FRAME_TABLE_COLUMN_HEADER_ITIME = "Itime";
  public static String IMAG_FRAME_TABLE_COLUMN_HEADER_COADDS = "Coadds";
  public static String IMAG_FRAME_TABLE_COLUMN_HEADER_REPEATS = "Repeats";
  public static String[] IMAG_FRAME_TABLE_COLUMN_HEADERS = {IMAG_FRAME_TABLE_COLUMN_HEADER_FILTER,
                                                            IMAG_FRAME_TABLE_COLUMN_HEADER_REPEATS,
                                                            IMAG_FRAME_TABLE_COLUMN_HEADER_COADDS,
                                                            IMAG_FRAME_TABLE_COLUMN_HEADER_ITIME};
  //. column sizes and order for table for editing a filter set
  public static int IMAG_FRAME_TABLE_COLUMN_FILTER = 0;
  public static int IMAG_FRAME_TABLE_COLUMN_REPEATS = 1;
  public static int IMAG_FRAME_TABLE_COLUMN_COADDS = 2;
  public static int IMAG_FRAME_TABLE_COLUMN_ITIME = 3;
  public static int IMAG_FRAME_TABLE_COLUMN_WIDTH_FILTER = 120;
  public static int IMAG_FRAME_TABLE_COLUMN_WIDTH_ITIME = 60;
  public static int IMAG_FRAME_TABLE_COLUMN_WIDTH_COADDS = 60;
  public static int IMAG_FRAME_TABLE_COLUMN_WIDTH_REPEATS = 60;

  //. tooltip text for part of status bar showing DDF status
  public static String TOOLTIP_DDF_STATUS_BAR = "DDF Status";

  //. default paths for reading and writing ddfs and cdfs
  public static File DDF_READ_PATH = new File("/u/osrseng/");
  public static File DDF_WRITE_PATH = new File("/u/osrseng/");
  public static File CDF_READ_PATH = new File("/u/osrseng/");
  public static File CDF_WRITE_PATH = new File("/u/osrseng/");

  private OOPGUIParameters() {
    //. private constructor as per singleton design pattern
  }

  public static OOPGUIParameters getInstance() {
    //. method to get instance of this singleton class

    //. if not yet defined, instantiate a new class
    if (singleton == null) {
      singleton = new OOPGUIParameters();
    }
    //. return instance
    return singleton;
  }

}
