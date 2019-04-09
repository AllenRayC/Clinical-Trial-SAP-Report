**-------------------------------------------------------------------------------------------**
** PROGRAM:    TDM.SAS
**
** CREATED:    NOVEMBER 2016
**
** PURPOSE:    CREATE TABLE 2 - DEMOGRAPHIC AND BASELINE CHARACTERISTICS
**
** PROGRAMMER: A.CHANG
**
** INPUT:      ADSL DATA
**
** OUTPUT:     TABLE 2
**
** PROTOCOL:   PROD-124
**
** MODIFIED:   DATE        BY          NOTE
**             ----------  ----------  -----------------------------------------------------
**
**-------------------------------------------------------------------------------------------**;

%include msetup ;

**-------------------------------------------------------------------------------**;
**  BRING IN ANALYSIS DATA                                                       **;
**-------------------------------------------------------------------------------**;

data adsl ;
   set adslib.adsl (where=(saffl eq 'Y')) ;
run ;

**-----------------------------------------------------------------------------------**;
**  EXPAND ADSL DATASET TO A NORMALIZED STRUCTURE (OUTPUT RECORDS FOR EACH CATEGORY) **;                                                       
**-----------------------------------------------------------------------------------**;

data adsl ;
	set adsl ;
	length parcat1 param $200 ;

	parcat1n = 1 ;
	parcat1 = 'Age (yrs)' ;
	if age gt .z then aval = age ;
	else aval = . ;
	if aval gt .z then output ;

	parcat1n = 2 ;
	parcat1 = 'Sex n (%)' ;
	paramn = sexgr1n ;
	param = sexgr1 ;
	aval = . ;
	output ;

	parcat1n = 3 ;
	parcat1 = 'Race n (%)' ;
	paramn = racegr1n ;
	param = racegr1 ;
	aval = . ;
	output ;

	parcat1n = 4 ;
	parcat1 = 'Weight (kg)' ;
	if weight gt .z then aval = weight ;
	else aval = . ;
	if aval gt .z then output ;

	parcat1n = 5 ;
	parcat1 = 'Height (cm)' ;
	if height gt .z then aval = height ;
	else aval = . ;
	if aval gt .z then output ;

run ;

**-- OUTPUT FOR TOTALS COLUMN --**;
data adsl ;
	set adsl ;
	output ;        			** OUTPUT ONCE FOR EACH SUBJECT **;
	trt01pn = 3 ;   			** RE-ASSIGN FOR SAFETY POPULATION, THEN OUTPUT AGAIN **;
	trt01p = 'All Subjects' ;
	output ;
	if fasfl = 'Y' then 
   		do ;
			trt01pn = 4 ;		** RE-ASSIGN FOR EVALUABLE POPULATION, THEN OUTPUT AGAIN **;
			trt01p = 'All' ;
			output ;
		end ;
run ;

**-- POPULATION COUNTS --**;
proc sort data=adsl out=popcnt nodupkey ;
   by trt01pn subjid ;
run ;

proc freq data=popcnt noprint ;
   tables trt01pn*trt01p /out=popcnt (drop=percent) ;
run ;

**-- ASSIGN POPULATION COUNT INTO MACRO VARIABLES --**;
data _null_ ;
   set popcnt ;
   call symput('popcnt'||compress(put(trt01pn,8.)),compress(put(count,8.))) ;
   call symput('trt'||compress(put(trt01pn,8.)),trim(left(trt01p))) ;
run ;

title "CHECK DENOMINATORS" ;
proc print data=popcnt ;
   where &printme ;
run ;
title ;

**-------------------------------------------------------------------------------**;
**  FREQUENCY COUNTS                                                             **;
**-------------------------------------------------------------------------------**;

proc freq data=adsl (where=(aval=.)) noprint ;
   tables trt01pn*parcat1n*parcat1*paramn*param /out=freqs (drop=percent) ;
run ;

**-- BRING IN DENOMINATORS --**;
data freqs ;
   merge freqs popcnt (rename=(count=popcnt)) ;
   by trt01pn ;
   length col $200 ;
   if n(count,popcnt) eq 2 then col = compress(put(count,8.))||' ('||compress(put(count/popcnt*100,8.1))||')' ;
run ;

title "CHECK FREQUENCY DATA" ;
proc print data=freqs ;
	where &printme ;
run ;
title ;

**-- CREATE TABLE SHELL --**;
data shell (drop = i j) ;
	length parcat1 param col $200 trt01p $20 ;
	count = 0 ;
	col = '0' ;
	do i = 1 to 4 by 1 ;
		trt01pn = i ; 
			 if trt01pn = 1 then trt01p = 'Cohort 1' ;
		else if trt01pn = 2 then trt01p = 'Cohort 2' ;
		else if trt01pn = 3 then trt01p = 'All Subjects' ;
		else if trt01pn = 4 then trt01p = 'All' ;
		
		parcat1n = 2 ;
		parcat1 = 'Sex n (%)' ;
		do j=1 to 2 by 1 ;
			paramn = j ;
				 if paramn = 1 then param = 'Male' ;
			else if paramn = 2 then param = 'Female' ;
			output ;
		end ;

		parcat1n = 3 ; 
		parcat1 = 'Race n (%)' ;
		do j=1 to 5 by 1 ;
			paramn = j ;
				 if paramn = 1 then param = 'Caucasian' ;
			else if paramn = 2 then param = 'Black' ;
			else if paramn = 3 then param = 'Hispanic' ;
			else if paramn = 4 then param = 'Asian' ;
			else if paramn = 5 then param = 'Other' ;
			output ;
		end ;
	end ;
run ;

proc sort data=shell ;
	by trt01pn parcat1n parcat1 paramn param ;
run ;

**-- MERGE FREQUENCY DATA WITH TABLE SHELL --**;
data freqs ;
	set freqs
		shell ;
	by trt01pn parcat1n parcat1 paramn param ;
	if first.paramn ;
run ;

**-------------------------------------------------------------------------------**;
**  SUMMARY STATS                                                                **;
**-------------------------------------------------------------------------------**;

proc sort data=adsl (where=(aval ne .))
		  out=summary ;
   by trt01pn trt01p parcat1n parcat1;
run ;

proc means data=summary noprint ;
   by trt01pn trt01p parcat1n parcat1 ;
   var aval ;
   output out=summary n=n mean=mean std=std median=median min=min max=max ;
run ;

**-- FORMAT SUMMARY STATS TO CHARACTER VARIABLES --**;
data summary (keep= trt01pn trt01p parcat1n parcat1 paramn param col) ;
	set summary ;
	length param col $200 ;

	paramn = 1 ;
	param = 'n' ;
	col = compress(put(n,8.)) ;
	output ;

	paramn = 2 ;
	param = 'Mean' ;
	col = compress(put(mean,8.1)) ;
	output ;

	paramn = 3 ;
	param = 'SD' ;
	col = compress(put(std,8.1)) ;
	output ;

	paramn = 4 ;
	param = 'Median' ;
	col = compress(put(median,8.1)) ;
	output ;

	paramn = 5 ;
	param = 'Range (Min, Max)' ;
	col = '(' || compress(put(min,8.)) || ', ' || compress(put(max,8.)) || ')' ;
	output ;

run ;

title "CHECK SUMMARY STATS" ;
proc print data=summary ;
   where &printme ;
run ;
title ;

**-------------------------------------------------------------------------------**;
**  COMBINE SUMMARY STATS AND FREQUENCY COUNTS                                   **;
**-------------------------------------------------------------------------------**;

data stats ;
   set freqs summary ;
run ;

title "CHECK DATA PRIOR TO TRANSPOSE" ;
proc print data=stats ;
	var parcat1n parcat1 paramn param trt01pn col ;
	where &printme ;
run ;
title ;

**----- TRANSPOSE DATA -----**;
proc sort data=stats out=stats ;
   by parcat1n paramn ;
run ;

proc transpose data=stats out=stats (drop=_name_) ;
   by parcat1n parcat1 paramn param ;
   id trt01pn ;
   var col ;
run ;

**-------------------------------------------------------------------------------**;
**  FORMAT DATA FOR REPORT                                                       **;
**-------------------------------------------------------------------------------**;

data stats ;
	set stats (rename= (_1=col3 _2=col4 _3=col1 _4=col2)) ;
		 if parcat1n in (1:4) then pagevar = 1 ;
	else if parcat1n = 5 then pagevar = 2 ;
run ;

**-------------------------------------------------------------------------------**;
**  CREATE REPORT                                                                **;
**-------------------------------------------------------------------------------**;

**----- RTF SETUP -----**;
options nodate nonumber orientation=landscape missing=' ';
ods listing close ;
ods escapechar='^' ;
ods rtf style=TStyleRTF file="&opath.\T2.rtf" ;

**----- TITLES/FOOTNOTES -----**;
title1 j=left "CM Pharmaceuticals, Inc." j=right 'Page ^{pageof}' ;
title2 j=left "Protocol PROD-124" j=right "&sysdate9"  ;
title3 j=center "Table 2" ;
*title4 ;
title5 j=center "Demographic and Baseline Characteristics" ;
title7 j=left "Study Population: Safety" ;

footnote1 "^{style [outputwidth=100% bordertopcolor=black bordertopwidth=1pt]}" ;
footnote2 j=left "Data Source: ADSL" j=right "Program: tdm.sas" ;

**----- REPORT DEFINITION -----**;
proc report data=stats missing nowindows center split='|' style(report)=[outputwidth=9.0in] ;
   column pagevar parcat1n parcat1 paramn param col1 ('^S={borderbottomcolor=black borderbottomwidth=2} Evaluable Population' col2-col4) ;

   define pagevar /order noprint ;
   define parcat1n /order noprint ;
   define parcat1 /order noprint ;
   define paramn /order noprint ;

   define param /"^R'\ql Characteristic'" style(column)=[leftmargin=0.15in just=left cellwidth=2.00in] ;
   define col1 /"&trt3|(N=&popcnt3)" style(column)=[just=center cellwidth=1.5in] ;
   define col2 /"&trt4|(N=&popcnt4)" style(column)=[just=center cellwidth=1.5in] ;
   define col3 /"&trt1|(N=&popcnt1)" style(column)=[just=center cellwidth=1.5in] ;
   define col4 /"&trt2|(N=&popcnt2)" style(column)=[just=center cellwidth=1.5in] ;

   break after pagevar / page ;

   compute before parcat1 ;
      length text $400 ;
      text = trim(left(parcat1)) ;
      line @2 text $400. ;
   endcomp ;

   compute before parcat1n ;
      line ' ' ;
   endcomp ;
run ;

**----- CLOSE RTF AND RESET TITLES/FOOTNOTES -----**;
ods rtf close ;
ods listing ;

options date number ;
title ;
footnote ;
