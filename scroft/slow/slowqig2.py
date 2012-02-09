#!/usr/bin/env python
#

import argparse
import sys
import sqlite3
#import pylab as py
import numpy as np
import matplotlib

parser = argparse.ArgumentParser(description='Plots lightcurves from SLOW database - two frequency version')
parser.add_argument('sources',help='sources to plot; default all',nargs="*")
parser.add_argument('--dual',help='only sources detected in two frequencies',action="store_true",default=False)
parser.add_argument('--ndet',help='only sources with at least ndet detections',type=int,default=0)
args = parser.parse_args()

matplotlib.use('PDF')
import matplotlib.pyplot as plt
from math import sqrt

dbfile = "slow.db"
dbh = sqlite3.connect(dbfile)
dbc = dbh.cursor()

print args.sources

#mjids = ""SELECT mjid FROM master WHERE mjid <> 'J' GROUP BY mjid HAVING avg(good) == 1"""
mjids = """SELECT mjid FROM master WHERE mjid <> 'J' GROUP BY mjid"""
if (args.sources != []):
	dbc.execute("""CREATE TABLE IF NOT EXISTS matchsource(mjid)""")
	dbh.executemany("insert into matchsource(mjid) values (?)", map(args.sources))
	mjids = """SELECT mjid FROM master WHERE mjid IN matchsource GROUP BY mjid"""
if (args.dual):
	mjids = """select m1.mjid,m1.ra,m1.decl,m1.epname,m1.freq,m2.epname,m2.mjid,m2.freq from master as m1, master as m2 where (m1.freq == '3040' and m2.freq == '3140' and m1.mjid == m2.mjid and m1.epname == m2.epname) group by m1.mjid"""
if (args.ndet > 0):
	mjids = """select mjid from master group by mjid having count(mjid) >= """+str(args.ndet)
dbc.execute(mjids)


mjo = dbc.fetchall()

for mjs in mjo:
    print mjs
    fig = plt.figure()
#    fig = plt.figure(num=1)
    pt = fig.add_subplot(1,1,1)
#    plt.subplot(1,1,1)
    mj = mjs[0]
    mjof = mj+'.pdf'
# use epoch number (does not account for missing epochs!)
#    fxc = "SELECT mjid,epname,fi,rb FROM master WHERE (mjid ='"+mj+"')"
#    dbc.execute(fxc)
#    fluxes = dbc.fetchall()
#    fxs = np.asanyarray(fluxes)
#    fx = np.asfarray(fxs[:,2])
#    fxe = np.asfarray(fxs[:,3])
#    N = len(fluxes)
#    ind = np.arange(N)
#    print fx
#    pt.errorbar(ind,fx,yerr=fxe)
# use julian date
#    fxc = "SELECT mjid,epjd,fi,rb,epname,freq FROM master WHERE (mjid =='"+mj+"' and epname != 'ATA_Coadd')"
    fxc = "SELECT mjid,epjd,fi,rb,epname,freq,slope,icpt FROM master WHERE (mjid =='"+mj+"' and epname != 'ATA_Coadd')"
    dbc.execute(fxc)
    fluxes = dbc.fetchall()
    fxco = "SELECT mjid,epjd,fi,rb FROM master WHERE (mjid =='"+mj+"' and epname == 'ATA_Coadd')"
    dbc.execute(fxco)
    fluxm = dbc.fetchall()
    fxs = np.asanyarray(fluxes)
    fluxms = np.asanyarray(fluxm)
    if (fluxms != []):
# take the first Coadd match
    	epjdm = np.asfarray(fluxms[0,1])
# sum Coadd fluxes if multiple components
    	fxm = sum(np.asfarray(fluxms[:,2]))
    	fxme = sqrt(sum(np.asfarray(fluxms[:,3])**2))
    	pt.errorbar(epjdm,fxm,yerr=fxme,fmt='-',color='magenta')
    	pt.axhline(y=fxm,color='magenta')
    if (fxs != []):
    	epjd = np.asfarray(fxs[:,1])
    	fx = np.asfarray(fxs[:,2])
    	fxe = np.asfarray(fxs[:,3])
    	epnames = np.asarray(fxs[:,4])
    	freqs = np.asarray(fxs[:,5])
    	slopes = np.asfarray(fxs[:,6])
    	icpts = np.asfarray(fxs[:,7])
#	freqc = epnames.copy()
#	freqc[freqs == "3040"] = 'green'
#	freqc[freqs == "3140"] = 'blue'
#	print freqc
#    	pt.errorbar(epjd,fx,yerr=fxe,fmt='o',color='green')
#    	pt.errorbar(epjd,fx,yerr=fxe,fmt='o',color=freqc)
	if (epjd[freqs == "3040"] != []):
		pt.errorbar(epjd[freqs == "3040"],fx[freqs == "3040"],yerr=fxe[freqs == "3040"],fmt=None,color='green')
	if (epjd[freqs == "3140"] != []):
		pt.errorbar(epjd[freqs == "3140"],fx[freqs == "3140"],yerr=fxe[freqs == "3140"],fmt=None,color='blue')
	sc = pt.scatter(epjd,fx,c=slopes,s=icpts+50,vmin=0.7,vmax=1.2)
#	print slopes
	hislo = 1.13
	loslo = 0.9
	hiin = 6
	loin = -14
	if (epjd[slopes > hislo] != []):
		pt.plot(epjd[slopes > hislo],fx[slopes > hislo],'*',color='magenta')
	if (epjd[slopes < loslo] != []):
		pt.plot(epjd[slopes < loslo],fx[slopes < loslo],'*',color='red',ms=10)
	if (epjd[icpts > hiin] != []):
		pt.plot(epjd[icpts > hiin],fx[icpts > hiin],'*',color='cyan')
	if (epjd[icpts < loin] != []):
		pt.plot(epjd[icpts < loin],fx[icpts < loin],'*',color='green')
#	pc = pt.pcolor(slopes)
	fig.colorbar(sc)
# for epoch names instead of MJD
#    	plt.xticks(epjd,epnames,rotation=90,size=3)
    plt.xlabel('MJD')
    plt.ylabel('Flux density (mJy)')
#    fig.show()
    plt.savefig(mjof)


#    for fx in fluxes:
#        print fx
if (args.sources != []):
	dbh.execute("""DROP TABLE matchsource""")    
dbh.close()

