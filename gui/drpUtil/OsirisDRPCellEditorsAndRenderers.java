package edu.ucla.astro.osiris.drp.util;

import javax.swing.*;
import java.awt.*;

/**
 * <p>Title: OSIRIS Software Package</p>
 * <p>Description: </p>
 * <p>Copyright: Copyright (c) 2004</p>
 * <p>Company: UCLA Infrared Imaging Detector Laboratory</p>
 * @author Jason L. Weiss
 * @version 1.0
 */

public class OsirisDRPCellEditorsAndRenderers {

  public static class ReductionModuleListCellRenderer extends JLabel implements ListCellRenderer {
    Color skipModuleFGColor;
    Color doModuleFGColor;
    Color selectedBGColor;
    Color notSelectedBGColor;
    public ReductionModuleListCellRenderer() {
      setOpaque(true);
      skipModuleFGColor = new Color(150, 150, 150);
      doModuleFGColor = new Color(0, 0, 0);
      selectedBGColor = new Color(220, 210, 255);
      notSelectedBGColor = Color.WHITE;
    }
    public Component getListCellRendererComponent(JList list, Object value, int index, boolean isSelected, boolean cellHasFocus) {
      setText(value.toString());
      if (value instanceof ReductionModule) {
	ReductionModule module = (ReductionModule)value;
        Font curFont = this.getFont();
	if (module.doSkip()) {
	  setFont(new Font(curFont.getName(), (curFont.getStyle() | Font.ITALIC), curFont.getSize()));
	  setForeground(skipModuleFGColor);
	} else {
	  setFont(new Font(curFont.getName(), (curFont.getStyle() & ~Font.ITALIC), curFont.getSize()));
	  setForeground(doModuleFGColor);
	}
      }
      if (isSelected) {
	setBackground(selectedBGColor);
      } else {
	setBackground(notSelectedBGColor);
      }
      return this;
    }
  }

}