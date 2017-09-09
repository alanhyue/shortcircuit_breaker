/* 
Author: Heng Yue 
Create: 2017-04-12 13:54:23
Desc  : get the firm characteristics ditribution of the sample firms.
*/

%include "../volatility/dsfcalculation.sas";

data wantdsf;
set dsf;
run;

* descriptive statistics;
proc means data=wantdsf MEAN MEDIAN P5 P95;
var PRC intraday_decline VOL mktValue;
run;

* number of stocks;
proc sql;
select count(unique(permno)) as numstocks
from wantdsf
;quit;
*the number of unique firms;
proc sql;
create table firms as
select unique(permco) as permco
from wantdsf
;quit;
proc sql;
select count(*) as uniquefirms
from firms
;quit;

* number of halts;
proc sql;
create table halts as
select date, sum(HALT_DUM) as nhalts, 
sum(EFFECT_DUM) as naffects, 
sum(EFFECT_DUM)/count(PRC) as pctaffect,
count(PRC) as nstocks
from wantdsf
group by date
;quit;
proc means data=halts;quit;

***** firm characteristics***;
* match GVKEY;
PROC SORT DATA = static.ccmxpf_linktable out=lnk;
	WHERE linktype in ("LU", "LC", "LD", "LN", "LO", "LS", "LX") AND usedflag = 1
	AND NOT MISSING(lpermco) AND NOT MISSING(gvkey);
	BY gvkey linkdt;
run;

proc sql;
create table firmgvkey as
select a.*, b.gvkey 
from firms as a
left join lnk as b
on a.permco=b.lpermco and year(b.linkdt)<=2009 and (b.linkenddt = .E or 2010<=year(b.linkenddt))
;quit;

proc sql;
select count(*) as tot, count(gvkey) as gvkmatch, count(gvkey)/count(*) as pct
from firmgvkey
;quit;

* get compustat data;
%let wrds=wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=_prompt_;

libname local 'C:\Users\yu_heng\Downloads\';

rsubmit;
proc upload data=firmgvkey out=mygvkey;run;
proc sql;
create table fund as
select a.*, b.???
from mygvkey as a
left join compa.funda as b
on a.gvkey = b.gvkey and b.fyear=2009
;quit;
proc download data=fund out=my.fund;run;
endrsubmit;

PROC PRINT DATA=firmgvkey(OBS=10);RUN;
