/* 
Author: Heng Yue 
Create: 2017-02-28 17:45:36
Desc  : Make the short halts link table. Especially, attach PERMNO and 
other identification variables to the halts observation.
table IN: 
	shohalts.csv
	stocknames.sas7bdat
table OUT:
	halts.sas7bdat
*/

/*Step 1. Import and clean*/
* import original short halts file;
proc import datafile="E:\SCB\data\shorthalts\shohalts.csv" out=halts_original dbms=CSV;
getnames=yes;
run;

* Format the table. Extract the time info from the halts datetime varible;
data halts;
set halts_original;
date=datepart(Trigger_Time);
format date date9.;
time=timepart(Trigger_time);
format time time9.;
year=year(date);
month=month(date);
day=day(date);
hour=hour(time);
minute=minute(time);
second=second(time);
run;
quit;

* Get a feel of the table.;
%histo(din=halts,var=date); * a "U" shape. The number of halts in a day declines until 2014 then rises.;
%histo(din=halts,var=time); * nearly 25% halts happen at 9:30am, when the market opens. There's also a drawf "U" shape from 9:30am to 4:00pm;
%histo(din=halts,var=year);
%histo(din=halts,var=month);
%histo(din=halts,var=day);
%histo(din=halts,var=hour);
%histo(din=halts,var=minute);
%histo(din=halts,var=second);

/*Step 2. Attach additional identification variables.*/
* Attach cusip, permno, permco, and ncusip to the halts table by matching
ticker symbol;
proc sql;
create table halts_mg as
select a.*, b.cusip, b.permno, b.permco, b.ncusip, b.comnam 
from halts as a
left join my.stocknames as b
on a.symbol=b.ticker and b.namedt<a.date<b.nameenddt
;quit;

* compute the ratio of successful matches out of all halts observations;
proc sql noprint; 
select count(*)into:total,
from halts_mg
;quit;
proc sql noprint; 
select count(permno)into:npermno
from halts_mg
;quit;
%put GVKEY match ratio: %sysevalf(&npermno/&total);

/*Step 3.Keep successful matches.*/
data my.halts;
set halts_mg;
if permno;
run;
