/* 
Author: Heng Yue 
Create: 2017-01-10 19:14:48
Update: 2017-01-10 19:48:42
Desc  : Merge with fundamentals and rank by fundamentals.
*/

* permno to gvkey;
%let din=my.neginfo_dsf_test;
%let dout=mged;

proc sql;
create table &dout as
select a.*, b.gvkey
from &din as a
left join static.ccmxpf_linktable as b
on a.permno=b.lpermno and b.linkdt<=a.date<=b.linkenddt
;quit;

data validobs;
set &dout;
if gvkey;
run;

* dld fundamentals;
%let wrds=wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=_prompt_;

libname local 'C:\Users\yu_heng\Downloads\';

rsubmit;
proc upload data=validobs(keep=date gvkey permno) out=validobs;run;
* select compustat datt;
proc sql;
create table seldata as
select 
a.*,
b.tic as symbol,
b.cusip as cusip,
b.datadate as date,
b.fyear as fyear,
b.AT as AT, /* Asset total*/
b.EBITDA as EBITDA, /*Earnings Before Interest. Cash flow ingredient(1/2)*/
b.ceq as ceq, /*Common/Ordinary Equity - Total*/
b.OIADP as earnings, /*Operating Income After Depreciation*/
b.CSHO as SHOUT, /*Common Shares Outstanding*/
b.prcc_f as prc, /*Price Close - Annual - Fiscal*/
b.capx as capx /*Capital Expenditures. Cash flow ingredient (2/2)*/
from validobs as a
left join compa.funda as b
on a.gvkey=b.gvkey and b.fyear=year(validobs.date)
order by gvkey, fyear
;quit;

* delete obs with any missing values;
* delete obs with negative AT;
* delete obs with negative numerator. i.e. CF, earnings, ceq;
* delete obs with zero shares outstanding or zero share price;
data want;
 set seldata;
 if cmiss(of _all_) then delete;
 if AT <=0 then delete;
 cf=ebitda-capx;
 if cf<0 then delete;
 if earnings<0 then delete;
 if ceq<0 then delete;
 pdt=SHOUT*prc;
 if pdt<=0 then delete;
 earning_to_prc=earnings/pdt;
 book_to_market=ceq/pdt;
 cf_to_prc=cf/pdt;
 ROA=EBITDA/AT;
 size=log(AT);
 drop pdt capx;
run;
proc download data=want out=funda; 
run;
endrsubmit;

* taking time-series average;
proc sql;
create table funda_avg as
select permno,
AVG(size) as size_avg,
AVG(ROA) as ROA_avg,
AVG(ceq) as ceq_avg,
AVG(earnings)as earnings_avg,
AVG(earning_to_prc) as earning_to_prc_avg
from funda
group by permno
order by permno
;quit;

* merge funda with beta rank;
proc sql;
create table mg_funda_ranked as
select a.*, b.*
from my.ranked_sector_beta as a
left join funda_avg as b
on a.permno=b.permno
;quit;

* save to local drive;
data my.merged_funda_ranked;
set mg_funda_ranked;
run;
