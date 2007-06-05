package edu.ucla.astro.osiris.drp.odrfgui;

import javax.swing.UIManager;
import javax.swing.JOptionPane;
import edu.ucla.astro.osiris.util.XmlToParams;

/**
 * <p>Title: </p>
 * <p>Description: </p>
 * <p>Copyright: Copyright (c) 2003</p>
 * <p>Company: </p>
 * @author unascribed
 * @version 1.0
 */

public class ODRFGUI {

  public ODRFGUI() throws Exception {
    new ODRFGUIApplication();
 }
  public static void main(String[] args) {
    String cfgFilename=new String("");

    if (System.getSecurityManager() == null) {
      System.setSecurityManager(new SecurityManager());
    }
    //. arg[0] should be cfg=Config_Filename
    for (int ii=0; ii<args.length; ii++) {
      if (args[ii].startsWith("cfg=")) {
	cfgFilename=args[ii].substring(4, (args[ii].length()));
      }
    }
    try {
      //. set Look and Feel based on OS
      //UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
      if (cfgFilename.length() > 0) {
	  //. get config file
	  java.io.File cfgFile = new java.io.File(cfgFilename);
	  //. extract parameters from config file
	  XmlToParams.extractParams(cfgFile, ODRFGUIParameters.getInstance());
      }
      //. define menu fonts here in this way, so that setFont doesn't have
      //. to be called for each item.
      UIManager.put("Menu.font", ODRFGUIParameters.FONT_MENU);
      UIManager.put("MenuItem.font", ODRFGUIParameters.FONT_MENUITEM);

     //. launch application
      new ODRFGUI();

    } catch (java.io.IOException ioE) {
      JOptionPane.showMessageDialog(null, ioE.getMessage(), "ODRFGUI Critical Error", JOptionPane.ERROR_MESSAGE);
      //ioE.printStackTrace();
      System.exit(-1);
    } catch (org.jdom.JDOMException jdE) {
      JOptionPane.showMessageDialog(null, jdE.getMessage(), "ODRFGUI Critical Error", JOptionPane.ERROR_MESSAGE);
      //jdE.printStackTrace();
      System.exit(-1);
    } catch(Exception e) {
      JOptionPane.showMessageDialog(null, e.getMessage(), "ODRFGUI Critical Error", JOptionPane.ERROR_MESSAGE);
      e.printStackTrace();
      System.exit(-1);
    }
  }
}
