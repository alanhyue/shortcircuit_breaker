import os
import sys

dir=os.path.dirname(os.path.realpath(__file__)) # dir of this .py file
rootdir = sys.argv[1]

outfile_path=os.path.join(dir, 'filepath_list.txt')
fout= open(outfile_path, 'w')

for folder, subs, files in os.walk(rootdir):
	for filename in files:
		path=os.path.join(folder, filename)
		fout.write(path+'\n')
		print(path)
fout.close()
print('============================')
print('Done. File list saved at {0}'. format(outfile_path))