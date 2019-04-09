%MACRO MDATES(ESTIMATE = NO,
               ESTFLAG = ESTFLAG,
              COMPCHAR = -/,
                INDATE =,
               OUTDATE =,
               OUTFORM = YYMMDD10,
              OUTLABEL =) ;

   /*--- CREATE THE NEW VARIABLES LABEL ---*/

   %if %length(&outlabel)>0 %then %do;
      label &outdate="%upcase(&outlabel)";
   %end;

   /*--- CREATE MO, DY AND YR CHARACTER VARIABLES ---*/

   dy = substr(compress(&indate,"&compchar"),7,2);
   mo = substr(compress(&indate,"&compchar"),5,2);
   yr = substr(compress(&indate,"&compchar"),1,4);

   /*--- ESTIMATE OR NOT DEPENDING ON THE ESTIMATE VALUE ---*/

   %if %upcase(&ESTIMATE)=YES %then
   %do;

      if dy in (' ','00','A') then
         do;
            dy = '01';
            &estflag = 1;
         end;

      if mo in (' ','00','A') then
         do;
            mo = '01';
            &estflag = 1;
         end;

   %end;

   /*--- PUT THE DATE PIECES BACK TOGETHER AND MAKE IT A SASDATE ---*/

   if (mo not in (' ','00','A')  and
       dy not in (' ','00','A')  and
       yr not in (' ','00','A')) then
        &outdate = input((compress(mo||'/'||dy||'/'||yr)),mmddyy10.) ;
   else &outdate = . ;

   %if %upcase(&outform)^= %then
      %do;
         format &outdate &outform.. ;
      %end;

   /**-- DROP VARIABLES THAT ARE NOT NEEDED --*/

   drop mo dy yr;

%MEND MDATES;

/*--------------------------------------------------------------------*
  Program Name  : MDATES.SAS
  Author        : J.Programmer
  Date Created  : October 2012
  Description   : Converts character dates to numeric dates

  Assumptions   : + This program assumes that the character date that
                    is being passed in is in the YYMMDD10. format
                  + Used within a data step

 I/O Variables  :

         ESTIMATE = YES to estimate missing or invalid month and
                    day values. missing months will be set to
                    january, missing days will be set to the first
                    of the month.
          ESTFLAG = variable name to contain the "1" if the month
                    or day were estimated
           INDATE = the character date variable to be converted
          OUTDATE = the outgoing numeric variable
          OUTFORM = the format to apply to the outgoing variable
         OUTLABEL = the label for the outgoing variable
         COMPCHAR = character to compress out of the date

*--------------------------------------------------------------------*/
