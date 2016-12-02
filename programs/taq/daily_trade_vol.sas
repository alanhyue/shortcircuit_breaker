* Step1. Construct query table;
* This query is for testing purpose;
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

* Step2. Append file paths to the query;
%GetFilePath(din=query,dout=withpath);
PROC PRINT DATA=withpath(OBS=10);RUN;

* Step3. filter unique date;
proc sort data=withpath(keep=date path_TIDX path_TBIN) nodupkey;
by date;
run;
*           For testing purpose;
data withpath;
set withpath(drop=path:);
if date="09aug2010"d then do;
	path_TIDX="c:\Users\yu_heng\Downloads\T201008F.IDX";
	path_TBIN="c:\Users\yu_heng\Downloads\T201008F.BIN";
end;
if date="24feb2011"d then do;
	path_TIDX="c:\Users\yu_heng\Downloads\T201102Q.IDX";
	path_TBIN="c:\Users\yu_heng\Downloads\T201102Q.BIN";
end;
run;
PROC PRINT DATA=withpath(OBS=10);RUN;

* Step 4.;
%MACRO LoopDates(query=,path_table=,dout=);
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
%LoopDates(query=query,path_table=withpath,dout=bb);
PROC PRINT DATA=bb(OBS=100);RUN;

* Step5. loop symbols;
%MACRO GetVolatility(idx_table=,bin_path=,dout=);
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
* Step5.2. Calculate variance;
proc means data=_bin var noprint;
var price;
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
%GetVolatility(idx_table=begin_end, bin_path="c:\Users\yu_heng\Downloads\T201102Q.BIN",dout=want);

PROC PRINT DATA=want(OBS=10);RUN;
*Step6. drop unnecessary columns.Save the table to local drive.;
data my.trade_vol;
set withvar(keep=symbol var);
run;

%let symbol="AAXJ";
%let var="0.87";
data withvar;
set withvar;
if symbol=&symbol then var=&var;
run;
PROC PRINT DATA=_withvar(OBS=10);RUN;
