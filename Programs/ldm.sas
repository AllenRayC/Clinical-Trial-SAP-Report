**-------------------------------------------------------------------------------------------**
** PROGRAM:    LDM.SAS
**
** CREATED:    NOVEMBER 2016
**
** PURPOSE:    CREATE DEMOGRAPHICS LISTING 2 - DEMOGRAPHIC AND BASELINE CHARACTERISTICS
**
** PROGRAMMER: A.CHANG
**
** INPUT:      ADSL DATA
**
** OUTPUT:     LISTING 2
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
**  BRING IN ANALYSIS DATA                                                       **;
**-------------------------------------------------------------------------------**;

data dm ;
	set adslib.adsl ;
	col1 = subjid ;
	col2 = armcd ;
	col3 = input(rfstdtc, mmddyy10.) ;
	col4 = input(brthdtc, mmddyy10.) ;
	col5 = age ;
	col6 = sexgr1 ;
	col7 = propcase(race) ;
	col8 = weight ;
	col9 = height ;
run ;

title 'CHECK LISTING DATA' ;
proc print data=dm ;
	var col1 - col9 ;
	where &printme ;
run ;
title ;

**-------------------------------------------------------------------------------**;
**  FORMAT DATA FOR REPORT                                                       **;
**-------------------------------------------------------------------------------**;

data dm ;
	set dm ;

	**-- SET NUMBER OF RECORDS TO DISPLAY PER PAGE --**;
	perpage = 28 ;

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
ods rtf style=TStyleRTF file="&opath.\L2.rtf" ;
** NOTE: MODIFIED OPTEMPLT.SAS **;

**----- TITLES/FOOTNOTES -----**;
title1 j=left "CM Pharmaceuticals, Inc." j=right 'Page ^{pageof}' ;
title2 j=left "Protocol PROD-124" j=right "&sysdate9"  ;
title3 j=center "Listing 2" ;
title4 ;
title5 j=center "Demographics and Baseline Characteristics" ;

footnote1 "^{style [outputwidth=100% bordertopcolor=black bordertopwidth=1pt]}" ;
footnote2 h=10pt j=left "^{super a} Cohort 1 Sequence: Bag in Infusion 1 / Bottle in Infusion 2"
						", Cohort 2 Sequence: Bottle in Infusion 1 / Bag in Infusion 2." ;
footnote3 ;
footnote4 j=left "Data Source: ADSL" j=right "Program: ldm.sas" ;

**----- REPORT DEFINITION -----**;
proc report data=dm missing nowindows center split='|' ;
	column pagevar subjid col1 - col9 ;

	define pagevar / order noprint ;
	define subjid / order noprint ;

	define col1 /"Subject" style(header)=[just=left] style(column)=[just=left cellwidth=0.9in] ;
	define col2 /"Cohort^{super a}" style(header)=[just=left] style(column)=[just=left cellwidth=0.9in] ;
	define col3 /"Informed|Consent|Date" style(header)=[just=left] style(column)=[just=left cellwidth=0.9in] f=date9. ;
	define col4 /"Date of|Birth" style(header)=[just=left] style(column)=[just=left cellwidth=0.9in] f=date9. ;
	define col5 /"Age|(yrs)" style(header)=[just=center] style(column)=[just=center cellwidth=0.9in] f=5.1 ;
	define col6 /"Sex" style(header)=[just=center] style(column)=[just=center cellwidth=0.9in] ;
	define col7 /"Race" style(header)=[just=center] style(column)=[just=center cellwidth=1.3in] ;
	define col8 /"Weight|(kg)" style(header)=[just=center] style(column)=[just=center cellwidth=0.9in] f=5.1 ;
	define col9 /"Height|(inch)" style(header)=[just=center] style(column)=[just=center cellwidth=0.9in] f=5.1 ;

	compute before pagevar ;
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
