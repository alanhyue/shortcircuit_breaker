import requests 
import time
import os
import requests
from bs4 import BeautifulSoup

def download(src,dst):
	with open(dst, 'wb') as f:
		f.write(requests.get(src).content)
	return

def GetHTMLSoup(url):
	headers = {
	'Accept':'*/*; q=0.01',
	'Accept-Encoding':'gzip,deflate',
	'Accept-Language':'q=0.8,en-US;q=0.6,en;q=0.4',
	'Cache-Control':'no-cache',
	'Connection':'keep-alive',
	'User-Agent':'Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.102 Safari/537.36'
	}
	r=requests.get(url,headers=headers)
	if r.status_code == 404:
		# A 404 was found
		return None
	soup = BeautifulSoup(r.text,"html.parser")
	return soup

if __name__=="__main__":
	soup=GetHTMLSoup("http://www.finra.org/industry/trf/trf-regulation-sho-2009")
	a=[]
	for li in soup.find(class_='field-item even field field--name-body field--type-text-with-summary field--label-hidden').findAll('ul',recursive=False):
		a.extend(li.findAll('a'))
	b=[li['href'] for li in a]
	print('\n'.join(b))
	exit(0)
	import os
	names=[os.path.join("C:/Users/yu_heng/Downloads/",li.split('/')[-1]) for li in b]
	pairs=zip(b,names)
	total=len(b)
	count=0
	for src,dst in pairs:
		count+=1
		print("({0}/{1}){2}".format(count,total, src))
		download(src,dst)
