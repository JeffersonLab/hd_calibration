#!/bin/tcsh
# Do a first pass of calibrations for a given run

# initialize CCDB before running
cp ${BASEDIR}/ccdb_pass2.sqlite ccdb.sqlite
setenv JANA_CALIB_URL  sqlite:///`pwd`/ccdb.sqlite                # run jobs off of SQLite
if ( $?CALIB_CCDB_SQLITE_FILE ) then
    setenv CCDB_CONNECTION sqlite:///$CALIB_CCDB_SQLITE_FILE
else
    setenv CCDB_CONNECTION mysql://ccdb_user@hallddb.jlab.org/ccdb    # save results in MySQL
endif
setenv JANA_CALIB_CONTEXT "variation=calib_pass3" 

# Debug info
if ( $?CALIB_DEBUG ) then 
    echo ==starting CCDB info==
    python cat_ccdb_tables.py ccdb_tables_pass3
endif

###################################################

# set some general variables
set RUNDIR=${BASEDIR}/output/Run${RUN}

# merge results of per-file processing
setenv RUN_OUTPUT_FILENAME hd_calib_pass3_Run${RUN}.root
echo ==summing ROOT files==
hadd -f -k $RUN_OUTPUT_FILENAME  ${RUNDIR}/*/hd_calib_pass3_*.root

# process the results
echo ==first pass calibrations==
python run_calib_pass3.py $RUN_OUTPUT_FILENAME

# update CCDB
echo ==update CCDB==
ccdb add /PHOTON_BEAM/hodoscope/tdc_timewalk -v calib_pass3 -r ${RUN}-${RUN} tdc_timewalk.txt
ccdb add /PHOTON_BEAM/microscope/tdc_timewalk_corrections -v calib_pass3 -r ${RUN}-${RUN} tagm_tw_parms.out

# register output
echo ==register output files to SWIF==
swif outfile $RUN_OUTPUT_FILENAME file:${RUNDIR}/$RUN_OUTPUT_FILENAME
mkdir -p ${BASEDIR}/output/Run${RUN}/pass3/
#swif outfile ${HLTIMING_CONST_DIR}/bcal_base_time.txt file:${BASEDIR}/output/Run${RUN}/pass3/bcal_base_time.txt
foreach MODULE (`seq 1 48`)
    set MODULE_FILENAME="pass3_BCAL_gainratios_module${MODULE}.png"
    swif outfile ${MODULE_FILENAME} file:file:${BASEDIR}/output/Run${RUN}/pass3/${MODULE_FILENAME}
end
swif outfile tdc_timewalk.txt file:${BASEDIR}/output/Run${RUN}/pass3/tagh_tdc_timewalk.txt
swif outfile gaussian-fits-csv file:${BASEDIR}/output/Run${RUN}/pass3/gaussian-fits-csv
swif outfile tagm_tw_parms.out file:${BASEDIR}/output/Run${RUN}/pass3/tagm_tdc_timewalk.txt
swif outfile sigmas.out file:${BASEDIR}/output/Run${RUN}/pass3/tagm_sigmas_twcorr.txt
swif outfile results.root file:${BASEDIR}/output/Run${RUN}/pass3/tagm_results_twcorr.txt

###################################################
## Cleanup

# generate CCDB SQLite for the next pass
==regenerate CCDB SQLite file==
if ( $?CALIB_CCDB_SQLITE_FILE ) then
    cp $CALIB_CCDB_SQLITE_FILE ${BASEDIR}/ccdb_pass3.sqlite
else
    $CCDB_HOME/scripts/mysql2sqlite/mysql2sqlite.sh -hhallddb.jlab.org -uccdb_user ccdb | sqlite3 ccdb_pass3.sqlite
    cp ccdb_pass3.sqlite ${BASEDIR}/ccdb_pass3.sqlite
endif

# Debug info
if ( $?CALIB_DEBUG ) then 
    echo ==ending CCDB info==
    python cat_ccdb_tables.py ccdb_tables_pass3
endif
