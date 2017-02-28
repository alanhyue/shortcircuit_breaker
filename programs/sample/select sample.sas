/* 
Author: Heng Yue 
Create: 2017-01-20 15:08:09
Desc  : Select sample.
*/

/*
Name 											8-digit CUSIP
Berkshire Hathaway Inc. Cl 'A' COM              08467010
Berkshire Hathaway Inc. Cl 'B' COM              08467070

Financials SIC codes 6000-6999
Utilities SIC codes 4800-4999
*/

%let wrds=wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=_prompt_;

libname local 'C:\Users\yu_heng\Downloads\';

rsubmit;
data sample_permno;
set crspa.dsfhdr;
if hshrcd=10 or hshrcd=11; * keep domestic stocks, share code 10 or 11;
if not hsiccd 
	or (6000<=hsiccd and hsiccd<=6999)
	or (4800<=hsiccd and hsiccd<=4999) then delete; * less financials and utilities;
if cusip="08467010"
	or cusip="08467070" then delete; * less Berkshire Hathaway A and B shares;
if length(htsymbol)>4 
	or length(htick)>4 then delete; * less more than 4-letter ticker;
run;

proc sql; 
create table sample_price_daily as
select a.*
from crspa.dsf as a
inner join sample_permno as b
on a.permno=b.permno and '01Jan2007'd<=a.date<='31Dec2013'd
;quit;
data sample_price_daily2;
set sample_price_daily;
if prc=0 then delete; * by crsp: a zero price means nor is the closing price or the bid/ask average is available;
if prc<0 then prc=-prc; * by crsp: a bid/ask average price is marked by a negative sign;
run;
proc sql;
create table sample_price_daily3 as
select *
from sample_price_daily2
group by permno
having count(PRC)=1762 
;quit;* keep stocks exist throught the period;

proc download data=sample_permno out=my.sample_permno;run;
proc download data=sample_price_daily3 out=my.sample_price_daily;run;
endrsubmit;
