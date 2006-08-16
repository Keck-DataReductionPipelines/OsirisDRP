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
public class UpdateModuleListTableModel extends ArrayListTableModel {

  public UpdateModuleListTableModel() {
      //. call super
      super();
      //. set column names
      super.setColumnNames(ODRFGUIParameters.UPDATE_MODULE_TABLE_COLUMN_HEADERS);
  }
  public Object getValueAt(int row, int column) {
    ArrayList data = getData();
    KeywordUpdateReductionModule module = (KeywordUpdateReductionModule)(data.get(row));
    if (column == ODRFGUIParameters.UPDATE_MODULE_TABLE_COLUMN_KEYWORD) {
      return module.getKeywordName();
    } else if (column == ODRFGUIParameters.UPDATE_MODULE_TABLE_COLUMN_DATATYPE) {
      return module.getKeywordDatatype();
    } else if (column == ODRFGUIParameters.UPDATE_MODULE_TABLE_COLUMN_VALUE) {
      return module.getKeywordValue();
    } else if (column == ODRFGUIParameters.UPDATE_MODULE_TABLE_COLUMN_COMMENT) {
      return module.getKeywordComment();
    } else
      return null;
  }
  public void setValueAt(Object aValue, int row, int column) {
    	//. this function might not be necessary, since table is not directly editable  
    	ArrayList data = getData();
      KeywordUpdateReductionModule module = (KeywordUpdateReductionModule)(data.get(row));

      //. convert object to proper datatype, then set in data arraylist
      if (aValue == null)
        return;
      if (column == ODRFGUIParameters.UPDATE_MODULE_TABLE_COLUMN_KEYWORD) {
       	module.setKeywordName(aValue.toString());
      } else if (column == ODRFGUIParameters.UPDATE_MODULE_TABLE_COLUMN_DATATYPE) {
      	module.setKeywordDatatype(aValue.toString());
      } else if (column == ODRFGUIParameters.UPDATE_MODULE_TABLE_COLUMN_VALUE) {
      	module.setKeywordValue(aValue.toString());
      } else if (column == ODRFGUIParameters.UPDATE_MODULE_TABLE_COLUMN_COMMENT) {
      	module.setKeywordComment(aValue.toString());
      }
      //. tell table something has changed
      fireTableCellUpdated(row, column);
    }

  public boolean isCellEditable(int row, int column) {
    return false;
  }
}