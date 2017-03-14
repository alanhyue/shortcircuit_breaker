libname static "E:\SCB\data" access=readonly;
libname ff "E:\SCB\data\ff" access=readonly;
libname my "C:\Users\yu_heng\Downloads\";
libname taqref 'E:\SCB\TAQ\data\sasdata';

%MACRO prank(din=,var=);
proc sql;
select &var._rank, 
count(*) as N, 
AVG(&var) as &var._avg, 
MAX(&var) as &var._max, 
MIN(&var) as &var._min
from &din
group by &var._rank
;quit;
%MEND prank;

%MACRO psort(din=,var=,order=1,n=10);
%IF &order=1 %THEN %DO;* sort large to small;
proc sort data=&din out=_temp;
by DESCENDING &var; run;
%END;
%ELSE %DO;* sort small to large;
proc sort data=&din out=_temp;
by &var; run;
%END;
PROC PRINT DATA=_temp(OBS=&n);RUN;
proc delete data=_temp;run;
%MEND sp;

%MACRO histo(din=,var=);
proc univariate data=&din;
var &var;
histogram &var;
run;
%MEND histo;

%MACRO Rank(din=,dout=,var=,n=10);
proc sort data=&din out=_temp;
by year symbol;
run;

proc rank data=_temp out=_temp2 group=&n ties=low;
/*by year;*/ * rank firm-year observation;
var &var;
ranks &var._rank;
run;

data &dout;
set _temp2;
run;
%MEND Rank;

%MACRO AppendSSCBDummy(din=,dout=);
data &dout;
set &din;
if date<="10Nov2010"d then dsscb=0;
else dsscb=1;
run;quit;
%MEND AppendSSCBDummy;


%MACRO Winsorize(din=,dout=,var=,pct=1);
proc sort data=&din out=_temp;
by &var;
run;
proc sql noprint;
select count(*) into:nobs
from _temp
;quit;
%let chunk=%eval(&nobs*&pct/100);
%let begrec=%eval(0+&chunk);
%let endrec=%eval(&nobs-&chunk);
%put There are &nobs observations.;
%put Winsorizing the lowest and highest &pct percent.;
%put &pct percent corresponds to &chunk observations.;
data &dout;
set _temp(firstobs=&begrec obs=&endrec);
run;
proc delete data=_temp;run;
%MEND Winsorize;


%MACRO TickerLinkPermno(din=,dout=);
%put ---------------------------------------;
%put Macro function: TickerLinkPermno;
%put The input table (din) has to have two columns named ;
%put exactly as Ticker and Date.; 
%put Column Ticker: the ticker symbol.;
%put Column Date: the corresponding date, including year, month, and day. In the format of YYYYMMDD.;
%put ---------------------------------------;
proc sql;
create table &dout as
select a.ticker, b.permno, a.*
from &din as a
left join stocknames as b
on a.ticker=b.ticker and b.namedt<a.date<b.nameenddt
;quit;
%MEND TickerLinkPermno;

%MACRO TickerLinkCusip(din=,dout=);
%put ---------------------------------------;
%put Macro function: TickerLinkCusip;
%put The input table (din) has to have two columns named ;
%put exactly as "Ticker" and "Date".; 
%put Column Ticker: the ticker symbol.;
%put Column Date: the corresponding date, including year, month, and day. In the format of YYYYMMDD.;
%put ---------------------------------------;
proc sql;
create table &dout as
select a.ticker, b.cusip, a.*
from &din as a
left join stocknames as b
on a.ticker=b.ticker and b.namedt<a.date<b.nameenddt
;quit;
%MEND TickerLinkCusip;
%MACRO TickerLinkPermco(din=,dout=);
%put ---------------------------------------;
%put Macro function: TickerLinkPermco;
%put The input table (din) has to have two columns named ;
%put exactly as "Ticker" and "Date".; 
%put Column Ticker: the ticker symbol.;
%put Column Date: the corresponding date, including year, month, and day. In the format of YYYYMMDD.;
%put ---------------------------------------;
proc sql;
create table &dout as
select a.ticker, b.permco, a.*
from &din as a
left join stocknames as b
on a.ticker=b.ticker and b.namedt<a.date<b.nameenddt
;quit;
%MEND TickerLinkPermco;



%MACRO TickerLinkAll(din=,dout=);
%put The input table (din) has to have two columns named ;
%put exactly as "Ticker" and "Date".; 
%put Column Ticker: the ticker symbol.;
%put Column Date: the corresponding date, including year, month, and day. In the format of YYYYMMDD.;
%put ---------------------------------------;
proc sql;
create table &dout as
select a.ticker, b.cusip, b.permno, b.permco, b.ncusip, b.comnam, a.*
from &din as a
left join stocknames as b
on a.ticker=b.ticker and b.namedt<a.date<b.nameenddt
;quit;

proc sql noprint; 
select count(*)into:total
from &dout
;quit;

proc sql noprint; 
select count(permno)into:npermno
from &dout
;quit;

%put overall* fill ratio: %sysevalf(&npermno/&total);
%put *using permno fill ratio as a proxy for;
%put cusip, permno, permco, ncusip, and company name..;
%MEND TickerLinkAll;





**********************match COMPUSTAT*****;
%MACRO CusipLinkGvkey(din=,dout=);
%put The input table (din) has to have a named ;
%put exactly as "Cusip"; 
%put Column Cusip: the 8-digit Cusip.;
%put ---------------------------------------;

data nonull;
set names;
if cusip='' then delete;
cusip=substr(cusip,1,8);
run;

proc sql;
create table &dout as
select a.cusip, b.gvkey, a.*
from &din as a
left join nonull as b
on a.cusip=b.cusip
order by ticker
;quit;

proc sql noprint; 
select count(*)into:total
from &dout
;quit;

proc sql noprint; 
select count(gvkey)into:ngvkey
from &dout
;quit;

%put overall gvkey fill ratio: %sysevalf(&ngvkey/&total);
%MEND CusipLinkGvkey;
%MACRO PERMNO2GVKEY(din=,dout=);
proc sql;
create table &dout as
select unique a.*, b.gvkey
from &din as a
inner join static.ccmxpf_linktable as b
on a.permno=b.lpermno and b.linkdt<=a.date<=b.linkenddt
order by permno, date
;quit;
%MEND PERMNO2GVKEY;



/* WORKING ...!! */
/*%MACRO permno_link_all(din=,dout=);*/
/*%put The input table (din) has to have two columns named ;*/
/*%put exactly as "permno" and "Date".; */
/*%put Column permno: the CRSP PERMNO identification number.;*/
/*%put Column Date: the corresponding date, including year, month, and day. In the format of YYYYMMDD.;*/
/*%put ---------------------------------------;*/
/*proc sql;*/
/*create table &dout as*/
/*select a.permno, b.**/
/*from &din as a*/
/*left join stocknames as b*/
/*on a.permno=b.permno and b.namedt<a.date<b.nameenddt*/
/*;quit;*/
/**/
/*proc sql noprint; */
/*select count(*)into:total*/
/*from &dout*/
/*;quit;*/
/**/
/*proc sql noprint; */
/*select count(gvkey)into:ngvkey*/
/*from &dout*/
/*;quit;*/
/**/
/*%put overall* fill ratio: %sysevalf(&ngvkey/&total);*/
/*%put *using gvkey fill ratio as a proxy.;*/
/*%MEND permno_link_all;*/
/**/
/*%permno_link_all(din=local.permnodata,dout=a);*/
