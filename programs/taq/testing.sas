data query;
input date date9. symbol$;
format date date10.;
datalines;
07jul2008 MSFT
31dec2010 AAPL
03aug2009 MSFT
;
run;

%GetFilePath(din=query,dout=test);
PROC PRINT DATA=test(OBS=10);RUN;


%GetFilePath(din=query,dout=pathtable);

proc means data=my.shvol var;
var shvol;
output out=_want var=variance;
run;
PROC PRINT DATA=_want(OBS=10);RUN;
data _null;
set _want;
if _N_=1;
call symput("variance",variance);
run;
%put &variance;

%MACRO GetVolatility(din=,var=,vol=);

proc sql noprint;
select count(*) into:total
from query
;quit;

%do j=1 %to &total;
data _null_;
 set query;
 if _n_=&j;
 call symput ('filein',path);
run;

proc means data=&din var;
var &var;
output out=_want var=variance;
run;
data _null;
set _want;
if _N_=1;
call symput("variance",variance);
run;

%let &vol=&variance;
%MEND GetVolatility;

%GetVolatility(din=my.shvol,var=shvol,vol=c);
%put &c;





















**********************************************;
%MACRO ExtractTradeRecords(symbol=,table_TIDX=,table_TBIN=, out=);
* get the Begin and End numbers;
data _a;
set table_TIDX;
if symbol=&symbol then do;
	call symput ('begrec',begrec);
	call symput ('endrec',endrec);
end;
run;

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

%MACRO ReadTBIN(file=,out=);
* read TyyymmX.BIN;
data &out;
infile &file truncover LRECL=19 recfm=f;
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
%ReadTBIN(file="\\Taq\nyse-taq01\TAQ_3\TAQ_May2008_Nov2008\T200807D.BIN",out=b);
PROC PRINT DATA=b(OBS=10);RUN;
%ReadTIDX(file="\\Taq\nyse-taq01\TAQ_3\TAQ_May2008_Nov2008\T200807D.IDX",out=a);
PROC PRINT DATA=a(OBS=10);RUN;
%MACRO ReadTradeFiles(path_tidx=,tidx=,path_tbin=,tbin=);
data &tidx;
infile "&path_tidx" truncover LRECL=22 recfm=f;
input
symbol $char10.
tdate pib4.
begrec pib4.
endrec pib4.
;
run;

data &tbin;
infile "&path_tbin" truncover 
LRECL=19 recfm=f obs=100;
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
