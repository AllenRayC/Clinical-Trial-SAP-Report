/*-------------------------------------------------------------------------------------------**
** PROGRAM:    D0VS.SAS
**
** CREATED:    NOVEMBER 2016
**
** PURPOSE:    CREATE SDTM VS DATASET
**
** PROGRAMMER: A.CHANG
**
** INPUT:      RAWLIB.VITAL, RAWLIB.VITALTPT
**
** OUTPUT:     SDTMLIB.VS
**
** PROTOCOL:   PROD-124
**
** MODIFIED:   DATE        BY         NOTE
**             ---------- ---------- -----------------------------------------
**
**-------------------------------------------------------------------------------------------**
** PROGRAMMED USING SAS VERSION 9.3                                                          **
**-------------------------------------------------------------------------------------------**/

%include msetup ;
%let printme = 1 ;

**-------------------------------------------------------------------------------**;
**  BRING IN ORIGINAL VITAL SIGNS DATA                                           **;
**-------------------------------------------------------------------------------**;

data vs (drop= inv_no patid proto seq vstptm) ;
	attrib
		studyid  length = $8   label = 'Study Identifier                   			'
		domain	 length = $2   label = 'Domain Abbreviation				   			'
	    &pat  	 length = $16  label = 'Unique Subject Identifier        			'
		visitnum length = 3	   label = 'Visit Number					   			'
		visit 	 length = $12  label = 'Visit Name						   			'
		vstpt 	 length = $40  label = 'Planned Time Point Name						'
	    ;
	set rawlib.vital (in=a drop= pageno e_stat weightun heightun)
		rawlib.vitaltpt (in=b rename=(vstacttm=vsacttm) drop= pageno e_stat) ;

	**-- ASSIGN REQUIRED SDTM VARIABLES --**;
	studyid = proto ;
	domain = 'VS' ;
	&pat = studyid || '-' || '0' || put(inv_no,2.) || '-' || put(patid,3.) ;

	**-- ASSIGN VSTPT, VISIT AND VISITNUM --**;
	if a then
		do ;
			if visit = 'STUDY DAY 1' then 
				do ;
					vstpt = 'SCREENING & BASELINE' ;
					visitnum = 1 ;
				end ;
			else if visit = 'STUDY DAY 2' then 
				do ;
					vstpt = 'STUDY DAY 2' ;
					visitnum = 2 ;
				end ;
		end ;
	if b then 
		do ;
			vstpt = vstptm ;
			visitnum = 1 ;
			visit = 'STUDY DAY 1' ;
			tptfl = 'Y' ;
		end ;
run ;

proc sort data=vs ;
	by usubjid visitnum vsacttm ;
run ;

data vs (drop= date tptfl vsacttm vsdt) ;
	attrib		
		vsdtc	 length = $30  label = 'Date/Time of Measurements		   			'
	    ;
	set vs ;

	**-- ASSIGN STUDY DAY 1 DATE TO VITALTPT DATA --**;
	retain date . ;
	if vstpt = 'SCREENING & BASELINE' then date = vsdt ;
	if tptfl = 'Y' then vsdt = date ;

	**-- COMBINE VISIT DATE/TIME IN ISO 8601 FORMAT --**;
	vsdtc = put(vsdt,yymmdd10.) || 'T' || put(vsacttm,tod5.2) ;
run ;

**-------------------------------------------------------------------------------**;
**  RESTRUCTURE VITAL SIGNS DATA (ONE RECORD FOR EACH TEST RESULT)               **;
**-------------------------------------------------------------------------------**;

data vs (keep= studyid domain &pat visitnum visit vsdtc vsseq vstpt vstestcd vstest vsorres vsorresu vsstresc vsstresn vsstresu) ;
	attrib
		vsseq    length = 3    label = 'Sequence Number                    			'
		vstestcd length = $8   label = 'Vital Signs Test Short Name		   			'
	    vstest   length = $40  label = 'Vital Signs Test Name	           			'
		vsorres  length = $20  label = 'Result or Finding in Original Units			'
		vsorresu length = $20  label = 'Original Units	           		   			'
		vsstresc length = $10  label = 'Character Result/Finding in Std Format	 	'
		vsstresn length = 8    label = 'Numeric Result/Finding in Standard Units	'
		vsstresu length = $20  label = 'Standard Units	           					'
	    ;
	set vs ;
	by usubjid ;

	if first.usubjid then vsseq = 0 ;

	** OUTPUT FOR PULSE **;
	vsseq + 1 ;
	vstestcd = 'PULSE' ;
	vstest = 'Pulse Rate' ;
	vsorres = put(heart,3.) ;
	vsorresu = 'BEATS/MIN' ;
	vsstresc = put(heart,3.) ;
	vsstresn = heart ;
	vsstresu = 'BEATS/MIN' ;
	if vsorres ne '' then output ;

	** OUTPUT FOR SYSBP **;
	vsseq + 1 ;
	vstestcd = 'SYSBP' ;
	vstest = 'Systolic Blood Pressure' ;
	vsorres = put(sysbp,3.) ;
	vsorresu = 'mmHG' ;
	vsstresc = put(sysbp,3.) ;
	vsstresn = sysbp ;
	vsstresu = 'mmHG' ;
	if vsorres ne '' then output ;

	** OUTPUT FOR DIABP **;
	vsseq + 1 ;
	vstestcd = 'DIABP' ;
	vstest = 'Diastolic Blood Pressure' ;
	vsorres = put(diabp,3.) ;
	vsorresu = 'mmHG' ;
	vsstresc = put(diabp,3.) ;
	vsstresn = diabp ;
	vsstresu = 'mmHG' ;
	if vsorres ne '' then output ;

	** OUTPUT FOR OXYSAT **;
	vsseq + 1 ;
	vstestcd = 'OXYSAT' ;
	vstest = 'Oxygen Saturation' ;
	vsorres = put(o2sat,3.) ;
	vsorresu = '%' ;
	vsstresc = put(o2sat,3.) ;
	vsstresn = o2sat ;
	vsstresu = '%' ;
	if vsorres ne '' then output ;

	** OUTPUT FOR RESP **;
	vsseq + 1 ;
	vstestcd = 'RESP' ;
	vstest = 'Respiratory Rate' ;
	vsorres = put(resp,3.) ;
	vsorresu = 'BREATHS/MIN' ;
	vsstresc = put(resp,3.) ;
	vsstresn = resp ;
	vsstresu = 'BREATHS/MIN' ;
	if vsorres ne '' then output ;

	** OUTPUT FOR TEMP **;
	vsseq + 1 ;
	vstestcd = 'TEMP' ;
	vstest = 'Temperature' ;
	vsorres = put(temp,5.1) ;
	vsorresu = 'F' ;
	vsstresc = put(temp,5.1) ;
	vsstresn = temp ;
	vsstresu = 'F' ;
	if vsorres ne '' then output ;

	** OUTPUT FOR WEIGHT **;
	vsseq + 1 ;
	vstestcd = 'WEIGHT' ;
	vstest = 'Weight' ;
	vsorres = put(weight,6.2) ;
	vsorresu = 'KG' ;
	vsstresc = put(weight,6.2) ;
	vsstresn = weight ;
	vsstresu = 'KG' ;
	if vsorres ne '' then output ;

	** OUTPUT FOR HEIGHT **;
	vsseq + 1 ;
	vstestcd = 'HEIGHT' ;
	vstest = 'Height' ;
	vsorres = put(height,5.1) ;
	vsorresu = 'IN' ;
	vsstresc = put(height,5.1) ;
	vsstresn = height ;
	vsstresu = 'IN' ;
	if vsorres ne '' then output ;

run ;

**-------------------------------------------------------------------------------**;
**  CREATE BASELINE FLAG (VSBLFL)					                             **;
**-------------------------------------------------------------------------------**;

** NOTE: BASELINE WAS TAKEN TO BE VITALS RECORDED AT 0 MINS OR THE LAST		**;
** 	     MEASUREMENT PRIOR TO 0 MINS.				 						**;

proc sort data=vs
		  out = vsfl ;
	by usubjid vstestcd vsseq ;
	where vstpt in ('SCREENING & BASELINE', '-5 min', '0 min') and vsorres ne '' ;
run ;

data vsfl ;
	attrib
		vsblfl  length = $1   label = 'Baseline Flag                   			'
	    ;
	set vsfl ;
	by usubjid vstestcd vsseq ;
	if last.vstestcd then vsblfl = 'Y' ;
run ;

proc sort data=vs ;
	by usubjid vstestcd vsseq ;
run ;

data vs ;
	merge vs
		  vsfl (keep= usubjid vstestcd vsseq vsblfl) ;
	by usubjid vstestcd vsseq ;
run ;

proc sort data=vs ;
	by usubjid vsseq ;
run ;

**-------------------------------------------------------------------------------**;
**  OUTPUT SDTM VS DATASET							                             **;
**-------------------------------------------------------------------------------**;

options replace ;

proc sql ;
   create table sdtmlib.vs (label='Vital Signs') as
      select studyid, domain, &pat, visitnum, visit, vsdtc, vsseq, vstpt, vstestcd, vstest
		   , vsorres, vsorresu, vsstresc, vsstresn, vsstresu, vsblfl
      from vs
      order by &pat, visitnum, vsseq ;
quit ;

options noreplace ;

title "CHECK VITAL SIGNS SDTM DATASET" ;
proc print data=sdtmlib.vs ;
	where &printme ;
run ;
title ;
