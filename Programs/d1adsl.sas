**-------------------------------------------------------------------------------------------**
** PROGRAM:    D1ADSL.SAS
**
** CREATED:    NOVEMBER 2016
**
** PURPOSE:    CREATE ANALYSIS DATASET ADSL
**
** PROGRAMMER: A.CHANG
**
** INPUT:      SDTM DATA
**
** OUTPUT:     ADSLIB.ADSL
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
**  BRING IN DM SDTM DATA                                                        **;
**-------------------------------------------------------------------------------**;

data adsl ;
	merge sdtmlib.dm (in=indm)
		  sdtmlib.suppdm ;
	by usubjid studyid ;
	if indm ;
run ;

**-------------------------------------------------------------------------------**;
**  DERIVED VARIABLES FOR TABLE/LISTINGS DISPLAY                                 **;
**-------------------------------------------------------------------------------**;

data adsl ;
	set adsl ;

	length trt01p $20 ;
		 if armcd eq '1' then trt01pn = 1 ;
	else if armcd eq '2' then trt01pn = 2 ;
		 if trt01pn eq 1 then trt01p = 'Cohort 1' ;
	else if trt01pn eq 2 then trt01p = 'Cohort 2' ;
		
	length sexgr1 $6 ;
	if sex eq 'M' then
		do ;
			sexgr1n = 1 ;
			sexgr1 = 'Male' ;
		end ;
	else if sex eq 'F' then
		do ;
			sexgr1n = 2 ;
			sexgr1 = 'Female' ;
		end ;
	else put "WARN" "ING: UNEXPECTED SEX " sex= ;

	length racegr1 $30 ;
	racegr1 = propcase(race) ;
		 if race eq 'CAUCASIAN' then racegr1n = 1 ;
	else if race eq 'BLACK' then racegr1n = 2 ;
	else if race eq 'HISPANIC' then racegr1n = 3 ;
	else if race eq 'ASIAN' then racegr1n = 4 ;
	else if race eq 'OTHER' then 
		do ;
			racegr1n = 5 ;
			race = 'OTHER, ' || trim(qval) ;
		end ;
	else put "WARN" "ING: UNEXPECTED RACE " race= ;

run ;

**-------------------------------------------------------------------------------**;
**  BRING IN TRTSDT AND TRTEDT													 **;
**-------------------------------------------------------------------------------**;

proc sort data=rawlib.vital
		  out=vs (keep= inv_no patid proto vsdt);
	by patid vsdt ;
run ;

data vs (keep= usubjid vsdt) ;
	set vs ;
	by patid vsdt ;
	length &pat $16 ;
	&pat = compress(proto) || '-' || '0' || put(inv_no,2.) || '-' || put(patid,3.) ;
	if first.patid ;
run ;

data adsl ;
	merge adsl (in=insl)
		  vs (rename=(vsdt=trtsdt));
	by usubjid ;
	trtedt = trtsdt ;
	format trtsdt trtedt date9. ;
	if insl ;
run ;

**-------------------------------------------------------------------------------**;
**  BRING IN PROD ADMINISTRATION TIME					  						 **;
**-------------------------------------------------------------------------------**;

proc sort data=sdtmlib.vs (where=(vstpt = '0 min')) nodupkey
		  out=vs (keep= usubjid vsdtc) ;
	by usubjid ;
run ;

data adsl ;
	merge adsl (in=insl) 
		  vs (rename=(vsdtc=trtsdtmc));
	by usubjid ;

	if trtsdtmc ne '' then
		trtsdtm = dhms(input(scan(trtsdtmc,1,'T'),YYMMDD10.)
					, input(scan(scan(trtsdtmc,2,'T'),1,':'),2.)
					, input(scan(scan(trtsdtmc,2,'T'),2,':'),2.)
					, 0) ;
	else trtsdtm = . ;

	format trtsdtm datetime16. ;
	if insl ;
run ;

**-------------------------------------------------------------------------------**;
**  BRING IN BASELINE WEIGHT AND HEIGHT (ONLY COLLECTED ONCE)					 **;
**-------------------------------------------------------------------------------**;

data weight ;
   set sdtmlib.vs (where=(vstestcd='WEIGHT' and vsblfl='Y')) ;
run ;

data height ;
   set sdtmlib.vs (where=(vstestcd='HEIGHT' and vsblfl='Y')) ;
run ;

data adsl ;
   merge adsl (in=insl) 
		 weight (keep=usubjid vsstresn rename=(vsstresn=weight))
		 height (keep=usubjid vsstresn rename=(vsstresn=height)) ;
   by usubjid ;
   if insl ;
run ;

**-------------------------------------------------------------------------------**;
**  CREATE SAFETY POPULATION FLAG						                         **;
**-------------------------------------------------------------------------------**;

data ex ;
	set rawlib.exposure (where=(proddose ne .)) ;
	length &pat $16 ;
	&pat = compress(proto) || '-' || '0' || put(inv_no,2.) || '-' || put(patid,3.) ;
run ;

proc sort data=ex nodupkey ;
	by usubjid ;
run ;

title 'CHECK EX DATA' ;
proc print data=ex ;
	var usubjid proddose ;
	where &printme ;
run ;
title ;

data adsl (drop= proddose) ;
	merge adsl (in=insl)
	      ex (keep=usubjid proddose) ;
	by usubjid ;
	if proddose ne . then saffl = 'Y' ;
	else saffl = 'N' ;
	if insl ;
run ;

**-------------------------------------------------------------------------------**;
**  EVALUABLE POPULATION                                                         **;
**-------------------------------------------------------------------------------**;

** NOTE: POPULATION	THAT DID NOT HAVE ANY OF THE BELOW PROTOCOL DEVIATIONS	**;
** 	     	reascd=1 : Entrance Criteria not met  							**;
** 	     	reascd=2 : PROD not administered fully							**;
** 	     	reascd=3 : Images not obtained									**;
** NOTE: USED FASFL (FULL ANALYSIS SET POPULATION FLAG) PER ADAMIG v1.1		**;

data ts ;
	set rawlib.summary (where=(reascd not in (1,2,3))) ;
	length &pat $16 ;
	&pat = compress(proto) || '-' || '0' || put(inv_no,2.) || '-' || put(patid,3.) ;
run ;

proc sort data=ts nodupkey ;
	by usubjid ;
run ;

data adsl ;
	merge adsl (in=insl)
	      ts (in=ints keep= usubjid) ;
	by usubjid ;
	if ints then fasfl = 'Y' ;
	else fasfl = 'N' ;
	if insl ;
run ;

title 'CHECK FASFL' ;
proc print data=adsl ;
	var usubjid fasfl ;
	where &printme ;
run ;
title ;

**-------------------------------------------------------------------------------**;
**  OUTPUT FINAL DATA                                                            **;
**-------------------------------------------------------------------------------**;

options replace ;
proc sql;
   create table adslib.adsl (label='Subject Level Analysis Dataset') as
   select studyid
      	, usubjid
   	    , subjid
		, country
		, siteid
		, rfstdtc
		, trtsdt   label='Date of First Exposure to Treatment     '
	    , trtedt   label='Date of Last Exposure to Treatment	  '
 		, trtsdtm  label='Datetime of First Exposure to Treatment '
		, brthdtc
        , age
        , ageu
        , sex
		, sexgr1   label='Pooled Sex Group 1					  '
		, sexgr1n  label='Pooled Sex Group 1 (N)				  '
        , race
		, racegr1  label='Pooled Race Group 1					  '
		, racegr1n label='Pooled Race Group 1 (N)				  '
		, arm
		, armcd
		, trt01p   label='Planned Treatment for Period 01		  '
		, trt01pn  label='Planned Treatment for Period 01 (N)	  '
        , weight   label='Baseline Weight (kg)                    '
        , height   label='Baseline Height (cm)                    '
	    , saffl	   label='Safety Population Flag 				  '
		, fasfl	   label='Full Analysis Set Population Flag		  ' 
   from adsl
   order by usubjid ;
quit;
options noreplace;

title "CHECK ANALYSIS DATA" ;
proc print data=adslib.adsl ;
   where &printme ;
run ;
title ;
