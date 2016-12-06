* Step1. Construct query table;
libname my 'C:\Users\yu_heng\Downloads\';
proc sql;
create table permno_dat as
select permno, date, count(*) as N
from my.permnodata
group by permno
;quit;
proc sql;
create table query as
select a.permno, a.date, b.htick as symbol
from permno_dat as a
left join my.permno_to_ticker as b
on a.permno=b.permno
;quit;
proc sort data=query;
by permno date;
run;
*use a sample of the dataset;
data query;
set query;
/*if _n_<1000;*/
if "17Jun2008"d<=date<="31Dec2011"d;
run;
PROC PRINT DATA=query(OBS=100);RUN;

* This query is for testing purpose;
/*data query;*/
/*input date date9. symbol$;*/
/*format date date10.;*/
/*datalines;*/
/*09aug2010 MSFT*/
/*09aug2010 AAPL*/
/*24feb2011 MSFT*/
/*24feb2011 AAXJ*/
/*;*/
/*run;*/

* Step2. Append file paths to the query;
%GetFilePath(din=query,dout=withpath);
PROC PRINT DATA=withpath(OBS=10);RUN;

* Step3. filter unique date;
proc sort data=withpath(keep=date path_TIDX path_TBIN) nodupkey;
by date;
run;
PROC PRINT DATA=withpath(OBS=max);RUN;

*Step4. Loop dates. Step5. Loop symbols.;
%LoopDates(query=query,path_table=withpath,dout=result);

*Step6. drop unnecessary columns.Save the table to local drive.;
data my.trade_vol;
set result;
run;

PROC PRINT DATA=result(OBS=max);RUN;
