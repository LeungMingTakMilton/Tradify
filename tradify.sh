TRADIFY="
import sys
from mafan import tradify
reload(sys)
sys.setdefaultencoding('utf-8')
for arg in sys.argv[1:]:
    try:
        f=open(arg,'r+')
        text=tradify(f.read())
        f.seek(0)
        f.write(text)
        f.truncate()
        f.close()
    except (UnicodeDecodeError,IOError):
        print 'Fail to open or decode '+str(arg)+' !'
"
function unzipEpub(){
    eval file="$1"
    local contant=`eval zipinfo -1 \"$file\" | grep -E '\.html|\.xhtml|\.ncx|\.opf'`
    local tmp_dir="`pwd`/`head /dev/urandom | LC_ALL=C tr -dc 'A-Za-z0-9' | head -c 10`"
    tmp_dir=`eval echo \"$tmp_dir\"`
    eval "mkdir \"$tmp_dir\" && unzip -q \"$file\" "$contant" -d \"$tmp_dir\""
    EPUB_LIST+=("$tmp_dir,$file")
}
function zipEpub(){
    local oldifs=$IFS
    IFS=','
    for i in "${EPUB_LIST[@]}";
    do
        set -- $i;
        cd $1 && zip -qr $2 * && cd .. && rm -rf $1
    done
    IFS=$oldifs
}
CONVERT_LIST=()
EPUB_LIST=()
for file in "$@";
do
    [ "${file:0:1}" != "/" ] && file="`pwd`/"$file""
    fileExt=`eval "file --mime-type \"$file\""`
    case $fileExt in
    *epub | *zip)   unzipEpub "\${file}"
                    tmp_dir=`echo "${EPUB_LIST[${#EPUB_LIST[@]}-1]}" | awk -F, '{print $1}'`
                    CONVERT_LIST+=( `find "$tmp_dir" -type f -exec echo '"{}"' \;` )
                    ;;
    *plain | *octet-stream ) CONVERT_LIST+=(\""$file"\");;
    *) ;;
    esac
done

echo "[ -n "$CONVERT_LIST" ] && eval "python2 -c \"$TRADIFY\" ${CONVERT_LIST[*]}""
[ -n "$CONVERT_LIST" ] && eval "python2 -c \"$TRADIFY\" ${CONVERT_LIST[*]}"
[ -n "$EPUB_LIST" ] && zipEpub
