def GetFileList(dir):
	import os
	file_paths=[]
	for root, dirname, fname in os.walk(dir):
		for li in fname:
			fpath=os.path.join(root,li)
			file_paths.append(fpath)
	return file_paths

if __name__=="__main__":
	import os
	a=GetFileList(r'C:/Users/yu_heng/Downloads/')
	b=[li for li in a if os.path.splitext(li)[1]==".txt"]
	open("C:/Users/yu_heng/Downloads/file_list.txt",'w').write(
		"path\n"+"\n".join(b))
