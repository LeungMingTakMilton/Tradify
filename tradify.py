# coding: utf-8
from __future__ import print_function
import sys
import os
import getopt
import tempfile
#from hanziconv import HanziConv
from opencc import OpenCC
from zipfile import ZipFile,ZipInfo
cc = OpenCC('s2hk')  # convert from Simplified Chinese to Traditional Chinese
def __conv__(file,string):
    try:
        return cc.convert(string.decode('utf-8'))
    except Exception:
        print ('Warning: Fail to decode '+file+'!')
    return string
def convName(file,verbose):
    org_file=os.path.abspath(file)
    new_file=os.path.dirname(org_file)+'/'+__conv__(file,os.path.basename(org_file))
    os.rename(org_file,new_file)
    return
def convText(file,verbose):
    if(verbose):
        print(file)
    try:
        f=open(os.path.abspath(file),'r+')
        text=__conv__(file,f.read())
        f.seek(0)
        f.write(text)
        f.truncate()
        f.close()
    except IOError:
           print ('Warning: Fail to open '+str(file)+'!')
def convEpub(file,verbose):
    if(verbose):
        print(file)
    ext=['.ncx',".htm",".xhtml",".html",".opt",".ncx"]
    zin=ZipFile(file,"r")
    update_contant=[((zipinfo.filename,__conv__(zipinfo.filename,zin.read(zipinfo.filename)))) \
            for zipinfo in zin.filelist if zipinfo.filename.endswith(tuple(ext))]
    tmpfd, tmpname = tempfile.mkstemp(dir=os.path.dirname(os.path.abspath(zin.filename)))
    zout=ZipFile(tmpname, 'w')
    os.close(tmpfd)
    zin.comment = zout.comment
    # get all names from input zip except file in update list
    update_name=[name for name,content in update_contant]
    zin_filename=[item.filename for item in zin.filelist if item.filename not in update_name]
    # add all files with its new data to new archive
    [zout.writestr(name,contant) for name,contant in update_contant]    
    [zout.writestr(name,zin.read(name)) for name in zin_filename]
    # replace with th temp archive
    os.remove(zin.filename)
    os.rename(tmpname,zin.filename)
    zin.close()
def main():
    sim=False
    name=False
    verbose=False
    try:
        opts,args = getopt.getopt(sys.argv[1:],'nsv',['simplify','name','verbose'])
    except getopt.GetoptError as err:
        print (str(err))
        sys.exit(2)
    for o, a in opts:
        if o in ('-s','--simplify'):
            sim=True
            cc = OpenCC('t2s')  # convert from Traditional Chinese to Simplified Chinese
        elif o in ('-n','--name'):
            name=True
        elif o in ('-v', '--verbpse'):
            verbose=True
        else:
            assert False, 'Unhandled option'
    [convEpub(arg,verbose) for arg in args if arg.endswith('.epub')]
    [convText(arg,verbose) for arg in args if arg.endswith('.txt')]
    [convName(arg,verbose) for arg in args if name]

if __name__ == "__main__":
    main()
