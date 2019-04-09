/*-------------------------------------------------------------------------------------------**
** PROGRAM:    D0AE.SAS
**
** CREATED:    NOVEMBER 2016
**
** PURPOSE:    CREATE SDTM AE DATASET
**
** PROGRAMMER: A.CHANG
**
** INPUT:      RAWLIB.AE
**
** OUTPUT:     SDTMLIB.AE
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
**  BRING IN ORIGINAL ADVERSE EVENTS DATA                                        **;
**-------------------------------------------------------------------------------**;

proc sort data=rawlib.ae
		  out=ae ;
	by patid seq ;
	where aeterm ne '' ;
run ;

** NOTE: THERE IS A DATA ISSUE IN RAWLIB.AE WHERE AEANYCD=0 BUT THERE IS	**;
** 	     	AN AE RECORDED. DECIDED TO INCLUDE THIS OBS BY SUBSETTING		**;
**			USING AETERM RATHER THAN AEANYCD. (PATID = 115)					**;

data ae (keep= studyid domain &pat aeseq aeterm aedecod aebodsys aesevn aesev aereln aerel aestdtc aeendtc aeacn aeacnoth aeser) ;
	attrib
	    studyid  length = $8   label = 'Study Identifier                 	  '
		domain	 length = $2   label = 'Domain Abbreviation				 	  '
	    &pat  	 length = $16  label = 'Unique Subject Identifier        	  '
		aeseq	 length = 3	   label = 'Sequence Number					   	  '
		aeterm   length = $120 label = 'Reported Term for the Adverse Event	  '
		aedecod  length = $100 label = 'Dictionary-Derived Term               '
		aebodsys length = $100 label = 'Body System or Organ Class			  '
		aesevn   length = 3	   label = 'Severity/Intensity (N) 				  '
		aesev	 length = $20  label = 'Severity/Intensity	  				  '
		aereln   length = 3    label = 'Causality (N) 						  '
		aerel    length = $20  label = 'Causality			  				  '
		aestdtc	 length = $30  label = 'Start Date/Time of Adverse Event	  '
		aeendtc  length = $30  label = 'End Date/Time of Adverse Event		  '
		aeacn    length = $20  label = 'Action Taken with Study Treatment     '
		aeacnoth length = $20  label = 'Other Action Taken 					  '
		aeser    length = $1   label = 'Serious Event						  '
	    ;
	set ae (rename=(seq=aeseq aesoc=aebodsys aesevcd=aesevn aerelcd=aereln) drop= pageno e_stat aeanycd);

	**-- ASSIGN REQUIRED SDTM VARIABLES --**;
	studyid = compress(proto) ;
	domain = 'AE' ;
	&pat = studyid || '-' || '0' || put(inv_no,2.) || '-' || put(patid,3.) ;

	**-- MAP AESEV ACCORDING TO CRF --**;
		 if aesevn = 1 then aesev = 'MILD' ;
	else if aesevn = 2 then aesev = 'MODERATE' ;
	else if aesevn = 3 then aesev = 'SEVERE' ;
	else if aesevn = 4 then aesev = 'LIFE-THREATENING' ;
	else put "WARN" "ING: UNEXPECTED AESEVCD " aesevn= ;

	**-- MAP AEREL ACCORDING TO CRF --**;
		 if aereln = 1 then aerel = 'UNRELATED' ;
	else if aereln = 2 then aerel = 'POSSIBLY' ;
	else if aereln = 3 then aerel = 'PROBABLY' ;
	else if aereln = 4 then aerel = 'DEFINITELY' ;
	else put "WARN" "ING: UNEXPECTED AERELCD " aereln= ;

	**-- AESTDTC, AEENDTC IN ISO8601 --**;
	aestdtc = put(aestdt,yymmdd10.) || 'T' || put(aesttm,tod5.2) ;
	aeendtc = put(aeendt,yymmdd10.) || 'T' || put(aeentm,tod5.2) ;

	**-- AEACN, AEACNOTH, AESER --**;
	
	if aetxcd = 1 then aeacnoth = 'Treatment' ;

	if aeprencd = 2 and aeacnoth = '' then 
		do ;
			aeacn = 'DRUG WITHDRAWN' ;
			aeacnoth = 'PROD stopped' ;
		end ;
	else if aeprencd = 2 and aeacnoth ne '' then 
		do ;
			aeacn = 'DRUG WITHDRAWN' ;
			aeacnoth = aeacnoth || ', ' || 'PROD stopped' ;
		end ;

		 if aedccd = 3 and aeacnoth = '' then aeacnoth = 'Discontinued trial' ;
	else if aedccd = 3 and aeacnoth ne '' then aeacnoth = aeacnoth || ', ' || 'Discontinued trial' ;

		 if aesercd = . then aeser = 'N' ;
	else if aesercd = 4 and aeacnoth = '' then
		do ;
			aeacnoth = 'SAE Reported' ;
			aeser = 'Y' ;
		end ;
	else if aesercd = 4 and aeacnoth ne '' then
		do ;
			aeacnoth = aeacnoth || ', ' || 'SAE Reported' ;
			aeser = 'Y' ;
		end ;

	if aenoatcd = 0 then 
		do ;
			if aeacnoth ne '' then put "WARN" "ING: CHECK ACTIONS TAKEN AE DATA." ;
			aeacnoth = 'None' ;
		end ;

run ;

**-------------------------------------------------------------------------------**;
**  OUTPUT SDTM AE DATASET							                             **;
**-------------------------------------------------------------------------------**;

options replace ;

proc sql ;
   create table sdtmlib.ae (label='Adverse Events') as
      select studyid, domain, &pat, aeseq, aeterm, aedecod, aebodsys, aesevn, aesev
		   , aereln, aerel, aestdtc, aeendtc, aeacn, aeacnoth, aeser
      from ae
      order by &pat ;
quit ;

options noreplace ;

title "CHECK ADVERSE EVENTS SDTM DATASET" ;
proc print data=sdtmlib.ae ;
	where &printme ;
run ;
title ;
