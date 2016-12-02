/* 
Author: HENG Yue
Last Update: 2016/12/01
Description:
This macro finds the TAQ TIDX/TBIN (tarde) and QIDX/QBIN (quote) file path for a given
security symbol at a specific date. Form your query as a table,
then pass it through the din= parameter, specify the name of the 
result table in the dout= parameter.

Example of the query table:
data query;
input date date9. symbol$;
format date date10.;
datalines;
07jul2008 MSFT
31dec2010 AAPL
03aug2009 MSFT
;
run;

To test the macro:
%GetFilePath(din=query,dout=test);
PROC PRINT DATA=test(OBS=10);RUN;
*/
%MACRO GetFilePath(din=,dout=);
* define the location of our partition and folder path map tables;
libname ref 'E:\SCB\TAQ\data\sasdata';
* attach the partition and folder path info to the desired security(s);
proc sql;
create table _partdiskroot as
select Q.*,P.part, D.disk, R.root
from &din as Q
left join ref.part_map as P
on year(Q.date)=P.year and month(Q.date)=P.month
	and  P.start_symbol <= Q.symbol < P.next_start_symbol
left join ref.date2 as D
on Q.date=D.date_new
left join ref.root_map as R
on R.start_date <= Q.date <= R.end_date
;quit;
* using the infomation provided by the previous SQL step,
clean & construct the full file path;
data &dout;
set _partdiskroot;
name_QIDX=cats('Q',put(date,yymmn.),disk,'.IDX');
path_QIDX=catx('\',root, part,name_QIDX);

name_QBIN=cats('Q',put(date,yymmn.),disk,'.BIN');
path_QBIN=catx('\',root, part,name_QBIN);

name_TIDX=cats('T',put(date,yymmn.),disk,'.IDX');
path_TIDX=catx('\',root,name_TIDX);

name_TBIN=cats('T',put(date,yymmn.),disk,'.BIN');
path_TBIN=catx('\',root,name_TBIN);

keep date symbol path:;
run;

%MEND GetFilePath;


* Macro ReadTIDX
Author:Heng Yue
Update: 20161201 18:22:31
Description:
Read a TIDX file.

Parameters:
file=, the path to the TIDX file.
out=, the table you want to store the result in.
;
%MACRO ReadTIDX(file=,out=);
data _tidx;
infile &file truncover LRECL=22 recfm=f;
input
symbol $char10.
tdate pib4.
begrec pib4.
endrec pib4.
;
run;

data &out;
set _tidx;
run;
%MEND ReadTIDX;

* Macro ReadTBIN
Author:Heng Yue
Update: 20161201 18:27:14
Description:
Read a TBIN file.

Parameters:
file=, the path to the TBIN file.
out=, the table you want to store the result in.
;
%MACRO ReadTBIN(file=,out=,beg=,end=);
* read TyyymmX.BIN;
data &out;
infile &file truncover LRECL=19 recfm=f
firstobs=&beg obs=&end;
input
ttim pibr4.
price pibr4.4
siz pibr4.
G127 pibr2.
corr pibr2.
cond $2.
ex $1.
;
run;
%MEND ReadTBIN;


* Macro: GetVolatility
Author:Heng Yue
Update: 20161201 22:13:54
Description:
find and calculate the trade-to-trade volatility for a security.
This macro funtion is usually called by another function %LoopDates.

Usage:
idx_table=, is the index table. It should contain 3 columns, which are
named exactly as: symbol | begrec | endrec.
bin_path= is the path of the corresponding TBIN file.
dout= is the table to store the result.
;
%MACRO GetVolatility(idx_table=,bin_path=,dout=);
* Step5. loop symbols;
* make a copy of the original table;
data _withvar;
set &idx_table;
var=0; * add a new variable: variance;
run;
* count the number of symbols, this is used in the next loop step;
proc sql noprint;
select count(*) into:total
from _withvar
;quit;
* Loop through all symbols;
%do j=1 %to &total; *beginning of the loop;
data _null_;
set _withvar;
 if _n_=&j then do;
 call symput ('symbol',symbol);
 call symput ('beg',begrec);
 call symput ('end',endrec);
end;
run;
* write information to the log;
%put symbol is &symbol;
%put begin record is &beg;
%put end   record is &end;
* Step5.1. Read trade-by-trade data from TBIN;
%ReadTBIN(file=&bin_path,out=_bin,beg=&beg,end=&end);
* calculate returns from price;
data _returns;
set _bin;
ret=(price-lag(price))/lag(price);
run;
* Step5.2. Calculate variance;
proc means data=_returns var noprint;
var ret;
output out=_want var=variance;
run;
* Step5.3. Append the variance to the table;
data _null_;
set _want;
if _N_=1;
call symput("var",variance);
run;
* write info to the log;
%put symbol is &symbol;
%put the variance is &var;
* update the variance to the table;
data _withvar;
set _withvar;
if symbol="&symbol" then var=&var;
run;
%end; *end of the loop;
*copy result to output table;
data &dout;
set _withvar;
run;
%MEND GetVolatility;

/* Macro LoopDates
Author:Heng Yue
Update: 20161201 22:18:38
Description:
Calculate the trade-to-trade volatility for different date.

Usage:
query= is the query table. Which contains two columns that are named 
exactly as: date | symbol.
path_table= is the table that contains the file path to TIDX and TBIN files. Which
contains 3 columns that are named exactly as: date | path_TIDX | path_TBIN.
dout= is the table to store the result.

Example:
data query;
input date date9. symbol$;
format date date10.;
datalines;
09aug2010 MSFT
09aug2010 AAPL
24feb2011 MSFT
24feb2011 AAXJ
;
run;
*/
%MACRO LoopDates(query=,path_table=,dout=);
* Step 4.;
* count the number of dates, this is used in the next loop step;
proc sql noprint;
select count(*) into:total_dates
from &path_table
;quit;
* Loop through all symbols;
%do i=1 %to &total_dates; *beginning of the loop;
%put Loop dates, &i/&total_dates;
data _null_;
set &path_table;
 if _n_=&i then do;
 call symput ('date',put(date, yymmddn8.));
 call symput ('path_TIDX',path_TIDX);
 call symput ('path_TBIN',path_TBIN);
end;
run;
* write info to log;
%put the date is &date;
%put path of TIDX file: &path_tidx;
%put path of TBIN file: &path_tbin;
* Step4.1. Read TIDX;
/*%let path_tidx="c:\Users\yu_heng\Downloads\T201102Q.IDX";*/
/*%let path_tbin="c:\Users\yu_heng\Downloads\T201102Q.BIN";*/
%ReadTIDX(file="&path_tidx",out=_idx);
* Step4.2. Merge it with symbol list for this date;
* remove duplicated dates;
proc sort data=&query(keep=symbol) out=symbol_list nodupkey;
by symbol;
run;
* append the begin and end records to the query;
proc sql noprint;
create table with_beg_end as
select b.*
from symbol_list as a
left join _idx as b
on a.symbol=b.symbol
;quit;
* get the volatility;
%GetVolatility(idx_table=with_beg_end,bin_path="&path_tbin",dout=_a);
* append to the result table;
proc append base=_result data=_a;run;
%end; * end of the loop;
* copy the result table to the output table;
data &dout;
set _result;
run;
/*PROC PRINT DATA=symbol_list(OBS=10);RUN;*/
***delete temporary datasets;
proc datasets lib=work memtype=data nolist;
delete _result;
quit;
%MEND LoopDates;
