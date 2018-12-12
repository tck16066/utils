#!/usr/bin/bash

set -e

print_help() {
    echo "Must suppply a ciphered file (-c), a peer file (-p), and a key file (-k)"
    echo "Usage: cmd [-c=<ciphered_file>] [-k=key_file] [-p=peer_file]"
    exit -1
}

for i in "$@"; do
  case $i in
    -c=* ) FILENAME="${i#*=}"
      ;;
    -k=* ) KEYFILE="${i#*=}"
      ;;
    -p=*) PEERFILE="${i#*=}"
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

if [ -z "$PEERFILE" ]; then
    print_help
fi

openssl pkeyutl -derive -inkey $KEYFILE -peerkey $PEERFILE -out shared_secret.bin

openssl enc -aes256 -base64 -k "$(base64 shared_secret.bin)" -d -in $FILENAME -out $FILENAME.plaintext
