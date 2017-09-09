/*
Last Update: 2016/10/25
This is a test field on getting the file path of IDX and BIN files.
The result is a macro that does all the jobs automatically.
*/




libname ref 'E:\SCB\TAQ\data\sasdata';


%MACRO GetPartition(din=, dout=);

proc sql noprint;
select part into :partition
from ref.part_map
where year=&year and month=&month and 
	&symbol>=start_symbol and &symbol<next_start_symbol
;quit;
%put &partition;
%MEND GetPartition;
%GetPartition(year=2008,month=8,symbol='A');


data query;
input date date9. symbol$;
format date date10.;
datalines;
07jul2008 MSFT
31dec2010 GOOG
31dec2010 AAPL
03aug2009 BAC
;
run;
PROC PRINT DATA=query(OBS=10);RUN;

* merged Partition, Disk, and Root;
proc sql;
create table diskpart as
select Q.*,P.part, D.disk, R.root
from query as Q
left join part as P
on year(Q.date)=P.year and month(Q.date)=P.month
	and  P.start_symbol <= Q.symbol < P.next_start_symbol
left join date2 as D
on Q.date=D.date_new
left join root as R
on R.start_date <= Q.date <= R.end_date
;quit;
PROC PRINT DATA=diskpart(OBS=10);RUN;

data path;
set diskpart;
name_QIDX=cats('Q',put(date,yymmn.),disk,'.IDX');
path_QIDX=catx('\',root, part,name_QIDX);

name_QBIN=cats('Q',put(date,yymmn.),disk,'.BIN');
path_QBIN=catx('\',root, part,name_QBIN);

keep date symbol path:;
run;
PROC PRINT DATA=path(OBS=10);RUN;


/*             END               */

/* MACRO CONSTRUCTION AREA */
%MACRO GetFilePath(din=,dout=);
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

data &dout;
set _partdiskroot;
name_QIDX=cats('Q',put(date,yymmn.),disk,'.IDX');
path_QIDX=catx('\',root, part,name_QIDX);

name_QBIN=cats('Q',put(date,yymmn.),disk,'.BIN');
path_QBIN=catx('\',root, part,name_QBIN);

keep date symbol path:;
run;

%MEND GetFilePath;

* test ;
%GetFilePath(din=query,dout=test);
PROC PRINT DATA=test(OBS=10);RUN;
/* END OF CONSTRUCTION AREA */

%let symbol='GOOG';
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










PROC PRINT DATA=ref.root_map(OBS=10);RUN;

data new_root;
set ref.root_map;
char1=put(start_date,8.);
new_start=input(char1,yymmdd8.);
format new_start date10.;
char2=put(end_date,8.);
new_end=input(char2,yymmdd8.);
format new_end date10.;
drop start_date end_date char1 char2;
rename new_start=start_date;
rename new_end=end_date;
run;
PROC PRINT DATA=new_root(OBS=10);RUN;

proc contents data=new_root;run;

data date2;
set clean;
run;

data sel;
set date2;
date_new = input(tdate, yymmdd8.);
format date_new date10.;
run;

data clean;
set sel(keep=date_new tdate disk);
run;
PROC PRINT DATA=clean(OBS=10);RUN;

%put %year('20090707');

data test;
date='07jul2008'd;
y=year(date);
m=month(date);
d=day(date);
run;
PROC PRINT DATA=test(OBS=10);RUN;
