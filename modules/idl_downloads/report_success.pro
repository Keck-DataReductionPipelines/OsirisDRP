pro report_success, functionName, T

    drpLog, functionName+' succesfully completed after ' + strg(systime(1)-T) + ' seconds.', /DRF, DEPTH = 1

end
