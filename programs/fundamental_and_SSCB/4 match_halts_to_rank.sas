..* extract the year number from the halts datetime varible;
data withyear_sscb;
set my.halts;
year=year(datepart(Trigger_Time));
run;

* group # of breakers by firm-year;
proc sql;
create table symbolyear_sscb as 
select symbol, year, count(*) as N
from withyear_sscb
group by symbol, year
;quit;

* extract the year from the date variable;
data withyear_funda;
set my.fundamentaldata;
year=year(date);
drop date;
run;

* match fundamental data to sscb;
proc sql;
create table match_funda_sscb as 
select a.*, b.N
from withyear_funda as a
left join symbolyear_sscb as b
on a.symbol=b.symbol and a.year=b.year
;quit;
* save it to local folder;
data my.funda_halts;
set match_funda_sscb;
run;
