#! /usr/bin/tcsh -f
#
# $Id$
#
# A simple mapping routine that has a bunch of cool features to it...

onintr enderr

if ($#argv == 0) then
      #################################################################
echo "================================================================="
echo "AUTOMAP - All in one mapping program"
echo "'Why should optical astronomers have all the pretty pictures?'"
echo ""
echo "CALLS - newautomap.csh (recursive), scompare.csh (TBI),  MIRIAD"
echo "    (uvplt,uvflag,uvplt,uvaflag,cgdisp,invert,clean,restor,"
echo "    selfcal,uvlist,blflag,mem,uvcal,gpcopy,imstat,sfind)"
echo "PURPOSE - Creates a full suite of maps for a dataset."
echo "RESPONSIBLE - Karto (karto@hcro.org)"
echo "================================================================="
echo ""
echo "AUTOMAP is designed as an 'all-in-one' mapping utility for source"
echo "data. AUTOMAP will build gains and flags solutions to improve"
echo "the image quality, and produce a full suite of maps. The"
echo "reduction requires datasets to already be calibrated, and works"
echo "best when noisy baselines and RFI have been removed from the"
echo "data."
echo ""
echo "AUTOMAP in automated mode works by iteratively processing the"
echo "data - deriving the number of deconvolution cycles, flagging bad"
echo "data and building better gains solutions each iteration. Once"
echo "the 'best' flags and gains solutions are found, final maps are"
echo "created and stored on the hard drive"
echo ""
echo "AUTOMAP will create 5 maps in total: residual, clean component,"
echo "dirty, clean, and beam. These maps, along with a imaging report"
echo "and (optionally) the final datasets are moved to a directory"
echo "created by the program (the path of which can be specified by "
echo "the user). Maps - by default - will not be overwritten, nor will"
echo "any changes be made to the imaged dataset."
echo ""
echo "AUTOMAP currently only supports automated mapping, and currently"
echo "only supports Stokes I imaging."
echo ""
echo "TECHNICAL NOTE: AUTOMAP creates a temporary directory to work"
echo "from, named mapXXXX (where X is a random character). These"
echo "directories should be automatically deleted after AUTOMAP"
echo "completes, but might remain in the event of a program error."
echo "Remnant directories can be safely deleted."
echo ""
echo "TECHNICAL NOTE: AUTOMAP will automatically pol-specific gains"
echo "files produced by CALCAL. More on this can be found in the"
echo "CALCAL documentation."
echo ""
echo "CALLING SEQUENCE: newautomap.csh vis=vis (mode=[auto,inter,skip]"
echo "    crange=crange interval=interval weightmode=[natural,uniform]"
echo "    imsize=imsize1,imsize2 cellsize=cellsize cleantpye=[clean,"
echo "    mem] cregion=cregion cleanlim=cleanlim calmodel=calmodel"
echo "    amplim=amplim1,amplim2,amplim3 sysflux=sysflux refant=refant"
echo "    selfcalint=selfcalint selfcaltol=selfcaltol selfcalsigma="
echo "    selfcalsigma device=device dregion=dregion outdir=outdir"
echo "    olay=olay restfreq=restfreq options=[autoflag,noflag]"
echo "    [autoamp,noamp],[autopha,nopha],[autocal,nocal],sefd,"
echo "    [drmax,fidmax],[intclean,nointclean],[savedata,savemaps,junk]"
echo "    ,autolim,autoref,[mfs,nomfs],verbose)"
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo "REQUIRED INPUTS:"
echo " vis - Name of the files contraining calibrator data. Supports"
echo "    wildcard expansion and multiple files. No default."
echo ""
echo "OPTIONAL INPUTS"
echo " mode - Operating mode for AUTOMAP. Supported modes include full"
echo "    automation (auto), user guided mapping (inter), or no extra"
echo "    processing (skip). Default is auto."
echo ""
echo " crange - Groups of channels to be imaged seperately. This"
echo "    parameter should be used for channels containing spectral"
echo "    line emission. Can be specified with one number (e.g." 
echo "    crange=(10) will only image channel 10 seperately) two "
echo "    numbers (e.g. crange=(10,20) will image channels 10 through"
echo "    20 seperately) or three numbers (e.g. crange=(10,20,11) will"
echo "    image channels 10 through 20 seperately, but will average"
echo "    over the 11 channels in that range before imaging, producing"
echo "    only one image). No default."
echo ""
echo " interval - Interval (in minutes) to average the source data"
echo "    before beginning processing. Default in 1."
echo ""
echo " select - Data to be processed by AUTOMAP. See MIRIAD for more"
echo "    details. Default is all data."
echo ""
echo " weightmode - Weighting mode for the invert stage of imaging."
echo "    Supported modes include natural weighting and uniform"
echo "    weighting. Default is natural"
echo ""
echo " imsize - Image size (in pixels). Can be specified with one"
echo "    number (e.g. imsize=100, which will make the image 100 by"
echo "    100 pixels) or two numbers (e.g. imsize=10,20, which will"
echo "    make the image 10 by 20 pixels). Default is 512."
echo ""
echo " cellsize - Size of pixels (in arcsec) in the image. Default is"
echo "    automatically scaled to the observing frequency, and is"
echo "    usually on the order of one-third the size of the beam."
echo ""
echo " cleantype - Deconvolution algorithm to use. Supported modes"
echo "    include clean and mem (to be implemented. Dedfault is clean."
echo ""
echo " cregion - Region to be cleaned. See MIRIAD for more details."
echo "    Default is the entire map."
echo ""
echo " cleanlim - Number of iterations that CLEAN is limited to."
echo "    Default is 2500"
echo ""
echo " calmodel - Name of the model to use for calibration. Default is"
echo "    to use the CLEAN model from the current dataset(s)."
echo ""
echo " amplim - Amplitude limits (in Jy) for automated flagging, the"
echo "    first number specifying the minimum flux, the second number"
echo "    specifying the maximum flux, and the third number specifying"
echo "    the maximum flux for a single channel (e.g. amplim=(1,5,10)"
echo "    will flag integrated spectra with fluxes below 1 Jy or above"
echo "    5 Jy, and individual channels above 10 Jy). Default is"
echo "    (0,5000,10000)"
echo ""
echo " sysflux - Expected variation (in Jy) of source measurements"
echo "    due to system noise. Default is 2."
echo ""
echo " refant - Reference antenna (MIRIAD number) for selfcal"
echo "    solutions. No default."
echo ""
echo " selfcalint - Interval period (in minutes) for self-calibration."
echo "    Default is 5."
echo ""
echo " selfcaltol - Minimum improvement neccessary for automated"
echo "    selfcal to continue. Default is .05 (i.e. 5%)."
echo ""
echo " selfcalsigma - How far above the noise (in sigma) to establish"
echo "    the calibration cut-off for selfcal. Default it 10."
echo ""
echo " dregion - Region to be displayed in PS/X-Window images. See"
echo "    MIRIAD for more details. Default is the area of the primary"
echo "    beam."
echo ""
echo " outdir - Directory to place finished maps and reports. Default"
echo "    is 'source name'-maps."
echo ""
echo " olay - Overlay file to be used when making final images. No"
echo "    default."
echo ""
echo " restfreq - The rest frequency (in GHz) for the dataset(s)."
echo "    No default."
echo ""
echo " device - Device to plot results to (e.g. /xw for x-window)."
echo '    Default is /null.'
echo ""
echo " options=[autoflag,noflag],[autoamp,noamp],[autopha,nopha],"
echo "    [autocal,nocal],[drmax,fidmax],[intclean,nointclean],"
echo "    [savedata,savemaps,junk],autolim,autoref,[mfs,nomfs],verbose"
echo "    autoflag - Automatically flag bad based on amplitude ranges"
echo "        specified (Default)."
echo "    noflag - No automated flagging."
echo "    autoamp - Automatically self-cal for amplitudes."
echo "    noamp - Do not auto self-cal for amplitudes (Default)."
echo "    autopha - Automatically self-cal for phases (Default)."
echo "    nopha - Do not auto self-cal for phases."
echo "    autocal - Automatically self-cal for phase and amplitudes."
echo "    nocal - Do not perform any automated self calibration."
echo "    drmax - Optimize the image for maximum dynamic range"
echo "        (Default)."
echo "    fidmax - Optimize the image for maximum fidelity (to be"
echo "        integrated)".
echo "    intclean - Automatically determine the number of"
echo "        deconvolution cycles to use (Default)."
echo "    nointclean - Do not automaticall determine the number of"
echo "        deconvolution cycles to use (Default if cleanlim is"
echo "        specified)."
echo "    savedata - Preserve finished maps and processed data."
echo "    savemaps - Preserve finished maps (Default)."
echo "    junk - Save no end products."
echo "    autolim - Automatically determine amplitude limits for"
echo "        automated flagging."
echo "    autoref - Automatically determine the refant (Default)."
echo "    mfs - Use the MFS switch for imaging. See MIRIAD for more"
echo "        details (Default)."
echo "    nomfs - Do not use the MFS switch for imaging."
echo "    verbose - Display results at each iteration."
exit 0
endif

# Begin variable preset, determine what variables to populate. These are variables that the user has control over when calling the program

set vis # Visibility file to be processed
set mode = "auto" # Operating mode (interactive, automated, or no extra processing)
set amplim = (0 5000 10000) # Amplitude limits for flagging of data
set preamplim
set uselect # User selection parameters for mapping, i.e. xx or yy. Users should note that shadowed ants are automatically deselected.
set niters = 0 # Limit to provide clean, assuming that it's nice and happy
set wniters = 100 # Limit for wrath cleaning
set cleantype = clean # Clean operating mode
set cregion # Cleaning region for thingy
set dregion # Display region for map
set autoflag = 1 # Automatically flag bad data in "auto" mode?
set autopha = 1 # Automatically selfcal phases in "auto" mode?
set autoamp = 0 # Automatically selfcal amplitudes in "auto" mode?
set scint = 5 # Selfcal soln interval
set sctol = .05 # Selfcal limiting tolerance iterative cycles
set scsigma # Sigma clipping limit for selfcal
set scmode = "dr" # Selfcal optimiztion (either fidelity or dynamic range)
set weightmode = "natural" # Weighting mode for the invert step
set imsize # Size of image (in pixels)
set cellsize # Size of cell (in arcsecs)
set device
set display
set iopt = "options=mfs,double" # Options for invert, usually just double and mfs
set intclean = 1 # IntelliCLEAN - Automatically determines the number of niters to use
set refant = 0 # As usual, just the referance antenna for selfcal to use
set olay # Overlay file coolness
set interval = 1 # Averaging interval of the date. So that things take less time, I think
set crange # Channels to image via coolness (single channel mode)
set sup = 0 # Weighing for invert
set outdir = "" # Puts data into a particular directory, instead of automatically choosing
set savedata = 0 # Switch on whether or not to save the data
set addflux = 5 # Non-init parameter, awaiting further testnig
set intamplim = 0 # Initial amp limit for data, non-init
set plotscale # Plotting scale for map
set sopt # slop parameter for invert, should be used if MFS is not
set wrath = 0 # Muah ha ha ha, let no RFI escape...
set autolim
set sysflux = 2
set verb
set debug = 0
set sefd = 0
set restfreq
set line
set regain
set calmodel
set scclip
set cleanopt
if ($#argv == 0) then
    echo "AUTOMAP: No input files detected!"
    exit 0
endif

#################################################################
# The automapping creates a temp directory to work in within the
# data directory being used. This is done to make operations
# "cleaner", as several MIRIAD results are dumped to temp files
# to be parsed later.
#################################################################

set wd = (`mktemp -d mapXXXX`)

if !( -e $wd) then
    echo "FATAL ERROR: Unable to create working directory, please make sure that you have read/write permissions for this area."
    exit 1
endif

set date1 = `date +%s.%N`

#################################################################
# Here is the keyword/value pairing code. It basically operates
# by going through each argument, attempting to figure out which
# keyword matches (via an if arguement) and sets the value
# accordingly
#################################################################

varassign:

if ("$argv[1]" =~ 'vis='*) then
    set vis = "`echo '$argv[1]/' | sed 's/vis=//'`"
    set vis = (`echo $vis | sed 's/\/ / /g' | sed 's/\(.*\)\//\1/g' | tr ',' ' '`)
    shift argv; if ("$argv" == "") set argv = "finish"
else if ("$argv[1]" =~ 'amplim='*) then
    set amplim = (`echo $argv[1] | sed 's/amplim=//' | tr ',' ' ' | awk '{print $1*1,$2*1,$3*1}'`)
    if ($amplim[2] == 0) set amplim[2] = 5000
    if ($amplim[3] == 0) set amplim[3] = 10000
    shift argv; if ("$argv" == "") set argv = "finish"
else if ("$argv[1]" =~ 'crange='*) then
    set crange = (`echo $argv[1] | sed -e 's/crange=//' -e 's/),/) /' | tr -d ')('`)
    shift argv; if ("$argv" == "") set argv = "finish"
else if ("$argv[1]" =~ 'line='*) then
    set line = "$argv[1]"
    shift argv; if ("$argv" == "") set argv = "finish"
else if ("$argv[1]" =~ 'selfcalint='*) then
    set scint = `echo $argv[1] | sed 's/selfcalint=//'`
    shift argv; if ("$argv" == "") set argv = "finish"
else if ("$argv[1]" =~ 'selfcaltol='*) then
    set sctol = `echo $argv[1] | sed 's/selfcaltol=//'`
    shift argv; if ("$argv" == "") set argv = "finish"
else if ("$argv[1]" =~ 'select='*) then
    set uselect = "`echo '$argv[1]' | sed 's/select=//'`"
    shift argv; if ("$argv" == "") set argv = "finish"
else if ("$argv[1]" =~ 'selfcalsigma='*) then
    set scsigma = `echo $argv[1] | sed 's/scsigma=//'`
    shift argv; if ("$argv" == "") set argv = "finish"
else if ("$argv[1]" =~ 'selfcalclip='*) then
    set scclip = `echo $argv[1] | sed 's/selfcalclip=//'`
    shift argv; if ("$argv" == "") set argv = "finish"
else if ("$argv[1]" =~ 'sysflux='*) then
    set sysflux = `echo $argv[1] | sed 's/sysflux=//'`
    shift argv; if ("$argv" == "") set argv = "finish"
else if ("$argv[1]" =~ 'interval='*) then
    set interval = `echo $argv[1] | sed 's/interval=//'`
    shift argv; if ("$argv" == "") set argv = "finish"
else if ("$argv[1]" =~ 'refant='*) then
    set refant = `echo $argv[1] | sed 's/refant=//'`
    shift argv; if ("$argv" == "") set argv = "finish"
else if ("$argv[1]" =~ 'calmodel='*) then
    set calmodel = `echo $argv[1] | sed 's/calmodel=//'`
    shift argv; if ("$argv" == "") set argv = "finish"
else if ("$argv[1]" =~ 'device='*) then
    set display = 1
    set device = "$argv[1]"
    shift argv; if ("$argv" == "") set argv = "finish"
else if ("$argv[1]" =~ 'outdir='*) then
    set outdir = (`echo "$argv[1]"/ | sed -e 's/outdir=//' | tr '/' ' '`)
    set outdir = `echo $outdir | tr ' ' '/'`
    rm -rf $outdir
    if (-e $outdir) then
	echo "FATAL ERROR: Unable to remove outbound directory. Please make sure that you have read/write permissions for this area."
	goto enderr
    endif
    shift argv; if ("$argv" == "") set argv = "finish"
else if ("$argv[1]" =~ 'mode='*) then
    set mode = `echo $argv[1] | sed 's/mode=//'`

    if !(" skip inter auto " =~ *" $mode "*) then
	echo "FATAL ERROR: $argv[1] not recognized!"
	goto enderr
    endif

    shift argv; if ("$argv" == "") set argv = "finish"
else if ("$argv[1]" =~ 'weightmode='*) then
    set wmode = `echo $argv[1] | sed 's/weightmode=//'`

    if !("natural uniform" =~ *"$wmode"*) then
	echo "FATAL ERROR: $argv[1] not recognized!"
	goto enderr
    endif

    if ("natural" =~ *"$wmode"*) set sup = 0
    if ("uniform" =~ *"$wmode"*) set sup = 10000
    shift argv; if ("$argv" == "") set argv = "finish"
else if ("$argv[1]" =~ 'cleantype='*) then
    set cleantype = `echo $argv[1] | sed 's/mode=//'`
    if !(" clean mem " =~ *" $cleantype "*) then
	echo "FATAL ERROR: $argv[1] not recognized!"
	goto enderr
    endif
    shift argv; if ("$argv" == "") set argv = "finish"
else if ("$argv[1]" =~ 'imsize='*) then
    set imsize = `echo $argv[1] | sed 's/imsize=//'`
    shift argv; if ("$argv" == "") set argv = "finish"
else if ("$argv[1]" =~ 'cregion='*) then
    set cregion = "$argv[1]"
    shift argv; if ("$argv" == "") set argv = "finish"
else if ("$argv[1]" =~ 'cleanlim='*) then
    set niters = `echo $argv[1] | sed 's/cleanlim=//' | awk '{print int($1*1)}'`
    set intclean = 0
    shift argv; if ("$argv" == "") set argv = "finish"
else if ("$argv[1]" =~ 'cellsize='*) then
    set cellsize = `echo $argv[1] | sed 's/cellsize=//'`
    shift argv; if ("$argv" == "") set argv = "finish"
else if ("$argv[1]" =~ 'olay='*) then
    set olay = `echo $argv[1] | sed 's/olay=//'`
    shift argv; if ("$argv" == "") set argv = "finish"
else if ("$argv[1]" =~ 'restfreq='*) then
    set restfreq = `echo $argv[1] | sed 's/restfreq=//' | awk '{print $1*1}'`
    if ("$restfreq" == "0") set restfreq
    shift argv; if ("$argv" == "") set argv = "finish"
else if ("$argv[1]" =~ 'options='*) then
    set options = `echo "$argv[1]" | sed 's/options=//g' | tr ',' ' ' | tr '[A-Z]' '[a-z]'`
    set badopt
    foreach option (`echo $options`)
	if ($option == "noflag") then
	    set autoflag = 0
	else if ($option == "autoflag") then
	    set autoflag = 1
	else if ($option == "autopha") then
	    set autopha = 1
	else if ($option == "autoamp") then
	    set autoamp = 1
	else if ($option == "autocal") then
	    set autopha = 1
	    set autoamp = 1
	else if ($option == "nocal") then
	    set autopha = 0
	    set autoamp = 0
	else if ($option == "nopha") then
	    set autopha = 0
	else if ($option == "negstop") then
	    set cleanopt = "negstop,$cleanopt"
	else if ($option == "positive") then
	    set cleanopt = "positive,$cleanopt"
	else if ($option == "noamp") then
    	    set autoamp = 0
	else if ($option == "drmax") then
	    set scmode = "dr"
	else if ($option == "fidmax") then
	    set scmode = "fid"
	else if ($option == "regain") then
	    set regain = 1
	else if ($option == "noregain") then
	    set regain = 0
	else if ($option == "intclean") then
	    set intclean = 1
	else if ($option == "nointclean") then
	    set intclean = 0	    
	else if ($option == "nomfs") then
	    set iopt = "options=double"
	    set sopt = "slop=1"
	else if ($option == "savedata") then
	    set savedata = 1
	else if ($option == "savemaps") then
	    set savedata = 0
	else if ($option == "junk") then
	    set savedata = 2	    
	else if ($option == "wrath") then
	    set wrath = 1
	else if ($option == "autolim") then
	    set autolim = 1
	else if ($option == "autoref") then
	    set refant = 0
	else if ($option == "verbose") then
	    set verb = 1
	    if !($display) set device = 'device=/xs'
	else if ($option == "debug") then
	    set debug = 1
	else if ($option == "sefd") then
	    set sefd = 1
	    set iopt = "$iopt,systemp"
	else if ($option == "nosefd") then
	    set sefd = 0
	else
	    set badopt = ($badopt $option)
	endif
    end
    if ("$badopt" != "") echo 'options='`echo $badopt | tr ' ' ','`' not recognized!'
    shift argv; if ("$argv" == "") set argv = "finish"
else
    echo "FATAL ERROR: $argv[1] not recognized..."
    goto enderr
endif

if ("$argv[1]" != "finish") goto varassign

if ("$vis" == "") then
    echo "FATAL ERROR: No vis file given"
    goto enderr
endif

foreach file ($vis)
    if !(-e $file) then
	echo "FATAL ERROR: $file does not exist!"
	goto enderr
    endif
end

#################################################################
# Below are a few other variables (counts) and some basic data
# capture about the observation (i.e. frequency, num of channels
# , etc.
#################################################################
if ("$calmodel" == "") set calmodel = "$wd/tempmap.clean"
if ($imsize == "") set imsize = 512
set badcal # Debugging var to tell what happened if auto-selfcal fails
set psci = 0 # Phase auto-selfcal iterations
set asci = 0 # Amp auto-selfcal iterations
set fli = 0 # Flagging iterations
set badchans
set nalevel = 0
set omode = $mode
set freqline = (`uvlist vis=$vis[1] options=var | grep "freq    :" | tr ':' ' '`) # Set the freq in MHz
set freq

while ("$freq" == "")
    if ($freqline[1] == "freq") then
	set freq = `echo $freqline[2] | awk '{print $1*1000}'` 
    else if ($#freqline == 1) then
	set freq == "1"
    else
	shift freqline
    endif
end

set nchanline = (`uvlist vis=$vis[1] options=var,full | grep nchan | tr ':' ' '`)
set nchan

while ($nchan == "")
    if ($nchanline[1] == "nchan") then
	set nchan = "$nchanline[2]" 
    else if ($#nchanline == 1) then
	set nchan == 512
    else
	shift nchanline
    endif
end

if ("$line" != "") then
    set nchan = `echo $line | tr ',' ' ' | awk '{print $2}'`
endif

set sourceline = (`uvlist vis=$vis[1] options=var,full | grep "source" | tr ':' ' ' | grep -v \* | sed 's/\?/ /g'`)
set source

while ($source == "")
    if ($sourceline[1] == "source") then
	set source = "$sourceline[2]" 
    else if ($#sourceline == 1) then
	set source == "UNK"
    else
	shift sourceline
    endif
end

set nantsline = (`uvlist vis=$vis[1] options=var | grep "nants" | tr ':' ' '`)

set nants

while ($nants == "")
    if ($nantsline[1] == "nants") then
	set nants = "$nantsline[2]" 
    else if ($#nantsline == 1) then
	set nants == 43
    else
	shift nantsline
    endif
end

set tsysarray = (100000)

while ($#tsysarray < $nants)
    set tsysarray = ($tsysarray 100000)
end

set linecmds

foreach cline ($crange)
    if (`echo $cline | tr ',' ' ' | wc -w` == 2) then
	set linecmds = ($linecmds `echo $cline | tr ',' ' ' | awk '{if ($1 < $2) print $2-$1+1","$1; else print "1,"$1}'`)
    else if (`echo $cline | tr ',' ' ' | wc -w` == 3) then
	set linecmds = ($linecmds `echo $cline | tr ',' ' ' | awk '{if ($1 < $2 && ($2-$1+1)/$3 > 1) print int(($2-$1+1)/$3)","$1","$3; else print "1,"$1}'`)
    else
	set linecmds = ($linecmds "1,"$cline)
    endif
end

set crange = ($linecmds)
echo "Mapping $source..."

set sidx = 0 # Index marker
set oldrange = 1 # Measure of dynamic range for auto-selfcal
set sel = "-auto" # This will be used later for different imaging options 

if ($autopha) then # Determine whether to start with a phase or amp selfcal during the autocal cycle.
    set scopt = pha
else
    set scopt = amp
endif

set flct = 0 # Flagged spectra count
if ($cellsize == "") set cellsize = `echo 30 | awk '{print $1*1430/freq}' freq=$freq` # Autosizing for cell size (in arcsec)

set arc = `echo 4500 | awk '{print $1*1430/freq}' freq=$freq`# fov of displayed plot in arcsec

echo "Imaging report for $vis" > $wd/imgrpt #Reporting tools
set noflct = 1
#set noflct = `uvplt vis=$vis device=/null options=2pass,nobase | grep Plot | awk '{print $2}'` # Quick count of spectra in original dataset

# We want to make sure that there is some sort of overlay if the display, so here we create one.

if !("$olay" == "") then
    if !(-e $olay) then
	echo "No overlay file found! Creating crosshairs..."
	echo "star arcmin arcmin star no 0 0 20 20 0 0" > $wd/olay
    else
	cp $olay $wd/olay
    endif
else
    echo "No overlay file found! Creating crosshairs..."
    echo "star arcmin arcmin star no 0 0 20 20 0 0" > $wd/olay
endif

#################################################################
# Because selfcal doesn't want to create indepenant gains soln's
# for different pols on the same ant, files are split into x and
# y pols. x-pol files and y-pol files are then group together 
# and combined in the invert step.
#
# If "special" gains files are found in the original folder
# (currently only created by calcal.csh) - normally named
# gains.xx and gains.yy - then automap will apply those gains
# soln's after the file is split. Due to additional problems
# with gpcopy options=apply, there is now also a new file type
# with the suffix xxp or yyp (p stands for prime).
#
# Gains information now "force" applied via UVAVER, i.e. they
# cannot be removed once applied. This is done for the sake of
# the calibration cycle, since MIRIAD will overwrite the old
# gains sol'n (unless you take "special" steps).
#################################################################

set vislist
set idx = 0

foreach file ($vis)
    convertgains.csh $file # Convert file to new gains system
    echo -n "Splitting $file..."
    @ idx++
    if ("$uselect" != "") then
	uvaver vis=$file out=$wd/tempselect options=relax interval=$interval select="$uselect" >& /dev/null
	echo -n "."
	uvaver vis=$wd/tempselect out=$wd/tempmap$idx.xpol options=relax select="-shadow(7.5),pol(xx)" >& /dev/null 
	echo -n "."
	uvaver vis=$wd/tempselect out=$wd/tempmap$idx.ypol options=relax select="-shadow(7.5),pol(yy)" >& /dev/null 
	rm -rf $wd/tempselect
    else
	uvaver vis=$file out=$wd/tempmap$idx.xpol options=relax select="-shadow(7.5),pol(xx),$uselect" interval=$interval >& /dev/null 
	echo -n "."
	uvaver vis=$file out=$wd/tempmap$idx.ypol options=relax select="-shadow(7.5),pol(yy),$uselect" interval=$interval >& /dev/null 
    endif
    if !(-e $wd/tempmap$idx.xpol/visdata || -e $wd/tempmap$idx.ypol/visdata) then
	echo "FATAL ERROR: UVAVER has failed! $file shows no viable data!" 
	goto enderr
    endif
    echo ""
    foreach dp (x y)
	if (-e $file/gains.$dp$dp && -e $wd/tempmap$idx.{$dp}pol/visdata) then
	    echo -n "Applying diff $dp$dp gains..."
	    gpcopy vis=$file/gains.$dp$dp out=$wd/tempmap$idx.{$dp}pol > /dev/null
	    uvaver vis=$wd/tempmap$idx.{$dp}pol out=$wd/tempgmap options=relax >& /dev/null
	    rm -rf $wd/tempmap$idx.{$dp}pol; mv $wd/tempgmap $wd/tempmap$idx.{$dp}pol
	    echo ""
	endif
	if (-e $file/gains.{$dp$dp}p && -e $wd/tempmap$idx.{$dp}pol/visdata) then
	    gpcopy vis=$file/gains.{$dp$dp}p out=$wd/tempmap$idx.{$dp}pol > /dev/null
	    uvaver vis=$wd/tempmap$idx.{$dp}pol out=$wd/tempgmap options=relax >& /dev/null
	    rm -rf $wd/tempmap$idx.{$dp}pol; mv $wd/tempgmap $wd/tempmap$idx.{$dp}pol
	endif
	if (-e $file/gains.{$dp$dp}pp && -e $wd/tempmap$idx.{$dp}pol/visdata && ! $regain) then
	    gpcopy vis=$file/gains.{$dp$dp}pp out=$wd/tempmap$idx.{$dp}pol > /dev/null
	    uvaver vis=$wd/tempmap$idx.{$dp}pol out=$wd/tempgmap options=relax >& /dev/null
	    rm -rf $wd/tempmap$idx.{$dp}pol; mv $wd/tempgmap $wd/tempmap$idx.{$dp}pol
	endif
	if (-e $wd/tempmap$idx.{$dp}pol/visdata && "$line" != "") then
	    echo -n "Performing line selection on data..."
	    uvaver vis=$wd/tempmap$idx.{$dp}pol out=$wd/tempgmap $line options=relax >& /dev/null
	    rm -rf $wd/tempmap$idx.{$dp}pol; mv $wd/tempgmap $wd/tempmap$idx.{$dp}pol	    
	    echo "done!"
	endif
	if (-e $file/sefd && -e $wd/tempmap$idx.{$dp}pol/visdata && $sefd) then
	    echo -n "Writing tsys values to file..."
	    sed 1,2d $file/sefd | awk '{if ($2 == dp) print "set tsysarray["$1"] = "$7*1/153}' dp=$dp > $wd/source.sefd
	    source $wd/source.sefd
	    set uvtsys = `echo $tsysarray | tr ' ' ','`
	    uvputhd vis=$wd/tempmap$idx.{$dp}pol out=$wd/tempgmap hdvar=systemp varval=$uvtsys > /dev/null
	    rm -rf $wd/tempmap$idx.{$dp}pol; mv $wd/tempgmap $wd/tempmap$idx.{$dp}pol
	    echo "done!"
	endif
	if (-e $wd/tempmap$idx.{$dp}pol/visdata && "$restfreq" != "") then
	    echo -n "Correcting for doppler shift..."
	    puthd in=$wd/tempmap$idx.{$dp}pol/restfreq value=$restfreq >& /dev/null
	    uvredo vis=$wd/tempmap$idx.{$dp}pol options=velocity out=$wd/tempgmap >& /dev/null
	    rm -rf $wd/tempmap$idx.{$dp}pol; mv $wd/tempgmap $wd/tempmap$idx.{$dp}pol
	    echo "done!"
	endif
	if (-e $wd/tempmap$idx.{$dp}pol/visdata) then
	    set vislist = ($vislist $wd/tempmap$idx.{$dp}pol)
	else
	    rm -rf $wd/tempmap$idx.{$dp}pol
	endif
    end
end

#################################################################
# Automap assumes that the image is a continuum image, unless
# the user specifies spectral channels via the "crange" keyword.
# If specline channels are specified, automap will excise those
# channels for later imaging, and concentrate only on those cont
# channels.
#################################################################

foreach file ($vislist)
    set idx = 0
    foreach chan (`echo $crange`)
	@ idx++
	uvaver vis=$file line=chan,$chan options=relax out=$file.S$idx > /dev/null
	if !(-e $file.S$idx/visdata) then
	    echo "UVAVER has failed! (probably too much data, try x and y pols seperately)"
	    goto enderr
	endif
    end
end

foreach chan (`echo $crange`)
    if (`echo $chan | tr ',' ' ' | wc -w` == 3) then
	set chanprime = `echo $chan | tr ',' ' ' | awk '{print int($1*$3)","$2}'`
	uvflag vis=`echo $vislist | tr ' ' ','` line=chan,$chanprime flagval=f options=none > /dev/null 
    else
	uvflag vis=`echo $vislist | tr ' ' ','` line=chan,$chan flagval=f options=none > /dev/null 
    endif
end

invert:

if !($autoflag || $autopha || $autoamp || $autoflag || $wrath || "$mode" == "inter") set mode = skip

#Clear out the garbage from the last run first

foreach type (map beam clean cm rs)
   if (-e $wd/tempmap.$type) rm -r $wd/tempmap.$type
end

#Grid an invert visabilities.
echo -n "Gridding and inverting data..."
invert vis=`echo $vislist | tr ' ' ','` map=$wd/tempmap.map beam=$wd/tempmap.beam cell=$cellsize imsize=$imsize sup=$sup select=$sel $iopt $sopt >& $wd/invertlog 
set tnoise = `grep Theoretical $wd/invertlog | awk '{print $4*1}'`

if !(-e $wd/tempmap.map && -e $wd/tempmap.beam) then
    echo "FATAL ERROR: INVERT has failed to complete (most likely a buffer space issue)"
    goto enderr
else
    echo "complete!"
endif


#################################################################
# Below is code for "intelligent cleaning". If requested by the
# user, automap will make a "first pass" at cleaning using an
# arbitrary number (in this case 1000), calculate the strength
# of all the point sources in the field, calculate the noise and
# determine the number of clean cycles neccessary to "clean" all
# of the sources down to 3 sigma. Automap then cleans this 
# number of times, looking for point sources in the residual map
# if enough additional sources are found, then automap will
# increase the number of clean cycles . If no sources are found,
# automap will move on.
#
# So far this method is effective in fields that have even a
# moderate amount of extended emission, but it's not known how
# well it does when the emission comes close to filling the
# primary beam.
################################################################# 

if ($intclean) then
    echo "Performing preliminary clean, deriving model for calculations"
    clean map=$wd/tempmap.map beam=$wd/tempmap.beam out=$wd/tempmap.clean niters=1000 cutoff=$tnoise options=negstop "$cregion" >& /dev/null
    if !(-e $wd/tempmap.clean) then
	echo "FATAL ERROR: Image is not cleanable (likely too much data was culled)."
	goto enderr
    endif
    restor map=$wd/tempmap.map beam=$wd/tempmap.beam model=$wd/tempmap.clean out=$wd/tempmap.cm >& /dev/null 
    restor map=$wd/tempmap.map beam=$wd/tempmap.beam model=$wd/tempmap.clean out=$wd/tempmap.rs mode=residual >& /dev/null 
    if !(-e $wd/tempmap.cm && -e $wd/tempmap.rs) then
	echo "FATAL ERROR: Image is not restorable (likely too much data was culled)."
	goto enderr
    endif
    rm -rf $wd/imlistcm $wd/imlistrs $wd/imlistcm2
    imlist in=$wd/tempmap.cm options=stat log=$wd/imlistcm >& /dev/null
    set imstats = (`imstat in=$wd/tempmap.rs | awk '{if (check == 1) print $0; else if ($1 == "Total") check = 1}' | tr '*' ' ' | sed 's/\([0-9][0-9]\)-/\1 -/g'`)
    set beamsize = `grep Effective $wd/imlistcm | awk '{print $4*1}'`
    set nalevel = `echo $beamsize $tnoise $imsize | tr ',' ' ' | awk '{if ($4*1 == 0) print .25*$2*log($3*$3/$1); else print .25*$2*log(($3*$4)/$1)}'`
    set alevel = `echo $nalevel $tnoise $imstats[3] | awk '{print $1*$3/$2}'`
    cd $wd
    rm -f sfind.log
    sfind in=tempmap.cm options=oldsfind,auto,nofit rmsbox=100 xrms=3 labtyp=arcsec >& /dev/null 
    cd ..
    # Had to patch here since sfind was having problems... stupid bugger
    set niterslim = `imstat in=$wd/tempmap.clean | awk '{if (check == 1) print $0; else if ($1 == "Total") check = 1}' | tr '*' ' ' | sed 's/\([0-9][0-9]\)-/\1 -/g' | awk '{if ($4 >= $5*-1) print int(log(3*noise/$4)/log(.9)); if ($4 < $5*-1) print int(log(-3*noise/$5)/log(.9))}' noise=$tnoise`
    set niters = `grep -v "#" $wd/sfind.log | awk '{if ($6*$7 > 3000*noise) cycles+=2*log((3000*noise)/($6*$7))/log(.9)} END {print int(cycles)}' noise=$tnoise`
    if ($niters < $niterslim) set niters=$niterslim

    if ($niters < 50) then
	echo "Derived value for niters was $niters... invoking safegaurd and putting niters at 50."
	set niters = 50
    else if ($niters > 25000) then
	echo "Derived value for $niters was $niters... invoking safeguard and putting nitters at 25000"
 	set niters = 25000
    endif
    rm -rf $wd/tempmap.cm $wd/tempmap.rs $wd/tempmap.clean
endif

if !($niters) set niters = 2500

clean:

# Create clean component map and make residual/cleaned images
clean map=$wd/tempmap.map beam=$wd/tempmap.beam out=$wd/tempmap.clean niters=$niters cutoff=$nalevel options="$cleanopt" "$cregion" >& $wd/cleanlog 
if !(-e $wd/tempmap.clean) then
    echo "FATAL ERROR: Image is not cleanable (likely too much data was culled)."
    goto enderr
endif
restor map=$wd/tempmap.map beam=$wd/tempmap.beam model=$wd/tempmap.clean out=$wd/tempmap.cm >& $wd/restorcm
restor map=$wd/tempmap.map beam=$wd/tempmap.beam model=$wd/tempmap.clean out=$wd/tempmap.rs mode=residual >& $wd/restorrs 
if !(-e $wd/tempmap.cm && -e $wd/tempmap.rs) then
    echo "FATAL ERROR: Image is not restorable (likely too much data was culled)."
    goto enderr
endif

rm -rf $wd/imlistcm $wd/imlistcm2
imlist in=$wd/tempmap.cm options=stat log=$wd/imlistcm >& /dev/null
imlist in=$wd/tempmap.cm log=$wd/imlistcm2 >& /dev/null

set beamsize = `grep Effective $wd/imlistcm | awk '{print $4*1}'`
set nalevel = `echo $beamsize $tnoise $imsize | tr ',' ' ' | awk '{if ($4*1 == 0) print $2*(.5*log($3*$3/$1)-2); else print $2*(.5*log(($3*$4)/$1)-2)}'` # Theoretical minimum max pixel magnitude

set actnitersline = (`grep niters $wd/imlistcm2 | tr ':' ' '`)
set actniters
while ("$actniters" == "")
    if ($#actnitersline < 2) then
	set actniters = $niters
    else if ("$actnitersline[1]" == "niters") then
	set actniters = $actnitersline[2]
    else
	shift actnitersline
    endif
end
set imstats = (`imstat in=$wd/tempmap.rs | awk '{if (check == 1) print $0; else if ($1 == "Total") check = 1}' | tr '*' ' ' | sed 's/\([0-9][0-9]\)-/\1 -/g'`)
set alevel = `echo $nalevel $tnoise $imstats[3] | awk '{print $1*$3/$2}'` # Expected minimum max pixel magnitude
set acheck = `echo $alevel $imstats[4-5] | awk '{if ($4+$5 < 0) print $1/$2; else print -1*$1/$3}'`
set nacheck = `echo $nalevel $imstats[4-5] | awk '{if ($4+$5 < 0) print $1/$2; else print -1*$1/$3}'`
#echo $beamsize $nalevel $alevel
#echo $nacheck $acheck
#echo $imstats[4-5]
#echo $tnoise $imstats[3]
cd $wd
rm -f sfind.log; touch sfind.log
if ($intclean || $mode != "skip") sfind in=tempmap.rs options=oldsfind,auto,nofit rmsbox=100 xrms=4 labtyp=arcsec >& /dev/null 
cd ..

#Verify that the residual maps look clean. If not, reclean or advise the user that recleaning needs to be performed
echo "Currently at $niters cycles..."

if (`grep -v "#" $wd/sfind.log | awk '{if ($7*$6 > 3000*noise) cycles+=2*log((3000*noise)/($6*$7))/log(.9)} END {print int(cycles)*1}' noise=$imstats[3]` > `echo $niters | awk '{print int(.025*$1)}'` && $niters != 25000) then
    if (`echo $actniters $niters | awk '{if ($1*1 != $2*1) print "1"; else print "0"}'` || `echo $alevel | awk '{if ($1 < 1.025) print "1"; else print "0"}'`) then
	echo "Cleaning reached theoretical noise limit!"
    else if ($intclean) then
	set niters = `grep -v "#" $wd/sfind.log | awk '{if ($7*$6 > 3000*noise) cycles+=2*log((3000*noise)/($6*$7))/log(.9)} END {print int(cycles)+niters}' noise=$imstats[3] niters=$niters`
	if ($niters < 50) then
	    echo "Derived value for $niters was $niters... invoking safegaurd and putting niters at 50."
	    set niters = 50
	else if ($niters > 25000) then
	    echo "Derived value for $niters was $niters... invoking safeguard and putting nitters at 25000"
	    set niters = 25000
	endif
	rm -rf $wd/tempmap.clean $wd/tempmap.rs $wd/tempmap.cm
	goto clean
    else if ("$mode" == "auto" || "$mode" == "skip") then
	echo "Warning! Automap has determined that this map is possibly undercleaned!"
    else
	echo "Warning! Automap has determined that this map is possibly undercleaned! Would you like to adjust niters? ([y]es (n)o)"
	if ($< =~ "y"*) then
	    echo "Enter niters:"
	    set niters = $<
	    rm -rf $wd/tempmap.clean $wd/tempmap.rs $wd/tempmap.cm
	    goto clean
	endif
    endif
else if (`echo $acheck $nacheck | awk '{if ($1 > 1 && $2 > 1) print 1; else print 0}'` && "$niters" != "50") then
    if ($intclean) then
	set niters = `echo $niters $acheck $nacheck | awk '{if ($2 < $3) print int($1*$2); else print int($1*$2)}'`
	if ($niters < 50) set niters = 50
	echo "WARNING: Overcleaning detected, rolling back to $niters iterations..."
	rm -rf $wd/tempmap.clean $wd/tempmap.rs $wd/tempmap.cm
	goto clean
    else if ($mode == "skip" || $mode == "auto") then
	echo "WARNING: Map potentially overcleaned..."
    else
	echo "WARNING: AUTOMAP has potentially found this map to be overcleaned."
	echo "Would you like to adjust the number of iterations? ([y]es (n)o)"
       	if ($< =~ "y"*) then
	    echo "Enter niters:"
	    set niters = $<
	    rm -rf $wd/tempmap.clean $wd/tempmap.rs $wd/tempmap.cm
	    goto clean
	endif
    endif
else
    echo "Clean looks good, moving to restoration and analysis/display"
endif

cd $wd; rm -f sfind.log; touch sfind.log
sfind in=tempmap.cm options=oldsfind,auto,nofit rmsbox=256 xrms=4 labtyp=arcsec >& /dev/null
cd ..

# Find some stats about the map...
#Imstat: 1) Sum 2) Mean 3) RMS 4) Max 5) Min 6) Npoints

set imstats = (`imstat in=$wd/tempmap.rs region=relcen,arcsec,"box(-$arc,-$arc,$arc,$arc)" | awk '{if (check == 1) print $0; else if ($1 == "Total") check = 1}' | tr '*' ' ' | sed 's/\([0-9][0-9]\)-/\1 -/g'`)
set imstats2 = (`imstat in=$wd/tempmap.cm region=relcen,arcsec,"box(-$arc,-$arc,$arc,$arc)" | awk '{if (check == 1) print $0; else if ($1 == "Total") check = 1}' | tr '*' ' ' | sed 's/\([0-9][0-9]\)-/\1 -/g'`)
set range = `echo $imstats[3] $imstats2[4] | awk '{print $2/$1}'`
set noise = `echo $imstats[3] | awk '{print $1*1000}'`

################################################################# 
# Below is the automatic calculator for amplitudes. It works by
# taking the sum of the clean components (which should hold
# nearly all of the flux of the map), adding some additional
# flux based on possible errors in the clean components,
# possible sources below the 3 sigma noise limit and the 
# "system" flux. The lower limit is established by taking the
# peak flux in the map and subtracting the "total" flux
# calculated above. The spectral channel limit is established by
# adding additional flux based on the "sysflux" to the "total"
# flux.
################################################################# 

if ($autolim) then
    set nsources = `grep -vc "#" $wd/sfind.log`
    set amplim = (0 5000 10000)
    set amplim[2] = `imstat in=$wd/tempmap.clean | awk '{if (check == 1) print $0; else if ($1 == "Total") check = 1}' | tr '*' ' ' | sed 's/\([0-9][0-9]\)-/\1 -/g' | awk '{print (nsources*3*2*noise)+(1.25*$1)+sysflux}' nsources=$nsources noise=$imstats[3] sysflux=$sysflux`
    set amplim[3] = `echo $amplim[2] $nchan $sysflux | awk '{print $1+(1.25*$3*($2^.5))}'`
    set amplim[1] = `echo $imstats2[4] $amplim[2] | awk '{if ($1 < $2) print 0; else print $1-$2}'` 
    echo "Amp limits automatically derived - $amplim[1] low, $amplim[2] high, $amplim[3] spectral."
endif

if ($verb) then
    set levs = (`echo $imstats[3] $imstats2[4] | awk '{lim = 4*$1; while (lim < $2) {print lim; lim=2*lim}}'`)
    set levs = `echo $levs | tr ' ' ','`
    if ("$plotscale" == "") then
	set plotscale = `echo $range | awk '{if ($1 > 500) print "log"; else print "lin"}'`
    endif
    cgdisp in=$wd/tempmap.cm,$wd/tempmap.cm region=relcenter,arcsec,box"(-$arc,-$arc,$arc,$arc)" labtyp=arcmin options=beambl,wedge,3value,mirr,full csize=0.6,1 olay=$wd/mixolay type=contour,pix levs1=$levs range=0,0,$plotscale,2 $device >& /dev/null
endif

if ($mode == "auto") goto auto # Skip display during the auto cycle

plot:
# Display the results... nothing exciting here.

if ("$plotscale" == "") then
    set plotscale = `echo $range | awk '{if ($1 > 500) print "log"; else print "lin"}'`
endif
set levs = (`echo $imstats[3] $imstats2[4] | awk '{lim = 4*$1; while (lim < $2) {print lim; lim=2*lim}}'`)
set levs = `echo $levs | tr ' ' ','`

grep -v "#" $wd/sfind.log | tr ":" " " | awk '{if ($10*$11 < 3000) print "star hms dms","sfind"NR,"no",$1,$2,$3,$4,$5,$6,$10*$11,$10*$11; else print "star hms dms","sfind"NR,"no",$1,$2,$3,$4,$5,$6,3000,3000}' > $wd/sfindolay # Build an overlay of detected sources
cat $wd/olay $wd/sfindolay > $wd/mixolay

echo "Writing PS document"
cgdisp in=$wd/tempmap.cm,$wd/tempmap.cm region=relcenter,arcsec,box"(-$arc,-$arc,$arc,$arc)" device=$wd/tempmap.ps/cps labtyp=arcmin options=beambl,wedge,3value,mirr,full csize=0.6,1 olay=$wd/mixolay type=contour,pix levs1=$levs range=0,0,$plotscale,3 >& /dev/null

if ($display) echo "Displaying Results"
if ($display) cgdisp in=$wd/tempmap.cm,$wd/tempmap.cm region=relcenter,arcsec,box"(-$arc,-$arc,$arc,$arc)" labtyp=arcmin options=beambl,wedge,3value,mirr,full csize=0.6,1 olay=$wd/mixolay type=contour,pix levs1=$levs range=0,0,$plotscale,2 $device >& /dev/null

set orc = `echo 500 $freq | awk '{print int($1*1430/$2)}'`

echo "RMS noise is $imstats[3] - dynamic range is $range"
if ($mode == "skip") set oldrange = $range
if ($mode == "skip") goto finish
if ($mode == "auto") goto finish

# The nonautomated side of this basically just allows the user to flag or selfcal and repeat the invert. This side still needs to be cleaned up.

imcomp:

echo "Imaging complete. Would you like to (s)elfcal, baseline (f)lag, (g)eneral flag, (w)rath, adjust (n)iters or e(x)it?"
set yn = $<
if ($yn == "s") goto selfcal
if ($yn == "f") goto postflag
if ($yn == "x") goto finish
if ($yn == "g") goto postgenflag
if ($yn == "w") goto wrath
if ($yn == "n") goto postclean
echo "$yn is not a recognized selection"
goto imcomp 

postclean:
echo "Enter number of iterations for CLEAN:"
set niters = "$<"
if (`echo $niters | awk '{print $1*1}'` == 0) then
    echo "WARNING: Number of iterations not recognized. Moving to default of 2500"
    set niters = 2500
endif

goto invert

postgenflag:

echo "Enter selection parameters for flagging"
set pfselect = "$<"
foreach file ($vislist)
    uvflag vis=$file options=none select="$pfselect" flagval=f > /dev/null
end

goto invert

selfcal:		# selfcal - in the true selfcal the imaged data

set clip = `echo $scsigma $imstats[3] | awk '{print $1*$2}'`
  echo "Selfcal interval [default=$scint]: "; set ans=$<
  if ($ans != "") set scint = $ans
  echo "amp or pha? [default=$scopt]: "; set cl=$<
  if ($cl != "") set scopt = $cl
  echo "Clip level? [default=$clip]: "; set ans=$<
  if ($ans != "") set clip = $ans
  foreach file ($vislist)
    echo $calmodel
    selfcal vis=$file model=$calmodel interval=$scint select=$sel \
	minants=4 options=mfs,$scopt clip=$clip refant=$refant
  end
  goto invert


postflag:
set blopt = "options=nobase" 
echo "Review baselines one-by-one? (y)es |n|o"
set yn = $< ; if ($yn == "y") set blopt
echo "Review phases? (y)es |n|o"
set yn = $<
foreach file ($vislist)
    echo "Plotting all baseline by uv distance and amp."
    blflag vis=$file device=/xs $blopt select='-auto' axis=uvd,amp
    echo "Plotting all baseline by time and amp."
    blflag vis=$file device=/xs $blopt select='-auto' axis=time,amp
    if ($yn == "y") then
	echo "Plotting all baselines by uv distance and phase."
	blflag vis=$file device=/xs options=nobase select='-auto' axis=uvd,pha
	echo "Plotting all baselines by time and phase."
	blflag vis=$file device=/xs options=nobase select='-auto' axis=time,pha
    endif
end

goto invert

auto:

################################################################# 
# First thing to do during the auto cycle is to see whether or 
# not more calibration is needed. Automap keeps track of the
# current image quality, and whether or not the image quality is
# degrading, stable or improving. If degrading, automap will
# itself two tries to bring the quality of the map back up to
# the previous best. If it succeeds, it proceeds like normal. If
# it cannot repoduce the "best" map, then it enters failsafe
# mode and copys back the flags and gains solutions from the
# best previous cycle
#
# If the image quality is stable, then automap declares success,
# makes sure that no more calibration needs to be done (i.e. it
# wont exit out if you told it to perform an amp self-cal and
# it's only performed phase self-cals up to this stage) and maps
# and exits accordingly. If all of the automated stages have not
# been completed (i.e. only flagging has been performed when you
# have asked for self-cal as well) or the image quality is still
# improving, then automap will continue along it's merry way
# until one of the two above scenarios are met.
################################################################# 

# This will eventually be expanded to include image fidelity

echo "Dynamic range for this cycle was $range, with an RMS noise of $imstats[3]"
set noise = `echo $imstats[3] | awk '{print $1*1000}'`
if (`echo $range $oldrange $sctol | awk '{if (($1/$2) < (1-$3)) print "go"}'` == "go") then
    @ sidx++
    if ($sidx >= 3) goto failsafe
    echo "Bad cycle number $sidx, attempting to recover..."
else if (`echo $range $oldrange $sctol | awk '{if (($1/$2) < (1+$3)) print "go"}'` == "go" && $autoamp <= $asci && $autopha <= $psci) then
    echo "Maximum dynamic range reached. Plotting results"
    set sidx = 0
    goto plot
else if (`echo $range $oldrange $sctol | awk '{if (($1/$2) < (1+$3)) print "go"}'` == "go" && $autoamp && $autopha && $psci != 0) then
    echo "Finished phase selfcal iterations, moving on to amp selfcal"
    set scopt = "amp"
    set oldrange = "$range"
    foreach file ($vislist)
	if (-e $file/gains) cp $file/gains $file/bugains
	if (-e $file/flags) cp $file/flags $file/buflags
    end
    set sidx = 0
else if (`echo $range $oldrange $sctol | awk '{if (($1/$2) < (1+$3)) print "go"}'` == "go") then
    echo "Awaiting flagging to finish before moving on to calibration cycles"
else
    echo "Last cycles was successful. Moving forward..."
    set oldrange = "$range"
    foreach file ($vislist)
	if (-e $file/gains) cp $file/gains $file/bugains
	if (-e $file/flags) cp $file/flags $file/buflags
    end
    set sidx = 0
endif

autoflag:

################################################################# 
# Autoflagging is fairly simple, automap uses uvaver to apply
# the gains solution (if there is one) and uses uvlist to calc
# the amplitude of each integrated spectra. If the amplitude
# falls outside of some preset limit (amplim[1] being the lower
# limit and amplim[2] being the higher limit), then automap will
# flag that spectra as being bad. Additionally, any spectral
# channels that exceed amplim[3] are flagged as bad (which is
# much simplier, since uvflag allows for that kind of selection)
# and the flagged file is used as a "template" to flag the
# original file (where the gains have not been engrained into
# the visibilities). Flagging for spectral line data only takes
# place based on the "wideband" (i.e. integrated spectra)
# flagging - any spectra that is entirely flagged in the cont
# dataset will also be flagged in the spectral line dataset.
################################################################# 

if ($autoflag) then
    set sflags = 0
    set totlinelim = 0
    set totlim = 0
    echo "Beginning automated amp flagging"
    foreach file ($vislist)
	rm -rf $wd/tempmap2
	
	uvaver vis=$file out=$wd/tempmap2 options=relax > /dev/null
	if !(-e $wd/tempmap2/visdata) then
	    echo "UVAVER has failed! (probably too much data, try x and y pols seperately)" 
	    goto enderr
	endif
	# Check to see if there are any spectra with amplitudes outside of nominal range
	uvlist vis=$wd/tempmap2 select=-auto line=chan,1,1,$nchan recnum=0 | awk '{if ($1*1 == 0); else if ($8*1 != 0 || $9*1 != 0) print $1*1,$9*1,$8*1}'| sort -nk3 > $wd/ampinfo
	set asel = "amp($amplim[3])"
	set sflags = 0
	set sflags = `uvflag vis=$wd/tempmap2 select=$asel options=brief,noquery flagval=f | grep "Changed to bad:" | awk '{sum += $7} END {print 1*sum}'`
	
	set linecheck = `wc -l $wd/ampinfo | awk '{print int($1*.95)}'` # Prevent loss of more than 5% of data at any time.
	set linelim = `wc -l $wd/ampinfo | awk '{print int($1*.001)}'`
	if ($linelim < 10) set linelim = 10
	set totlinelim = `echo $totlinelim $linelim | awk '{print $1+$2}'`
	if (`echo $amplim[2] | awk '{print int($1)}'` > `sed -n {$linecheck}p $wd/ampinfo | awk '{print int($3)}'`) then
	awk '{if ($3 > hamp || $3 < lamp) print $1}' lamp=$amplim[1] hamp=$amplim[2] $wd/ampinfo | sort -nk1 > $wd/amplog
	else
	    sed -n 1,{$linecheck}d $wd/ampinfo | awk '{print $1}' | sort -nk1 > $wd/amplog
	endif
    # Amplitude flagging is broken up because miriad can only handle so many vis flags in a single sitting. These flags are also applied to the spectral line data, since presumably the data should be bad in those channels as well.

	set llim=1
	set ulim=50
	set lim = `wc -w $wd/amplog | awk '{print $1}'`
	set totlim = `echo $lim $totlim | awk '{print $1+$2}'`
	echo "$lim amp records to flag, $sflags spectral records to flag..."
	
	while ($llim <= $lim)
	    set flags = `sed -n {$llim},{$ulim}p $wd/amplog | awk '{printf "%s","vis("$1"),"}' ulim=$ulim`
	    uvflag vis=$wd/tempmap2 flagval=f options=none select=$flags >& /dev/null
	    if ("$crange" != "") uvflag vis="$wd/tempmapS*" flagval=f options=none select=$flags >& /dev/null
	    set llim = `echo $llim | awk '{print $1+50}'`
	    set ulim = `echo $ulim | awk '{print $1+50}'`
	    echo -n '.'
	end
	    echo '.'
	uvaflag vis=$file tvis=$wd/tempmap2 >& /dev/null
	rm -rf $wd/tempmap2 $wd/amplog $wd/ampinfo
    end
    if ($sflags < `echo $totlinelim | awk '{print $1*30}'` && $totlim < $totlinelim) goto wrath
    @ fli++
    echo "Restarting cycle!"
    echo " "
    goto invert
endif

wrath:

################################################################# 
# Wrath is a new option for automap. Basically once all of the
# "obviously bad" data points have been culled, automap will go
# through on a channel by channel basis and look for any channel
# maps that don't clean out as well as others.  Any channel maps
# that exceed the noise limit are excised (that limit being
# dervived so that only one non-polluted channel will be outside
# that limit by gaussian stats).
################################################################# 

if ($wrath || "$mode" == "inter") then
    set cniters = `grep -v "#" $wd/sfind.log | awk '{if ($6*$7 > .25*3000*noise*(nchan^.5)) cycles+=log((.25*3000*noise)/($6*$7))/log(.9)} END {print int(cycles)}' noise=$imstats[3] nchan=$nchan`
    if ($cniters < 10) then
	set cniters = 10
    else if ($cniters > 10000) then
    set cniters = 10000
    endif
    echo "Beginning WRATH clean, performing invert..."
    invert vis=`echo $vislist | tr ' ' ','` map=$wd/wrath.map beam=$wd/wrath.beam cell=$cellsize imsize=$imsize sup=$sup select=$sel options=double slop=1 >& $wd/progress
    if !(-e $wd/wrath.map && -e $wd/wrath.beam) then
	echo "FATAL ERROR: INVERT has failed to complete (most likely a buffer space issue)"
	goto enderr
    endif
    echo -n "Cleaning channel maps with $cniters iterations..."
    clean map=$wd/wrath.map beam=$wd/wrath.beam out=$wd/wrath.clean niters=$cniters "$cregion" >& $wd/progress 
    echo "restoring..."
    restor map=$wd/wrath.map beam=$wd/wrath.beam model=$wd/wrath.clean out=$wd/wrath.rs mode=residual >& $wd/progress

    imstat in=$wd/wrath.rs options=noheader | tr '*' ' ' | sed -e 1d -e 's/\([0-9][0-9]\)-/\1 -/g' | awk '{if ($5 !=0) printf "%s %.24f\n",$1,$5}' | sort -nk2 > $wd/wrathstats
    set midplane = `wc -l $wd/wrathstats | awk '{print int(.5+$1/2)}' | awk '{if ($1 < 1) print 1; else print $1}'`
    set midnoise = `sed -n {$midplane}p $wd/wrathstats | awk '{print $2}'`
    set midrms = `awk '{if ($2 <= midnoise) {idx++; sms += ($2-midnoise)^2}} END {if (idx > 0) {print (sms/idx)^.5}}' midnoise=$midnoise $wd/wrathstats`
    set badchans = (`awk '{if ($2 > midnoise+(log(midplane*2)*midrms)) print $1}' midnoise=$midnoise midplane=$midplane midrms=$midrms $wd/wrathstats`)
    echo "$#badchans RFI afflicted images planes found...blasting RFI!"
    echo "Eliminating the following bad channels:"
    echo "WRATHCHAN: $badchans"
    echo -n "Beginning flagging..."

    foreach chan ($badchans)
	echo -n "."
	foreach file ($vislist)
	    uvflag vis=$file options=none flagval=f line=chan,1,$chan > /dev/null
	end
    end
    echo "complete!"
    set wrath = 0
    if ("$badchans" != "" || "$mode" == "inter") goto invert
endif

autocal:
################################################################# 
# The autocal step is fairly simple, basically it performs an
# amp or phase selfcal based on what the user has specified.
# Automap will attempt to run a phase selfcal (as it should!)
# before it runs an amp selfcal. The new gains solutions are
# then used to make the next map, and the cycle continues. Once
# finalized, the solutions are copied to the spectral line data
# (if they exist) during the last part of the program.
################################################################# 

if !($autoamp || $autopha) goto invert
if ($scopt == "pha") @ psci++
if ($scopt == "amp") @ asci++

echo "Now performing $scopt self-cal on data set...currently at $psci phase cycles and $asci amplitude cycles."

if ("$scsigma" == "" && "$scclip" == "") then
    set clip = `echo $beamsize $imstats[3] $imsize | tr ',' ' ' | awk '{if ($4*1 == 0) print $2*(.5*log($3*$3/$1)+2); else print $2*(.5*log(($3*$4)/$1)+2)}'`
else if ("$scsigma" != "") then
    set clip = `echo $scsigma $imstats[3] | awk '{print $1*$2}'`
else
    set clip = $scclip
endif

foreach file ($vislist)
    selfcal vis=$file model=$calmodel interval=$scint select=$sel minants=4 options=mfs,$scopt clip=$clip refant=$refant >& /dev/null
    if ($autoamp && ! $autopha && -e $file/gains) gpedit vis=$file options=amp > /dev/null
end

echo "Restarting cycle!"
echo " "
goto invert

enderr:
if !($debug) rm -rf $wd
exit 1

failsafe:

echo "Failsafe initiated!"

################################################################# 
# Under failsafe mode, automap will copy back the "best" flags
# and gains solution for each file (that derived the best map).
# Currently, automap WILL produce spectral line images (if
# specified by the user via the crange keyword).
################################################################# 

foreach file ($vislist)
    if (-e $file/buflags) mv $file/buflags $file/flags
    if (-e $file/bugains) then
	mv $file/bugains $file/gains
    else
	rm -f $file/gains
    endif
end
set mode = "skip"
goto invert

finish:

if ($regain) then
    echo "Copying new gains solutions to vis files..."
    set idx = 1
    while ($idx <= $#vis)
	foreach dp (x y)
	    if (-e $wd/tempmap$idx.{$dp}pol/gains) then
		gpcopy vis=$wd/tempmap$idx.{$dp}pol out=$vis[$idx]/gains.{$dp$dp}pp mode=create > /dev/null
	    endif
	end
	echo "Gains copied to $vis[$idx]..."
	@ idx++
    end
    echo "Copying complete!"
endif

# Below this is all reporting code. All of this code will need to be changed...
set nalevel = `echo $beamsize $tnoise $imsize | tr ',' ' ' | awk '{if ($4*1 == 0) print .5*$2*(log($3*$3/$1)); else print .5*$2*(log($3*$4/$1))}'`
echo "IMAGING REPORT" > $wd/imgrpt
echo "================================================================" >> $wd/imgrpt
echo "Imaging of $source was successfully completed using $omode mode." >> $wd/imgrpt
echo "Image noise is $noise mJy, with a dynamic range of $range." >> $wd/imgrpt
echo "(theoretical noise limit is "`echo $tnoise | awk '{print $1*1000}'`" mJy)" >> $wd/imgrpt

set beampara = (`prthd in=$wd/tempmap.cm | grep 'Beam Size:' | tr ':' ' ' | awk '{print $3*1,$5*1}'`)
set beampara = ($beampara `prthd in=$wd/tempmap.cm | grep 'Position angle:' | awk '{print $3*1}'`)

echo "Beamsize was $beampara[1] x $beampara[2] arcsecs (PA of $beampara[3] degrees)" >> $wd/imgrpt
echo "(cellsize is $cellsize arcsec, imsize is $imsize pixels)" >> $wd/imgrpt
echo "" >> $wd/imgrpt
echo "Expected noise threshold is "`echo $nalevel $imstats[3] $tnoise | awk '{print 1000*$1*$2/$3}'`" mJy (theoretical "`echo $nalevel | awk '{print $1*1000}'`" mJy)" >> $wd/imgrpt
echo "Artifact level is "`echo $nalevel $tnoise $imstats[3-5] | awk '{if ($4+$5 >= 0) print int(100*$2*$4/($1*$3)); else print int(-100*$2*$5/($1*$3))}'`"% of expected level. (50 - 200% is nominal)" >> $wd/imgrpt
echo "Image min/max are "`echo $imstats2[4-5] | awk '{print $2*1000"/"$1*1000}'`" mJy." >> $wd/imgrpt
#Imstat: 1) Sum 2) Mean 3) RMS 4) Max 5) Min 6) Npoints
echo ""`wc -l $wd/sfindolay | awk '{print $1}'`" point sources were identified in the image." >> $wd/imgrpt
echo "" >> $wd/imgrpt
echo "There were a total of $fli flagging cycles, $psci phase self-cal" >> $wd/imgrpt
echo "iterations and $asci amplitude selfcal iterations." >> $wd/imgrpt
if ("$badchans" != "") then
    echo "WRATH eliminated $#badchans channels with potential RFI (channels" >> $wd/imgrpt
    echo `echo $badchans | tr ' ' ','`")" >> $wd/imgrpt
endif
if ($sidx) then
    if ($psci > 0 && $asci == 0) echo "Imaging was not able to find a proper phase self-cal solution." >> $wd/imgrpt
    if ($psci > 0 && $asci > 0)  echo "Imaging was not able to find a proper amplitude self-cal solution." >> $wd/imgrpt
    if ($psci == 0 && $asci == 0) echo "Imaging was not able to find a proper flagging solution." >> $wd/imgrpt
endif
if (! $sidx && $psci && ! $asci) echo "A phase self-cal solution was successfully reached." >> $wd/imgrpt
if (! $sidx && ! $psci && $asci) echo "An amplitude self-cal solution was successfully reached." >> $wd/imgrpt
if (! $sidx && $psci && $asci) echo "Amplitude and phase self-cal solutions were successfully reached" >> $wd/imgrpt
if !($autoflag) echo "No amplitude-based flagging was performed." >> $wd/imgrpt
if ($autoflag) echo "Spectra with amplitudes below $amplim[1] Jy amd above $amplim[2] Jy" >> $wd/imgrpt
if ($autoflag) echo " (and channels above $amplim[3] Jy) were flagged as 'bad'." >> $wd/imgrpt
if ($autolim) echo "(flagging limits were automatically determined)" >> $wd/imgrpt
echo "" >> $wd/imgrpt
if ("$iopt" =~ *"mfs"*) echo "Image was created using MFS imaging." >> $wd/imgrpt
if ($sefd) echo "Image used system temperatures for weighting of data" >> $wd/imgrpt
if ("$sup" == "0") then
    echo "Image used the 'natural' weighting scheme." >> $wd/imgrpt
else if ("$sup" == "10000") 
    echo "Image used the 'uniform' weighting scheme." >> $wd/imgrpt
else
    echo "Image used the 'robust' weighting scheme." >> $wd/imgrpt
endif
echo -n "The " >> $wd/imgrpt
if ($intclean) echo -n "auto-" >> $wd/imgrpt
if ("$cleantype" == "clean") echo "CLEAN mode (with $niters iterations) was used." >> $wd/imgrpt
if ("$cleantype" == "mem") echo "MEM (maximum entropy) (with $niters iterations) was used." >> $wd/imgrpt
echo "+++++++++++++++++++++++++++++++++" >> $wd/imgrpt

################################################################# 
# After reporting is finished, automap will move the images into
# a directory. If the user specifies a directory, everything
# will be moved there, otherwise automap creates a directory
# with the syntax "source-maps{.idx}", where the idx parameter
# is used if the "source-maps" directory already exists (i.e.
# automap attempt to avoid overwriting previous results). 
#
# The default is to save the dirty, clean and residual maps, the
# beam, the clean model and the imaging report. The user can
# also specify to save the reduced dataset or save nothing.
#
# After this, if any spectral line ranges have been specified,
# automap will move through and image them, placing them in the
# same folder as the continuum image.
################################################################# 

set idx = 0
if ("$outdir" == "") then
    set outfile = $source-maps
    set idx = 0
    while (-e $outfile)
        @ idx++
        set outfile = "$source-maps.$idx"
    end
else
    set outfile = "$outdir"
endif

if ($savedata != 2) then
    mkdir -p $outfile
    cp -r $wd/tempmap.map $outfile/$source.map
    cp -r $wd/tempmap.clean $outfile/$source.clean
    cp -r $wd/tempmap.beam $outfile/$source.beam
    cp -r $wd/tempmap.rs $outfile/$source.rs
    cp -r $wd/tempmap.cm $outfile/$source.cm
    cp -r $wd/tempmap.ps $outfile/$source.ps
    cp -r $wd/mixolay $outfile/$source.olay
    if ($savedata) then
	set idx = 1
	while ($idx <= $#vis)
	    if (-e $wd/tempmap$idx.xpol) cp -r $wd/tempmap$idx.xpol $outfile/$source.$idx.xx
	    if (-e $wd/tempmap$idx.ypol) cp -r $wd/tempmap$idx.ypol $outfile/$source.$idx.yy
	    @ idx++
	end
    endif
    #Apply gains for each channel range, and make individual image maps.
    set idx = 1
    set switch
    if ($savedata) set switch = 'savedata'
    foreach chan (`echo $crange`)
	foreach file ($vislist)
    	gpcopy vis=$file out=$file.S$idx
        end
    	@ idx++
    end
    set idx = 1
    foreach chan (`echo $crange`)
        newautomap.csh vis="$wd/*.S$idx" mode=skip options=nomfs,$switch outdir=$outfile/SLine$idx cleanlim=$niters
    end
    echo "Imaging report now available under $outfile/imgrpt"
    cp $wd/imgrpt $outfile/imgrpt
endif

set times = (`date +%s.%N | awk '{print int(($1-date1)/60),int(($1-date1)%60)}' date1=$date1` 0 0)

echo "Imaging took $times[1] minute(s) and $times[2] second(s)."

if !($debug) rm -rf $wd
exit 0
