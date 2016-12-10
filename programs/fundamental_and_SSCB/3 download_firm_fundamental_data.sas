*This program reads the Compustat data on the UNIX server, downloads it to the local computer, and prints it from the local system.
;
%let wrds=wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=_prompt_;

libname local 'C:\Users\yu_heng\Downloads\';

rsubmit;

* Reference to lib COMPUSTAT fundamental annual: compa.funda:
https://wrds-web.wharton.upenn.edu/wrds/tools/variable.cfm?library_id=129&file_id=65811
;

* select compustat datt;
proc sql;
create table seldata as
select 
a.tic as symbol,
a.cusip as cusip,
a.datadate as date,
a.ceq as ceq, /*Common/Ordinary Equity - Total*/
a.OIADP as earnings, /*Operating Income After Depreciation*/
a.CSHO as SHOUT, /*Common Shares Outstanding*/
a.prcc_f as prc, /*Price Close - Annual - Fiscal*/
a.ebitda as ebitda, /*Earnings Before Interest. Cash flow ingredient(1/2)*/
a.capx as capx /*Capital Expenditures. Cash flow ingredient (2/2)*/
from COMPA.funda as a
where '01Jan2011'd<=a.datadate<='07Jan2017'd
;quit;

* delete obs with any missing values;
data want;
 set seldata;
 if cmiss(of _all_) then delete;
 cf=ebitda-capx;
 pdt=SHOUT*prc;
 earning_to_prc=earnings/pdt;
 book_to_market=ceq/pdt;
 cf_to_prc=cf/pdt;
 drop pdt ebitda capx;
run;
* this will be a permanent dataset on the local pc;
proc download data=want out=local.fundamentaldata; 
run;
endrsubmit;

proc print data=local.fundamentaldata (obs=30);
run;
