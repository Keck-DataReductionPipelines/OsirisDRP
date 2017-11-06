from astropy.modeling import models, fitting
import numpy as np


def fit_gaussian_peak(x,y,guess = None):

    # fit a Gaussian to a peak
    #
    # Return model fitted object
    #        peak_model_fit.parameters = [offset, amplitude, mean, standard deviation]

    if guess is None:
        # help make some guesses
        offset = np.min(y)
        guess = [offset, np.max(y)-offset,x[np.argmax(y)],1.0]
    g1 = models.Gaussian1D(guess[1],guess[2],guess[3])
    amp = models.Const1D(guess[0])
    peak_model = amp + g1

    fitter = fitting.LevMarLSQFitter()

    peak_model_fit = fitter(peak_model,x,y)


    return peak_model_fit
