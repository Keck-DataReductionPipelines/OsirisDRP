package edu.ucla.astro.osiris.drp.odrfgui;


/**
 * <p>Title: </p>
 * <p>Description: </p>
 * <p>Copyright: Copyright (c) 2003</p>
 * <p>Company: </p>
 * @author unascribed
 * @version 1.0
 */

public class ODRFGUIApplication {
  boolean packFrame = false;

  //Construct the application
  public ODRFGUIApplication() throws org.jdom.JDOMException, java.io.IOException, edu.ucla.astro.osiris.drp.util.DRDException, Exception {
    ODRFGUIModel model = new ODRFGUIModel();
    ODRFGUIFrame frame = new ODRFGUIFrame(model);
    //Validate frames that have preset sizes
    //Pack frames that have useful preferred size info, e.g. from their layout

    if (packFrame) {
      frame.pack();
    }
    else {
      frame.validate();
    }

    frame.setLocation(ODRFGUIParameters.POINT_MAINFRAME_LOCATION);
    frame.setVisible(true);
  }
}
