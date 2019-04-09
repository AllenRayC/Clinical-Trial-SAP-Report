**-------------------------------------------------------------------------------------------**
** PROGRAM:    LVS1.SAS
**
** CREATED:    NOVEMBER 2016
**
** PURPOSE:    CREATE VITAL SIGNS LISTING 8.1 - VITAL SIGNS (BLOOD PRESSURE AND HEART RATE)
**												AND OXYGEN SATURATION
**
** PROGRAMMER: A.CHANG
**
** INPUT:      ADVS, ADSL DATA
**
** OUTPUT:     LISTING 8.1
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
	if vstestcd in ('PULSE','SYSBP','DIABP','OXYSAT') ;
run ;

**-------------------------------------------------------------------------------**;
**  CREATE BASELINE ROW                                            		         **;
**-------------------------------------------------------------------------------**;

data vs ;
	set vs ;
	if vtpt='0 min' then output ;
	output ;
run ;

proc sort data=vs ;
	by usubjid vsseq vstestcd ;
run ;

data vs ;
	set vs ;
	by usubjid vsseq vstestcd ;
	if vstpt = '0 min' and last.vstestcd then vtpt='Baseline^{super c}' ;
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
	set vs (rename=(col1=c4 col2=c5 col3=c6 col4=c7 
				    col5=c8 col6=c9 col7=c10 col8=c11));
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
ods rtf style=TStyleRTF file="&opath.\L8-1.rtf" ;
** NOTE: MODIFIED OPTEMPLT.SAS **;

**----- TITLES/FOOTNOTES -----**;
title1 j=left "CM Pharmaceuticals, Inc." j=right 'Page ^{pageof}' ;
title2 j=left "Protocol PROD-124" j=right "&sysdate9"  ;
title3 j=center "Listing 8.1" ;
title4 ;
title5 j=center "Vital Signs (Blood Pressure and Heart Rate) and Oxygen Saturation" ;

footnote1 "^{style [outputwidth=100% bordertopcolor=black bordertopwidth=1pt]}" ;
footnote2 h=10pt j=left "^{super a} Cohort 1 Sequence: Bag in Infusion 1 / Bottle in Infusion 2"
						", Cohort 2 Sequence: Bottle in Infusion 1 / Bag in Infusion 2." ;
footnote3 h=10pt j=left "^{super b} Change from baseline." ;
footnote4 h=10pt j=left "^{super c} Baseline is the last value prior to the start of PROD." ;
footnote5 h=10pt j=left 

"^R'\ "
" \line I or D = Increase or decrease from baseline of clinical importance based on the criteria specified below: \line "
"       Systolic blood pressure above/below normal range (90 to 200 mm Hg) and increase/decrease >= 20 mm Hg \line "
"       Diastolic blood pressure above/below normal range (60 to 120 mm Hg) and increase/decrease >= 10 mm Hg \line "
"       Heart Rate above/below normal range (45 to 120 bpm) and increase/decrease >= 10 bpm \line "
"       Oxygen Saturation <90% and decrease >= 5% \line";

footnote6 j=left "^R'\ " "n/a = not applicable \line - = missing \line" ;
footnote7 j=left "Data Source: ADVS, ADSL" j=right "Program: lvs1.sas" ;

**----- REPORT DEFINITION -----**;
proc report data=vs missing nowindows center split='|' ;
	column c1-c3 ("^R'\brdrb\brdrs Systolic Blood \line Pressure (mmHg)" c4-c5) _empty 
		   ("^R'\brdrb\brdrs Diastolic Blood \line Pressure (mmHg)" c6-c7) _empty 
		   ("^R'\brdrb\brdrs Heart Rate \line (beats/min)" c8-c9) _empty
		   ("^R'\brdrb\brdrs Oxygen Saturation \line (%)" c10-c11) ;

	define _empty / display " " style(column)=[just=center cellwidth=0.1in] ;
	define c1 / order "Subject" style(column)=[just=center cellwidth=0.9in] ;
	define c2 / order "Cohort^{super a}" style(column)=[just=center cellwidth=0.9in] ;
	define c3 /"Scheduled|Timepoint" style(header)=[just=left] style(column)=[just=left cellwidth=1in] ;
	define c4 /"Value" style(column)=[just=center cellwidth=0.7in] ;
	define c5 /"Change^{super b}" style(column)=[just=center cellwidth=0.7in] ;
	define c6 /"Value" style(column)=[just=center cellwidth=0.7in] ;
	define c7 /"Change^{super b}" style(column)=[just=center cellwidth=0.7in] ;
	define c8 /"Value" style(column)=[just=center cellwidth=0.7in] ;
	define c9 /"Change^{super b}" style(column)=[just=center cellwidth=0.7in] ;
	define c10 /"Value" style(column)=[just=center cellwidth=0.7in] ;
	define c11 /"Change^{super b}" style(column)=[just=center cellwidth=0.7in] ;

	break after c1 / page ;

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
