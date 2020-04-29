import pandas as pd
import uuid
import requests
import urllib.request
import time
from bs4 import BeautifulSoup
from shapely.geometry import Polygon
import uuid
from subprocess import call


bbox = pd.read_csv("bbox.csv").set_index("Unnamed: 0")
bbox = Polygon(bbox.values).buffer(0.1).boundary.minimum_rotated_rectangle.exterior.xy
bbox = ["{}%2C{}%7C".format(round(x,4),round(y,4)) for [x,y] in zip(*bbox)]
coords = "".join(bbox)

request_id = "extract_" + str(uuid.uuid4()).split("-")[0]
request_id
print("Requesting map {}...".format(request_id))
url = "https://extract.bbbike.org/?lang=en&format={}&city={}&email=fje86316%40aklqo.com&as=0.1&coords={}&oi=1&layers=B000T&submit=extrakt&expire={}&ref=download"
url = url.format("osm.gz",request_id,coords,round(time.time(),0)+3600)
print(url)
response = requests.get(url)

if response.ok:
    not_found = True
    max_tries = 30
    tries = 0
    while not_found and tries < max_tries:
        tries += 1
        url = "https://download.bbbike.org/osm/extract/?date=all"
        response = requests.get(url)
        link = None
        if response.ok:
            print("Parse map url...")
            soup = BeautifulSoup(response.text, "html.parser")
            link = [x for x in soup.findAll("tr") if request_id in str(x) and ">download</a>" in str(x)]
            if len(link) == 1:
                link = "https://download.bbbike.org" + link[0].find("a").attrs["href"]
                print("Link found... {}".format(link))
                not_found = False
                call(["curl", "-o","planet.osm.gz", link])
                exit(0)
        print("Map not ready. Wait 20 seconds...")
        time.sleep(20)
else:
    print("Unable to contact https://extract.bbbike.org")
    exit(1)
