libname static "E:\SCB\data" access=readonly;
libname ff "E:\SCB\data\ff" access=readonly;
libname my "C:\Users\yu_heng\Downloads\";
libname taqref 'E:\SCB\TAQ\data\sasdata';

%macro orgRegEst(est=,dout=);
* organize the estimation output of proc reg with option tableout specified;
proc sort data=&est; by _DEPVAR_;run;
proc transpose data=&est(drop=_MODEL_ _RMSE_) out=_trans;
id _TYPE_;
by _DEPVAR_;
run;
* filter unrelated variables for each model;
data &dout;
set _trans;
if T;
run;
proc delete data=_trans;run;
%mend orgRegEst;


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
proc rank data=&din out=&dout group=&n ties=low;
var &var;
ranks &var._rank;
run;
%MEND Rank;

%MACRO AppendSSCBDummy(din=,dout=);
data &dout;
set &din;
if date<="10Nov2010"d then dsscb=0;
else dsscb=1;
run;quit;
%MEND AppendSSCBDummy;

%macro winsorize(din=,dout=,vars=,pct=1 99);
%WT(data=&din,out=&dout,byvar=none, vars=&vars, type=W, pctl=&pct, drop= N);
%mend winsorize;
%macro WT(data=_last_, out=, byvar=none, vars=, type = W, pctl = 1 99, drop= N);

	%if &out = %then %let out = &data;
    
	%let varLow=;
	%let varHigh=;
	%let xn=1;

	%do %until (%scan(&vars,&xn)= );
    	%let token = %scan(&vars,&xn);
    	%let varLow = &varLow &token.Low;
    	%let varHigh = &varHigh &token.High;
    	%let xn = %EVAL(&xn + 1);
	%end;

	%let xn = %eval(&xn-1);

	data xtemp;
   	 	set &data;

	%let dropvar = ;
	%if &byvar = none %then %do;
		data xtemp;
        	set xtemp;
        	xbyvar = 1;

    	%let byvar = xbyvar;
    	%let dropvar = xbyvar;
	%end;

	proc sort data = xtemp;
   		by &byvar;

	/*compute percentage cutoff values*/
	proc univariate data = xtemp noprint;
    	by &byvar;
    	var &vars;
    	output out = xtemp_pctl PCTLPTS = &pctl PCTLPRE = &vars PCTLNAME = Low High;

	data &out;
    	merge xtemp xtemp_pctl; /*merge percentage cutoff values into main dataset*/
    	by &byvar;
    	array trimvars{&xn} &vars;
    	array trimvarl{&xn} &varLow;
    	array trimvarh{&xn} &varHigh;

    	do xi = 1 to dim(trimvars);
			/*winsorize variables*/
        	%if &type = W %then %do;
            	if trimvars{xi} ne . then do;
              		if (trimvars{xi} < trimvarl{xi}) then trimvars{xi} = trimvarl{xi};
              		if (trimvars{xi} > trimvarh{xi}) then trimvars{xi} = trimvarh{xi};
            	end;
        	%end;
			/*truncate variables*/
        	%else %do;
            	if trimvars{xi} ne . then do;
              		if (trimvars{xi} < trimvarl{xi}) then trimvars{xi} = .T;
              		if (trimvars{xi} > trimvarh{xi}) then trimvars{xi} = .T;
            	end;
        	%end;

			%if &drop = Y %then %do;
			   if trimvars{xi} = .T then delete;
			%end;

		end;
    	drop &varLow &varHigh &dropvar xi;

	/*delete temporary datasets created during macro execution*/
	proc datasets library=work nolist;
		delete xtemp xtemp_pctl; quit; run;

%mend;

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


* Newey-West stderr estimation;
/*%let lag=5;*/
/*ods output parameterestimates=nw;*/
/*ods listing close;*/
/*proc model data=your_data;*/
/* endo Y;*/
/* exog X;*/
/* instruments _exog_;*/
/* parms b0 b1; * your parameters;*/
/* Y=b0+b1*DSSCB; * your model;*/
/* fit Y / gmm kernel=(bart,%eval(&lags+1),0) vardef=n; run;*/
/*quit;*/
/*ods listing;*/
/**/
/*proc print data=nw; id variable;*/
/* var estimate--df; format estimate stderr 7.4;*/
/*run;*/
