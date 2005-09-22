pro define_error_constants

   COMMON ERROR_CONSTANTS, ERROR_SINGLE_LINE_OK, $
                           ERROR_SINGLE_LINE_COIERROR           , $   
                           ERROR_SINGLE_LINE_FLUX               , $   
                           ERROR_SINGLE_LINE_SIGMA              , $   
                           ERROR_SINGLE_LINE_COIOUT             , $   
                           ERROR_SINGLE_LINE_OUT                , $   
                           ERROR_SINGLE_LINE_NOCOI              , $  
                           ERROR_SINGLE_LINE_WINDOW             , $  
                           ERROR_SINGLE_LINE_FEW                , $  
                           ERROR_SINGLE_LINE_FAILED             , $
                           ERROR_SINGLE_LINE_ITERATION_FAILED   , $

                           ERROR_DISPERSION_OK        , $
                           ERROR_DISPERSION_NOPIX     , $
                           ERROR_DISPERSION_NOINT     , $  
                           ERROR_DISPERSION_FEW       , $   
                           ERROR_DISPERSION_SVDFIT    , $ 
                           ERROR_DISPERSION_NOFIT     , $  
                           ERROR_DISPERSION_LAG       , $  
                           ERROR_DISPERSION_OUT       , $  
                           ERROR_DISPERSION_FAILED    , $ 

                           ERROR_COEFF_OK             , $
                           ERROR_COEFF_FEW            , $
                           ERROR_COEFF_CLIPFEW        , $
                           ERROR_COEFF_SVD            , $
                           ERROR_COEFF_FAILED

   ; define error constants

   ; wavelength calibration

   ; error codes for individual gaussian line fits
   ERROR_SINGLE_LINE_OK               = 0       ; error of determined COI exceeds limit
   ERROR_SINGLE_LINE_COIERROR         = 1       ; error of determined COI exceeds limit
   ERROR_SINGLE_LINE_FLUX             = 2       ; determined flux too low
   ERROR_SINGLE_LINE_SIGMA            = 4       ; determined sigma exceeds limits
   ERROR_SINGLE_LINE_COIOUT           = 8       ; determined COI out of fit window
   ERROR_SINGLE_LINE_OUT              = 16      ; line is not within spectral range
   ERROR_SINGLE_LINE_NOCOI            = 32      ; COI of line could not be determined, less than 4 pixel
                                                ; are available in the search window
   ERROR_SINGLE_LINE_WINDOW           = 64      ; part of the search window is outside the valid spectrum
   ERROR_SINGLE_LINE_FEW              = 128     ; to few valid pixel after recentering the search window left
   ERROR_SINGLE_LINE_FAILED           = 256     ; to few valid pixel after recentering the search window left
   ERROR_SINGLE_LINE_ITERATION_FAILED = 512     ; line sorted out when doing the iterative dispersion fit

   ; error codes for fitting the dispersion relation of individual spectra
   ERROR_DISPERSION_OK        = 0
   ERROR_DISPERSION_NOPIX     = 1
   ERROR_DISPERSION_NOINT     = 2
   ERROR_DISPERSION_FEW       = 4       ; to few valid fitted individual lines found
   ERROR_DISPERSION_SVDFIT    = 8       ; SVDFIT failed
   ERROR_DISPERSION_NOFIT     = 16      ; coefficients could not be fitted
   ERROR_DISPERSION_LAG       = 32      ; Lag of cross correlation exceeds maximum
   ERROR_DISPERSION_OUT       = 64      ; the pixel does not contain information
   ERROR_DISPERSION_FAILED    = 128     ; failed

   ; error codes for fitting the coefficients
   ERROR_COEFF_OK             = 0
   ERROR_COEFF_FEW            = 1  ; too few valid coefficients for fitting
   ERROR_COEFF_CLIPFEW        = 2  ; too few valid coefficients for fitting after clipping
   ERROR_COEFF_SVD            = 4  ; svd fit of coefficients failed
   ERROR_COEFF_FAILED         = 8

end
