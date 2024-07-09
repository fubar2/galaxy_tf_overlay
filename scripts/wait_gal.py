from time import sleep
from urllib import request
from urllib.error import URLError


def run_wait_gal(url,maxloops):
    ALREADY = False
    loops = 0
    ok = False
    while not ok and loops < maxloops:
        try:
            request.urlopen(url=url)
            ok = True
        except URLError:
            print("no galaxy yet at", url)
            sleep(10 + 2*loops)
            loops += 1
    return ok

if __name__ == "__main__":
    port = 8080
    url="http://localhost:%d" % port
    ok = run_wait_gal(url, 15)
    if not ok:
        print('timed out - no galaxy')
    else:
        print('Galaxy is running')
