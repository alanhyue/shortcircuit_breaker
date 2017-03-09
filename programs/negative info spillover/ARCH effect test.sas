* Test for ARCH effect;
/*Step 1. Run the OLS regression and save the residuals*/
proc reg data=dsf_halt;
model ret = posthalt_DUM low_DUM high_DUM 
post_low_DUM post_high_DUM
SMB HML RMW CMA mktrf / ADJRSQ CLB STB VIF;
output out=est r=resid;
run;
/*Step 2.Square the residuals. Then Regress the residual on its own Q lags
 for testing ARCH(Q) effect.*/
data est;
set est;
resid_sq=resid**2;
resid_lag1=LAG(resid_sq);
resid_lag2=LAG(resid_lag1);
resid_lag3=LAG(resid_lag2);
run;
proc reg data=est;
model resid_sq=resid_lag1;
run;

* TR^2=522220*0.0078=4073;
%winsorize(din=est,dout=estwin,var=resid_sq);
%histo(din=estwin,var=resid_sq);
* 
Test statistic is TR^2 ~ chi-square(Q)
H0: no ARCH effect
Ha: there is ARCH effect
;
