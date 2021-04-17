#! /usr/bin/python3

from fetch_ip_apis import determine_external_ip

if __name__ == "__main__":
    p = determine_external_ip(timeout=10)
    print("Result with no timeout:  " + ("PASS, " + p) if p else "FAIL")


    p = determine_external_ip(timeout=0.00000001)
    print("Result with timeout:  " + "PASS" if p is None else "FAIL")

