**-------------------------------------------------------------------------------------------**
** PROGRAM:    D2ADAE.SAS
**
** CREATED:    NOVEMBER 2016
**
** PURPOSE:    CREATE ANALYSIS DATASET ADAE
**
** PROGRAMMER: A.CHANG
**
** INPUT:      SDTM AE DATA, ADSL
**
** OUTPUT:     ADSLIB.ADAE
**
** PROTOCOL:   PROD-124
**
** MODIFIED:   DATE        BY          NOTE
**             ----------  ----------  -----------------------------------------------------
**
**-------------------------------------------------------------------------------------------**;

%include msetup;
%let printme = 1 ;

**-------------------------------------------------------------------------------**;
**  BRING IN AE AND DM SDTM DATA                                                 **;
**-------------------------------------------------------------------------------**;

data adae ;
	merge sdtmlib.ae (in=inae drop= domain studyid)
		  adslib.adsl ;
	by usubjid ;
	if inae ;
run ;

**-------------------------------------------------------------------------------**;
**  DERIVED VARIABLES FOR TABLE/LISTINGS 		                                 **;
**-------------------------------------------------------------------------------**;

data adae ;
	set adae ;
	
	**-- CONVERT CHARACTER DATE/TIME TO NUMERIC --**;
	if aestdtc ne '' then
		aestdtm = dhms(input(scan(aestdtc,1,'T'),YYMMDD10.)
					, input(scan(scan(aestdtc,2,'T'),1,':'),2.)
					, input(scan(scan(aestdtc,2,'T'),2,':'),2.)
					, 0) ;
	else aestdtm = . ;
	if aeendtc ne '' then
		aendtm = dhms(input(scan(aeendtc,1,'T'),YYMMDD10.)
					, input(scan(scan(aeendtc,2,'T'),1,':'),2.)
					, input(scan(scan(aeendtc,2,'T'),2,':'),2.)
					, 0) ;
	else aendtm = . ;
	format aestdtm aendtm datetime16. ;

	**-- CALCULATE AE DURATION --**;
	adurn = aendtm - aestdtm ;
	aduru = 'SECONDS' ;

	**-- ASEV AND AREL --**;
	asev = propcase(aesev) ;
	arel = propcase(aerel) ;

run ;

title 'CHECK DATE/TIME CONVERSION AND DURATIONS' ;
proc print data=adae ;
	var aestdtc aestdtm aeendtc aendtm adurn ;
	where &printme ;
run ;
title ;

**-------------------------------------------------------------------------------**;
**  OUTPUT FINAL DATA                                                            **;
**-------------------------------------------------------------------------------**;

options replace ;
proc sql;
   create table adslib.adae (label='Adverse Event Analysis Dataset ') as
   select studyid
      	, usubjid
   	    , subjid
     	, siteid
		, aeseq
		, aeterm
		, aedecod
		, aebodsys
		, aestdtc
		, aestdtm  label='Analysis Start Date/Time 				  	'
		, aeendtc
		, aendtm   label='Analysis End Date/Time 				  	'
		, trtsdtm  
		, adurn	   label='AE Duration (N)  				  		  	'
		, aduru    label='AE Duration Units  				  	  	'
		, aesevn
		, aesev
		, asev	   label='Analysis Severity/Intensity				'
		, aereln   
		, aerel    
		, arel     label='Analysis Causality 						'
		, aeacn
		, aeacnoth
		, aeser
   from adae
   order by usubjid ;
quit;
options noreplace;

title "CHECK ANALYSIS DATA" ;
proc print data=adslib.adae ;
	where &printme ;
run ;
title ;
