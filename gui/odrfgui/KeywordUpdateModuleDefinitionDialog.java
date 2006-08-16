package edu.ucla.astro.osiris.drp.odrfgui;

import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import edu.ucla.astro.osiris.drp.util.KeywordUpdateReductionModule;


public class KeywordUpdateModuleDefinitionDialog extends Dialog {

	private JPanel mainPanel = new JPanel();
	private JPanel buttonPanel = new JPanel();
	private JLabel nameLabel = new JLabel();
	private JLabel datatypeLabel = new JLabel();
	private JLabel valueLabel = new JLabel();
	private JLabel commentLabel = new JLabel();
	
	private JTextField nameField = new JTextField();
	private JComboBox datatypeBox = new JComboBox(ODRFGUIParameters.HEADER_DATATYPE_OPTIONS);
	private JTextField valueField = new JTextField();
	private JTextField commentField = new JTextField();

	private JButton okButton = new JButton();
	private JButton removeButton = new JButton();
	private JButton cancelButton = new JButton();
	
	private int index=0;
	private KeywordUpdateReductionModule module = new KeywordUpdateReductionModule();
	
	public KeywordUpdateModuleDefinitionDialog(Frame parent) {
		super(parent, "Update Keywords", true);
		jbInit();
	}
	private void jbInit() {
		mainPanel.setLayout(new GridBagLayout());
		buttonPanel.setLayout(new GridLayout(1,3));
		nameLabel.setText("Keyword:");
		datatypeLabel.setText("Datatype:");
		valueLabel.setText("Value:");
		commentLabel.setText("Comment");
		
		okButton.setText("OK");
		removeButton.setText("Remove");
		cancelButton.setText("Cancel");
		
		okButton.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent event) {
				okButton_actionPerformed();
			}
		});
		removeButton.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent event) {
				removeButton_actionPerformed();
			}
		});
		cancelButton.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent event) {
			  cancelButton_actionPerformed();
			}
		});
		
		buttonPanel.add(okButton);
		buttonPanel.add(removeButton);
		buttonPanel.add(cancelButton);
		
		mainPanel.add(nameLabel, new GridBagConstraints(0,0,1,1,0.0,0.0,
				GridBagConstraints.EAST,GridBagConstraints.NONE,new Insets(0,0,0,0),0,0));
		mainPanel.add(nameField, new GridBagConstraints(1,0,1,1,1.0,0.0,
				GridBagConstraints.WEST,GridBagConstraints.HORIZONTAL,new Insets(0,0,0,0),0,0));
		mainPanel.add(datatypeLabel, new GridBagConstraints(0,1,1,1,0.0,0.0,
				GridBagConstraints.EAST,GridBagConstraints.NONE,new Insets(0,0,0,0),0,0));
		mainPanel.add(datatypeBox, new GridBagConstraints(1,1,1,1,1.0,0.0,
				GridBagConstraints.WEST,GridBagConstraints.HORIZONTAL,new Insets(0,0,0,0),0,0));
		mainPanel.add(valueLabel, new GridBagConstraints(0,2,1,1,0.0,0.0,
				GridBagConstraints.EAST,GridBagConstraints.NONE,new Insets(0,0,0,0),0,0));
		mainPanel.add(valueField, new GridBagConstraints(1,2,1,1,1.0,0.0,
				GridBagConstraints.WEST,GridBagConstraints.HORIZONTAL,new Insets(0,0,0,0),0,0));
		mainPanel.add(commentLabel, new GridBagConstraints(0,3,1,1,0.0,0.0,
				GridBagConstraints.EAST,GridBagConstraints.NONE,new Insets(0,0,0,0),0,0));
		mainPanel.add(commentField, new GridBagConstraints(1,3,1,1,1.0,0.0,
				GridBagConstraints.WEST,GridBagConstraints.HORIZONTAL,new Insets(0,0,0,0),0,0));
		mainPanel.add(buttonPanel, new GridBagConstraints(0,4,2,1,1.0,0.0,
				GridBagConstraints.CENTER,GridBagConstraints.HORIZONTAL,new Insets(0,0,0,0),0,0));

		this.add(mainPanel);
		
		this.pack();
	}
	public void okButton_actionPerformed() {
		String name = nameField.getText();
		String nameCheckMessage = validateKeywordName(name);
		if (nameCheckMessage.length() > 0) {
			JOptionPane.showMessageDialog(this, nameCheckMessage, "Keyword Error", JOptionPane.ERROR_MESSAGE);
		} else {
			String value = valueField.getText();
			String datatype = (String)datatypeBox.getSelectedItem();
			String suggestedValue = validateValue(value, datatype);
		
			if (suggestedValue.compareToIgnoreCase(value) != 0) {
				String[] message = {"The value you entered does not seem correct for a "+datatype+".", 
						"Perhaps you meant "+suggestedValue+".",
						"",
						"Would you like to use this value?"};
				if (JOptionPane.showConfirmDialog(this, message, "Keyword Value Error", JOptionPane.OK_CANCEL_OPTION) == JOptionPane.CANCEL_OPTION) {
					return;
				}
			}
			module.setKeywordName(name.toUpperCase());
			module.setKeywordValue(suggestedValue);
			module.setKeywordDatatype(datatype);
			module.setKeywordComment(commentField.getText());
			((ODRFGUIFrame)this.getParent()).updateModelKeywordUpdateModuleList(index, module);
			this.setVisible(false);
			
		}
	}
	public void removeButton_actionPerformed() {
		((ODRFGUIFrame)this.getParent()).updateModelRemoveKeywordUpdateModule(index);
		this.setVisible(false);
	}
	public void cancelButton_actionPerformed() {
		this.setVisible(false);
	}
	private String validateValue(String value, String datatype) {
		if (datatype.equals(ODRFGUIParameters.HEADER_DATATYPE_STRING)) {
			return value;
		} else if (datatype.equals(ODRFGUIParameters.HEADER_DATATYPE_BOOLEAN)) {
			if ((value.compareToIgnoreCase("f") == 0) ||
					(value.compareToIgnoreCase("false") == 0) ||
					(value.compareToIgnoreCase("0") == 0)) {
				return "F";
			} else
				return "T";
		} else if (datatype.equals(ODRFGUIParameters.HEADER_DATATYPE_INTEGER)) {
			try {
				Integer.parseInt(value);
				return value;
			} catch (NumberFormatException e) {
				return "0";
			}
		} else if (datatype.equals(ODRFGUIParameters.HEADER_DATATYPE_FLOAT)) {
			try {
				Float.parseFloat(value);
				return value;
			} catch (NumberFormatException e) {
				return "0.0";
			}
		} else
			return "";
	}
	private String validateKeywordName(String name) {
		if (name.length() > 8) {
			return "Keyword name must be 8 characters or less.";
		} else if (name.length() == 0) { 
			return "Keyword name must not be empty.";
		} else {
			char[] nameAsChars = name.toCharArray();
			for (int ii=0; ii<nameAsChars.length; ii++) {
				if (!Character.isLetterOrDigit(nameAsChars[ii])) {
					if ((nameAsChars[ii] != '-') && (nameAsChars[ii] != '_'))
						return "Keyword name must be composed of letters, numbers, the hyphen, and the underscore only.";
				}
			}
			return "";
		}
}
	
	public void setIndex(int i) {
		index=i;
	}
	public void setRemoveEnabled(boolean status) {
		removeButton.setEnabled(status);
	}
	public void setModule(KeywordUpdateReductionModule m) {
		module = new KeywordUpdateReductionModule(m);
		nameField.setText(module.getKeywordName());
		datatypeBox.setSelectedItem(module.getKeywordDatatype());
		valueField.setText(module.getKeywordValue());
		commentField.setText(module.getKeywordComment());
	}

}
