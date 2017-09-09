/* read The Master Table (Myyyymm.TAB) file */
/* read DATE2.DAT */
data date2;
infile "C:\Users\yu_heng\Downloads\DATE2.DAT" truncover 
LRECL=46 recfm=f;
input
tdate $8.
cqidxb $8.
cqidxe $8.
ctidxb $8.
ctidxe $8.
space $1.
disk $2.
datafmt $1.
;
run;
proc print data=date2(obs=max);run;



* read TyyymmX.BIN;
data TBin;
infile "C:\Users\yu_heng\Downloads\T201105B.BIN" truncover 
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
proc print data=Tbin(obs=30);run;

/* read the CT Index File (TyyymmX.IDX) */
data Tindex;
infile "C:\Users\yu_heng\Downloads\T200807D.IDX" truncover LRECL=22 recfm=f;
input
symbol $char10.
tdate pib4.
begrec pib4.
endrec pib4.
;
run;
proc print data=tindex(obs=30);run;


/* read QyyyymmX.bin */
data Qbin;
infile "C:\Users\yu_heng\Downloads\Q201007A.BIN" truncover LRECL=27 recfm=f firstobs=1 obs=1131940;
input
qtim pib4.
bid pib4.4
ofr pib4.4
bidsiz pib4.
ofrsiz pib4.
ode pib2.
ex $1.
mmid $4.
;
run;
proc print data=Qbin(obs=20);run;


/* read the CQ Index File (QyyymmX.IDX) */
data Qindex;
infile "&path" truncover LRECL=22 recfm=f;
input
symbol $char10.
tdate pib4.
begrec pib4.
endrec pib4.
;
run;
proc print data=Qindex(obs=max);run;




/* read Myyymm.TAB*/
data MTAB;
infile "C:\Users\yu_heng\Downloads\M201010.TAB" truncover 
LRECL=95 recfm=f obs=100;
input
symbol $char10.
name $char30.
cusip $char12.
etx $char10.
its $char1.
icode $char4.
sharesout $char10.
uot $char4.
denom $char1.
type $char1.
datef $char8.
;
run;
proc print data=MTAB(obs=20);run;







proc import datafile="C:\Users\yu_heng\Downloads\T201007A.IDX"  dbms=dlm
out=y replace;
delimiter='20'x;
run;
proc print data=y(obs=10);run;


%MACRO read_taq(file=,out=);
proc import datafile=&file  dbms=dlm out=&out replace;
delimiter='09'x;
getnames=yes;
run;
%MEND read_taq;
%read_taq(file="C:\Users\yu_heng\Downloads\M201006.TAB",out=test);
proc print data=test(obs=10);run;

