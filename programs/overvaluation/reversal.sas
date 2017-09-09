/* 
Author: Heng Yue 
Create: 2017-04-16 16:09:40
Desc  : Return reversal test.
*/

* Parameter Settings;
%let CARfollow_beg=2;
%let CARfollow_end=5;

/*Step 1. Calculate event CAR*/
data evtar;
set culreturns;
if datedif=0 or datedif=1;
run;

proc sql;
create table evtcar as
select permno, evt, sum(AR) as CAR
from evtar
group by permno, evt
;quit;

/*Step 1.1 Get market capital*/
data cap;
set culreturns;
MKTCAP=log(PRC*SHROUT*1000);
if datedif=-6;
run;

/*Step 2. calculate following day return*/
data folar;
set culreturns;
if &CARfollow_beg<=datedif<=&CARfollow_end;
run;

proc sql;
create table folcar as 
select permno, evt, sum(AR) as CAR
from folar
group by permno, evt
;quit;


/*Step 3. Join them together*/
proc sql;
create table mged as 
select a.*, b.CAR as fol, c.mktcap
from evtcar as a
left join folcar as b
	on a.permno=b.permno and a.evt=b.evt
left join cap as c
	on a.permno=c.permno and a.evt=c.evt
;quit;

/*Step 4. Reg*/
proc reg data=mged;
model fol = car MKTCAP;
run;
