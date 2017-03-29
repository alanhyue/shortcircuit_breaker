import sys
sys.path.append("..")
import ytZoo

flist=ytZoo.GetFileList(r"E:\SCB\data\backup01Mar2017\shorthalts\Nasdaq")
# Get the variable names
a=flist[1]
head=open(a,'r').readline()
# Get the data
with open(r'E:\SCB\data\backup01Mar2017\shorthalts\shohalts.txt','w') as fout:
	fout.write(head)
	count=0
	total=len(flist)
	for li in flist:
		count+=1
		print('{0}/{1}: {2}'.format(count,total,li))
		cont=open(li,'r').readlines()
		filedata=cont[1:-1]
		fout.write(''.join(filedata))

