/* 
Author: Heng Yue 
Create: 2017-01-20 15:08:09
Desc  : Select sample from CRSP daily stock file.
Table IN: None.
Table OUT:
DSF (SAS dataset), daily stock return table
*/

/*
NOTES:
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
/*Step 1. Select stock sample.*/
data stocks;
set crspa.dsfhdr;
if hshrcd=10 or hshrcd=11; * keep domestic stocks, share code 10 or 11;
if HEXCD=1 or HEXCD=3; * keep NYSE(1) and Nasdaq(3) stocks;
if not hsiccd 
	or (6000<=hsiccd and hsiccd<=6999)
	or (4800<=hsiccd and hsiccd<=4999) then delete; * less financials and utilities;
if cusip="08467010"
	or cusip="08467070" then delete; * less Berkshire Hathaway A and B shares;
if length(htsymbol)>4 
	or length(htick)>4 then delete; * less more than 4-letter ticker;
run;

/*Step 2. Select daily stock return data according to your stock sample.*/
* Select daily stock records that is in our stock sample, and the date is 
in our specified time.;
proc sql; 
create table dsf as
select a.*
from crspa.dsf as a
inner join stocks as b
on a.permno=b.permno and '10Nov2009'd<=a.date<='10Nov2011'd
;quit;

/*Step 3. Clease our firm-day sample.*/
* delete observations with missing values;
data dsf2;
set dsf;
if not prc then delete; * delete obs. with missing price;
if not ret then delete; * delete obs. with missing return;
if not bidlo then delete; * delete obs. with missing daily low price;
if prc=0 then delete; * by crsp: a zero price means nor the closing price or the bid/ask average is available;
if prc<0 then delete; * by crsp: a bid/ask average price is marked by a negative sign;
if bidlo=0 then delete; * a zero means neither low price nor last bid is available;
if bidlo<0 then delete; * negative price means it is a last bid price;
run;

proc download data=dsf2 out=my.dsf;run;
endrsubmit;

* report descriptive statistics;
proc means data=my.dsf; run;

