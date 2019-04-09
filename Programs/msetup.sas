**-------------------------------------------------------------------------------------------**
** PROGRAM:    MSETUP.SAS
** CREATED:    NOVEMBER 2016
** PURPOSE:    SET STUDY-WIDE OPTIONS, LIBRARIES AND MACRO VARIABLES
** PROGRAMMER: A.CHANG
** PROTOCOL:   PROD-124
**-------------------------------------------------------------------------------------------**
** PROGRAMMED USING SAS VERSION 9.3                                                          **
**-------------------------------------------------------------------------------------------**;

**-- DEFINE LIBRARIES --**;

%let xdir = E:\PROD124\ ;
%let opath=&xdir.Output ;	** TLF OUTPUT FOLDER **;

libname rawlib "&xdir.Data\Original" access=readonly ;
libname adslib "&xdir.Data\Analysis" ;
libname sdtmlib "&xdir.Data\SDTM" /* access=readonly */ ;
libname pgmlib "&xdir.Programs" ;

**-- INCLUDE LIBRARY MACROS --**;
%include "&xdir.Library\m*.sas" ;  

**-- ODS TEMPLATE --**;
ods path pgmlib.templat (READ) sashelp.tmplmst (READ) ;		** CONNECT TO STANDARD ODS TEMPLATES **;

options /* fmtsearch=(fmtlib)*/
        mprint
        msglevel=i
		ls=125 
		missing=''
        noreplace
        nocenter
        validvarname = upcase ;

/* 
validvarname - makes all created variables upcase.
ls(linesize) - specifys the number of characters in a line.
msglevel - specifies to print additional notes, such as warning when data is overwritten.
nocenter - left aligns SAS procedure output.
noreplace - specifies that a permanently stored SAS data set cannot be replaced with another 
			SAS data set of the same name
*/

**-- DEFINE GENERIC VARIABLES --**;
%let pat=usubjid ;
%let trt=trt01pn ;
