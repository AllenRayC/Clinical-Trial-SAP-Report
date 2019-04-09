%macro mrelday(add     =1,
               basevar =rfstdt,
                 invar =,
                outvar =days,
               outlabel=) ;

   /*-- LABEL NEW VAR IF NECESSARY ---------------------------------------*/

   length &outvar 4.;
   %if %length(&outlabel)>0 %then
      %do;
         label &outvar="&outlabel";
      %end;

   /*-- IF DATA EXISTS... --*/

   if nmiss(&basevar,&invar)=0 then
      do;

         /*-- CALCULATE FOR PRE DOSE --*/

         if (&invar-&basevar) < 0 then &outvar = &invar - &basevar;

         /*-- CALCULATE FOR STUDY DAY 1 TO END --*/

         else &outvar = (&invar - &basevar) + &add;

      end;

%MEND MRELDAY;

/**************************************************************************
   PROGRAM:   MRELDAY.SAS
   CREATED:   13JAN99  C.Matthews
   MODIFIED:

   PURPOSE:   Calculates the number of relative days from one variable to the other

   NOTES:     + assumes dates coming in are SAS dates
              + used within a data step

   PARAMETERS:

           ADD = the number of days to add to the product (default=1).
                 Used if the BASEVAR is to be considered a full study day.
       BASEVAR = the base value of the relative days calculation.
                 (usually start/baseline date, default=rfstdt)
         INVAR = the comparison value of the relative day calculation
                 (usually visit date)
        OUTVAR = the output variable containing the relative number of days
                 between &basevar and &invar (default=days)
      OUTLABEL = the label for the output variable

   I/O VARIABLES: none

   MACROS USED:   none

   EXAMPLE1: %mrelday(basevar=dmrefdt,invar=aestart,outvar=aerelsdy,
                      outlabel=Relative start date of ae)
             result:
               if dmrefdt = 01/15/97 and aestart = 01/18/97 then
               aerelsdy = 4  (ae started on the 4th day of the study)
               label for aerelsdy = Relative start date of ae

   EXAMPLE2: %mrelday(add=0,basevar=startdt,invar=stopdt,outvar=relstop,
                      outlabel=Relative stop date of med)
             result:
               if startdt = 01/15/97 and stopdt = 01/18/97 then
               relstop = 3  (med stopped 3 days after it started)
               label for relstop = Relative stop date of med

*********************************************************************************
PROGRAMMED USING SAS VERSION 6.12
*********************************************************************************/
