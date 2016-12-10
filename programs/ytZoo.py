import requests 
import time
import os
import requests
from bs4 import BeautifulSoup

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
def GetDynamicSoup(url,sleep=3):
	from selenium import webdriver
	import time
	driver = webdriver.PhantomJS(executable_path=r'C:\Users\Heng\Desktop\Spiders\phantomjs-2.1.1-windows\bin\phantomjs.exe')
	driver.get('https://www.udemy.com/courses/search/?q=excel%20data%20analysis&src=ukw&lang=en')
	time.sleep(sleep)
	driver.get_screenshot_as_file("webscreencapture.jpg") #获取页面截图
	src=driver.page_source
	soup=BeautifulSoup(src,'html.parser')
	driver.close()
	return soup
	
def GetFileList(dir):
	import os
	file_paths=[]
	for root, dirname, fname in os.walk(dir):
		for li in fname:
			fpath=os.path.join(root,li)
			file_paths.append(fpath)
	return file_paths
class Spider:
	headers = {
	'Accept':'*/*; q=0.01',
	'Accept-Encoding':'gzip,deflate',
	'Accept-Language':'zh-CN,zh;q=0.8,en-US;q=0.6,en;q=0.4',
	'Cache-Control':'no-cache',
	'Connection':'keep-alive',
	'User-Agent':'Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.102 Safari/537.36'
	}

	pagelist=[]
	dictlist=[]
	def __init__(self,pages):
		self.pagelist=pages
		self.dictlist=[]
		return
	def setHeaderDict(self,item):
		self.headers.update(item)

	def run(self, extractor):
		# extractor 为外界传入函数。此函数应当接受request作为参数，并返回一个元素为Dict的
		# list，每一个Dict包含两个Key：一个"link"为要下载的文件的完整URL；另一个"path"是
		# 要写入的本地文件完整路径。
		total=len(self.pagelist)
		count=0
		for url in self.pagelist:
			count+=1
			r = requests.get(url,headers=self.headers)
			self.dictlist+=extractor(r)
			print(u'处理页面（{0}/{1}）:{2}'.format(count,total,url))
		self.processItems()
		return
	def processItems(self):
		total=len(self.dictlist)
		count=0
		for li in self.dictlist:
			count+=1
			try:
				self.download(li)
				print(u'已经下载（{0}/{1}）:{2}'.format(count,total,li['path']))
			except:
				print(u'未能下载（{0}/{1}）:{2}'.format(count,total,li['path']))
				pass
		return
	def automkdir(self,dirpath):
		try:
			os.makedirs(dirpath)
			print(u'已经创建目录“{0}”'.format(dirpath))
		except FileExistsError:
			pass

	def download(self, item):
		self.automkdir(os.path.dirname(item['path']))
		with open(item['path'], 'wb') as f:
			f.write(requests.get(item['link'],headers = self.headers).content)
		return

