#!/bin/bash

file=$1
shift
user=$1
shift
passwd=$1
shift

tfile=`mktemp`
openssl enc -base64 -in $file -out ${tfile}.b64
for x in `cat ${tfile}.b64`
{
    echo -n $x
} > ${tfile}
mv ${tfile} ${tfile}.b64

size=`wc -c < ${tfile}.b64`
numurls=$(( ( $size + 1023 ) / 1024 ))

tweet=""

chars=0

for (( skip=0 ; skip < size ; skip += 1024 ))
do dd if=$file bs=1 skip=$skip of=${tfile}.dd count=1024 &>/dev/null
url=`cat ${tfile}.dd`
curl "http://tinyarro.ws/api-create.php?utfpure=1&url=$url" -o ${tfile}.cl -s
dd if=${tfile}.cl bs=1 skip=14 of=${tfile}.dd &>/dev/null
tweet="$tweet`cat ${tfile}.dd`"
chars=$(($chars + 2))
if [[ $chars == 140 ]]
then curl -u $user:$passwd -d "status=$tweet" http://twitter.com/statuses/update.xml -o ${tfile}.cl -s
tweet=""
chars=0
fi
done
if [[ ! -z $tweet ]]
then curl -u $user:$passwd -d "status=$tweet" http://twitter.com/statuses/update.xml -o ${tfile}.cl -s
fi
tweet="$file "`sha1sum $file | cut -f 1 -d " "`" $numurls"
curl -u $user:$passwd -d "status=$tweet" http://twitter.com/statuses/update.xml -o ${tfile}.cl -s

rm -f ${tfile} ${tfile}.b64 ${tfile}.dd ${tfile}.cl

