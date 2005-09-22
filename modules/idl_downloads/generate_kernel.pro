function sinc, x

   pi = 3.1415926535897932384626433832795D

   if (abs(x) lt 1e-4)
       return, 1.D ;
   else
       return, sin(x * pi)/(x * pi) ;

end

function sinc2, x

   pi = 3.1415926535897932384626433832795D

   if (abs(x) lt 1e-4)
       return, 1.D ;
   else
       return, sin(x * pi)/(x * pi) ;

end



function generate_kernel, d_x ,d_y, s_Type

   KERNEL_SIZE = 301

   dist_circle, m_Dist, [KERNEL_SIZE, KERNEL_SIZE], 150, 150

   x=1000. * dindgen(2001)/2000.

   case s_Type of 

      'tanh'    : begin end
      'sinc'    : begin
                     x        = 1000. * dindgen(2001)/2000.
                     m_Kernel = sinc(m_Dist)
      'sinc2'   : begin end
      'lanczos' : begin end
      'hamming' : begin end
      'hann'    : begin end



	if (kernel_type==NULL) {
		tab = generate_interpolation_kernel("tanh") ;
	} else if (!strcmp(kernel_type, "default")) {
		tab = generate_interpolation_kernel("tanh") ;
	} else if (!strcmp(kernel_type, "sinc")) {
		tab = malloc(samples * sizeof(double)) ;
		tab[0] = 1.0 ;
		tab[samples-1] = 0.0 ;
		for (i=1 ; i<samples ; i++) {
			x = (double)KERNEL_WIDTH * (double)i/(double)(samples-1) ;
			tab[i] = sinc(x) ;
		}
	} else if (!strcmp(kernel_type, "sinc2")) {
		tab = malloc(samples * sizeof(double)) ;
		tab[0] = 1.0 ;
		tab[samples-1] = 0.0 ;
		for (i=1 ; i<samples ; i++) {
			x = 2.0 * (double)i/(double)(samples-1) ;
			tab[i] = sinc(x) ;
			tab[i] *= tab[i] ;
		}
	} else if (!strcmp(kernel_type, "lanczos")) {
		tab = malloc(samples * sizeof(double)) ;
		for (i=0 ; i<samples ; i++) {
			x = (double)KERNEL_WIDTH * (double)i/(double)(samples-1) ;
			if (fabs(x)<2) {
				tab[i] = sinc(x) * sinc(x/2) ;
			} else {
				tab[i] = 0.00 ;
			}
		}
	} else if (!strcmp(kernel_type, "hamming")) {
		tab = malloc(samples * sizeof(double)) ;
		alpha = 0.54 ;
		inv_norm  = 1.00 / (double)(samples - 1) ;
		for (i=0 ; i<samples ; i++) {
			x = (double)i ;
			if (i<(samples-1)/2) {
				tab[i] = alpha + (1-alpha) * cos(2.0*PI_NUMB*x*inv_norm) ;
			} else {
				tab[i] = 0.0 ;
			}
		}
	} else if (!strcmp(kernel_type, "hann")) {
		tab = malloc(samples * sizeof(double)) ;
		alpha = 0.50 ;
		inv_norm  = 1.00 / (double)(samples - 1) ;
		for (i=0 ; i<samples ; i++) {
			x = (double)i ;
			if (i<(samples-1)/2) {
				tab[i] = alpha + (1-alpha) * cos(2.0*PI_NUMB*x*inv_norm) ;
			} else {
				tab[i] = 0.0 ;
			}
		}
	} else if (!strcmp(kernel_type, "tanh")) {
		tab = generate_tanh_kernel(TANH_STEEPNESS) ;
	} else {
		e_error("unrecognized kernel type [%s]: aborting generation",
				kernel_type) ;
		return NULL ;
	}

    return tab ;
}


