**-------------------------------------------------------------------------------------------**
** PROGRAM:    TAE.SAS
**
** CREATED:    NOVEMBER 2016
**
** PURPOSE:    CREATE TABLE 7.2.1 - ADVERSE EVENTS BY BODY SYSTEM
**					  TABLE 7.2.2 - ADVERSE EVENTS BY BODY SYSTEM RELATED
**
** PROGRAMMER: A.CHANG
**
** INPUT:      ADAE, ADSL DATA
**
** OUTPUT:     TABLE 7.2.1, TABLE 7.2.2
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

%macro tae (num=) ;
	data adae ;
		merge adslib.adae (in=inae where=(aestdtm > trtsdtm)) 
			  adslib.adsl ;										** TAKE ONLY AE REPORTED AFTER PROD ADMINISTERED **;  
		by usubjid ;

			 if &num = 1 then if inae ;
		else if &num = 2 then if inae and aerel ne 'UNRELATED' ;

	run ;

	**----- EXPAND ADAE DATASET TO A NORMALIZED STRUCTURE (OUTPUT RECORDS FOR EACH CATEGORY) -----**;
	data adae ;
	   set adae ;
	   length aetext $400 ;

	   ** OUTPUT FOR PREFERRED TERM **;
	   seq = 3 ;
	   aetext = trim(left(propcase(aedecod))) ;
	   output ;

	   ** OUTPUT FOR BODY SYSTEM ROWS **;
	   seq = 2 ;
	   aetext = trim(left(propcase(aebodsys))) ;
	   output ;

	   ** OUTPUT FOR ANY AE ROW **;
	   seq = 1 ;
	   aebodsys = 'AAAA' ;
	   aetext = 'Subjects with Adverse Event(s)^{super d}' ;
	   output ;
	run ;

	**----- OUTPUT FOR TOTALS COLUMN -----**;
	data adae ;
	   set adae ;
	   output ;        ** OUTPUT ONCE FOR EACH SUBJECT **;
	   trt01pn = 0 ;   ** RE-ASSIGN TOTAL, THEN OUTPUT AGAIN **;
	   trt01p = 'All Subjects' ;
	   output ;
	run ;

	**----- POPULATION COUNTS -----**;
	data popcnt ;
	   set adslib.adsl (where=(saffl eq 'Y')) ;
	   output ;        ** OUTPUT ONCE FOR EACH SUBJECT **;
	   trt01pn = 0 ;   ** RE-ASSIGN TOTAL, THEN OUTPUT AGAIN **;
	   trt01p = 'Total' ;
	   output ;
	run ;

	proc sort data=popcnt out=popcnt nodupkey ;
	   by trt01pn subjid ;
	run ;

	proc freq data=popcnt noprint ;
	   tables trt01pn*trt01p /out=popcnt (drop=percent) ;
	run ;

	**----- ASSIGN POPULATION COUNT INTO MACRO VARIABLES -----**;
	data _null_ ;
	   set popcnt ;
	   call symput('popcnt'||compress(put(trt01pn,8.)),compress(put(count,8.))) ;
	   call symput('trt'||compress(put(trt01pn,8.)),trim(left(trt01p))) ;
	run ;

	proc print data=popcnt ;
	   title "CHECK DENOMINATORS" ;
	   where &printme ;
	run ;

	**-------------------------------------------------------------------------------**;
	**  FREQUENCY COUNTS                                                             **;
	**-------------------------------------------------------------------------------**;

	**-- DEDUPE BY SUBJECT/EVENTS --**;
	proc sort data=adae out=subjects nodupkey ;
	   by usubjid trt01pn aebodsys seq aetext ;
	run ;

	proc freq data=subjects noprint ;
	   tables trt01pn*aebodsys*seq*aetext /out=subjects (drop=percent) ;
	run ;

	proc print data=subjects ;
	   format aebodsys aetext $20. ;
	   where &printme ;
	run ;

	data subjects ;
	   merge subjects
			 popcnt (rename=(count=popcnt)) ;
	   by trt01pn ;
	   length col $200 ;

		if n(count,popcnt) eq 2 then 
			do ;
				if seq = 1 then col = compress(put(count,8.)) ;
				else col = compress(put(count,8.))||' ('||compress(put(count/popcnt*100,8.1))||')' ;
			end	;

	run ;

	proc sort data=subjects out=subjects ;
	   by aebodsys seq aetext ;
	run ;

	proc transpose data=subjects out=adae (drop=_name_) ;
	   by aebodsys seq aetext ;
	   id trt01pn ;
	   var col ;
	run ;

	data adae ;
		set adae (rename=(_0=col0 _1=col1 _2=col2 )) ;
		if aebodsys = '' then delete ;
	run ;

	**-------------------------------------------------------------------------------**;
	**  FORMAT DATA FOR REPORT                                                       **;
	**-------------------------------------------------------------------------------**;

	data adae ;
	   set adae ;
	   if col0 eq ' ' then col0 = '0' ;
	   if col1 eq ' ' then col1 = '0' ;
	   if col2 eq ' ' then col2 = '0' ;

	   if seq eq 3 then aetext = "^R'\li360 '" || aetext ;

	run ;

	proc print data=adae ;
	   title "CHECK COMBINED STATS" ;
	   var aebodsys seq aetext col0 col1 col2 ;
	   where &printme ;
	run ;

	**-------------------------------------------------------------------------------**;
	**  CREATE MACRO TITLE AND FOOTNOTE A                                            **;
	**-------------------------------------------------------------------------------**;

	data _null_ ;
		if &num = 1 then 
			do ;
				call symput('title','Adverse Events^{super a} by Body System') ;
				call symput('footnote',
							'^{super a} Includes all adverse events reported after start of PROD administration.') ;
			end ;
		else if &num = 2 then 
			do ;
				call symput('title','Adverse Events by Body System Related^{super a}') ;
				call symput('footnote',
							'^{super a} Includes all adverse events reported after start of PROD administration that are considered definitely, probably, or possibly related to PROD.') ;
			end ;
	run ;

	**-------------------------------------------------------------------------------**;
	**  CREATE REPORT                                                                **;
	**-------------------------------------------------------------------------------**;

	**----- RTF SETUP -----**;
	options nodate nonumber orientation=landscape missing=' ';
	ods listing close ;
	ods escapechar='^' ;
	ods rtf style=TStyleRTF file="&opath.\T7-2-&num..rtf" ;

	**----- TITLES/FOOTNOTES -----**;
	title1 j=left "CM Pharmaceuticals, Inc." j=right 'Page ^{pageof}' ;
	title2 j=left "Protocol PROD-124" j=right "&sysdate9"  ;
	title3 j=center "Table 7.2.&num" ;

	title5 j=center "&title" ;


	title6 j=left "Study Population: Safety" ;

	footnote1 "^{style [outputwidth=100% bordertopcolor=black bordertopwidth=1pt]}" ;
	footnote2 h=10pt j=left "&footnote" ;
	footnote3 h=10pt j=left "^{super b} Subjects who had more than one event within a body system were counted once." ;
	footnote4 h=10pt j=left "^{super c} Subjects who had more than one event assigned to the same preferred term were counted once." ;
	footnote5 h=10pt j=left "^{super d} Subjects who had more than one event were counted once." ;
	footnote6 ;
	footnote7 j=left "Data Source: ADAE, ADSL" j=right "Program: tae.sas" ;

	**----- REPORT DEFINITION -----**;
	proc report data=adae missing nowindows center split='|' style(report)=[outputwidth=9.0in] ;
	   column aebodsys seq aetext col0-col2 ;

	   define aebodsys /order noprint ;
	   define seq /order noprint ;

	   define aetext /"^R'\ql\li360\fi-360 MedDRA Body System'^{super b}"
					  "Preferred Term^{super c}" style(header)=[just=left] style(column)=[just=left cellwidth=3.00in] ;
	   define col0 /"&trt0|(N=&popcnt0)|n (%)" style(column)=[just=center cellwidth=1.2in] ;
	   define col1 /"&trt1|(N=&popcnt1)|n (%)" style(column)=[just=center cellwidth=1.2in] ;
	   define col2 /"&trt2|(N=&popcnt2)|n (%)" style(column)=[just=center cellwidth=1.2in] ;

	   compute before aebodsys ;
	      line ' ' ;
	   endcomp ;


	run ;

	**----- CLOSE RTF AND RESET TITLES/FOOTNOTES -----**;
	ods rtf close ;
	ods listing ;

	options date number ;
	title ;
	footnote ;

%mend tae ;

%tae(num=1)
%tae(num=2)
