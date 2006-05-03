;-----------------------------------------------------------------------------------------------------
; CLASS drpDRFParser
;
; DESCRIPTION:
;	drpDRFParser is responsible for parsing a DRF and reading the input data files.  
;	Data set information is placed in structDataSet variables and module information 
;	placed in structModule variables.
;	
;	drpParser inherits the IDL IDLffXMLSAX class, a general XML parser.  IDLffXMLSAX is
;	an event driven parser, using callback functions to handle XML elements on the fly.
;-----------------------------------------------------------------------------------------------------
PRO drpDRFParser__define

	void = {drpDRFParser, INHERITS IDLffXMLSAX, $
			LogPath:'', $
			ReductionType:'', $
			Data:PTR_NEW(), $
			Modules:PTR_NEW(), $
			UpdateLists:PTR_NEW()}

END

PRO drpDRFParser::Cleanup

	; This Cleanup supposes that there may be more than one dataset in a DRF
	; though we do not currently create DRFs in this manner.

	IF PTR_VALID(Self.UpdateLists) THEN BEGIN
		FOR i = 0, N_ELEMENTS(*Self.UpdateLists)-1 DO BEGIN
			PTR_FREE, (*Self.UpdateLists)[i].parameters
		ENDFOR
	ENDIF

	IF PTR_VALID(Self.Data) THEN BEGIN
		FOR i = N_ELEMENTS(*Self.Data)-1, 0, -1 DO BEGIN
			PTR_FREE, (*Self.Data)[i].IntAuxFrames[*]
			PTR_FREE, (*Self.Data)[i].IntFrames[*]
			PTR_FREE, (*Self.Data)[i].Headers[*]
			PTR_FREE, (*Self.Data)[i].Frames[*]
		ENDFOR
	ENDIF


	PTR_FREE, Self.UpdateLists
	PTR_FREE, Self.Modules
	PTR_FREE, Self.Data

  Self->IDLffXMLSAX::Cleanup

END

PRO drpDRFParser::Comment, newComment
  PRINT, "Comment found.  Text = " + newComment
END

PRO drpDRFParser::ParseFile, FileName, Backbone
  COMMON APP_CONSTANTS

	; Free any previous structDataSet, structModule and structUpdateLists data
	; See note for drpDRFParser::Cleanup
	IF PTR_VALID(Self.UpdateLists) THEN BEGIN
		FOR i = 0, N_ELEMENTS(*Self.UpdateLists)-1 DO BEGIN
			PTR_FREE, (*Self.UpdateLists)[i].parameters
		ENDFOR
	ENDIF

	IF PTR_VALID(Self.Data) THEN BEGIN
		FOR i = N_ELEMENTS(*Self.Data)-1, 0, -1 DO BEGIN
			PTR_FREE, (*Self.Data)[i].IntAuxFrames[*]
			PTR_FREE, (*Self.Data)[i].IntFrames[*]
			PTR_FREE, (*Self.Data)[i].Headers[*]
			PTR_FREE, (*Self.Data)[i].Frames[*]
		ENDFOR
	ENDIF

	PTR_FREE, Self.UpdateLists
	PTR_FREE, Self.Modules
	PTR_FREE, Self.Data

  Self -> IDLffXMLSAX::ParseFile, FileName

  IF continueAfterDRFParsing  EQ 1 THEN BEGIN
    Backbone.LogPath = Self.LogPath
    Backbone.ReductionType = Self.ReductionType
    Backbone.Data = Self.Data
    Backbone.Modules = Self.Modules
    IF PTR_VALID(Self.UpdateLists) THEN BEGIN
      FOR i = 0, N_ELEMENTS(*Self.UpdateLists)-1 DO BEGIN
        PTR_FREE, (*Self.UpdateLists)[i].parameters
      ENDFOR
    ENDIF
    PTR_FREE, Self.UpdateLists
  ENDIF ELSE BEGIN  ; Cleanup everything and return from parsing.
    IF PTR_VALID(Self.UpdateLists) THEN BEGIN
      FOR i = 0, N_ELEMENTS(*Self.UpdateLists)-1 DO BEGIN
        PTR_FREE, (*Self.UpdateLists)[i].parameters
      ENDFOR
    ENDIF
  
    IF PTR_VALID(Self.Data) THEN BEGIN
      FOR i = N_ELEMENTS(*Self.Data)-1, 0, -1 DO BEGIN
        PTR_FREE, (*Self.Data)[i].IntAuxFrames[*]
        PTR_FREE, (*Self.Data)[i].IntFrames[*]
        PTR_FREE, (*Self.Data)[i].Headers[*]
        PTR_FREE, (*Self.Data)[i].Frames[*]
      ENDFOR
    ENDIF
  
    PTR_FREE, Self.UpdateLists
    PTR_FREE, Self.Modules
    PTR_FREE, Self.Data
  ENDELSE

END


PRO drpDRFParser::Error, SystemID, LineNumber, ColumnNumber, Message
  COMMON APP_CONSTANTS

  ; Any error parsing the input file is too much error for you.

  ; Log the error info
  drpLog, 'DRP parsing non-fatal error', /GENERAL, DEPTH=1
  drpLog, '    Filename: ' + SystemID, /GENERAL, DEPTH=2
  drpLog, '  LineNumber: ' + STRTRIM(STRING(LineNumber),2), /GENERAL, DEPTH=2
  drpLog, 'ColumnNumber: ' + STRTRIM(STRING(ColumnNumber),2), /GENERAL, DEPTH=2
  drpLog, '     Message: ' + Message, /GENERAL, DEPTH=2

	continueAfterDRFParsing = 0
END


PRO drpDRFParser::FatalError, SystemID, LineNumber, ColumnNumber, Message
  COMMON APP_CONSTANTS

  ; Any fatal error parsing the input file is certainly too much error for you.

  ; Log the error info
  drpLog, 'DRP parsing fatal error', /GENERAL, DEPTH=1
  drpLog, '    Filename: ' + SystemID, /GENERAL, DEPTH=2
  drpLog, '  LineNumber: ' + STRTRIM(STRING(LineNumber),2), /GENERAL, DEPTH=2
  drpLog, 'ColumnNumber: ' + STRTRIM(STRING(ColumnNumber),2), /GENERAL, DEPTH=2
  drpLog, '     Message: ' + Message, /GENERAL, DEPTH=2

	IF PTR_VALID(Self.UpdateLists) THEN BEGIN
		FOR i = 0, N_ELEMENTS(*Self.UpdateLists)-1 DO BEGIN
			PTR_FREE, (*Self.UpdateLists)[i].parameters
		ENDFOR
	ENDIF

	IF PTR_VALID(Self.Data) THEN BEGIN
		FOR i = N_ELEMENTS(*Self.Data)-1, 0, -1 DO BEGIN
			PTR_FREE, (*Self.Data)[i].IntAuxFrames[*]
			PTR_FREE, (*Self.Data)[i].IntFrames[*]
			PTR_FREE, (*Self.Data)[i].Headers[*]
			PTR_FREE, (*Self.Data)[i].Frames[*]
		ENDFOR
	ENDIF

	PTR_FREE, Self.UpdateLists
	PTR_FREE, Self.Modules
	PTR_FREE, Self.Data

	continueAfterDRFParsing = 0
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
PRO drpDRFParser::StartDocument

	COMMON APP_CONSTANTS

	drpPushCallStack, 'drpDRFParser::StartDocument'


	Self.Data = PTR_NEW(/ALLOCATE_HEAP)
	Self.Modules = PTR_NEW(/ALLOCATE_HEAP)
	Self.UpdateLists = PTR_NEW(/ALLOCATE_HEAP)

	; ----------------- TO DO: Validate the document ----------------------------

	drpLog, 'File is currently unvalidated and is assumed to be valid', /GENERAL, DEPTH=1

	void = drpPopCallStack()

END

;-----------------------------------------------------------------------------------------------------
; Procedure EndDocument
;
; DESCRIPTION:
; 	This procedure is inherited from the IDLffxMLSAX parent class.  EndDocument is
;	called automatically when the parser finishes parsing an XML document.  We use
;	this routine to update any selected frame headers from the UpdateLists, if any
;	exist.  NOTE: There is a DataSetNumber parameter that is required in an UpdateList
;	but in general, for data management reasons, DRFs do not have multiple datasets.
;
; ARGUMENTS:
;	None.
;
; KEYWORDS:
;	None.
;-----------------------------------------------------------------------------------------------------
PRO drpDRFParser::EndDocument

	drpPushCallStack, 'drpDRFParser::StartDocument'

	; Correct reference for the array of pointers to Headers is (*(Self.Data)[i]).Headers where
	; i is the index of the DataSet in the (possible) list of datasets, e.g.,
	;HELP, (*(Self.Data)[0]).Headers, /FULL
	; Correct reference for a single Header is *(*(Self.Data)[n]).Headers[i] which dereferences
	; pointer i (which may be 0 to (MAXFRAMESINDATASETS-1)) in the Nth array of Header pointers, e.g.,
	;PRINT, *(*(Self.Data)[0]).Headers[1]

	;FOR i = 0, DataSet.ValidFrameCount-1 DO BEGIN
	;	PRINT, (*(*Self.Data)[0]).Headers[i]
	;ENDFOR

	; Correct reference for DataSet attribute is (*Self.Data)[i].<attribute>, e.g.,
	;PRINT, "(*Self.Data)[0].ValidFrameCount = ", (*Self.Data)[0].ValidFrameCount

	nUpdateLists = N_ELEMENTS(*Self.UpdateLists)

	; For every defined UpdateList, fix the Header arrays indicated by the datasetNumber and
	; headerNumber parameters.  An attribute value of -1 indicates that all available arrays
	; either datasets and/or headers are to be updated.
	FOR indexUpdateLists = 0, nUpdateLists-1 DO BEGIN
		; Get attributes for the current UpdateList
		datasetNumber = (*Self.UpdateLists)[indexUpdateLists].datasetNumber
		headerNumber = (*Self.UpdateLists)[indexUpdateLists].headerNumber
		; Derive start and stop dataset numbers from the attributes
		IF datasetNumber LT 0 THEN BEGIN	; Actually, should be -1
			; Do all datasets
			startDataset = 0
			stopDataset = N_ELEMENTS(*Self.Data) - 1
		ENDIF ELSE BEGIN
			startDataset = datasetNumber
			stopDataset = datasetNumber
		ENDELSE
		FOR indexDataSet = startDataset, stopDataset DO BEGIN	; For all datasets
			; Derive start and stop header numbers from the attributes
			IF headerNumber LT 0 THEN BEGIN		; Actually, should be -1
				; Do all headers
				startHeader = 0
				stopHeader = (*Self.Data)[indexDataSet].ValidFrameCount - 1
			ENDIF ELSE BEGIN
				startHeader = headerNumber
				stopHeader = headerNumber
			ENDELSE
			FOR indexHeader = startHeader, stopHeader DO BEGIN	; For all headers
				;PRINT, "DataSet Number ", indexDataSet
				;PRINT, "Header  Number ", indexHeader
				; Correct reference for UpdateList attribute is (*Self.UpdateLists)[i].<attribute>, e.g.,
				;PRINT, (*Self.UpdateLists)[i].datasetNumber
				;PRINT, (*Self.UpdateLists)[i].headerNumber
				; Correct reference for an UpdateList parameter array is *(*Self.UpdateLists)[i].parameters, e.g.,
				;IF N_ELEMENTS(*(*Self.UpdateLists)[indexUpdateLists].parameters) GT 0 THEN BEGIN
				;	PRINT, *(*Self.UpdateLists)[indexUpdateLists].parameters
				;ENDIF
				; All parameters must be of correct type for call to program unit sxaddpar
				; Valid types are integer, float, double and string.  If type is string and
				; the value is 'T' or 'F' (upper or lower case) then the value is stored as
				; a logical.
				IF N_ELEMENTS(*(*Self.UpdateLists)[indexUpdateLists].parameters) GT 0 THEN BEGIN
          maxIndex = (SIZE(*(*Self.UpdateLists)[indexUpdateLists].parameters, /N_ELEMENTS)/4)-1
					FOR indexParameter = 0, maxIndex DO BEGIN	; For all parameters
						;PRINT, "indexParameter = ", indexParameter
						name    = (*(*Self.UpdateLists)[indexUpdateLists].parameters)[0, indexParameter]
						value   = (*(*Self.UpdateLists)[indexUpdateLists].parameters)[1, indexParameter]
						comment = (*(*Self.UpdateLists)[indexUpdateLists].parameters)[2, indexParameter]
						vtype   = (*(*Self.UpdateLists)[indexUpdateLists].parameters)[3, indexParameter]
						;PRINT, name + " " + value + " " + comment + " " + vtype
						; Set the value type correctly with a cast
						CASE vtype OF
							'integer':	value = FIX(value)
							'float':	value = FLOAT(value)
							'double':	value = DOUBLE(value)
							ELSE:
						ENDCASE
						;HELP, *(*Self.Data)[indexDataSet].Headers[indexHeader]
						SXADDPAR, *(*Self.Data)[indexDataSet].Headers[indexHeader], name, value, comment, BEFORE='COMMENT'
					ENDFOR
				ENDIF
			ENDFOR
		ENDFOR
	ENDFOR

  ; Now place a copy of the current DRF into each available header
  ; First, get the file name of the file we are parsing
  Self -> IDLffXMLSAX::GetProperty, FILENAME=myOwnFileName

  ; Open the DRF file and read it into a string array
  fileAsStringArray = ['']
  inputString = ''
  GET_LUN, myunit
  OPENR, myunit, myOwnFileName
  count = 0
  WHILE ~EOF(myunit) DO BEGIN
    READF, myunit, inputString
    IF count EQ 0 THEN fileAsStringArray = [inputString] $
    ELSE fileAsStringArray = [fileAsStringArray, inputString]
    count += 1
  ENDWHILE
  CLOSE, myunit
  FREE_LUN, myunit

  ; Get the number of datasets to do
	startDataset = 0
	stopDataset = N_ELEMENTS(*Self.Data) - 1
  ; Get the number of headers to do
	FOR indexDataSet = startDataset, stopDataset DO BEGIN	; For all datasets
    ; Get the number of headers to do
    startHeader = 0
    stopHeader = (*Self.Data)[indexDataSet].ValidFrameCount - 1
    FOR indexHeader = startHeader, stopHeader DO BEGIN	; For all headers
      SXADDPAR, *(*Self.Data)[indexDataSet].Headers[indexHeader], 'COMMENT', '////////////////////////////////////////////////////////////////////////'
      ; Save the file name as one or more comments
      ; Figure out how many 68 character strings there are in the file name string
      clen = STRLEN(myOwnFileName)
      n = (clen/68) + 1
      FOR j=0, n-1 DO BEGIN
        newsubstring = STRMID(myOwnFileName, j*68, 68)
        SXADDPAR, *(*Self.Data)[indexDataSet].Headers[indexHeader], 'COMMENT', 'DRFN' + newsubstring
      ENDFOR
      FOR i=0, N_ELEMENTS(fileAsStringArray)-1 DO BEGIN
        IF STRLEN(fileAsStringArray[i]) LT 68 THEN BEGIN
          SXADDPAR, *(*Self.Data)[indexDataSet].Headers[indexHeader], 'COMMENT', 'DRF ' + fileAsStringArray[i]
        ENDIF ELSE BEGIN
          ; Figure out how many 68 character strings there are in the current string
          clen = STRLEN(fileAsStringArray[i])
          n = (clen/68) + 1
          FOR j=0, n-1 DO BEGIN
            newsubstring = STRMID(fileAsStringArray[i], j*68, 68)
            SXADDPAR, *(*Self.Data)[indexDataSet].Headers[indexHeader], 'COMMENT', 'DRFC' + newsubstring
          ENDFOR
        ENDELSE
      ENDFOR
      SXADDPAR, *(*Self.Data)[indexDataSet].Headers[indexHeader], 'COMMENT', '\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\'
    ENDFOR
  ENDFOR

	void = drpPopCallStack()

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
PRO drpDRFParser::StartElement, URI, Local, qName, AttNames, AttValues

	COMMON APP_CONSTANTS
	
	drpPushCallStack, 'drpDRFParser::StartElement'

	CASE qName OF
		'DRF': BEGIN
			; This FOR statement allows the attributes to be in any order in the XML file
			FOR i = 0, N_ELEMENTS(AttNames) - 1 DO BEGIN	; Place attribute values in the 
				CASE AttNames[i] OF			; variable fields.
					'LogPath':	   Self.LogPath = AttValues[i]
					'ReductionType':   Self.ReductionType = AttValues[i]
					ELSE:
				ENDCASE
			END
		END		
		'dataset': Self -> NewDataSet, AttNames, AttValues	; Add a new data set
		'fits':	BEGIN
			N = N_ELEMENTS(*Self.Data) - 1
			DataFileName = ''
      FileControl = READWHOLEFRAME
			FOR i = 0, N_ELEMENTS(AttNames) - 1 DO BEGIN	; Place attribute values in the 
				CASE AttNames[i] OF			; variable fields.
					'FileName':	   DataFileName = AttValues[i]
					'FileControl': FileControl = FIX(AttValues[i])  ; Overwrite the default if alternative is provided
					ELSE: drpLog, 'Error in drpDRFParser::StartElement - Illegal/Unnecessary attribute ' + AttNames[i], /GENERAL, Depth=1
				ENDCASE
			END
			IF DataFileName NE '' THEN BEGIN
				drpFITSToDataSet, (*Self.Data)[N], (*Self.Data)[N].ValidFrameCount, DataFileName, FileControl
        IF continueAfterDRFParsing EQ 1 THEN BEGIN
				  (*Self.Data)[N].ValidFrameCount = (*Self.Data)[N].ValidFrameCount + 1
        ENDIF
			ENDIF ELSE BEGIN
				drpLog, 'ERROR: <fits/> element is incomplete, Probably no filename', /GENERAL, DEPTH=2
        continueAfterDRFParsing = 0
			ENDELSE
		END
		'module': Self -> NewModule, AttNames, AttValues	; Add a new module
		'update': BEGIN
			Self -> NewUpdateList, AttNames, AttValues	; Start a new update list
		END
		'updateParameter':  BEGIN
			Self -> AddUpdateParameter, AttNames, AttValues	; Add parms to latest list
		END
	ENDCASE

	void = drpPopCallStack()

END

FUNCTION drpDRFParser::DataSetNameIsUnique, Name
  if N_ELEMENTS(*Self.Data) EQ 0 THEN RETURN, 1
	FOR i = 0, N_ELEMENTS(*Self.Data)-1 DO BEGIN
    IF Name EQ (*Self.Data)[i].Name THEN RETURN, 0  ; We found a duplicate
  ENDFOR
  RETURN, 1
END

;-----------------------------------------------------------------------------------------------------
; Procedure NewDataSet
;
; DESCRIPTION:
; 	Creates a new structDataSet variable, enters the information from the DRF into the 
;	variable fields and reads the specified FITS files in to the variables Frames
;	field.
;
; ARGUMENTS:
;	AttNames	Array of attribute names
;	AttValues	Array of attribute values
;-----------------------------------------------------------------------------------------------------
PRO drpDRFParser::NewDataSet, AttNames, AttValues

	COMMON APP_CONSTANTS
	
	drpPushCallStack, 'drpDRFParser::NewDataSet'

	DataSet = {structDataSet}			; Create a new structDataSet variable
	DataSet.Frames = PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP)
	DataSet.Headers = PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP)
	DataSet.IntFrames = PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP)
	DataSet.IntAuxFrames = PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP)

	FOR i = 0, N_ELEMENTS(AttNames) - 1 DO BEGIN	; Place attribute values in the 
		CASE AttNames[i] OF			; variable fields.
			'InputDir':	DataSet.InputDir = AttValues[i]
			'Name': BEGIN
        IF Self -> DataSetNameIsUnique(AttValues[i]) THEN BEGIN
          DataSet.Name = AttValues[i]
        ENDIF ELSE BEGIN
				  drpLog, 'DataSet Name ' + AttValues[i] + ' attribute is duplicated.', /GENERAL, DEPTH=2
          drpLog, 'DRF will be aborted', /GENERAL, DEPTH = 2
          continueAfterDRFParsing = 0
        ENDELSE
      END
			'OutputDir':	DataSet.OutputDir = AttValues[i]
			ELSE:
		ENDCASE
	END

	; This adds the new dataset to the array of datasets; this is an array
	; of structDataSet elements.
	if N_ELEMENTS(*Self.Data) EQ 0 THEN *Self.Data = DataSet $	; Add the DataSet
	ELSE *Self.Data = [*Self.Data, DataSet]				; variable to the 
									; array.

	void = drpPopCallStack()
	
END

;-----------------------------------------------------------------------------------------------------
; Procedure NewModule
;
; DESCRIPTION:
; 	Creates a new structModule variable, enters the information from the DRF
;	<module/> element into the variable fields.
;
; ARGUMENTS:
;	AttNames	Array of attribute names
;	AttValues	Array of attribute values
;
;
; HISTORY:
; 	2006-04-20	Modified to allow arbitrary additional attributes in modules.
; 				Requires struct_merge.pro  and struct_trimtags.pro
; 				 - Marshall Perrin
;-----------------------------------------------------------------------------------------------------
PRO drpDRFParser::NewModule, AttNames, AttValues

	COMMON APP_CONSTANTS
	
	drpPushCallStack,'drpDRFParser::NewModule'
	
	Module = {structModule}				; Create structModule variable
;	Module = {Name: ''}

	
	FOR i = 0, N_ELEMENTS(AttNames) - 1 DO BEGIN		; Enter attribute values 
		; if this attribute is already a tag in the structure, just add the value to
		; that tag.
		indx = where(tag_names(module) eq strupcase(attnames[i]))
		if (indx ge 0) then begin
			module.(indx) = attvalues[i]
		endif else begin
			; otherwise, add a new tag
			module = create_struct(module,AttNames[i],AttValues[i])
		endelse
	
				
	
;		CASE AttNames[i] OF				; into the variable fields
;			'Name': 	Module.Name = AttValues[i]
;			else:       module = create_struct(module,AttNames[i],AttValues[i])
;			'Skip':		Module.Skip = AttValues[i]
;			'Save':		Module.Save = AttValues[i]
;			'SaveOnErr':	Module.SaveOnErr = AttValues[i]
;			'OutputDir':	Module.OutputDir = AttValues[i]
;			'CalibrationFile':	Module.CalibrationFile = AttValues[i]
 ;     'LabDataFile':	Module.LabDataFile = AttValues[i]
;		ENDCASE
	ENDFOR

	IF N_ELEMENTS(*Self.Modules) EQ 0 THEN *Self.Modules = [Module] $	; Add to the array
	ELSE *Self.Modules = struct_merge(*Self.Modules, Module)
	print,module.name
	;stop

	void = drpPopCallStack()


END

;-----------------------------------------------------------------------------------------------------
; Procedure NewUpdateList
;
; DESCRIPTION:
; 	Creates a new structUpdateList variable, enters the information from the
;	DRF into the variable fields.
;
; ARGUMENTS:
;	AttNames	Array of attribute names
;	AttValues	Array of attribute values
;-----------------------------------------------------------------------------------------------------
PRO drpDRFParser::NewUpdateList, AttNames, AttValues

	COMMON APP_CONSTANTS
	
	drpPushCallStack,'drpDRFParser::NewUpdateList'

	UpdateList = {structUpdateList}				; Create structUpdateList variable
	UpdateList.parameters = PTR_NEW(/ALLOCATE_HEAP)

	FOR i = 0, N_ELEMENTS(AttNames) - 1 DO BEGIN		; Enter attribute value(s) 
		CASE AttNames[i] OF				; into the variable field(s)
			'DataSetNumber': UpdateList.datasetNumber = AttValues[i]
			'HeaderNumber': UpdateList.headerNumber = AttValues[i]
		ENDCASE
	ENDFOR

	; This adds the new UpdateList to the array of UpdateLists; this is an array
	; of structUpdateList elements.
	IF N_ELEMENTS(*Self.UpdateLists) EQ 0 THEN BEGIN
		*Self.UpdateLists = UpdateList	; Add to the array
	ENDIF ELSE BEGIN
		*Self.UpdateLists = [*Self.UpdateLists, UpdateList]
	ENDELSE

	void = drpPopCallStack()

END

;-----------------------------------------------------------------------------------------------------
; Procedure AddUpdateParameter
;
; DESCRIPTION:
; 	Adds a keyword/value/comment/type parameter to the current UpdateList in
;	the array of UpdateLists
;
; ARGUMENTS:
;	AttNames	Array of attribute names
;	AttValues	Array of attribute values
;-----------------------------------------------------------------------------------------------------
PRO drpDRFParser::AddUpdateParameter, AttNames, AttValues

	COMMON APP_CONSTANTS

	drpPushCallStack,'drpDRFParser::AddUpdateParameter'

  ; Set all fields to the empty string
  Keyword = ""
  KValue = ""
  KComment = ""
  KType = ""

	FOR i = 0, N_ELEMENTS(AttNames) - 1 DO BEGIN		; Enter attribute value(s) 
		CASE AttNames[i] OF				; into the variable field(s)
			'Keyword':	Keyword = AttValues[i]
			'KeywordValue':	KValue = AttValues[i]
			'KeywordComment':	KComment = AttValues[i]
			'KeywordType':	KType = AttValues[i]
		ENDCASE
	ENDFOR
  ; Save the UpdateParameter; save it even if the comment is an empty string
	IF Keyword NE '' AND KValue NE '' AND KType NE '' THEN BEGIN
		; This adds the new keyword/value/comment/type to the current array of 4-ples
		index = N_ELEMENTS(*Self.UpdateLists) - 1
		IF N_ELEMENTS(*(*Self.UpdateLists)[index].parameters) EQ 0 THEN BEGIN
			*(*Self.UpdateLists)[index].parameters = [Keyword, KValue, KComment, KType]
		ENDIF ELSE BEGIN
			*(*Self.UpdateLists)[index].parameters = [[*(*Self.UpdateLists)[index].parameters], [Keyword, KValue, KComment, KType]]
		ENDELSE
	ENDIF

	void = drpPopCallStack()

END

;-----------------------------------------------------------------------------------------------------
; Procedure updateParameters
;
; DESCRIPTION:
; 	Updates the keywords in all headers of the input FITS files to allow the modules
;	to use the proper parameter values.
;
; ARGUMENTS:
;	AttNames	Array of attribute names
;	AttValues	Array of attribute values
;-----------------------------------------------------------------------------------------------------
PRO drpDRFParser::updateParameters, AttNames, AttValues

	COMMON APP_CONSTANTS
	
	drpPushCallStack,'drpDRFParser::updateParameters'

	nHeaders = (*Self.Data).ValidFrameCount

	FOR i = 0, (nHeaders-1)	DO BEGIN
		PRINT, "Updating Header[", STRTRIM(STRING(i), 2), "]"
		;drpUpdateKeywords, (*(*Self.Data).Headers)[*,i], AttNames, AttValues
		FOR j = 0, N_ELEMENTS(AttNames) - 1 DO BEGIN
			addString = "SXADDPAR, (*Self.Data).Headers[i], '" + AttNames[j]  + "', '" + AttValues[j] + "', BEFORE='COMMENT'"
			PRINT, addString
			returnValue = EXECUTE(addString)
			PRINT, 'Update/Add keyword ' + AttNames[j] + ' returnValue = ', returnValue
		ENDFOR
	ENDFOR

	PRINT, (*Self.Data).Headers[*]

	void = drpPopCallStack()

END
