/*
Author: Heng Yue
Date: 2016/10/21 
This program is designed to find out firms that exists constantly from
the beginning (May 2008) to the end (Dec 2011).
*/
proc import out=firms datafile='C:\Users\yu_heng\Downloads\firms2008to2011.xlsx' dbms=xlsx replace;
getnames=yes;
run;quit;

/* daw a sample from the original data for code testing purposes */
/*data sample;*/
/*set firms(obs=10000);*/
/*run;*/
/*proc delete data=firms;quit;*/
/*data firms;*/
/*set sample;*/
/*run;*/

/* select only firms that satisfy the following requirements:
1. exists consistantly from May 2008 to Dec 2011.
2. always have an "A (active)" trading status
*/
proc sql;
create table const_firms as
select distinct permco, permno
from firms
where trading_status = 'A'
group by permno
having count(*)=44
;quit;
/*PROC PRINT DATA=const_firms(OBS=50);RUN;*/
proc export data=const_firms outfile="C:\Users\yu_heng\Downloads\const_security.xlsx" dbms=xlsx replace;run;

/*print and verify the number of observations for the firms*/
/*proc sql;*/
/*select distinct permco, trading_status, ticker_symbol, company_name, count(*) as N*/
/*from const_firms*/
/*group by permco*/
/*;quit;*/
