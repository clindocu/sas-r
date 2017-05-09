;/******************************************************************;
*      PROGRAM: saschk_format.sas
*      VERSION: 0.2.0
*       AUTHOR: @aleaiacta
********************************************************************;
*  DESCRIPTION: This program performs data checks regarding values that 
*               are in the database but not in proc format (and vice versa);
********************************************************************;
*        INPUT: Files generated from SAS program sas_r.sas;
*               (run this program directly after sas_r.sas);
********************************************************************;
*       OUTPUT: Value is in Database, but not in format catalog (critical errors)
*               Value is in format catalog, but not in Database (warnings);
********************************************************************;
* DEVELOPED ON: Windows 64-bit, SAS 9.4 TS Level 1M4, R 3.3.2;
********************************************************************;
*    TESTED ON: Windows 64-bit, SAS 9.4 TS Level 1M4, R 3.3.2
********************************************************************;
* 
* SAS MACRO(S): %Read, %ReadAll, %ChkFormat, %CheckAll;
*
* PROGRAM HISTORY:
*  DATE MODIFIED  USERID      COMMENT
*  -------------  ----------  ----------------------------------------------
*  23Feb2017      alea        Initialization of db03_formats_files modified to avoid errors 
*                             when there are no user-defined formats in the database;
*  03Mar2017      alea        split="~~" in proc report added for better readability (no line break with /);
*  08Mar2017      alea        strip removed from LABEL=strip(vvalue(&FORMVAR)), semicolon ; prior run added;
*  09Mar2017      alea        Modifications regarding sas_r.sas (instead of SAS program sasxpt_r.sas);
******************************************************************************/;

;/******************************************************************;
********** DATA CHECKS REGARDING FORMAT ASSIGNMENTS
********** 
********** ---- BEGIN ----------------------------------------------;
********************************************************************/

********** Select all files with user defined formats;
data db03_User_Defs;
    set db01_DDT_FINAL (keep=MEMNAME NAME FORMAT DECODE where=(DECODE ne ""));
run;
proc sort data=db03_User_Defs; by FORMAT; run;

********** Initialize File - Database with 'distinct' formats/labels;
data db03_formats_files;
    format LABEL $200. MEMNAME $32. NAME $32. INDATAFRAME $1.;
    LABEL="";
    NAME="";
    MEMNAME="";
    INDATAFRAME="";
    delete;
run;

********** Macro for counting distinct formats/labels in SAS database;
********** Similar to 'proc freq data=&INDB, table FORMVAR;
%macro ChkFormat(INDB, FORMVAR);
;/********** Temporary File */ 
data db03_Temp;
    format LABEL $200.;
    set &INDB;
    LABEL=vvalue(&FORMVAR);
    ;/********** Exclude missings values */ 
    if not missing(&FORMVAR);
run;

proc sql;
create table db03_chk1 as 
       select distinct LABEL,
              "&INDB" format=$32. length=32 as MEMNAME, 
              "&FORMVAR" format=$32. length=32 as NAME,
              "Y" as INDATAFRAME
       from db03_Temp;
run;
quit;
;/********** Append with previously generated dataset (if available) */ 
proc append base=db03_formats_files data=db03_chk1; run; quit;

%mend ChkFormat;

%macro CheckAll();
    ;/********** Read all files with user defined formats and make a freq. distribution of categories */ 
    data _null_; 
        set db03_User_Defs;
        call execute('%ChkFormat(' ||trim(MEMNAME)|| ', ' ||trim(NAME)|| ');');
    run;
%mend CheckAll;

%CheckAll;

proc sort data=db03_formats_files; by MEMNAME NAME LABEL; run;

********** Generate alphabetic Order of formats/labels (not by 'rank');
data db03_formats2;
    set db00_formats;
run;
proc sort data=db03_formats2; by FULL_FNAME LABEL; run;

********** Exclude missing formats/labels (should not be counted as discrepancies); 
data db03_formats3;
    set db03_formats2 (keep=FULL_FNAME LABEL FORM rename=FULL_FNAME=FORMAT
                       where=(not(FORM eq "." or missing(dequote(FORM))))); * do not read 'missing' formats ;
    INFORMDEF="Y";
run;
proc sort data=db03_formats3; by FORMAT; run;

********** SQL Join (Database with Formats and Database with Decodes of Formats/value labels); 
proc sql;
create table db03_CHK_Final1a as 
    select a.MEMNAME, a.NAME, a.FORMAT, b.LABEL, b.INFORMDEF
    from db03_User_Defs as a left join db03_formats3 as b
    on a.FORMAT=b.FORMAT
    order by MEMNAME, NAME, FORMAT, LABEL;
quit;

********** Merge files: (1) Database with Formats/Decodes AND (2) Database with Values;
data db04_Final_Checks;
    merge db03_CHK_Final1a db03_formats_files;
    by MEMNAME NAME LABEL;
    format ERRMSG $9. ERRMSG2 $41.;
    if INFORMDEF="Y" and INDATAFRAME="" then do;
       ERRMSG="Warning";
       ERRMSG2="Format defined but not in Database";
       end;
    if INFORMDEF="" and INDATAFRAME="Y" then do;
       ERRMSG="ERROR!!!!";
       ERRMSG2="Value in Database but not in proc format";
       end;
label INFORMDEF="Proc Format"
INDATAFRAME="In Database"
ERRMSG="Type Error"
ERRMSG2="Explanation";
run;

********** Select all formats with error or warnings;
proc sql;
create table db04_Final_Errors as 
    select *
    from db04_Final_Checks 
    group by MEMNAME, NAME
    having COUNT(ERRMSG)>0
    order by MEMNAME, NAME, FORMAT desc, LABEL;
quit;

title1 "sasformat_chk.sas Errors and Warnings regarding Values in Database and defined Formats";
footnote1 "NOTE: In case of 'ERROR!!!!' (critical) the value will be assigned to 'NA' in R (w/o warnings)";
footnote2 "Extend SAS Format Definitions (highly recommended!)";
footnote3 "NOTE: In case of 'Warning' review Format Definitions (changes not necessary)";
proc report data=db04_Final_Errors nowd split="~~" ls=160 headskip headline missing;
    column MEMNAME NAME FORMAT LABEL INFORMDEF INDATAFRAME ERRMSG ERRMSG2;
    define MEMNAME / width=10 flow order;
    define NAME / width=10 order;
    define FORMAT / width=12 flow order descending;
    define LABEL / width=45 flow;
    define INFORMDEF / width=7 flow;
    define INDATAFRAME / width=9 flow;
    define ERRMSG / width=10;
    define ERRMSG2 / width=41 flow;
    break after MEMNAME / skip;
    break after NAME / skip;
run;

;/******************************************************************;
********** DATA CHECKS REGARDING FORMAT ASSIGNMENTS
********** 
********** ---- END ------------------------------------------------;
********************************************************************/
