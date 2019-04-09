**-------------------------------------------------------------------------------------------**
** PROGRAM:    LAE.SAS
**
** CREATED:    NOVEMBER 2016
**
** PURPOSE:    CREATE ADVERSE EVENTS LISTING 6 - ADVERSE EVENTS
**
** PROGRAMMER: A.CHANG
**
** INPUT:      ADAE, ADSL DATA
**
** OUTPUT:     LISTING 6
**
** PROTOCOL:   PROD-124
**
** MODIFIED:   DATE        BY          NOTE
**             ----------  ----------  -----------------------------------------------------
**
**-------------------------------------------------------------------------------------------**;

%include msetup ;
%let printme = 1 ;

**-------------------------------------------------------------------------------**;
**  BRING IN ADAE DATA                                             		         **;
**-------------------------------------------------------------------------------**;

data ae ;
	merge adslib.adae (in=inae)
		  adslib.adsl ;
	by usubjid ;
	if inae ;
run ;

**-------------------------------------------------------------------------------**;
**  DERIVE VARIABLES FOR LISTING DISPLAY                                		 **;
**-------------------------------------------------------------------------------**;

data ae ;
	set ae ;

	**-- ONSET TIME --**;
	asttm = substr(aestdtc,12,5) ;

	**-- DERIVE ONSET TIME RELATIVE TO PROD ADMINISTRATION --**;
	** NOTE: RETURNS LOG MESSAGE WHEN TIME IS GREATER THAN 10 DAYS		**;
	arelsdtm = aestdtm - trtsdtm ;

		 if 0 le abs(arelsdtm) le 86399 then arelsdtc = substr('0:'||put(abs(arelsdtm), tod.),1,7) ;
	else if abs(arelsdtm) ge 86400 then 
		do ;
			days = floor(abs(arelsdtm)/86400) ;
				 if days le 9 then arelsdtc = substr(put(days,1.)||':'||put(mod(abs(arelsdtm),86400), tod.),1,7) ;
			else if days ge 10 then put "WARN" "ING: TIME GREATER THAN 10 DAYS." ;
		end ; 
	else if arelsdtm eq . then arelsdtc = ' ' ;

	if arelsdtm lt 0 then arelsdtc = '-' || arelsdtc ;

	**-- DERIVE ADUR --**;
	** NOTE: RETURNS LOG MESSAGE WHEN DURATION IS NEGATIVE OR OVER 100 DAYS			**;
		 if 0 le adurn le 86399 then adur = substr('00:'||put(adurn, tod.),1,8) ;
	else if adurn ge 86400 then 
		do ;
			days = floor(adurn/86400) ;
				 if days le 99 then adur = substr(put(days,z2.)||':'||put(mod(adurn,86400), tod.),1,8) ;
			else if days ge 100 then put "WARN" "ING: DURATION GREATER THAN 100 DAYS." ;
		end ; 
	else if adurn lt 0 then put "WARN" "ING: DURATION IS NEGATIVE, CHECK DATA." ;
	else if adurn eq . then adur = 'ongoing' ;

run ;

**-------------------------------------------------------------------------------**;
**  FORMAT DATA FOR REPORT                                                       **;
**-------------------------------------------------------------------------------**;

data ae ;
	set ae ;
	length col1 - col9 $800 ;
	col1 = subjid ;
	col2 = "^R'\ "
		   || armcd || '\line '
		   || compress(put(age,3.0)) || '\line '
		   || sexgr1 || '\line '
		   || racegr1 || '\line '
		   ;
	col3 = "^R'\ "
		   || trim(left(propcase(aebodsys))) || '\line '
		   || trim(left(propcase(aedecod))) || '\line '
		   || trim(left(propcase(aeterm))) || '\line '
		   ;
	col4 = asttm ;
	col5 = arelsdtc ;
	col6 = adur ;
	col7 = asev ;
	col8 = arel ;
	col9 = aeacnoth ;
run ;

title 'CHECK LISTING DATA' ;
proc print data=ae ;
	var col1 - col9 ;
	where &printme ;
run ;
title ;

data ae ;
	set ae ;

	**-- SET NUMBER OF RECORDS TO DISPLAY PER PAGE --**;
	perpage = 4 ;

	**-- PAGEVAR USED AS ORDER VARIABLE IN PROC REPORT 				 --**;
	**-- USED TO CREATE SPACE BETWEEN HEADING AND FIRST OBS PER PAGE --**;
	pagevar = ceil(_n_/perpage) ;
run ;

**-------------------------------------------------------------------------------**;
**  CREATE REPORT                                                                **;
**-------------------------------------------------------------------------------**;

**----- RTF SETUP -----**;
options nodate nonumber orientation=landscape missing=' ';
ods listing close ;
ods escapechar='^' ;
ods rtf style=TStyleRTF file="&opath.\L6.rtf" ;

**----- TITLES/FOOTNOTES -----**;
title1 j=left "CM Pharmaceuticals, Inc." j=right 'Page ^{pageof}' ;
title2 j=left "Protocol PROD-124" j=right "&sysdate9"  ;
title3 j=center "Listing 6" ;
title4 ;
title5 j=center "Adverse Events" ;

footnote1 "^{style [outputwidth=100% bordertopcolor=black bordertopwidth=1pt]}" ;
footnote2 h=10pt j=left "^{super a} Cohort 1 Sequence: Bag in Infusion 1 / Bottle in Infusion 2"
						", Cohort 2 Sequence: Bottle in Infusion 1 / Bag in Infusion 2." ;
footnote3 h=10pt j=left "^{super b} Relative to the start of PROD administration. Negative times " 
						"indicate occurrence prior to the start of PROD administration." ;
footnote4 h=10pt j=left "^{super c} Duration (D:H:M): D = Days; H = Hours; M = Minutes. " ;
footnote5 ;
footnote6 j=left "Data Source: ADAE, ADSL" j=right "Program: lae.sas" ;

**----- REPORT DEFINITION -----**;
proc report data=ae missing nowindows center split='|' ;
	column pagevar subjid arelsdtm col1 - col9 ;

	define pagevar / order noprint ;
	define subjid / order noprint ;
	define arelsdtm / order noprint ;

	define col1 /"Subject" style(header)=[just=left] style(column)=[just=left cellwidth=0.8in] ;
	define col2 /"Cohort^{super a}|Age|Sex|Race" style(header)=[just=left] style(column)=[just=left cellwidth=0.8in] ;
	define col3 /"MedDRA Body System|MedDRA Preferred Term|CRF Verbatim Term" style(header)=[just=left] style(column)=[just=left cellwidth=2in] ;
	define col4 /"Onset|Time|(HH:MM)" style(header)=[just=center] style(column)=[just=center cellwidth=0.8in] ;
	define col5 /"Onset|Time^{super b}|Relative|to PROD|(D:H:M)" style(header)=[just=center] style(column)=[just=center cellwidth=0.8in] ;
	define col6 /"Duration|(D:H:M)^{super c}" style(header)=[just=center] style(column)=[just=center cellwidth=0.8in] ;
	define col7 /"Severity" style(header)=[just=center] style(column)=[just=center cellwidth=0.8in] ;
	define col8 /"Relationship|to PROD" style(header)=[just=center] style(column)=[just=center cellwidth=0.8in] ;
	define col9 /"Action Taken" style(header)=[just=center] style(column)=[just=center cellwidth=0.8in] ;

	break after pagevar / page ;

	compute before subjid ;
		line '' ;
	endcomp ;

run;

run ;

**----- CLOSE RTF AND RESET TITLES/FOOTNOTES -----**;
ods rtf close ;
ods listing ;

options date number ;
title ;
footnote ;
