#!/usr/bin/bash

set -e

print_help() {
    echo "Must suppply a plaintext file (-p) and a key file (-k)"
    echo "Usage: cmd [-p=<plaintext_file>] [-k=key_file]"
    exit -1
}

for i in "$@"; do
  case $i in
    -p=* ) FILENAME="${i#*=}"
      ;;
    -k=* ) KEYFILE="${i#*=}"
      ;;
    \? ) print_help
      ;;
  esac
done

if [ -z "$FILENAME" ]; then
    print_help
fi

if [ -z "$KEYFILE" ]; then
    print_help
fi

openssl ecparam -name secp521r1 -genkey -noout -out priv_key_out.pem
openssl ec -in priv_key_out.pem -pubout -out pub_key_out.pem

openssl pkeyutl -derive -inkey priv_key_out.pem -peerkey $KEYFILE -out shared_secret.bin

openssl enc -aes256 -base64 -k "$(base64 shared_secret.bin)" -e -in $FILENAME -out $FILENAME.ciphered

rm priv_key_out.pem
rm shared_secret.bin

echo ""
echo "Your public key is pub_key_out.pem."
echo "Your ciphered file is $FILENAME.ciphered."
echo "Email both of these."
