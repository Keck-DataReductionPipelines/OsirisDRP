import numpy as np
import pandas as pd

def extract_kbb_map():
    '''
    Extract the kbb mapping of rectification slice to lenslet array
    from the LensletMapping.xlsx file.
    NOTE: the excel file has the first two rows masked, but we will not consider
    them here. The first row is where there is actually flux, corresponding to
    the first slice in the rect. matrix.

    2017-03-28 - T. Do
    '''

    tab = pd.read_excel('LensletMapping.xlsx',sheetname='K1 QL2 Kbb 35',
                        parse_cols='C:U',skiprows=4)
    tab = tab[:64]
    t2 = np.array(tab,dtype=int)
#    t2[:,0] = t2[:,0]+2
    
    # save the lenslet mapping
    np.savetxt('kbb_2016_lenslet_mapping.txt',t2,delimiter=' ',fmt='%i')

    # we can also unravel the lenslet mapping
    s = np.shape(t2)
    output = open('kbb_2016_slice_to_lenslet.txt','w')
    print(s)
    for i in xrange(s[0]):
        for j in xrange(s[1]):
            row = t2[i,0]+2  # the rows start at 2
            col = j
            output.write('%i %i %i\n' % (t2[i,j],row,col))
    output.close()
