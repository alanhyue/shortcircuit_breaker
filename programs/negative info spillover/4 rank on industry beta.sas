/* 
Author: Heng Yue 
Create: 2017-01-10 18:44:46
Update: 2017-01-10 18:44:46
Desc  : Ranking by sector beta.
*/

data betas;
set my.industry_beta;
run;

proc rank data=betas out=ranked group=5 ties=low;
var ret;
ranks rank_sector_beta;
run;

data my.ranked_sector_beta;
set ranked;
run;
****;
PROC PRINT DATA=ranked(OBS=10);RUN;
