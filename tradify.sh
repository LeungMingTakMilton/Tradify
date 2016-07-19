TRADIFY="
import sys
import os
import getopt
from hanziconv import HanziConv
def conv(str,sim):
	if (sim):
		return HanziConv.toSimplified(str)
	else:
		return HanziConv.toTraditional(str)
sim=False
name=False
try:
	opts,args = getopt.getopt(sys.argv[1:],'ns',['simplify','name'])
except getopt.GetoptError as err:
	print (str(err))
	sys.exit(2)
for o, a in opts:
	if o in ('-s','--simplify'):
		sim=True
	elif o in ('-n','--name'):
		name=True
	else:
		assert False, 'Unhandled option'
for arg in args:
	try:
		if(name):
			path, name=os.path.split(arg)
			os.rename(arg,path+'/'+conv(name,sim))
		else:
			f=open(arg,'r+')
			text=conv(f.read(),sim)
			f.seek(0)
			f.write(text)
			f.truncate()
			f.close()
	except (UnicodeDecodeError,IOError):
		print ('Warning: Fail to open or decode '+str(arg)+' !')
"
function usage(){
	cat<<EOF
Usage: `basename $0` [OPTION]... [FILE]...

Tradify: Convert epub and plain text files from 
Simplified Chinese to Traditional Chinese

-h	show usage
-s	to Simplified Chinese
-v	verbose mode
-d	debug mode, dump working directories and files
EOF
}
function verbose(){
	$VERBOSE && echo "$@"
}
function unzipEpub(){
    eval file="$1"
    local epub_files=`eval zipinfo -1 \"$file\" \
	| grep -E $EPUB_TARGET \
	| awk '{ print "\""$0"\""}'`
    local tmp_dir="`pwd`/`head /dev/urandom \
	| LC_ALL=C tr -dc 'A-Za-z0-9' \
	| head -c 10`"
    tmp_dir=`eval echo \"$tmp_dir\"`
    eval "mkdir \"$tmp_dir\" && unzip -q \"$file\" "$epub_files" -d \"$tmp_dir\""
    EPUB_LIST+=("$tmp_dir","$file")
}
function zipEpub(){
    local oldifs=$IFS
    IFS=','
    for i in "${EPUB_LIST[@]}";
    do
        set -- $i;
        cd $1 && zip -qr $2 * && cd ..
    done
    IFS=$oldifs
}
function cleanup(){
    local oldifs=$IFS
    IFS=','
    for i in "${EPUB_LIST[@]}";
    do
        set -- $i;
        ! $DEBUG && rm -rf $1
    done
    IFS=$oldifs
}
trap cleanup EXIT
VERBOSE=false
DEBUG=false
OPTION=""
EPUB_TARGET='\.html|\.xhtml|\.ncx|\.opf'
CONVERT_LIST=()
CONVERT_NAME_LIST=()
EPUB_LIST=()
ARGS=`getopt --long verbose,debug,simplify,help -- vdsh "$@"` || exit 2
eval set -- "$ARGS"
while true; do
	case "$1" in
		-v | --verbose) VERBOSE=true; shift;;
		-d | --debug ) DEBUG=true; shift;;
		-s | --simplify) OPTION="-s "; shift;;
		-h | --help) usage && exit;;
		-- ) shift; break;;
		* ) echo "Try '$0 -h' for more information." && exit ;;
	esac
done
for file in "$@"; do
	verbose "${file}"
	[ ! -e "${file}" ] && echo "Warning: "${file}" not found, ignored"\
			 && continue
	[ "${file:0:1}" != "/" ] && file="`pwd`/"$file"" # Check relative path
	fileExt=`eval "file --mime-type \"${file}\""`
	case $fileExt in # Check file format
	*epub | *zip)   unzipEpub "\${file}"
	        tmp_dir=`echo "${EPUB_LIST[${#EPUB_LIST[@]}-1]}" \
	    		| awk -F, '{print $1}'`
	        CONVERT_LIST+=( `find "$tmp_dir" -type f -exec echo '"{}"' \;` )
	        ;;
	*plain | *octet-stream ) CONVERT_LIST+=(\""$file"\");;
	*directory ) echo "Warning: "${file}" is a directory" && continue;;
	*) echo "Warning: File "${file}": format not supported" && continue;;
	esac
	CONVERT_NAME_LIST+=(\""$file"\")
done
if [ -n "$CONVERT_LIST" ]; 
then
	echo "${#EPUB_LIST[@]} epubs, ${#CONVERT_LIST[@]} files in total."
	echo "Converting ${#CONVERT_NAME_LIST[@]} documents in total."
	eval "python3 -c \"$TRADIFY\" ${OPTION} ${CONVERT_LIST[*]} "; zipEpub
	eval "python3 -c \"$TRADIFY\" ${OPTION} '-n' ${CONVERT_NAME_LIST[*]} "
fi
