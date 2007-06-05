package edu.ucla.astro.osiris.drp.util;

import javax.swing.JOptionPane;

public class ReductionModuleArgument {
	private String name="";
	private String type="";
	private String range="";
	private String value="";
	public static String TYPE_ENUM = "enum";
	public static String TYPE_STRING = "string";
	public static String TYPE_FLOAT = "float";
	public static String TYPE_INT = "int";
	
	private Number minValue;
	private Number maxValue;
	private boolean minInclusive;
	private boolean maxInclusive;
	
	public ReductionModuleArgument() throws DRDException {
		this("");
	}
	public ReductionModuleArgument(String argName) throws DRDException {
			this(argName, TYPE_STRING);
	}
	public ReductionModuleArgument(String argName, String argType) throws DRDException {
		this(argName, argType, "");
	}

	public ReductionModuleArgument(String argName, String argType, String argRange) throws DRDException {
		this(argName, argType, argRange, "");
	}
	public ReductionModuleArgument(String argName, String argType, String argRange, String argValue) throws DRDException {
		name=argName;
		setType(argType);
		setRange(argRange);
		setValue(argValue);
	}
	public ReductionModuleArgument(ReductionModuleArgument arg) {
		name = arg.getName();
		type = arg.getType();
		range = arg.getRange();
		value = arg.getValue();
	}
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public String getType() {
		return type;
	}
	public void setType(String type) throws DRDException {
		if ((type.compareTo(TYPE_ENUM) == 0) ||
				(type.compareTo(TYPE_FLOAT) == 0) ||
				(type.compareTo(TYPE_INT) == 0) ||
				(type.compareTo(TYPE_STRING) == 0)) {	
			this.type = type;
		} else
			throw new DRDException("Invalid type <"+type+"> for argument <"+name+">.  Must be string, int, float, or enum.");
	}
	public String getRange() {
		return range;
	}
	public void setRange(String range) throws DRDException {
		if ((type.compareTo(TYPE_FLOAT) == 0) || 
				(type.compareTo(TYPE_INT) == 0)) {
			//. strip leading and trailing whitespace
			range = range.trim();
			
			//. make sure it starts with either a [ or (
			if ((range.charAt(0) == '[') || 
					(range.charAt(0) == '(')) {
				
				//. if it is (, min value is not inclusive
				if (range.charAt(0) == '(') {
					minInclusive = false; 
				} else {
					minInclusive = true;
				}

				//. check if last val is inclusive
				if (range.charAt(range.length()-1) == ')') {
					maxInclusive = false; 
				} else if (range.charAt(range.length()-1) == ']') {
					maxInclusive = true;
				} else
					throw new DRDException("Invalid range <"+range+"> for argument <"+name+">. Ranges using interval notation must end with either ) or ].");
				
				//. get location of comma separating values
				int commaLoc = range.indexOf(",");
				//. if no comma, throw an error
				if (commaLoc < 0) 
					throw new DRDException("Invalid range <"+range+"> for argument <"+name+">. Ranges using interval notation must have two values separated by a comma.");

				//. extract and trim string for each limit
				String minNumber = range.substring(1, commaLoc).trim();
				String maxNumber = range.substring(commaLoc+1, range.length()-1).trim();

				try {
					//. for float types, convert strings to numbers
					if (type.compareTo(TYPE_FLOAT) == 0) {
						//. min limit
						if (minNumber.compareToIgnoreCase("-inf") == 0) {
							minValue = new Double(Double.NEGATIVE_INFINITY);
							minInclusive = false;
						} else if (minNumber.compareToIgnoreCase("inf") == 0) {
							minValue = new Double(Double.POSITIVE_INFINITY);
							minInclusive = false;
						} else {
							minValue = new Double(minNumber);
						}
						//. max limit
						if (maxNumber.compareToIgnoreCase("-inf") == 0) {
							maxValue = new Double(Double.NEGATIVE_INFINITY);
							maxInclusive = false;
						} else if (maxNumber.compareToIgnoreCase("inf") == 0) {
							maxValue = new Double(Double.POSITIVE_INFINITY);
							maxInclusive = false;
						} else {
							maxValue = new Double(maxNumber);
						}
					//. for ints
					} else {
						//. min limit
						if (minNumber.compareToIgnoreCase("-inf") == 0) {
							minValue = new Long(Long.MIN_VALUE);
						} else if (minNumber.compareToIgnoreCase("inf") == 0) {
							minValue = new Long(Long.MAX_VALUE);
						} else {
							minValue = new Long(minNumber);
						}
						//. max limit
						if (maxNumber.compareToIgnoreCase("-inf") == 0) {
							maxValue = new Long(Long.MIN_VALUE);
						} else if (maxNumber.compareToIgnoreCase("inf") == 0) {
							maxValue = new Long(Long.MAX_VALUE);
						} else {
							maxValue = new Long(maxNumber);
						}
					}
					//. if max is bigger than min, throw error
					if (minValue.doubleValue() > maxValue.doubleValue()) 
						throw new DRDException("Invalid range <"+range+"> for argument <"+name+">.  Max value <"+maxValue+"> must be larger than min value <"+minValue+">.");
					//. if they are the same, both need to be inclusive
					else if ((minValue.doubleValue() == maxValue.doubleValue()) && !(minInclusive && maxInclusive))
						throw new DRDException("Invalid range <"+range+"> for argument <"+name+">.  Min value <"+minValue+"> cannot equal max value <"+maxValue+"> unless both are inclusive.");
				//. throw error if cannot parse strings to numbers	
				} catch (NumberFormatException nfEx) {
					throw new DRDException("Invalid range <"+range+"> for argument <"+name+">.  Must be made of numbers of type <"+type+">.");
				}				
			} else {
				throw new DRDException("Invalid range <"+range+"> for argument <"+name+">.  Must be written in interval notation: [min,max], (min,max), [min,max), (min,max].  Use -inf and inf for infinity.");
			}
		} 
		this.range = range;
	}
	public String getValue() {
		return value;
	}
	public void setValue(String value) throws DRDException {
		try {
			if (type.compareTo(TYPE_FLOAT) == 0) {
				double dValue = Double.parseDouble(value);
				if (range.length() > 0) {
					if ((dValue > maxValue.doubleValue()) ||
							((dValue == maxValue.doubleValue()) && !maxInclusive) ||
							(dValue < minValue.doubleValue()) ||
							((dValue == minValue.doubleValue()) && !minInclusive)) {
						String max = maxValue.toString();
						if (maxInclusive)
							max = max+" (Inclusive)";
						String min = minValue.toString();
						if (minInclusive)
							min = min+" (Inclusive)";
						throw new DRDException("Invalid value <"+value+"> for argument <"+name+">.  Must be between "+min+" and "+max+".");
					}
				}
				this.value = Double.toString(dValue);
			} else if (type.compareTo(TYPE_INT) == 0) {
				long iValue = Long.parseLong(value);
				if (range.length() > 0) {
					if ((iValue > maxValue.longValue()) ||
							((iValue == maxValue.longValue()) && !maxInclusive) ||
							(iValue < minValue.longValue()) ||
							((iValue == minValue.longValue()) && !minInclusive)) {
						String max = maxValue.toString();
						if (maxInclusive)
							max = max+" (Inclusive)";
						String min = minValue.toString();
						if (minInclusive)
							min = min+" (Inclusive)";
						throw new DRDException("Invalid value <"+value+"> for argument <"+name+">.  Must be between "+min+" and "+max+".");
					}
				}
				this.value = Long.toString(iValue);
			} else if (type.compareTo(TYPE_ENUM) == 0) {
				if (range.length() == 0)
					throw new DRDException("Cannot set value of enum argument <"+name+">.  Range has not been set.");
				//. must of enum values in range
				String[] choices = range.split("\\|");
				StringBuffer choicesString = new StringBuffer();
				for (int ii = 0; ii<choices.length; ii++) {
					if (value.compareTo(choices[ii]) == 0) {
						this.value = value;
						return;
					}
					choicesString.append(choices[ii]);
					if (ii < (choices.length-1))
						choicesString.append(", ");
				}
				throw new DRDException("Invalid value <"+value+"> for argument <"+name+">.  Must be one of "+choicesString.toString());
			} else {
				this.value = value;
			}
		} catch (NumberFormatException nfEx) {    			
			throw new DRDException("Invalid value <"+value+"> for argument <"+name+">.  Must be a number of type <"+type+">.");
		}
	}
}

