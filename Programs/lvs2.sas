**-------------------------------------------------------------------------------------------**
** PROGRAM:    LVS2.SAS
**
** CREATED:    NOVEMBER 2016
**
** PURPOSE:    CREATE VITAL SIGNS LISTING 8.2 - VITAL SIGNS (RESPIRATION RATE AND TEMPERATURE) 
**
** PROGRAMMER: A.CHANG
**
** INPUT:      ADVS, ADSL DATA
**
** OUTPUT:     LISTING 8.2
**
** PROTOCOL:   PROD-124
**
** MODIFIED:   DATE        BY          NOTE
**             ----------  ----------  -----------------------------------------------------
**
**-------------------------------------------------------------------------------------------**;

%include msetup ;
%let printme = 0 ;

**-------------------------------------------------------------------------------**;
**  BRING IN ADVS DATA                                             		         **;
**-------------------------------------------------------------------------------**;

data vs ;
	set adslib.advs ;
	if vstestcd in ('RESP','TEMP') ;
	if vstpt = 'SCREENING & BASELINE' then vtpt = 'Baseline' ;
run ;

**-------------------------------------------------------------------------------**;
**  FORMAT DATA FOR REPORT                                                       **;
**-------------------------------------------------------------------------------**;

**-- PREPARE DATA FOR TRANSPOSE --**;
proc sort data=vs ;
	by subjid armcd vsdtc vtpt ;
run ;

data vs ;
	set vs ;
	flag = 1 ;
	output ;
	flag = 2 ;
	output ;
run ;

data vs ;
	set vs ;
		 if flag = 1 then avalc = vstresc ;
	else if flag = 2 then avalc = vschgblc ;
run ;

**-- TRANSPOSE DATA --**;
proc transpose data=vs out=vs (drop=_name_) ;
   by subjid armcd vsdtc vtpt ;
   var avalc ;
run ;

data vs ;
	set vs (rename=(col1=c4 col2=c5 col3=c6 col4=c7));
	length c1 - c3 $200 ;
	c1 = subjid ;
	c2 = armcd ;
	c3 = vtpt ;
	
	**-- EMPTY COLUMN FOR TABLE DISPLAY --**;
	_empty = ' ' ;

run ;

title 'CHECK LISTING DATA' ;
proc print data=vs ;
	var c1 - c11 ;
	where &printme ;
run ;
title ;

**-------------------------------------------------------------------------------**;
**  CREATE REPORT                                                                **;
**-------------------------------------------------------------------------------**;

**----- RTF SETUP -----**;
options nodate nonumber orientation=landscape missing=' ';
ods listing close ;
ods escapechar='^' ;
ods rtf style=TStyleRTF file="&opath.\L8-2.rtf" ;
** NOTE: MODIFIED OPTEMPLT.SAS **;

**----- TITLES/FOOTNOTES -----**;
title1 j=left "CM Pharmaceuticals, Inc." j=right 'Page ^{pageof}' ;
title2 j=left "Protocol PROD-124" j=right "&sysdate9"  ;
title3 j=center "Listing 8.2" ;
title4 ;
title5 j=center "Vital Signs (Respiration Rate and Temperature)" ;

footnote1 "^{style [outputwidth=100% bordertopcolor=black bordertopwidth=1pt]}" ;
footnote2 h=10pt j=left "^{super a} Cohort 1 Sequence: Bag in Infusion 1 / Bottle in Infusion 2"
						", Cohort 2 Sequence: Bottle in Infusion 1 / Bag in Infusion 2." ;
footnote3 h=10pt j=left "^{super b} Change from baseline." ;
footnote4 ;
footnote5 h=10pt j=left "n/a = not applicable" ;
footnote6 ;
footnote7 j=left "Data Source: ADVS, ADSL" j=right "Program: lvs2.sas" ;

**----- REPORT DEFINITION -----**;
proc report data=vs missing nowindows center split='|' ;
	column c1-c3 ("^R'\brdrb\brdrs Respiration Rate \line (breaths/min)" c4-c5) _empty
		   ("^R'\brdrb\brdrs Temperature \line (°C)" c6-c7) ;

	define _empty / display " " style(column)=[just=center cellwidth=0.1in] ;
	define c1 / order "" style(column)=[just=center cellwidth=1.25in] ;
	define c2 / order "Cohort^{super a}" style(column)=[just=center cellwidth=1.25in] ;
	define c3 /"Scheduled|Timepoint" style(header)=[just=left] style(column)=[just=left cellwidth=1.25in] ;
	define c4 /"Value" style(column)=[just=center cellwidth=1.25in] ;
	define c5 /"Change^{super b}" style(column)=[just=center cellwidth=1.25in] ;
	define c6 /"Value" style(column)=[just=center cellwidth=1.25in] ;
	define c7 /"Change^{super b}" style(column)=[just=center cellwidth=1.25in] ;

	compute before c1 ;
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
