libname my "C:\Users\yu_heng\Downloads\";
libname taqref 'E:\SCB\TAQ\data\sasdata';

%MACRO AppendSSCBDummy(din=,dout=);
data &dout;
set &din;
if date<="10Nov2010"d then dsscb=0;
else dsscb=1;
run;quit;
%MEND AppendSSCBDummy;
