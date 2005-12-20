package edu.ucla.astro.osiris.drp.odrfgui;

import edu.ucla.astro.osiris.drp.util.*;
import edu.ucla.astro.osiris.util.*;
import java.util.*;

/**
 * <p>Title: OSIRIS Software Package</p>
 * <p>Description: </p>
 * <p>Copyright: Copyright (c) 2004</p>
 * <p>Company: UCLA Infrared Imaging Detector Laboratory</p>
 * @author Jason L. Weiss
 * @version 1.0
 */
/** @todo  this class depends on util, it shouldn't */
public class ReductionModuleListTableModel extends ArrayListTableModel {

  public ReductionModuleListTableModel() {
      //. call super
      super();
      //. set column names
      super.setColumnNames(ODRFGUIParameters.REDUCTION_MODULE_TABLE_COLUMN_HEADERS);
  }
  public Object getValueAt(int row, int column) {
    ArrayList data = getData();
    ReductionModule module = (ReductionModule)(data.get(row));
    if (column == ODRFGUIParameters.REDUCTION_MODULE_TABLE_COLUMN_NAME) {
      return module.getName();
    } else if (column == ODRFGUIParameters.REDUCTION_MODULE_TABLE_COLUMN_SKIP) {
      return new Boolean(module.doSkip());
    } else if (column == ODRFGUIParameters.REDUCTION_MODULE_TABLE_COLUMN_FIND_FILE) {
      return module.getFindFileMethod();
    } else if (column == ODRFGUIParameters.REDUCTION_MODULE_TABLE_COLUMN_RESOLVED_FILE) {
      return module.getCalibrationFile();
    } else
      return null;
  }
    public void setValueAt(Object aValue, int row, int column) {
      ArrayList data = getData();
      ReductionModule module = (ReductionModule)(data.get(row));

      //. convert object to proper datatype, then set in data arraylist
      if (aValue == null)
        return;
      if (column == ODRFGUIParameters.REDUCTION_MODULE_TABLE_COLUMN_SKIP) {
        try {
	  module.setSkip(((Boolean)aValue).booleanValue());
        } catch (Exception e) {
          e.printStackTrace();
        }
      } else if (column == ODRFGUIParameters.REDUCTION_MODULE_TABLE_COLUMN_FIND_FILE) {
	module.setFindFileMethod(aValue.toString());
      }
      //. tell table something has changed
      fireTableCellUpdated(row, column);
    }

  public boolean isCellEditable(int row, int column) {
    return ((column != ODRFGUIParameters.REDUCTION_MODULE_TABLE_COLUMN_NAME) &&
	    (column != ODRFGUIParameters.REDUCTION_MODULE_TABLE_COLUMN_RESOLVED_FILE));
  }
}