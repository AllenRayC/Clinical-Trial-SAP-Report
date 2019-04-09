/*-------------------------------------------------------------------------------------------**
** PROGRAM:    D0DM.SAS
**
** CREATED:    NOVEMBER 2016
**
** PURPOSE:    CREATE SDTM DM DATASET
**
** PROGRAMMER: A.CHANG
**
** INPUT:      RAWLIB.DEMO
**
** OUTPUT:     SDTMLIB.DM
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

** NOTE: MODIFIED MAGE.SAS IN ORDER TO DISPLAY AGE TO THE TENTH		**;
** 	     DECIMAL PLACE AS REQUIRED BY MOCKUPS 						**;

data dm (keep= studyid domain &pat subjid country rfstdtc rfendtc siteid brthdtc age ageu sex race) ;
	attrib
	    studyid  length = $8   label = 'Study Identifier                   '
		domain	 length = $2   label = 'Domain Abbreviation				   '
	    &pat  	 length = $16  label = 'Unique Subject Identifier          '
	    subjid   length = $7   label = 'Subject Identifier for the Study   '
		country  length = $3   label = 'Country							   '
		rfstdtc  length = $10  label = 'Subject Reference Start Date/Time  '
		rfendtc  length = $10  label = 'Subject Reference End Date/Time    '
		siteid   length = $3   label = 'Study Site Identifier              '
	    brthdtc  length = $10  label = 'Date/Time of Birth                 '
	    age      length = 3    label = 'Age                                '
	    ageu     length = $5   label = 'Age Units                          '
	    sex      length = $1   label = 'Sex                                '
	    race     length = $30  label = 'Race                               '
	    ;
	set rawlib.demo ;

	**-- ASSIGN REQUIRED SDTM VARIABLES --**;
	studyid = compress(proto) ;
	domain = 'DM' ;
	siteid = '0' || put(inv_no,2.) ;
	subjid = siteid || '-' || put(patid,3.) ;
	&pat = studyid || '-' || subjid ;
	rfstdtc = put(icdt,mmddyy10.) ;
	rfendtc = put(icdt,mmddyy10.) ;

	**-- SET COUNTRY --**;
	country = 'USA' ;

	**-- DERIVE AGE --**;
	brthdtc = put(birthdt,mmddyy10.) ;
	%mage(indate=icdt,dobvar=birthdt)
	*agechk = (icdt-birthdt)/365.25 ;
	ageu = 'YEARS' ;

run ;

**-------------------------------------------------------------------------------**;
**  MERGE WITH ARM AND ARMCD FROM EXPOSURE DATASET            		             **;
**-------------------------------------------------------------------------------**;

data ex ;
	set rawlib.exposure ;
	length &pat $16 ;
	&pat = compress(proto) || '-' || '0' || put(inv_no,2.) || '-' || put(patid,3.) ;
run ;

proc sort data=ex nodupkey 
		  out=ex (keep= usubjid cohort);
	by &pat ;
run ;

data dm (drop= cohort) ;
	attrib
	    armcd  length = $1   label = 'Planned Arm Code                   '
		arm	   length = $60   label = 'Description of Planned Arm	     '
	    ;
	merge dm (in=indm)
		  ex ;
	by &pat ;
	armcd = put(cohort,1.) ;
		 if armcd = '1' then arm = 'Bag in Infusion 1 / Bottle in Infusion 2' ;
	else if armcd = '2' then arm = 'Bottle in Infusion 1 / Bag in Infusion 2' ;
	if indm ;
run ;

**-------------------------------------------------------------------------------**;
**  OUTPUT SDTM DM DATASET							                             **;
**-------------------------------------------------------------------------------**;

options replace ;

proc sql ;
   create table sdtmlib.dm (label='Demography') as
      select studyid, domain, &pat, subjid, country, rfstdtc, rfendtc, siteid
		   , brthdtc, age, ageu, sex, race, armcd, arm
      from dm
      order by &pat ;
quit ;

options noreplace ;

title "CHECK DEMOGRAPHY SDTM DATASET" ;
proc print data=sdtmlib.dm ;
	where &printme ;
run ;
title ;
