import sys
import pandas as pd
from glob import glob

flist=glob(r"C:\Users\yu_heng\Desktop\NYSEGroupSSRCircuitBreakers\NYSEGroupSSRCircuitBreakers_2016\*\*.xls")
print(flist)
all_data = pd.DataFrame()
total=len(flist)
count=0
for f in flist:
    count+=1
    print("{0}/{1}: {2}".format(count,total,f))
    df = pd.read_excel(f)
    all_data = all_data.append(df,ignore_index=True)
all_data.to_csv("shorthalts.csv",index=False)
# Get the variable names
# a=flist[1]
# head=open(a,'r').readline()
# # Get the data
# with open(r'E:\SCB\data\backup01Mar2017\shorthalts\shohalts.txt','w') as fout:
#   fout.write(head)
#   count=0
#   total=len(flist)
#   for li in flist:
#       count+=1
#       print('{0}/{1}: {2}'.format(count,total,li))
#       cont=open(li,'r').readlines()
#       filedata=cont[1:-1]
#       fout.write(''.join(filedata))

