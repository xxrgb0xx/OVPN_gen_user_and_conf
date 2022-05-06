#!/bin/bash
EASYRSA_REQ_CN=$1
if [ ! $1 ]; then
        echo 'Certificate name not specified!'
        exit 1
fi
if [ -e pki/issued/$1.crt ]; then
        echo 'A certificate with the same name already exists!'
        exit 1
fi
echo 'Generating and signing certs...'
if [[ -n $2 && $2 != 'nopass' ]]; then
        echo 'Crt password is set.'
        ./easyrsa --batch --passout=pass:$2 gen-req $1
else
        echo 'Crt password is unset.'
        ./easyrsa --batch gen-req $1 nopass
fi
./easyrsa --batch sign-req client $1
echo 'Done.'
echo '********************'
echo 'Making .ovpn file with embedded certs...'
cp /etc/openvpn/client.sample.ovpn $1.ovpn
sed -i "1s/###/###$1/" $1.ovpn

sed -i '/<ca>/r pki/ca.crt' $1.ovpn

sed '/-----BEGIN CERTIFICATE-----/,$!d' pki/issued/$1.crt > ca.crt_tmp
sed -i '/<cert>/r ca.crt_tmp' $1.ovpn
rm ca.crt_tmp

sed -i "/<key>/r pki/private/$1.key" $1.ovpn

sed '/#.*/d' ta.key > ta.key_tmp
sed -i '/<tls-auth>/r ta.key_tmp' $1.ovpn
rm ta.key_tmp
echo 'Done.'

mv $1.ovpn /opt/nginx_ovpn
chown -R nginx:nginx /opt/nginx_ovpn
chmod -R g+rw /opt/nginx_ovpn
echo "$1.ovpn file may be download ones from the link: http://ovpn.DOMAIN.local"
