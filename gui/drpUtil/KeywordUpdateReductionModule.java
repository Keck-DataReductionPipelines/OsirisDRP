package edu.ucla.astro.osiris.drp.util;

import java.beans.PropertyChangeListener;
import java.beans.PropertyChangeSupport;

public class KeywordUpdateReductionModule {
	private String keywordName;
	private String keywordValue;
	private String keywordComment;
	private String keywordDatatype;
	private transient PropertyChangeSupport propertyChangeListeners = new PropertyChangeSupport(this);

  public KeywordUpdateReductionModule() {
		keywordName = "";
		keywordValue = "";
		keywordComment = "";
		keywordDatatype = "";
	}
	public KeywordUpdateReductionModule(KeywordUpdateReductionModule module) {
		this.keywordName = module.getKeywordName();
		this.keywordValue = module.getKeywordValue();
		this.keywordComment = module.getKeywordComment();
		this.keywordDatatype = module.getKeywordDatatype();
	}
  public synchronized void removePropertyChangeListener(PropertyChangeListener l) {
    propertyChangeListeners.removePropertyChangeListener(l);
  }
  public synchronized void addPropertyChangeListener(PropertyChangeListener l) {
    propertyChangeListeners.addPropertyChangeListener(l);
  }
  public void setKeywordName(String keywordName) {
    String  oldKeywordName = this.keywordName;
    this.keywordName = keywordName;
    propertyChangeListeners.firePropertyChange("keywordName", oldKeywordName, keywordName);
  }
  public String getKeywordName() {
    return keywordName;
  }
  public void setKeywordValue(String keywordValue) {
    String  oldKeywordValue = this.keywordValue;
    this.keywordValue = keywordValue;
    propertyChangeListeners.firePropertyChange("keywordValue", oldKeywordValue, keywordValue);
  }
  public String getKeywordValue() {
    return keywordValue;
  }
  public void setKeywordComment(String keywordComment) {
    String  oldKeywordComment = this.keywordComment;
    this.keywordComment = keywordComment;
    propertyChangeListeners.firePropertyChange("keywordComment", oldKeywordComment, keywordComment);
  }
  public String getKeywordComment() {
    return keywordComment;
  }
  public void setKeywordDatatype(String keywordDatatype) {
    String  oldKeywordDatatype = this.keywordDatatype;
    this.keywordDatatype = keywordDatatype;
    propertyChangeListeners.firePropertyChange("keywordDatatype", oldKeywordDatatype, keywordDatatype);
  }
  public String getKeywordDatatype() {
    return keywordDatatype;
  }

}
