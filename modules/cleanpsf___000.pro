FUNCTION cleanpsf___000, DataSet, Modules, Backbone
	functionName = 'cleanpsf___000'

	drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

	; Get all COMMON parameter values

	BranchID = Backbone->getType()
	CASE BranchID OF
		'ARP_SPEC':	BEGIN
			;(*DataSet.Frames)[*, *, *] = (*DataSet.Frames)[*, *, *] + 1
		END
		ELSE:	$
			drpLog, 'FUNCTION '+ functionName +': CASE error: Bad Type = ' + BranchID, /DRF, DEPTH = 2
	ENDCASE

	RETURN, 0

END
