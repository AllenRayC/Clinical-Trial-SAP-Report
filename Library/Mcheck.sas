%macro mcheck(inset=check,why=,warn=Y) ;

   /* IF CHECK DATASET HAS OBS THEN PRINT AND WARN IN LOG */

   %mnumobs(inset=&inset,numobs=cccc)
   %if &cccc ne 0 %then
      %do ;

         %if %upcase(&warn)=Y %then %put WARNING: &why ;

         proc print data=&inset ;
            title "MCHECK: &why" ;
         run ;
         title;

      %end ;

%mend mcheck ;

/**************************************************************************
   PROGRAM:   MCHECK.SAS
   CREATED:   12JAN99 C.Matthews
   MODIFIED:  04JAN99 - put print inside of obs checking loop
              16MAR00 - add WARN option so LOG warning message is optional

   PURPOSE:   prints checking datasets and puts a warning note in the log

   NOTES:     + used outside of a data step

   PARAMETERS:

         INSET = Dataset to print (default=CHECK)
           WHY = Title for proc print and warning message for the log
          WARN = (Default=Y) print warning in log if Y

   I/O VARIABLES:

          &cccc = (global) number of obs in &inset

   MACROS USED:  %mnumobs

   EXAMPLE:

      data good check ;
         merge ds1 (in=in1)
               ds2 (in=in2) ;
         if in1 and in2 then output good ;
         else if in1 and not in2 then output check ;
      run ;

      %mchecj(why=IN DS1 BUT NOT INDS2?!)

      result:

         proc print of all obs in the CHECK dataset, title on the output is
           'IN DS1 BUT NOT IN DS2?!' (ONLY if CHECK dataset has observations)
         if CHECK dataset has observations, a line in the .log will say
           WARNING: IN DS1 BUT NOT IN DS2?!

*********************************************************************************
PROGRAMMED USING SAS VERSION 6.12
COPYRIGHT (C) 1999 BY BIOCOR, LLC, YARDLEY PA 19067 USA --- ALL RIGHTS RESERVED
*********************************************************************************/
