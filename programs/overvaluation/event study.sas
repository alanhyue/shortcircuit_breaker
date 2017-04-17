* 
In this example the market index return is used for:
- monthly returns: calculating the beta for each observation
- daily returns: calculating the abnormal return for the 3 days surrounding the press release

To also use the market indices in other studies, a seperate library is constructed 
to hold the index datasets. This allows appending the market return to datasets locally. 
*/;

libname myLib2 "D:\_examples\sasdata2";
libname indices "D:\_examples\sasdata_indices";

/* retrieve monthly and daily index */
%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

rsubmit;
/* Even though "Home -> Support -> Data -> Dataset List" shows "/wrds/crsp/sasdata/ix"
as the location of the library, this location triggers the following error:
ERROR: User does not have appropriate authorization level for library CRSP.
Instead, "/wrds/crspq/sasdata/ix" needs to be used (q implies that the dataset 
is updated quarterly).
Thus, this library assignment may vary across institutions (depending on permissions)
*/

libname crsp '/wrds/crspq/sasdata/ix';
             
/* msix: (Monthly)NYSE/AMEX/NASDAQ Capitalization Deciles, Annual Rebalanced
/* dsix: (Daily) NYSE/AMEX/NASDAQ Capitalization Deciles, Annual Rebalanced 

variables of interest: 
- vwretd: Value-Weighted Return-incl. dividends
- ewretd: Equal-Weighted Return-incl. dividends
- caldt: Calendar Date */

PROC SQL;
  create table monthlyIndex(keep = permno caldt ret vwretd ewretd) as
  select a.*
  from crsp.msix a;
  quit;


  PROC SQL;
  create table dailyIndex(keep = permno caldt ret vwretd ewretd) as
  select a.*
  from crsp.dsix a;
  quit;


proc download data=monthlyIndex out=indices.monthlyIndex;
proc download data=dailyIndex out=indices.dailyIndex;

run;
endrsubmit;


/* import the dataset */
PROC IMPORT OUT= myLib2.a_tickers
            DATAFILE= "D:\_examples\example2_restatements.txt"
            DBMS=TAB REPLACE;
     GETNAMES=YES;
     DATAROW=2;
RUN;

/* 
ticker symbols change over time, it is preferable to use PERMNO as the firm 
identifier for stock price/return info However, the GAO dataset has the ticker 
symbol as the firm identifier.
How can we get the correct PERMNO if the ticker symbol changes over time?
Solution: we use 'dsenames', which keeps track of changes in ticker symbol, 
firm name, PERMNO, etc NAMEDT holds the beginning date, and NAMEENDT the end 
date. 
We therefore match on ticker symbol AND also the press release date needs to 
be between these dates
*/

rsubmit;
libname crsp '/wrds/crsp/sasdata/sd';

proc upload data=myLib2.a_tickers out=tickers;run;

PROC SQL;
  create table withcusip 
    (keep = firmname ticker press_date exchange cusip permno ncusip comnam 
    reason1-reason12 NAMEDT NAMEENDT) as
  select a.* , b.*
  from crsp.dsenames a , tickers b
  where a.ticker = b.ticker 
    and a.NAMEDT <= press_date <= a.NAMEENDT;
quit;

proc sort data=withcusip nodup; by ticker press_date ;

proc download data=withcusip out=myLib2.b_withcusip;
run;
endrsubmit;

/* create an identifier for the observations
since a firm can have multiple restatements, an obvious candidate for such
an identifier is a combination of both
'||' concatenates the press release date (converted to a number) with the ticker 
symbol. hence: key is unique for each observation
*/
data myLib2.b_withcusip;
set myLib2.b_withcusip;
key = trim(press_date || "_")|| trim(ticker);
run;

/* sometimes firms have multiple permno's
if so, then there will be multiple observations with the same key.
in that case, take the first observation */

proc sort data=myLib2.b_withcusip nodup; by key permno;

/* note the 'by' statement, this will group all observations by their key
the 'if first.key then output' will only output the first observation, hence, 
there will be no multiple instances of a single key
*/
data myLib2.b_withcusip;
set myLib2.b_withcusip;
by key;
if first.key then output;run;


/*
As an additional test, verify if the name in the press release (provided by GAO)
is sufficiently comparable to the name on crsp 'spedis' is a function that compares
 to strings, the lower the score, the more the strings are alike observations with 
a score smaller than 30 are retained (this cutoff is arbitrary)
*/

data myLib2.c_verifyThese (keep = permno COMNAM firmname);
set myLib2.b_withcusip;
name_dist = spedis(lowcase(firmname), lowcase(comnam));
if name_dist >= 30;run;

/*
the dataset d_verifyThese contains 142 observations that are manually inspected
of these 144 observations, the names of 6 firms (9 observations) does not match
permno of firms with different company names: 
85654, 81547, 80142, 90173, 49429, 89303 
these observations are hence excluded from the sample
*/
data myLib2.d_verified (drop = NAMEDT NAMEENDT);
set myLib2.b_withcusip;
if permno ne 49429;
if permno ne 80142;
if permno ne 81547;
if permno ne 85654;
if permno ne 89303;
if permno ne 90173;
run;

/* compute a beta for each observation */

/* create a small dataset with the neccessary info to estimate beta
month_1 - month_30 is a 30 month window
collect 30 months of montly returns for the observation
and add the return on the index for each month
an observation's beta is the correlation between the 30 months and the index
*/
data myLib2.e_getBeta (keep = key permno press_date  month_1 month_30);
set myLib2.d_verified; 

month_1=INTNX('Month',press_date,-30,'B'); 
month_30=INTNX('Month',press_date,0,'B'); 

format month_1  date.;
format month_30 date.;
run;

rsubmit;
libname crsp '/wrds/crsp/sasdata/sm';
             
proc upload data=myLib2.e_getBeta out=getBeta;run;


PROC SQL;
  create table returnData
    (keep = key permno press_date month_1 month_30 date ret) as
  select msf.*, b.*
  from crsp.msf a, getBeta b
  where b.month_1 <= a.date <= b.month_30 and a.permno = b.permno;
  quit;

proc sort data = returnData nodup;by key date;
proc download data=returnData out=myLib2.f_returnData;
run;
endrsubmit;

data myLib2.f_returnData;
set myLib2.f_returnData;
if RET gt -55;      * missing: -66, -77, -88 etc;
if (1*RET eq RET) ; * must be numeric;
run;

/* append the return on the index*/
PROC SQL;
  create table myLib2.g_withIndex
    (keep = key permno press_date date ret vwretd) as
  select a.*, b.*
  from indices.monthlyIndex a, myLib2.f_returnData b
  where a.caldt = b.date ;
  quit;

/* make sure there are enough monthly returns to estimate beta */
proc sql;
    create table myLib2.h_numMonths as
        select 
            distinct key, count(*) as number_of_months
        from
            myLib2.g_withIndex
        group by key;           
quit;


/* go back to g_withIndex and only select those observations that have s
ufficient number of months; arbitrary cutoff: 12 months*/
proc sql;
    create table myLib2.i_readyToEstimate as
    select a.* 
    from myLib2.g_withIndex a, myLib2.h_numMonths b
    where a.key = b.key
        and b.number_of_months >=12
;
quit;

/* estimate beta's */
PROC REG OUTEST = myLib2.j_beta data=myLib2.i_readyToEstimate;
   ID key;
   MODEL  ret = vwretd / NOPRINT;
   by key;
RUN ;

/* the coefficients have the names of the variables,
hence beta equals vwretd in this dataset
renamed here and only keep the relevant variables: key and beta*/
data myLib2.j_beta2 (keep = key alpha beta);
set myLib2.j_beta;
alpha = intercept;
beta = vwretd;
run;

/* include alpha and beta in myLib2.d_verified */
proc sql;
    create table myLib2.k_verifiedAndBeta as
    select a.*, b.alpha, b.beta
    from
        myLib2.d_verified a, myLib2.j_beta2 b
    where
        a.key = b.key;
quit;

/* 3 day stock return [-1, +1]*/
rsubmit;
libname crsp '/wrds/crsp/sasdata/sd';

proc upload data=myLib2.k_verifiedAndBeta out=get3Day;run;

data get3Day;
set get3Day;
prevday=INTNX('Day',press_date,-1,'B'); 
nextday=INTNX('Day',press_date,+1,'B'); 
format prevday nextday date9.;

PROC SQL;
  create table return3Day(keep = key permno date press_date ret alpha beta) as
  select dsf.*, get3Day.*
  from crsp.dsf a, get3Day b
  where b.prevday <= a.date <= b.nextday and a.permno = b.permno;
  quit;

proc download data=return3Day out=myLib2.l_return3Day;
run;
endrsubmit;


data myLib2.l_return3Day;
set myLib2.l_return3Day;
if RET gt -55;      * missing: -66, -77, -88 etc;
if (1*RET eq RET) ; * must be numeric;
run;

/* append daily return on index */
PROC SQL;
  create table myLib2.m_withdailyIndex(keep = key permno press_date alpha 
beta date ret vwretd) as
  select a.*, b.*
  from indices.dailyIndex a, myLib2.l_return3Day b
  where a.caldt = b.date ;
quit;

proc sort data = myLib2.m_withdailyIndex; by key date;run;

/* compute CAR's */
data myLib2.n_CAR (keep = key r_3day car_vw counter alpha beta  );
set myLib2.m_withdailyIndex;
/* by key means that it will run through these statements for each key,
where key is a unique identifier of one observation
*/
by key;
/* retain means that the contents of these variables will be available
for example, counter will be set to zero with every observation 
with every row of data (return), it will increase by 1
"if last.key then output" will write the value of the counter to the newly
created dataset

r_3day: 1 + 3 days of returns
car_vw: 3-day cumulative abnormal return 
*/
retain counter r_3day  car_vw;
if first.key then counter=0;
if first.key then car_vw=1;
if first.key then r_3day=1;

if ret eq . then ret = 0;
counter+1;

/* cumulative abnormal return */
car_vw = car_vw + ret - (alpha+beta * vwretd);

/* raw return, 3 day cumulative */
r_3day = r_3day + ret;

/* we are only interested in keeping the cumulative 3 day return (and not 
cumulative 1 and 2 day) */
if last.key then output;
run;


/* match CAR with myLib2.k_verifiedAndBeta */
proc sql;
    create table myLib2.o_withCAR as
    select a.*, b.car_vw, b.r_3day, b.counter
    from
        myLib2.k_verifiedAndBeta a, myLib2.n_CAR b
    where
        a.key = b.key;

quit;

data myLib2.p_allVariables;
set myLib2.o_withCAR;
car_vw_log = log(car_vw);
r_3day_log = log(r_3day);
run;



/* exclude firms where the event date was no trading day
   for example the press release was issued on a sunday
   or on a holiday */

proc sql;
    create table myLib2.q_finalSet as
    select a.*
    from
        myLib2.p_allVariables a
    where
        a.press_date IN (select caldt from indices.dailyIndex);

quit;


/*****************************************
Trim or winsorize macro
* byvar = none for no byvar;
* type  = delete/winsor (delete will trim, winsor will winsorize;
*dsetin = dataset to winsorize/trim;
*dsetout = dataset to output with winsorized/trimmed values;
*byvar = subsetting variables to winsorize/trim on;
****************************************/

%macro winsor(dsetin=, dsetout=, byvar=none, vars=, type=winsor, pctl=1 99);

%if &dsetout = %then %let dsetout = &dsetin;
    
%let varL=;
%let varH=;
%let xn=1;

%do %until ( %scan(&vars,&xn)= );
    %let token = %scan(&vars,&xn);
    %let varL = &varL &token.L;
    %let varH = &varH &token.H;
    %let xn=%EVAL(&xn + 1);
%end;

%let xn=%eval(&xn-1);

data xtemp;
    set &dsetin;
    run;

%if &byvar = none %then %do;

    data xtemp;
        set xtemp;
        xbyvar = 1;
        run;

    %let byvar = xbyvar;

%end;

proc sort data = xtemp;
    by &byvar;
    run;

proc univariate data = xtemp noprint;
    by &byvar;
    var &vars;
    output out = xtemp_pctl PCTLPTS = &pctl PCTLPRE = &vars PCTLNAME = L H;
    run;

data &dsetout;
    merge xtemp xtemp_pctl;
    by &byvar;
    array trimvars{&xn} &vars;
    array trimvarl{&xn} &varL;
    array trimvarh{&xn} &varH;

    do xi = 1 to dim(trimvars);

        %if &type = winsor %then %do;
            if not missing(trimvars{xi}) then do;
              if (trimvars{xi} < trimvarl{xi}) then trimvars{xi} = trimvarl{xi};
              if (trimvars{xi} > trimvarh{xi}) then trimvars{xi} = trimvarh{xi};
            end;
        %end;

        %else %do;
            if not missing(trimvars{xi}) then do;
              if (trimvars{xi} < trimvarl{xi}) then delete;
              if (trimvars{xi} > trimvarh{xi}) then delete;
            end;
        %end;

    end;
    drop &varL &varH xbyvar xi;
    run;

%mend winsor;

/* invoke macro to winsorize */
%winsor(dsetin=myLib2.q_finalSet, dsetout=myLib2.r_finalWinsorized, byvar=none, 
vars=car_vw_log r_3day_log , type=winsor, pctl=1 99);

/* run regressions by exchange */
proc sort data = myLib2.r_finalWinsorized; by exchange;run;

PROC REG ;
   MODEL  car_vw_log = reason1-reason12 ;
     by exchange;
RUN ;