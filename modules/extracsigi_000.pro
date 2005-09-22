FUNCTION extracsigi_000, DataSet, Modules, Backbone
	functionName = 'extracsigi_000'

	drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

	; Get all COMMON parameter values

	BranchID = Backbone->getType()
	CASE BranchID OF
		'TRP_IMAG':	BEGIN
		END
		ELSE:	$
			drpLog, 'FUNCTION '+ functionName +': CASE error: Bad Type = ' + BranchID, /DRF, DEPTH = 2
	ENDCASE

	RETURN, 0

END
