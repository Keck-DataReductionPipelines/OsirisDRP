package edu.ucla.astro.osiris.drp.odrfgui;

import java.util.ArrayList;

import javax.swing.JOptionPane;

import edu.ucla.astro.osiris.drp.util.ReductionModule;
import edu.ucla.astro.osiris.drp.util.ReductionModuleArgument;
import edu.ucla.astro.osiris.util.ArrayListTableModel;
import edu.ucla.astro.osiris.drp.util.DRDException;

public class ReductionModuleArgumentListTableModel extends ArrayListTableModel {

	public ReductionModuleArgumentListTableModel() {
		super();
    //. set column names
    super.setColumnNames(ODRFGUIParameters.MODULE_ARGUMENT_TABLE_COLUMN_HEADERS);
	}

	public Object getValueAt(int row, int column) {
    ArrayList data = getData();
    ReductionModuleArgument argument = (ReductionModuleArgument)(data.get(row));
    if (column == ODRFGUIParameters.MODULE_ARGUMENT_TABLE_COLUMN_NAME) {
      return argument.getName();
    } else if (column == ODRFGUIParameters.MODULE_ARGUMENT_TABLE_COLUMN_VALUE) {
      return argument.getValue();
    } else
      return null;
	}
  public void setValueAt(Object aValue, int row, int column) {
    ArrayList data = getData();
    ReductionModuleArgument argument = (ReductionModuleArgument)(data.get(row));

    //. convert object to proper datatype, then set in data arraylist
    if (aValue == null)
      return;
    if (column == ODRFGUIParameters.MODULE_ARGUMENT_TABLE_COLUMN_VALUE) {
    		try {
    			argument.setValue(aValue.toString());
    		} catch (DRDException drdEx) {
    			JOptionPane.showMessageDialog(null, drdEx.getMessage(), "Error setting value", JOptionPane.ERROR_MESSAGE);
    		}
    }
    //. tell table something has changed
    fireTableCellUpdated(row, column);
  }

  public boolean isCellEditable(int row, int column) {
  	return ((column != ODRFGUIParameters.MODULE_ARGUMENT_TABLE_COLUMN_NAME));
  }
}
