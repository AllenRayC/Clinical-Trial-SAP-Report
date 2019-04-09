**-------------------------------------------------------------------------------------------**
** PROGRAM:    D2ADVS.SAS
**
** CREATED:    NOVEMBER 2016
**
** PURPOSE:    CREATE ANALYSIS DATASET ADVS
**
** PROGRAMMER: A.CHANG
**
** INPUT:      SDTM VS DATA, ADSL
**
** OUTPUT:     ADSLIB.ADVS
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
**  BRING IN SDTM DATA                                                           **;
**-------------------------------------------------------------------------------**;

data advs ;
	merge sdtmlib.vs (in=invs drop= studyid)
		  adslib.adsl ;
	by usubjid ;
	if invs ;
run ;

**-------------------------------------------------------------------------------**;
**  DERIVED VARIABLES FOR TABLE/LISTINGS DISPLAY                                 **;
**-------------------------------------------------------------------------------**;

data advs ;
	set advs ;

	length vtpt $40 ;
		 if vstpt = 'SCREENING & BASELINE' then vtpt = 'Screening' ;
	else if vstpt = '-5 min' or vstpt = '0 min' then vtpt = vstpt ;
	else if vstpt = '1 HOUR AFTER INFUSION PERIOD #2' then vtpt = '+105 min' ;
	else if vstpt = 'STUDY DAY 2' then vtpt = 'Study Day 2' ;
	else vtpt = '+' || vstpt ;

	length vstresc $10 ;
	vstresc = trim(left(put(vsstresn,5.1))) ;

run ;

**-------------------------------------------------------------------------------**;
**  CALCULATE CHANGE IN BASELINE AND ASSIGN CLINICALLY SIGNIFICANT FLAG          **;
**-------------------------------------------------------------------------------**;

**-- ADD BASELINE VALUE --**;
proc sort data=advs (where=(vsblfl='Y'))
		  out=bl (keep = usubjid vstestcd vsstresn rename=(vsstresn=vsbl)) ;
	by usubjid vstestcd ;
run ;

proc sort data=advs ;
	by usubjid vstestcd ;
run ;

data advs ;
	merge advs (in=invs)
		  bl ;
	by usubjid vstestcd ;
	if invs ;
run ;

proc sort data=advs ;
	by usubjid vsseq ;
run ;

**-- CALCULATE CHANGE IN BASELINE --**;
data advs ;
	set advs ;

	length vschgblc $10 ;
	if vtpt in ('Screening','-5 min','0 min') then
		do ;
			vschgbl = . ;
			vschgblc = 'n/a' ;	
		end ;
	else
		do ;
			vschgbl = vsstresn - vsbl ;
			vschgblc = trim(left(put(vschgbl,5.1))) ;
		end ;

run ;

**-- ASSIGN CLINICAL IMPORTANCE FLAG --**;
data advs ;
	set advs ;
	if vschgblc ne 'n/a' then
		do ;
			if vstestcd='SYSBP' then
				do ;
						 if vsstresn gt 200 and vschgbl ge 20 then clinsig='I' ;
					else if vsstresn lt 90 and vschgbl le -20 then clinsig='D' ;
				end ;
			else if vstestcd='DIABP' then
				do ;
						 if vsstresn gt 120 and vschgbl ge 10 then clinsig='I' ;
					else if vsstresn lt 60 and vschgbl le -10 then clinsig='D' ;
				end ;
			else if vstestcd = 'OXYSAT' then
				do ;
					if vsstresn lt 90 and vschgbl le -5 then clinsig='D' ;
				end ;

			else if vstestcd='PULSE' then
				do ;
						 if vsstresn gt 120 and vschgbl ge 10 then clinsig='I' ;
					else if vsstresn lt 45 and vschgbl le -10 then clinsig='D' ;
				end ;
		end ;

		if clinsig in ('I','D') then vschgblc = trim(left(put(vschgbl,5.1))) || clinsig ;
run ;

**-------------------------------------------------------------------------------**;
**  OUTPUT FINAL DATA                                                            **;
**-------------------------------------------------------------------------------**;

options replace ;
proc sql;
   create table adslib.advs (label='Vital Signs Analysis Dataset') as
   select studyid		
      	, usubjid
   	    , subjid
     	, siteid
		, country
        , age
        , sex
        , race
		, arm
		, armcd
		, trt01p
		, trt01pn
	    , saffl
		, fasfl
		, visitnum		
		, visit
		, vsdtc
		, vsseq
		, vstpt
		, vtpt	   label='Analysis Planned Time Point Name		  ' 
		, vstestcd
		, vstest
		, vsorres
		, vsorresu
		, vsstresc
		, vsstresn
		, vstresc  label='Analysis Character Result/Finding		  '						
		, vsstresu
		, vsblfl
		, vsbl	   label='Baseline Value						  ' 
		, vschgbl  label='Analysis Change from Baseline (N)		  ' 
		, vschgblc label='Analysis Change from Baseline 		  ' 
		, clinsig  label='Clinically Significant Flag			  '
   from advs
   order by usubjid, vsseq ;
quit;
options noreplace;

title "CHECK ANALYSIS DATA" ;
proc print data=adslib.advs ;
	where &printme ;
run ;
title ;
