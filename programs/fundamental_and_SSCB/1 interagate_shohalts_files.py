import sys
sys.path.append("..")
import ytZoo

flist=ytZoo.GetFileList(r"C:\Users\yu_heng\Desktop\shorthalts")
# Get the variable names
a=flist[1]
head=open(a,'r').readline()
# Get the data
with open('shohalts.txt','w') as fout:
	fout.write(head)
	count=0
	total=len(flist)
	for li in flist:
		count+=1
		print('\r {0}/{1}'.format(count,total))
		cont=open(li,'r').readlines()
		filedata=cont[1:-1]
		fout.write(''.join(filedata))

