%MACRO MMEXIST(VAR) ;

  %global mmexist;

  options noserror;
  %if %quote(%nrquote(&&&var)) = %nrstr(&)&var %then %let mmexist=NO;
                                               %else %let mmexist=YES;
  options serror;

  %put >>>> mmexist=&mmexist;

%MEND MMEXIST;


/*---------------------------------------------------------------------|
| PROGRAM: MMEXIST.SAS
| PURPOSE: CHECKS WHETHER A MACRO VARIABLE HAS BEEN DEFINED

| AUTHOR:  J.PROGRAMMER   29-DEC-87
| Modified: Mar 1994 - M.PYRE - Turn off macro error message
|
| SEE:     SAS GUIDE TO MACRO PROCESSING, VERSION 6 EDITION, P. 254
| USAGE: %mm_exist(trt);
|        %if &mm_exist = YES %then %do;
|          %put The macro variable trt exists.;
|        %end;
|_____________________________________________________________________*/
