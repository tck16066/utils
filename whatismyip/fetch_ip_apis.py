#! /usr/bin/python3

import concurrent.futures
import json
import logging
import requests

def determine_external_ip(timeout: float=10.0) -> str:
    """Returns external API as string, or None on error."""
    r = request_ip(timeout=timeout)
    p = None
    if r:
        p = parse_ip_from_request(r)
    return p

def request_ip(timeout: float=10.0) -> requests.Request:
    service_6_url = 'https://api64.ipify.org?format=json'
    service_4_url = 'https://api.ipify.org?format=json'
    urls = [service_4_url, service_6_url]
    executor = concurrent.futures.ThreadPoolExecutor(max_workers=len(urls))
    futures = []
    for u in urls:
        futures.append(executor.submit(call_request_api, u))
    results = concurrent.futures.wait(futures, timeout=timeout, return_when=concurrent.futures.FIRST_COMPLETED)
    done = results[0]
    return None if len(done) == 0 else done.pop().result()
    

def call_request_api(service_url: str) -> requests.Request:
   """Returns text section of response if no error, None if error."""
   try:
       r = requests.get(service_url)
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

