pro misflux_singlesky_wrapper

infile = getenv('OSIRIS_ROOT')+'/tests/test_misflux_singlesky/data_misflux_single/s160902_a009006_Kbb_050.fits'

refchannel = 305

misflux_single,infile,refchannel=refchannel

end
