**-------------------------------------------------------------------------------------------**
** PROGRAM:    TVS.SAS
**
** CREATED:    NOVEMBER 2016
**
** PURPOSE:    CREATE TABLES 9.1 - VITAL SIGNS - SYSTOLIC BLOOD PRESSURE (MM HG)
**							 9.2 - VITAL SIGNS - DIASTOLIC BLOOD PRESSURE (MM HG)
**							 9.3 - VITAL SIGNS - HEART RATE (BEATS/MIN)
**							 9.4 - VITAL SIGNS - OXYGEN SATURATION (%)
**									
** PROGRAMMER: A.CHANG
**
** INPUT:      ADVS, ADSL DATA
**
** OUTPUT:     TABLES 9.1-9.4
**
** PROTOCOL:   PROD-124
**
** MODIFIED:   DATE        BY          NOTE
**             ----------  ----------  -----------------------------------------------------
**
**-------------------------------------------------------------------------------------------**;

%include msetup ;

%macro tvs (num=) ;
	**-------------------------------------------------------------------------------**;
	**  BRING IN ANALYSIS DATA                                                       **;
	**-------------------------------------------------------------------------------**;
	data vs ;
		set adslib.advs ;

		**-- SET PARCAT1N --**;
			 if vtpt = 'Screening' then parcat1n = 1 ;
		else if vtpt = '-5 min' then parcat1n = 2 ;
		else if vtpt = '0 min' then parcat1n = 3 ;
		else if vtpt = 'Baseline^{super b}' then parcat1n = 4 ;
		else if vtpt = '+5 min' then parcat1n = 5 ;
		else if vtpt = '+10 min' then parcat1n = 6 ;
		else if vtpt = '+15 min' then parcat1n = 7 ;
		else if vtpt = '+20 min' then parcat1n = 8 ;
		else if vtpt = '+25 min' then parcat1n = 9 ;
		else if vtpt = '+30 min' then parcat1n = 10 ;
		else if vtpt = '+35 min' then parcat1n = 11 ;
		else if vtpt = '+40 min' then parcat1n = 12 ;
		else if vtpt = '+45 min' then parcat1n = 13 ;
		else if vtpt = '+105 min' then parcat1n = 14 ;
		else if vtpt = 'Study Day 2' then parcat1n = 15 ;

		**-- SUBSET BASED ON TABLE NUMBER --**;
			 if &num = 1 then if vstestcd in ('SYSBP') ;
		else if &num = 2 then if vstestcd in ('DIABP') ;
		else if &num = 3 then if vstestcd in ('PULSE') ;
		else if &num = 4 then if vstestcd in ('OXYSAT') ;

	run ;

	**-------------------------------------------------------------------------------**;
	**  REMOVE DATA OUTSIDE PLANNED TIMEPOINTS			                             **;
	**-------------------------------------------------------------------------------**;

	** NOTE: REMOVED DATA WITH DATA OUTSIDE PLANNED TIMEPOINTS		**;
	** 	     (PATID = 118 HAD EXTRA DATA AT 50 MIN,					**;
	**		  PATID = 125 HAD EXTRA DATA AT 50 MIN, 55 MIN)			**;

	data vs dropped ;
		set vs ;
		if vstpt in ('SCREENING & BASELINE','-5 min','0 min','5 min','10 min','15 min'
					,'20 min','25 min','30 min','35 min','40 min','45 min'
					,'1 HOUR AFTER INFUSION PERIOD #2','STUDY DAY 2') then output vs ;
		else output dropped ;
	run ;

	**-------------------------------------------------------------------------------**;
	**  BASELINE AND TABLE SHELL                           		         	         **;
	**-------------------------------------------------------------------------------**;

	data vsbl ;
		set vs (where=(vsblfl='Y')) ;
	run ;

	**-- SUMMARY STATS FOR BASELINE --**;
	proc sort data=vsbl (where=(vsstresn ne .))
			  out=vsbl ;
	   by trt01pn trt01p parcat1n vtpt ;
	run ;

	proc means data=vsbl noprint ;
	   by trt01pn trt01p parcat1n vtpt ;
	   var vsstresn ;
	   output out=vsbl n=n mean=mean std=std median=median min=min max=max ;
	run ;

	**-- CREATE TABLE SHELL --**;
	data shell ;
		set vsbl (drop= _type_ _freq_) ;
			 
		do i=1 to 16 by 1 ;
				 if i in (1:4) then parcat1n = i ;
			else if i = 5 then 
				do ;
					parcat1n = 4.1 ;
					n = . ;
				end ;
			else if i in (6:16) then parcat1n = i-1 ;

				 if parcat1n = 1 then vtpt = 'Screening' ;
			else if parcat1n = 2 then vtpt = '-5 min' ;
			else if parcat1n = 3 then vtpt = '0 min' ;
			else if parcat1n = 4 then vtpt = 'Baseline^{super b}' ;
			else if parcat1n = 5 then vtpt = '+5 min' ;
			else if parcat1n = 6 then vtpt = '+10 min' ;
			else if parcat1n = 7 then vtpt = '+15 min' ;
			else if parcat1n = 8 then vtpt = '+20 min' ;
			else if parcat1n = 9 then vtpt = '+25 min' ;
			else if parcat1n = 10 then vtpt = '+30 min' ;
			else if parcat1n = 11 then vtpt = '+35 min' ;
			else if parcat1n = 12 then vtpt = '+40 min' ;
			else if parcat1n = 13 then vtpt = '+45 min' ;
			else if parcat1n = 14 then vtpt = '+105 min' ;
			else if parcat1n = 15 then vtpt = 'Study Day 2' ;
			else vtpt = '' ;

			output ;
		end ;
	run ;

	**-- BLANK LINE BETWEEN SCREENING & BASELINE AND SCHEDULED TIMEPOINTS --**;
	data shell ;
		set shell ;
		if parcat1n = 4.1 then
			do ;
				mean=. ; std=. ; median=. ; min=. ; max=. ;
			end ;
	run ;

	**-------------------------------------------------------------------------------**;
	**  SCHEDULED TIMEPOINT                                 		         	     **;
	**-------------------------------------------------------------------------------**;

	data vsst ;
		set vs (where= (parcat1n in (5:15))) ;
	run ;

	**-- SUMMARY STATS FOR SCHEDULED TIMEPOINT --**;
	proc sort data=vsst (where=(vsstresn ne .))
			  out=vsst ;
	   by trt01pn trt01p parcat1n vtpt ;
	run ;

	proc means data=vsst noprint ;
	   by trt01pn trt01p parcat1n vtpt ;
	   var vsstresn ;
	   output out=vsst n=n mean=mean std=std median=median min=min max=max ;
	run ;

	**-------------------------------------------------------------------------------**;
	**  CHANGE FROM BASELINE                                 		         	     **;
	**-------------------------------------------------------------------------------**;

	data vschg ;
		set vs (where= (parcat1n in (5:15))) ;
	run ;

	**-- SUMMARY STATS FOR CHANGE FROM BASELINE --**;
	proc sort data=vschg (where=(vschgbl ne .))
			  out=vschg ;
	   by trt01pn trt01p parcat1n vtpt ;
	run ;

	proc means data=vschg noprint ;
	   by trt01pn trt01p parcat1n vtpt ;
	   var vschgbl ;
	   output out=vschg n=n mean=mean std=std median=median min=min max=max ;
	run ;

	**-------------------------------------------------------------------------------**;
	**  MERGE TOGETHER	  	                                 		         	     **;
	**-------------------------------------------------------------------------------**;

	data summary ;
		merge shell
			  vsst (drop= _type_ _freq_ rename=(n=n1 mean=mean1 std=std1 median=median1 min=min1 max=max1))
			  vschg (drop= _type_ _freq_ rename=(n=n2 mean=mean2 std=std2 median=median2 min=min2 max=max2)) ;
		by trt01pn trt01p parcat1n vtpt ;

		**-- COHORT AND SCHEDULED TIMEPOINT --**;
		col1 = compress(put(trt01pn,8.)) ;
		col2 = vtpt ;

		**-- N --**;
			 if parcat1n in (1:4) then n0 = n ;
		else if parcat1n in (5:15) then n0 = n1 ;
		col3 = compress(put(n0,2.)) ;

		**-- BASELINE --**;
		col4 = compress(put(mean,5.1)) ;
		col5 = compress(put(std,5.1)) ;
		col6 = compress(put(median,5.)) ;
		if n(min,max)=2 then col7 = '(' || compress(put(min,8.)) || ', ' || compress(put(max,8.)) || ')' ;

		**-- SCHEDULED TIMEPOINT --**;
		col8 = compress(put(mean1,5.1)) ;
		col9 = compress(put(std1,5.1)) ;
		col10 = compress(put(median1,5.)) ;
		if n(min1,max1)=2 then col11 = '(' || compress(put(min1,8.)) || ', ' || compress(put(max1,8.)) || ')' ;

		**-- CHANGE FROM BASELINE --**;
		col12 = compress(put(mean2,5.1)) ;
		col13 = compress(put(std2,5.1)) ;
		col14 = compress(put(median2,5.)) ;
		if n(min2,max2)=2 then col15 = '(' || compress(put(min2,8.)) || ', ' || compress(put(max2,8.)) || ')' ;

		**-- EMPTY COLUMN FOR TABLE DISPLAY --**;
		_empty = ' ' ;

	run ;

	proc sort data = summary ;
		by trt01pn parcat1n ;
	run ;

	**-------------------------------------------------------------------------------**;
	**  FORMAT DATA FOR REPORT                                                       **;
	**-------------------------------------------------------------------------------**;

	**-- ASSIGN TABLE TITLE MACRO --**;
	data _null_ ;
			 if &num = 1 then call symput('title','Vital Signs - Systolic Blood Pressure (mm Hg)') ;
		else if &num = 2 then call symput('title','Vital Signs - Diastolic Blood Pressure (mm Hg)') ;
		else if &num = 3 then call symput('title','Vital Signs - Heart Rate (beats/min)') ;
		else if &num = 4 then call symput('title','Vital Signs - Oxygen Saturation (%)') ;
	run ;

	**-- ASSIGN SAFFL POPULATION COUNT MACRO --**;
	proc freq data=adslib.adsl (where=(saffl='Y')) noprint ;
	   tables studyid /out=popcnt (drop=percent) ;
	run ;

	data _null_ ;
	   set popcnt ;
	   call symput('popcnt',compress(put(count,8.))) ;
	run ;

	**-------------------------------------------------------------------------------**;
	**  CREATE REPORT                                                                **;
	**-------------------------------------------------------------------------------**;

	**----- RTF SETUP -----**;
	options nodate nonumber orientation=landscape missing=' ';
	ods listing close ;
	ods escapechar='^' ;
	ods rtf style=TStyleRTF file="&opath.\T9-&num..rtf" ;

	**----- TITLES/FOOTNOTES -----**;
	title1 j=left "CM Pharmaceuticals, Inc." j=right 'Page ^{pageof}' ;
	title2 j=left "Protocol PROD-124" j=right "&sysdate9"  ;
	title3 j=center "Table 9.&num" ;
	title5 j=center "&title" ;
	title7 j=left "Study Population: Safety (N = &popcnt)" ;

	footnote1 "^{style [outputwidth=100% bordertopcolor=black bordertopwidth=1pt]}" ;
	footnote2 h=10pt j=left "^{super a} Cohort 1 Sequence: Bag in Infusion 1 / Bottle in Infusion 2"
						", Cohort 2 Sequence: Bottle in Infusion 1 / Bag in Infusion 2." ;
	footnote3 h=10pt j=left "^{super b} Baseline is the last value prior to the start of PROD." ;
	footnote4 h=10pt j=left "Note: Summary statistics at each scheduled timepoint include those subjects with a baseline value and a value at the scheduled timepoint. " ;
	footnote6 j=left "Data Source: ADVS, ADSL" j=right "Program: tvs.sas" ;

	**----- REPORT DEFINITION -----**;
	proc report data=summary missing nowindows center split='|' style(report)=[outputwidth=9.0in] ;
	   column col1-col3 ('^S={borderbottomcolor=black borderbottomwidth=2} Baseline^{super b}' col4-col7) _empty
			  ('^S={borderbottomcolor=black borderbottomwidth=2} Scheduled Timepoint' col8-col11 ) _empty
			  ('^S={borderbottomcolor=black borderbottomwidth=2} Change from Baseline' col12-col15) ;

	   define _empty / display " " style(column)=[just=center cellwidth=0.1in] ;
	   define col1 / order "Cohort^{super a}" style(column)=[just=center cellwidth=0.4in] ;
	   define col2 /"Scheduled|Timepoint" style(column)=[just=center cellwidth=0.6in] ;
	   define col3 /"N" style(column)=[just=center cellwidth=0.4in] ;
	   define col4 /"Mean" style(column)=[just=center cellwidth=0.4in] ;
	   define col5 /"SD" style(column)=[just=center cellwidth=0.4in] ;
	   define col6 /"Median" style(column)=[just=center cellwidth=0.4in] ;
	   define col7 /"(Min, Max)" style(column)=[just=center cellwidth=0.6in] ;

	   define col8 /"Mean" style(column)=[just=center cellwidth=0.4in] ;
	   define col9 /"SD" style(column)=[just=center cellwidth=0.4in] ;
	   define col10 /"Median" style(column)=[just=center cellwidth=0.4in] ;
	   define col11 /"(Min, Max)" style(column)=[just=center cellwidth=0.6in] ;

	   define col12 /"Mean" style(column)=[just=center cellwidth=0.4in] ;
	   define col13 /"SD" style(column)=[just=center cellwidth=0.4in] ;
	   define col14 /"Median" style(column)=[just=center cellwidth=0.4in] ;
	   define col15 /"(Min, Max)" style(column)=[just=center cellwidth=0.6in] ;

	   break after col1 / page ;

		compute before col1 ;
			line '' ;
		endcomp ;

	run ;

	**----- CLOSE RTF AND RESET TITLES/FOOTNOTES -----**;
	ods rtf close ;
	ods listing ;

	options date number ;
	title ;
	footnote ;

%mend tvs ;

%tvs(num=1)
%tvs(num=2)
%tvs(num=3)
%tvs(num=4)

