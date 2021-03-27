#! /usr/bin/python3

import json
import logging
import requests

def determine_external_ip() -> str:
    """Returns external API as string, or None on error."""
    r = request_ip()
    p = None
    if r:
        p = parse_ip_from_request(r)
    return p

def request_ip() -> requests.Request:
    """Returns text section of response if no error, None if error."""
    try:
        r = requests.get('https://api64.ipify.org?format=json')
        if r.status_code == 200:
            return r.text
        else:
            logging.exception("ipify bad return code: {code}".format(code=r.status_code))
    except Exception as err:
        logging.exception(err)
    return None

def parse_ip_from_request(req: requests.Request) -> str:
    """Returns external API as string, or None on error."""
    parsed = json.loads(req)
    if 'ip' not in parsed:
        logging.exception("Request missing IP field.")
        return None
    return parsed['ip'].strip()

