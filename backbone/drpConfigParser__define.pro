;-----------------------------------------------------------------------------------------------------
; CLASS drpConfigParser
;
; DESCRIPTION:
;	drpConfigParser is responsible for parsing the configuration file.
;	drpConfigParser inerits the IDL IDLffXMLSAX class, a general XML parser.  IDLffXMLSAX is
;	an event driven parser, using callback functions to handle XML elements on the fly.
;-----------------------------------------------------------------------------------------------------
PRO drpConfigParser__define

	void = {drpConfigParser, INHERITS IDLffXMLSAX, $
			Parms:PTR_NEW(), $
			Modules:PTR_NEW(), $
			PipelineLabel:'' }
		
END

PRO drpConfigParser::Cleanup

	PTR_FREE, Self.Modules
	PTR_FREE, Self.Parms

END

;-----------------------------------------------------------------------------------------------------
; Procedure StartDocument
;
; DESCRIPTION:
; 	This procedure is inherited from the IDLffxMLSAX parent class.  StartDocument is
;	called automatically when the parser begins parsing an XML document.
;
; ARGUMENTS:
;	None.
;
; KEYWORDS:
;	None.
;-----------------------------------------------------------------------------------------------------
PRO drpConfigParser::StartDocument

	IF PTR_VALID(Self.Parms) THEN BEGIN
		PRINT, "Freeing parameter data..."
		PTR_FREE, Self.Parms
		PTR_FREE, Self.Modules
	ENDIF
	Self.Modules = PTR_NEW(/ALLOCATE_HEAP)
	Self.Parms = PTR_NEW(/ALLOCATE_HEAP)
	drpPushCallStack, 'drpConfigParser::StartDocument'

	; ----------------------- TO DO: Validate the file -------------------

	void = drpPopCallStack()
	
END

PRO drpConfigParser::EndDocument

	;Self->printInfo
	
END

;-----------------------------------------------------------------------------------------------------
; Procedure StartElement
;
; DESCRIPTION:
; 	This procedure is inherited from the IDLffxMLSAX parent class.  StartElement is
;	called automatically when the parser encounters an XML element.
;
; ARGUMENTS:
;	URI		 
;	Local		
;	qName		Name of the XML element
;	AttNames	Array of attribute names
;	AttValues	Array of atribute values
;
; KEYWORDS:
;	Inherited from parent class.  See documentation.
;-----------------------------------------------------------------------------------------------------
PRO drpConfigParser::StartElement, URI, Local, qName, AttNames, AttValues

	;COMMON PARAMS, PARAMETERS
	COMMON PARAMS

	drpPushCallStack, 'drpConfigParser::StartElement'

	CASE qName OF
		'Config': BEGIN
				MYPARAMETERS = [[AttNames], [AttValues]]
				PARAMETERS = MYPARAMETERS
				PARMTRANS = TRANSPOSE(PARAMETERS)
				StructString = '*Self.Parms = CREATE_STRUCT('
				FOR i = 1, ((N_ELEMENTS(PARMTRANS)/2)-1) DO StructString = StructString + "'" + PARMTRANS[0, i-1] + "', '" + PARMTRANS[1, i-1] + "', "
				StructString = StructString + "'" + PARMTRANS[0, i-1] + "', '" + PARMTRANS[1, i-1] + "'"
				StructString = StructString + ')'
				retval = EXECUTE(StructString)
			END
		'TEST_DRP': Self.PipelineLabel = 'TEST_DRP'
		'ARP_SPEC': Self.PipelineLabel = 'ARP_SPEC'
		'CRP_SPEC': Self.PipelineLabel = 'CRP_SPEC'
		'CRP_IMAG': Self.PipelineLabel = 'CRP_IMAG'
		'ORP_SPEC': Self.PipelineLabel = 'ORP_SPEC'
		'ORP_IMAG': Self.PipelineLabel = 'ORP_IMAG'
		'SRP_SPEC': Self.PipelineLabel = 'SRP_SPEC'
		'SRP_IMAG': Self.PipelineLabel = 'SRP_IMAG'
		'TRP_SPEC': Self.PipelineLabel = 'TRP_SPEC'
		'TRP_IMAG': Self.PipelineLabel = 'TRP_IMAG'
		'Astronomical': Self.PipelineLabel = 'Astronomical'
		'OnLine': Self.PipelineLabel = 'OnLine'
		'Calibration': Self.PipelineLabel = 'Calibration'
		'Stellar': Self.PipelineLabel = 'Stellar'
		'Module': Self -> NewModule, AttNames, AttValues
		ELSE:
	ENDCASE

	void = drpPopCallStack()

END

;-----------------------------------------------------------------------------------------------------
; Procedure NewModule
;
; DESCRIPTION:
; 	This procedure adds a new module to the array of modules retreived
;	from the conifig file (Self.Modules). This is a 3 column module
;	containing the name, IDL function name and pipeline type of 
;	each module.
;
; ARGUMENTS:
;	AttNames	The names of the attributes
;	Attvalues	The values of the attributes
;
;-----------------------------------------------------------------------------------------------------
PRO drpConfigParser::NewModule, AttNames, AttValues

	drpPushCallStack, 'drpConfigParser::NewModule'

	FOR i = 0, N_ELEMENTS(AttNames) - 1 DO BEGIN	; Place attribute values into 
		CASE AttNames[i] OF			                    ; variable fields.
			'Name': BEGIN
          moduleName = AttValues[i]
        END
			'IDLFunc': BEGIN
          moduleFunction = AttValues[i]
        END
      ELSE:
		ENDCASE
	END

	IF N_ELEMENTS(*Self.Modules) EQ 0 THEN $
		*Self.Modules = [moduleName, moduleFunction, Self.PipelineLabel] $
	ELSE *Self.Modules = [[*Self.Modules], [moduleName, moduleFunction, Self.PipelineLabel]]

	void = drpPopCallStack()

END


;-----------------------------------------------------------------------------------------------------
; Procedure getIDLFunctions
;
; DESCRIPTION:
; 	This procedure receives a reference to a backbone object, 
;	with a Modules array and assigns the appropriate IDL function
;	to each module in the array. 
;
; ARGUMENTS:
;	Backbone	The backbone object to be updated
;
; KEYWORDS:
;	Inherited from parent class.  See documentation.
;-----------------------------------------------------------------------------------------------------
PRO drpConfigParser::getIDLFunctions, Backbone

	drpPushCallStack, 'drpConfigParser::getIDLFunctions'

	FOR i = 0, N_ELEMENTS(*Backbone.Modules)-1 DO BEGIN
		FOR j = 0, N_ELEMENTS(*Self.Modules)/3-1 DO BEGIN
			IF (*Self.Modules)[0, j] EQ (*Backbone.Modules)[i].Name AND $
			   (*Self.Modules)[2, j] EQ Backbone.ReductionType THEN $
				(*Backbone.Modules)[i].CallSequence = (*Self.Modules)[1,j]
		ENDFOR
		If (*Backbone.Modules)[i].CallSequence EQ '' THEN $
			MESSAGE, 'No IDL function is specified in the ' + $
			'configuration file for module: ' + (*Backbone.Modules)[i].Name 
	ENDFOR

	void = drpPopCallstack()

END


;-----------------------------------------------------------------------------------------------------
; Procedure getParameters
;
; DESCRIPTION:
; 	This procedure receives a reference to a backbone object 
;	and transfers the configuration parameter information to
;	the backbone ParmList. 
;
; ARGUMENTS:
;	Backbone	The backbone object to be updated
;
; KEYWORDS:
;	Inherited from parent class.  See documentation.
;-----------------------------------------------------------------------------------------------------
PRO drpConfigParser::getParameters, Backbone

	drpPushCallStack, 'drpConfigParser::getParameters'

	Backbone.ParmList = Self.Parms

	void = drpPopCallstack()

END


PRO drpConfigParser::printInfo

	COMMON PARAMS

	drpPushCallStack, 'drpConfigParser::printInfo'

	drpIOLock
	OPENW, unit, "temp.tmp", /get_lun
	FOR j = 0, N_ELEMENTS(*Self.Modules)/3-1 DO BEGIN
		PRINTF, unit, (*Self.Modules)[0, j] , "  ", (*Self.Modules)[1, j], "  ", (*Self.Modules)[2,j]
	ENDFOR

	FOR j = 0, 31 DO BEGIN
		PRINTF, unit, PARAMETERS[j, 0] , "  ", PARAMETERS[j, 1]
	ENDFOR
	FLUSH, unit
	CLOSE, unit
	FREE_LUN, unit
	drpIOUnlock

	void = drpPopCallstack()

END
			
	
