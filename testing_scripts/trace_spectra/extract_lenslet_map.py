import numpy as np
import pandas as pd

def extract_kbb_map():
    '''
    Extract the kbb mapping of rectification slice to lenslet array

    '''

    tab = pd.read_excel('LensletMapping.xlsx',sheetname='K1 QL2 Kbb 35',
                        parse_cols='C:U',skiprows=4)
    tab = tab[:64]
    t2 = np.array(tab,dtype=int)

    # save the lenslet mapping
    np.savetxt('kn3_lenslet_mapping.txt',t2,delimiter=' ',fmt='%i')
