/* 
Author: Heng Yue 
Create: 2017-01-19 15:38:58
Desc  : Running diff-in-diff regression.
Table IN:
Table OUT:
*/
***NOTES***;
*1. filter the SSCB observations by implementing the rule yourself. That is, if the daily low price is a 10 percent or more declination from last trading-day's closing price, it is would have triggered the breaker. Compare your result with the data obtained directly from Nasdaq. Using this method, you can even go back to the days before the breaker came effective and mark those stocks. Reasonably, when the breaker was introduced, these stocks that experiences violent intraday price declination are the ones that the breaker was intended for.
2. When comparing the difference in volatility, it makes more sense to compare the difference in intra-day downside volatility. The breaker should significantly reduce the intraday downside volatility. Using the techniques introduced in point 1, we separate the sample stocks into two groups: one has triggered the breaker and one has never. Then do a diff-in-diff test for intraday-downside volatility and other volatility measures as well. The expected result is that the intraday-downside volatility is significantly reduced but the general variance is not, which proves that the breaker is sharp at its target without strong "side-effects".
3. Fixed-effect, Fama macbeth, Newey-west, https://kelley.iu.edu/nstoffma/fe.html
;

/*Step 1. Calculate the decpct variable.*/
* calculate intraday decline;
data dsf;
set static.dsf;
by permno date;
lag_price=PRC/(RET+1); * derive the closing price on day T-1 from the return on day T.;
decpct=(BIDLO-lag_price)/lag_price;
run;

/*Step 2. The Target Group*/
/*Step 2.1 Preparation*/
/*The target group is identified by the number of SCB-triggerations.*/

* Mark the SCB-triggerations;
%AppendSSCBDummy(din=dsf,dout=dsfwin);
data dsfmark;
set dsfwin;
trigger_DUM=.;
/*if decpct<=-0.10 then trigger_DUM=1; * mark based on intraday decline in the whole sample.*/
if decpct<=-0.10 and dsscb=0 then trigger_DUM=1; * mark based on intraday decline in pre-SCB period.;
;run;

* Generates SCB-triggeration counts.;
proc sql;
create table triggerCounts as
select permno, count(trigger_DUM) as nTrigger
from dsfmark
group by permno
;quit;

/*Step 2.2 Form the Target Group*/
/*
There are several definition of the Target (control) group. The definition
talbe is named as Target_Def[n], where n equals 1 for definition 1. So on 
and so forth.
However, the identification of target stocks are in the same fashion among
all the target definitions. That is, Target stocks are marked by Target_DUM=1 whereas 
control stocks are marked by Target_DUM=0.*/

* Definition 1. 
Target group are stocks that ever triggered the breaker. 
Control group are stocks that never triggered the breaker.;
data Target_Def1;
set triggerCounts;
if nTrigger>0 then Target_DUM=1;
else Target_DUM=0;
run;

* Definition 2.
Target group (Control group) are stocks in the highest (lowest) 
decile portfolio when the whole sample is ranked by the number 
of SCB-triggeration.
;

* Rank the sample by the number of triggerations.;
proc rank data=triggerCounts out=_ranked group=10 ties=low;
var nTrigger;
ranks nTrigger_rank;
run;

* Mark the highest (lowest) portfolio as Target (Control) gorup.;
data Target_Def2;
set _ranked;
Target_DUM=.;
if nTrigger_rank=0 then Target_DUM=0;
if nTrigger_rank>=9 then Target_DUM=1;
if Target_DUM=. then delete;
run;

/*Step 2.3 Mark Target stocks in the daily stock data.*/
proc sql;
create table dsfmarked as
select a.*, b.Target_DUM, b.nTrigger, b.nTrigger_rank
from dsf as a
inner join Target_Def2 as b
on a.permno=b.permno
;quit;

/*Step 3. Final preparation.*/
* Attach the circuit breaker dummy.;
%AppendSSCBDummy(din=dsfmarked,dout=dsf_scbdummy);
* Calculate the interaction term.;
data dsf_full;
set dsf_scbdummy;
Target_INT_SCB=Target_DUM*DSSCB;
run;

/*Step 4. Regression Analysis*/
/*Step 4.1 Diff-in-diff regression on firm-day observation decpct.*/
proc reg data=dsf_full;
model decpct=DSSCB Target_DUM Target_INT_SCB;
run;

/*Step 4.2 Diff-in-diff regression on the cross-sectional average of decpct.*/
* find average decpct by date & rank group;
proc sql;
create table sfavg as 
select date, ntrigger_rank, AVG(decpct) as decpct_avg
from dsf_full
group by date, ntrigger_rank
;quit;

* Attach the SCB dummy;
%AppendSSCBDummy(din=sfavg,dout=sfsfavg_scbdummy);

* Attach the Target dummy and calculate the interaction term.;
data sfavg_full;
set sfsfavg_scbdummy;
if ntrigger_rank=9 then Target_DUM=1;
else Target_DUM=0;
Target_INT_SCB=Target_DUM*DSSCB;
run;

* run diff-in-diff reg u;
proc reg data=sfavg_full;
model decpct_avg=DSSCB Target_DUM Target_INT_SCB;
run;


























*********LEGACY*******************;
*********LEGACY*******************;
*********LEGACY*******************;
* date filter to shrink the sample size;
/*data win;*/
/*set win;*/
/*if '10May2010'd<=date<='10Jan2011'd;*/
/*run;*/

* average downside extreme volatility;
proc sql;
select TargetGroup,dsscb,AVG(decpct_avg) as decpct_avg_avg
from dh
group by TargetGroup, dsscb
;quit;
PROC PRINT DATA=win(OBS=10);RUN;
* fiexed-effect test;
proc glm data=win;
 class permno;
 model decpct = DSSCB TargetGroup SCBINTGROUP / solution; run;
quit;


%MACRO clus2OLS(yvar, xvars, cluster1, cluster2, dset);
	/* do interesection cluster*/
	proc surveyreg data=&dset; cluster &cluster1 &cluster2; model &yvar= &xvars /  covb; ods output CovB = CovI; quit;
	/* Do first cluster */
	proc surveyreg data=&dset; cluster &cluster1; model &yvar= &xvars /  covb; ods output CovB = Cov1; quit;
	/* Do second cluster */
	proc surveyreg data=&dset; cluster &cluster2; model &yvar= &xvars /  covb; ods output CovB = Cov2 ParameterEstimates = params;	quit;

	/*	Now get the covariances numbers created above. Calc coefs, SEs, t-stats, p-vals	using COV = COV1 + COV2 - COVI*/
	proc iml; reset noprint; use params;
		read all var{Parameter} into varnames;
		read all var _all_ into b;
		use Cov1; read all var _num_ into x1;
	 	use Cov2; read all var _num_ into x2;
	 	use CovI; read all var _num_ into x3;

		cov = x1 + x2 - x3;	/* Calculate covariance matrix */
		dfe = b[1,3]; stdb = sqrt(vecdiag(cov)); beta = b[,1]; t = beta/stdb; prob = 1-probf(t#t,1,dfe); /* Calc stats */

		print,"Parameter estimates",,varnames beta[format=8.4] stdb[format=8.4] t[format=8.4] prob[format=8.4];

		  conc =    beta || stdb || t || prob;
  		  cname = {"estimates" "stderror" "tstat" "pvalue"};
  		  create clus2dstats from conc [ colname=cname ];
          append from conc;

		  conc =   varnames;
  		  cname = {"varnames"};
  		  create names from conc [ colname=cname ];
          append from conc;
	quit;

	data clus2dstats; merge names clus2dstats; run;
%MEND clus2OLS;
%clus2OLS(yvar=decpct,xvars=DSSCB TargetGroup SCBINTGROUP,cluster1=permno,cluster2=date,dset=win);
* LEGACY;
*==============================;
* calculate the close-close volatility;
* because the RET is already calculated using closing prices, 
the close-close volatility is simply the square of RET;
data calc;
set my.permnodata;
* Close-to-close volatility;
ccvol=ret*ret; 
* semivariance;
lgret=log(prc/lag(prc));
if lgret<0 then up=0;
	else up=lgret*lgret;
if lgret>0 then down=0;
	else down=lgret*lgret;
* Parkinson volatility;
parkinson=log(ASKHI/BIDLO);
run;
