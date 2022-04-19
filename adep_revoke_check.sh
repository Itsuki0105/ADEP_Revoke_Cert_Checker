#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Useage: $0 [File]" 1>&2
    exit 1
fi

cd `dirname $0`

mkdir ./tmp
mkdir ./tmp/cert
unzip -q $1 -d ./tmp

sed -e "s/OCSP-URI://g" <(sed "s/ //g" <(grep -h "OCSP - URI:" <(/usr/libexec/PlistBuddy -c "Print DeveloperCertificates:0" /dev/stdin <<< $(security cms -D -i ./tmp/Payload/Scarlet.app/embedded.mobileprovision) | openssl x509 -inform der -text -noout))) | (u=$(cat) ;openssl ocsp -noverify -no_nonce -issuer <(openssl x509 -in <(sed -e "s/CAIssuers-URI://g" <(sed "s/ //g" <(grep -h "CA Issuers - URI:" <(/usr/libexec/PlistBuddy -c "Print DeveloperCertificates:0" /dev/stdin <<< $(security cms -D -i ./tmp/Payload/Scarlet.app/embedded.mobileprovision) | openssl x509 -inform der -text -noout))) | (v=$(cat) ;curl -s $v;)) -inform DER -outform PEM -text) -cert <(openssl x509 -in <(/usr/libexec/PlistBuddy -c "Print DeveloperCertificates:0" /dev/stdin <<< $(security cms -D -i ./tmp/Payload/Scarlet.app/embedded.mobileprovision)) -inform DER -outform PEM -text) -url $u;) > ./tmp/cert/result.txt

grep "good" ./tmp/cert/result.txt > /dev/null

V=""

if [ $? = 0 ]; then
    V="有効"
else
    grep "revoked" ./tmp/cert/result.txt > /dev/null
    if [ $? = 0 ]; then
        V="無効"
    else
        V="不明"
    fi
fi

echo "現在の証明書の有効状態は、【${V}】です。"
rm -rf ./tmp
exit
    



