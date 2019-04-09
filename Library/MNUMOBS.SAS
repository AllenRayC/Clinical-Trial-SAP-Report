%macro mnumobs(inset=,numobs=dsobs) ;

   %global &numobs ;
   data _null_ ;
      if 0 then set &inset nobs=numobs ;
      call symput("&numobs", left(put(numobs,5.))) ;
      stop ;
   run ;

%mend mnumobs ;

/**************************************************************************
   PROGRAM:  mnumobs.sas

   CREATED:  12JAN98 C.Matthews


   PURPOSE: determine the number of observations in a dataset

   NOTES:    + if you want the number of obs in a permanent dataset, just include
               the libname with the dataset name (see examples)
             + used outside of a data step

   PARAMETERS:

          INSET = dataset to check (work or permanent dataset)
         NUMOBS = macro variable name to put the number of obs from &inset

   I/O VARIABLES:

        &&NUMOBS = (global) macro variable with the number of obs from &inset

   MACROS USED: none

   EXAMPLES:

      %mnumobs(inset=demo,numobs=indemo)
      results:    &indemo = 35   (35 obs in work.demo)

      %mnumobs(inset=datlib.conmed,numobs=incmed)
      results:    &incmed = 123  (123 obs in datlib.conmed)

*********************************************************************************
PROGRAMMED USING SAS VERSION 6.12
COPYRIGHT (C) 1999 BY BIOCOR, LLC, YARDLEY PA 19067 USA --- ALL RIGHTS RESERVED
*********************************************************************************/
