import os
import pyfits

# location of OSIRIS DRP:
drp_dir = '/Users/aboehle/osiris_dev/OsirisDRP/'

source_dir = drp_dir + '/modules/source/'   
RPB_dir =  drp_dir + '/backbone/SupportFiles/'

# location of rect mat raw scans and created rect mats
reduce_dir = '/Users/aboehle/research/irlab/projects/osiris_rectmat_tests/images/160412/reduce/'      # from here, raw dir is: ../SPEC/raw/
rectmat_outdir = 'rectmat/'  # sub-directory of reduce_dir above


def make_rectmat(slice,maxslice,weightlimit,dir_suffix='', xml_filename = 'Kbb_050.xml', xml_test_filename = 'testrectmat_Kbb_50_newpipeline.xml'):
    '''
    Make a rect mat with a given slice, maxslice, and weight limit value.  Save the rect mat into a sub-directory of the reduce_dir (reduce_dir is hard-coded above).  This sub-directory is named with the weightlimit, slice, and maxslice values followed by an optional dir_suffix.

    To make rect mat: updates the given rect mat xml file (named "xml_filename") with new output dir and the appropriate drp files with new maxslice, slice, and weight limit values.  Prompts the user to close the OSIRIS DRP so it can be reopened with the new drp parameter values.  Recompiles the c code in drp modules/source/ directory.

    Also updates the given test filename (named "xml_test_filename") with the new data directory
    '''

    if dir_suffix and dir_suffix[0] != '_':
        dir_suffix = '_'+dir_suffix

    # Check that output directories exist
    if not os.path.exists(reduce_dir + rectmat_outdir + '/weightlimit%1.2f_slice%i_maxslice%i%s/' % (weightlimit, slice, maxslice,dir_suffix)):
        os.mkdir(reduce_dir + rectmat_outdir + '/weightlimit%1.2f_slice%i_maxslice%i%s/' % (weightlimit, slice, maxslice,dir_suffix))
    if not os.path.exists(reduce_dir + '/cubed_frames_newpipeline/weightlimit%1.2f_slice%i_maxslice%i%s/' % (weightlimit, slice, maxslice,dir_suffix)):
        os.mkdir(reduce_dir + '/cubed_frames_newpipeline/weightlimit%1.2f_slice%i_maxslice%i%s/' % (weightlimit, slice, maxslice,dir_suffix))
        
    setup_drp_files(slice,maxslice,weightlimit)
    setup_xml_files(reduce_dir, xml_filename, xml_test_filename, rectmat_outdir, slice, maxslice, weightlimit ,dir_suffix)
    recompile_ccode()

    raw_input("\n\nClose the OSIRIS DRP if it is currently running!\nThen press enter to drop the new xml files.  ")

    os.chdir(reduce_dir + '/xml/')
    cmds = ['run_odrp &','osirisDropDRF '+xml_filename + ' 1','osirisDropDRF '+xml_test_filename + ' 2']
    for cmd in cmds:
        print cmd
        os.system(cmd)
    
def check_rectmats(rectmat_name = 's160412_c006___infl_Kbb_050.fits', slice_arr = [[14,16],[20,22],[28,30]], weight_lim_arr = [0,0.01]):   #'s160318_c003___infl_Hn3_100.fits'):
    
    for slice,maxslice in slice_arr:
        for lmt in weight_lim_arr:
                filename = reduce_dir +rectmat_outdir +  '/weightlimit%1.2f_slice%i_maxslice%i/' % (lmt, slice, maxslice) + rectmat_name
                print filename
                mat_hdu = pyfits.open(filename)
                hdr = mat_hdu[0].header

                if slice == hdr['slice']:
                    print 'slice test: passed'
                    slicefailed = False
                else:
                    print 'slice test: FAILED'
                    slicefailed = True
                    
                if lmt == hdr['wtlimit']:
                    print 'weightlimit test: passed'
                    lmtfailed = False
                else:
                    print 'weightlimit test: FAILED'
                    lmtfailed = True
                    
                if maxslice == mat_hdu[2].data.shape[1]:
                    print 'maxslice test: passed'
                    maxslice_failed = False
                else:
                    print 'maxslice test: FAILED'
                    maxslice_failed = True

                if maxslice_failed or slicefailed or lmtfailed:
                    print 'ERROR with rectmat: '+filename
                else:
                    print 'rectmat passed!'

                print
                        
                #print '\nInput value/Rectmat Value:'
                #print slice,hdr['slice']
                #print lmt,hdr['wtlimit']
                #print maxslice,mat_hdu[2].data.shape[1]
                #print

        
def setup_drp_files(slice,maxslice,weightlimit):

    rpb_file = open(RPB_dir+'RPBconfig.xml','r')
    drp_file = open(source_dir+'drp_structs.h','r')

    # Edit RPB_file lines
    rpb_lines = rpb_file.readlines()
    rpb_lines[74] =  '    mkrecmatrx_COMMON___slice="%i"\n'  % (slice)
    rpb_lines[76] =  '    mkrecmatrx_COMMON___weight_limit="%1.2f"\n' % (weightlimit)
    rpb_file.close()

    rpb_file = open(RPB_dir+'RPBconfig.xml','w')
    rpb_file.writelines(rpb_lines)
    rpb_file.close()

    # Edit drp file lines
    drp_lines = drp_file.readlines()
    drp_lines[21] = '#define MAXSLICE     %i                           // Maximum slice of image in pixels; original value = 16\n' % (maxslice)
    drp_file.close()

    drp_file = open(source_dir+'drp_structs.h','w')
    drp_file.writelines(drp_lines)
    drp_file.close()        

def setup_xml_files(reduce_dir, xml_filename, xml_test_filename, rectmat_outdir, slice, maxslice, weightlimit, dir_suffix):  

    xml_file = open(reduce_dir + '/xml/'+xml_filename,'r')
    xml_lines = xml_file.readlines()
    xml_lines[8]  = '      OutputDir="'+reduce_dir + '/' +rectmat_outdir+'/weightlimit%1.2f_slice%i_maxslice%i%s/">\n' % (weightlimit, slice, maxslice, dir_suffix)
    xml_lines[31] = '      OutputDir="/Users/aboehle/research/IRLab/Projects/osiris_rectmat_tests/images/160412/reduce/'+rectmat_outdir+'/weightlimit%1.2f_slice%i_maxslice%i%s/"\n' % (weightlimit, slice, maxslice, dir_suffix)
    xml_file.close()

    xml_file = open(reduce_dir + '/xml/'+xml_filename,'w')    # xml file to make rect mat
    xml_file.writelines(xml_lines)
    xml_file.close()

    xml_test_file = open(reduce_dir + '/xml/'+xml_test_filename,'r')   # xml file to reduce single column scan
    xml_test_lines = xml_test_file.readlines()
    xml_test_lines[3] = '<dataset InputDir="/Users/aboehle/research/IRlab/Projects/osiris_rectmat_tests/images/160412/SPEC/raw/" OutputDir="/Users/aboehle/research/IRlab/Projects/osiris_rectmat_tests/images/160412/reduce/cubed_frames_newpipeline/weightlimit%1.2f_slice%i_maxslice%i%s/">\n' % (weightlimit, slice, maxslice, dir_suffix)
    xml_test_lines[8] = '<module CalibrationFile="/Users/aboehle/research/IRlab/Projects/osiris_rectmat_tests/images/160412/reduce/'+rectmat_outdir+'/weightlimit%1.2f_slice%i_maxslice%i%s/s160412_c006___infl_Kbb_050.fits" Name="Spatially Rectify Spectrum" />\n' % (weightlimit, slice, maxslice, dir_suffix)
    xml_test_file.close()

    xml_test_file = open(reduce_dir + '/xml/'+xml_test_filename,'w')
    xml_test_file.writelines(xml_test_lines)
    xml_test_file.close()
    
    
def recompile_ccode():

    current_dir = os.getcwd()

    os.chdir(source_dir)
    cmds = ['rm *.o','rm libosiris_drp_ext_null.so.0.0','make -f local_Makefile']

    for cmd in cmds:
        print cmd
        os.system(cmd)

    os.chdir(current_dir)
    
