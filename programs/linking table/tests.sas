* comparing crspa.stocknames with crspa.dsenames,
the result shows that the former is much more comprehensive 
than the later;
proc sql;
create table faceon as
select a.permno as permnoA, b.permno as permnoB,
	a.ticker as tickerA, b.ticker as tickerB,
	a.namedt, a.nameenddt,
	a.comnam as nameA, b.comnam as nameB
from stocknames as a
left join DSENAMES as b
on a.permno=b.permno and a.namedt=b.namedt and
	a.nameenddt=b.nameendt
;quit;
PROC PRINT DATA=faceon(OBS=100);RUN;

* using the compa.names file, except null values (no cusip or no ticker), the link between gvkey and cusip is unique;
* gvkey with tiker is unique;
