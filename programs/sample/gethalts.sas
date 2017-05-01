%let wrds=wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=_prompt_;

libname local 'C:\Users\yu_heng\Downloads\';

rsubmit;
proc sort data=crspa.dsf(where=(date>="10Nov2009"d)) out=crsp; by permno date;run;
data crsp;
set crsp;
if HEXCD=1 or HEXCD=2 or HEXCD=3;*NYSE, AMEX, or Nasdaq;
if PRC;
if RET;
if BIDLO;
if BIDLO<0 then delete; *The field is set to zero if it is calculated by the bid price;
if BIDLO=0 then delete; *The field is set to zero if no Bid or Low Price is available;
by permno;
if PRC<0 then delete; * delete bid/ask average price;
* initialize variables;
halt=0;
leftover=0;
affect=0;
refresh=0;

lag_price=ifn(not(first.permno),lag(PRC),.);
dec=(BIDLO-lag_price)/lag_price;
if dec ne . and dec<= -0.10 then halt=1;
lhalt=ifn(not(first.permno),lag(halt),.);
if lhalt=1 then leftover=1;
if halt=1 or leftover=1 then affect=1;
if halt=1 and leftover=1 then refresh=1; 
run;

* form halt records;
proc sql; 
create table records as
select permno, date, halt, affect
from crsp
where halt=1 or affect=1
;quit;

* calculate halt affects;
proc sql;
create table halt as
select date, 
	sum(affect) as affected,
	sum(halt) as halts, 
	sum(refresh) as refreshs,
	count(PRC) as stocks,
	sum(affect)/count(PRC)*100 as pct
from crsp
group by date
order by date
;quit;

proc download data=halt out=my.haltstats;run;
proc download data=records out=my.crsphalt;run;
endrsubmit;



* print the means;
proc means data=my.haltstats MEAN MEDIAN STD P5 P95;run;
