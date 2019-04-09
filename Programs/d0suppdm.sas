/*-------------------------------------------------------------------------------------------**
** PROGRAM:    D0SUPPDM.SAS
**
** CREATED:    NOVEMBER 2016
**
** PURPOSE:    CREATE SDTM SUPPDM DATASET
**
** PROGRAMMER: A.CHANG
**
** INPUT:      RAWLIB.DEMO
**
** OUTPUT:     SDTMLIB.SUPPDM
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
**  BRING IN ORIGINAL DEMOGRAPHICS DATA                                          **;
**-------------------------------------------------------------------------------**;

data suppdm (keep= studyid rdomain &pat qnam qlabel qval qorig) ;
	attrib
	    studyid  length = $8   label = 'Study Identifier                   '
		rdomain	 length = $2   label = 'Related Domain Abbreviation		   '
	    &pat  	 length = $16  label = 'Unique Subject Identifier          '
		qnam	 length = $8   label = 'Qualifier Variable Name 		   '
		qlabel	 length = $40  label = 'Qualifier Variable Label		   '
		qval	 length = $200 label = 'Data Value						   '
		qorig	 length = $10  label = 'Origin							   '
	    ;
	set rawlib.demo ;

	**-- ASSIGN REQUIRED SDTM VARIABLES --**;
	studyid = compress(proto) ;
	rdomain = 'DM' ;
	&pat = studyid || '-' || '0' || put(inv_no,2.) || '-' || put(patid,3.) ;
	
	**-- RACEOTH --**;
	qnam = 'RACEOTH' ;
	qlabel = 'Race, Other' ;
	if race = 'OTHER' then qval = raceoth ;
	qorig = pageno ;
run ;

**-------------------------------------------------------------------------------**;
**  OUTPUT SDTM DM DATASET							                             **;
**-------------------------------------------------------------------------------**;

options replace ;

proc sql ;
   create table sdtmlib.suppdm (label='Supplemental Qualifiers DM') as
      select studyid, rdomain, &pat, qnam, qlabel, qval, qorig
      from suppdm
      order by &pat ;
quit ;

options noreplace ;

title "CHECK SUPPLEMENTAL QUALIFIERS DM DATASET" ;
proc print data=sdtmlib.suppdm ;
	where &printme ;
run ;
title ;
