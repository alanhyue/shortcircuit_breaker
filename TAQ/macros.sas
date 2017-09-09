/* 
Author: HENG Yue
Last Update: 2016/10/25
Description:
This macro finds the TAQ IDX and BIN file path for a given
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

keep date symbol path:;
run;

%MEND GetFilePath;
PROC PRINT DATA=test(OBS=10);RUN;

%let symbol='MSFT';
/* store the file path into macro variables */
data _null_;
set test;
if symbol=&symbol then do;
	call symput('path_IDX',path_QIDX);
	call symput('path_BIN',path_QBIN);
end;
run;

%put The IDX file is: &path_IDX;
%put The BIN file is: &path_BIN;

data _Qindex;
infile "&path_IDX" truncover LRECL=22 recfm=f;
input
symbol $char10.
tdate pib4.
begrec pib4.
endrec pib4.
;
run;
/*PROC PRINT DATA=_Qindex(OBS=max);RUN;*/
proc sql noprint;
select begrec, endrec into :beg,:end
from _Qindex
where symbol=&symbol
;quit;

%PUT The index start position is: &beg;
%PUT The index end position is  : &end;

/* read QyyyymmX.bin */
data _Qbin;
infile "&path_BIN" truncover LRECL=27 recfm=f firstobs=&beg obs=&end;
input
qtim pib4.
bid pib4.4
ofr pib4.4
bidsiz pib4.
ofrsiz pib4.
mode pib2.
ex $1.
mmid $4.
;
run;
PROC PRINT DATA=_Qbin(OBS=1000);RUN;
