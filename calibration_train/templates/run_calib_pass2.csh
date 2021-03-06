#!/bin/tcsh
# Do a first pass of calibrations for a given run

# initialize CCDB before running
cp ${BASEDIR}/sqlite_ccdb/ccdb_pass1.${RUN}.sqlite ccdb.sqlite
setenv JANA_CALIB_URL sqlite:///`pwd`/ccdb.sqlite                # run jobs off of SQLite
if ( $?CALIB_CCDB_SQLITE_FILE ) then
    setenv CCDB_CONNECTION $JANA_CALIB_URL
    #setenv CCDB_CONNECTION sqlite:///$CALIB_CCDB_SQLITE_FILE
else
    setenv CCDB_CONNECTION mysql://ccdb_user@hallddb.jlab.org/ccdb    # save results in MySQL
endif
if ( $?CALIB_CHALLENGE ) then
    setenv VARIATION calib_pass2
else
    setenv VARIATION calib
endif
setenv JANA_CALIB_CONTEXT "variation=$VARIATION" 

# Debug info
if ( $?CALIB_DEBUG ) then 
    echo ==starting CCDB info==
    python cat_ccdb_tables.py ccdb_tables_pass2
endif

###################################################

# set some general variables
set RUNDIR=${BASEDIR}/output/Run${RUN}

# merge results of per-file processing
#setenv PASS2_OUTPUT_FILENAME hd_calib_pass2_Run${RUN}_${FILE}.root
setenv RUN_OUTPUT_FILENAME hd_calib_pass2_Run${RUN}.root
echo ==summing ROOT files==
#hadd -f -k $RUN_OUTPUT_FILENAME  ${RUNDIR}/*/hd_calib_pass2_*.root
# ONE JOB!
cp -v hd_calib_pass2_Run${RUN}_${FILE}.root hd_calib_pass2_Run${RUN}.root

# process the results
set RUNNUM=`echo ${RUN} | awk '{printf "%d\n",$0;}'`

echo ==second pass calibrations==
echo Running: HLDetectorTiming, ExtractTrackBasedTiming.C
python run_single_root_command.py $HALLD_HOME/src/plugins/Calibration/HLDetectorTiming/FitScripts/ExtractTrackBasedTiming.C\(\"${RUN_OUTPUT_FILENAME}\",${RUNNUM},\"${VARIATION}\"\)
echo Running: BCAL_TDC_Timing, ExtractTimeWalk.C
python run_single_root_command.py $HALLD_HOME/src/plugins/Calibration/BCAL_TDC_Timing/FitScripts/ExtractTimeWalk.C\(\"${RUN_OUTPUT_FILENAME}\"\)
#echo Running: PS_E_calib, PSEcorr.C
#python run_single_root_command.py $HALLD_HOME/src/plugins/Calibration/PS_E_calib/PSEcorr.C\(\"${RUN_OUTPUT_FILENAME}\"\)
#python run_calib_pass2.py $RUN_OUTPUT_FILENAME

echo ==make monitoring output==
python run_single_root_command.py -F $RUN_OUTPUT_FILENAME -O pass2_CalorimeterTiming $HALLD_HOME/src/plugins/Calibration/HLDetectorTiming/HistMacro_CalorimeterTiming.C
python run_single_root_command.py -F $RUN_OUTPUT_FILENAME -O pass2_PIDSystemTiming $HALLD_HOME/src/plugins/Calibration/HLDetectorTiming/HistMacro_PIDSystemTiming.C
python run_single_root_command.py -F $RUN_OUTPUT_FILENAME -O pass2_TrackMatchedTiming $HALLD_HOME/src/plugins/Calibration/HLDetectorTiming/HistMacro_TrackMatchedTiming.C
python run_single_root_command.py -F $RUN_OUTPUT_FILENAME -O pass2_TaggerTiming $HALLD_HOME/src/plugins/Calibration/HLDetectorTiming/HistMacro_TaggerTiming.C
python run_single_root_command.py -F $RUN_OUTPUT_FILENAME -O pass2_TaggerRFAlignment $HALLD_HOME/src/plugins/Calibration/HLDetectorTiming/HistMacro_TaggerRFAlignment.C
python run_single_root_command.py -F $RUN_OUTPUT_FILENAME -O pass2_TaggerSCAlignment $HALLD_HOME/src/plugins/Calibration/HLDetectorTiming/HistMacro_TaggerSCAlignment.C

# update CCDB
if ( $?CALIB_SUBMIT_CONSTANTS ) then
    echo ==update CCDB==
    ccdb add /BCAL/base_time_offset -v $VARIATION -r ${RUN}-${RUN} bcal_base_time.txt
    ccdb add /CDC/base_time_offset -v $VARIATION -r ${RUN}-${RUN} cdc_base_time.txt
    ccdb add /FCAL/base_time_offset -v $VARIATION -r ${RUN}-${RUN} fcal_base_time.txt
    #ccdb add /FDC/base_time_offset -v $VARIATION -r ${RUN}-${RUN} fdc_base_time.txt
    ccdb add /START_COUNTER/base_time_offset -v $VARIATION -r ${RUN}-${RUN} sc_base_time.txt
    ccdb add /PHOTON_BEAM/hodoscope/base_time_offset -v $VARIATION -r ${RUN}-${RUN} tagh_base_time.txt
    ccdb add /PHOTON_BEAM/microscope/base_time_offset -v $VARIATION -r ${RUN}-${RUN} tagm_base_time.txt
    ccdb add /TOF/base_time_offset -v $VARIATION -r ${RUN}-${RUN} tof_base_time.txt
    #ccdb add /BCAL/ADC_timing_offsets -v $VARIATION -r ${RUN}-${RUN} bcal_adc_timing_offsets.txt
    #ccdb add /BCAL/TDC_offsets -v $VARIATION -r ${RUN}-${RUN} bcal_tdc_timing_offsets.txt
    #ccdb add /FCAL/timing_offsets -v $VARIATION -r ${RUN}-${RUN} fcal_adc_timing_offsets.txt
    ccdb add /START_COUNTER/adc_timing_offsets -v $VARIATION -r ${RUN}-${RUN} sc_adc_timing_offsets.txt
    ccdb add /START_COUNTER/tdc_timing_offsets -v $VARIATION -r ${RUN}-${RUN} sc_tdc_timing_offsets.txt
    ccdb add /PHOTON_BEAM/microscope/fadc_time_offsets -v $VARIATION -r ${RUN}-${RUN} tagm_adc_timing_offsets.txt
    ccdb add /PHOTON_BEAM/microscope/tdc_time_offsets -v $VARIATION -r ${RUN}-${RUN} tagm_tdc_timing_offsets.txt
    ccdb add /PHOTON_BEAM/hodoscope/fadc_time_offsets -v $VARIATION -r ${RUN}-${RUN} tagh_adc_timing_offsets.txt
    ccdb add /PHOTON_BEAM/hodoscope/tdc_time_offsets -v $VARIATION -r ${RUN}-${RUN} tagh_tdc_timing_offsets.txt
    #ccdb add /TOF/adc_timing_offsets -v $VARIATION -r ${RUN}-${RUN} tof_adc_timing_offsets.txt
    ccdb add /BCAL/timewalk_tdc -v $VARIATION -r ${RUN}-${RUN} TimewalkBCAL.txt
#    ccdb add /PHOTON_BEAM/pair_spectrometer/fine/energy_corrections -v $VARIATION -r ${RUN}-${RUN} Eparms-TAGM.out
endif

# register output
echo ==register output files to SWIF==
swif outfile $RUN_OUTPUT_FILENAME file:${RUNDIR}/$RUN_OUTPUT_FILENAME
mkdir -p ${BASEDIR}/output/Run${RUN}/pass2/
swif outfile bcal_base_time.txt file:${BASEDIR}/output/Run${RUN}/pass2/bcal_base_time.txt
swif outfile cdc_base_time.txt file:${BASEDIR}/output/Run${RUN}/pass2/cdc_base_time.txt
swif outfile fcal_base_time.txt file:${BASEDIR}/output/Run${RUN}/pass2/fcal_base_time.txt
#swif outfile fdc_base_time.txt file:${BASEDIR}/output/Run${RUN}/pass2/fdc_base_time.txt
swif outfile sc_base_time.txt file:${BASEDIR}/output/Run${RUN}/pass2/sc_base_time.txt
swif outfile tagh_base_time.txt file:${BASEDIR}/output/Run${RUN}/pass2/tagh_base_time.txt
swif outfile tagm_base_time.txt file:${BASEDIR}/output/Run${RUN}/pass2/tagm_base_time.txt
swif outfile tof_base_time.txt file:${BASEDIR}/output/Run${RUN}/pass2/tof_base_time.txt
#swif outfile bcal_adc_timing_offsets.txt file:${BASEDIR}/output/Run${RUN}/pass2/bcal_adc_timing_offsets.txt
#swif outfile bcal_tdc_timing_offsets.txt file:${BASEDIR}/output/Run${RUN}/pass2/bcal_tdc_timing_offsets.txt
#swif outfile fcal_adc_timing_offsets.txt file:${BASEDIR}/output/Run${RUN}/pass2/fcal_adc_timing_offsets.txt
swif outfile sc_adc_timing_offsets.txt file:${BASEDIR}/output/Run${RUN}/pass2/sc_adc_timing_offsets.txt
swif outfile sc_tdc_timing_offsets.txt file:${BASEDIR}/output/Run${RUN}/pass2/sc_tdc_timing_offsets.txt
swif outfile tagm_adc_timing_offsets.txt file:${BASEDIR}/output/Run${RUN}/pass2/tagm_adc_timing_offsets.txt
swif outfile tagm_tdc_timing_offsets.txt file:${BASEDIR}/output/Run${RUN}/pass2/tagm_tdc_timing_offsets.txt
swif outfile tagh_adc_timing_offsets.txt file:${BASEDIR}/output/Run${RUN}/pass2/tagh_adc_timing_offsets.txt
swif outfile tagh_tdc_timing_offsets.txt file:${BASEDIR}/output/Run${RUN}/pass2/tagh_tdc_timing_offsets.txt
#swif outfile tof_adc_timing_offsets.txt file:${BASEDIR}/output/Run${RUN}/pass2/tof_adc_timing_offsets.txt
swif outfile BCALTimewalk_Results.root file:${BASEDIR}/output/Run${RUN}/pass2/BCALTimewalk_Results.root
swif outfile TimewalkBCAL.txt file:${BASEDIR}/output/Run${RUN}/pass2/TimewalkBCAL.txt
#swif outfile  file:${BASEDIR}/output/Run${RUN}/pass2/
#swif outfile Eparms-TAGM.out file:${BASEDIR}/output/Run${RUN}/pass2/ps_ecalib.txt
swif outfile pass2_CalorimeterTiming.png file:${BASEDIR}/output/Run${RUN}/pass2/pass2_CalorimeterTiming.png
swif outfile pass2_PIDSystemTiming.png file:${BASEDIR}/output/Run${RUN}/pass2/pass2_PIDSystemTiming.png
swif outfile pass2_TrackMatchedTiming.png file:${BASEDIR}/output/Run${RUN}/pass2/pass2_TrackMatchedTiming.png
swif outfile pass2_TaggerTiming.png file:${BASEDIR}/output/Run${RUN}/pass2/pass2_TaggerTiming.png
swif outfile pass2_TaggerRFAlignment.png file:${BASEDIR}/output/Run${RUN}/pass2/pass2_TaggerRFAlignment.png
swif outfile pass2_TaggerSCAlignment.png file:${BASEDIR}/output/Run${RUN}/pass2/pass2_TaggerSCAlignment.png


echo ==DEBUG==
ls -lhR

###################################################
## Cleanup

# generate CCDB SQLite for the next pass
echo ==regenerate CCDB SQLite file==
if ( $?CALIB_CCDB_SQLITE_FILE ) then
    cp ccdb.sqlite ${BASEDIR}/sqlite_ccdb/ccdb_pass2.${RUN}.sqlite
    #cp $CALIB_CCDB_SQLITE_FILE ${BASEDIR}/ccdb_pass2.sqlite
else
    $CCDB_HOME/scripts/mysql2sqlite/mysql2sqlite.sh -hhallddb.jlab.org -uccdb_user ccdb | sqlite3 ccdb_pass2.sqlite
    cp ccdb_pass2.sqlite ${BASEDIR}/sqlite_ccdb/ccdb_pass2.${RUN}.sqlite
endif

# Debug info
if ( $?CALIB_DEBUG ) then 
    echo ==ending CCDB info==
    python cat_ccdb_tables.py ccdb_tables_pass2
endif
