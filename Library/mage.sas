%macro mage(indate=icdate,dobvar=birthdt,agevar=age) ;

   if nmiss(&indate,&dobvar)=0 then &agevar =
      (intck('month',&dobvar,&indate) - (day(&indate) < day(&dobvar))) / 12 ;

%mend mage;

/*********************************************************************************************
   PROGRAM:  MAGE.SAS
   CREATED:  29JAN01   C.Matthews
                       Based on a SAS Technical Report by William Kreuter,

   PURPOSE:  Calculates age at somedate when birthdate is known

   NOTES:    + used within a data step
             + When This Won't Work:
               There are only two instances where this approach might fail to yield the
               expected result.  The birthday is February 29, and during non-leap years
               the person celebrates the birthday on February 28. This algorithm would
               treat the birthday during non-leap years as March 1.


   PARAMETERS:

          AGEVAR = name of the variable to contain age (default=age)
          INDATE = name of the variable with the target date (default=icdate)
          DOBVAR = name of the variable with the birth date (default=birthdt)

   I/O VARIABLES:

            &AGEVAR,&INDATE,&DOBVAR (local)
            value of &AGEVAR as a SAS variable

   MACROS USED: none

   EXAMPLES:

      %mage(indate=strtdate)

**********************************************************************************************/
