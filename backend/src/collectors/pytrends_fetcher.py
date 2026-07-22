import sys
import json
import urllib.request
import urllib.parse
import xml.etree.ElementTree as ET
import ssl

# Bypass SSL Verification issues for expired local developer certificate chains
try:
    ssl._create_default_https_context = ssl._create_unverified_context
except AttributeError:
    pass

def fetch_suggestions(query):
    try:
        quoted_query = urllib.parse.quote_plus(query)
        url = f'https://suggestqueries.google.com/complete/search?client=firefox&hl=en&q={quoted_query}'
        req = urllib.request.Request(
            url,
            headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
        )
        with urllib.request.urlopen(req, timeout=3) as response:
            data = json.loads(response.read().decode('utf-8'))
            if len(data) > 1 and isinstance(data[1], list):
                return data[1]
    except Exception:
        pass
    return []

def fetch_worldwide_trends():
    geos = ['US', 'NG', 'GB', 'CA', 'ZA', 'IN']
    trends_list = []
    
    for geo in geos:
        url = f'https://trends.google.com/trends/trendingsearches/daily/rss?geo={geo}'
        try:
            req = urllib.request.Request(
                url, 
                headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
            )
            with urllib.request.urlopen(req, timeout=5) as response:
                xml_data = response.read()
                
            root = ET.fromstring(xml_data)
            
            namespaces = {
                'ht': 'https://trends.google.com/trends/trendingsearches/daily'
            }
            
            for item in root.findall('.//item'):
                title = item.find('title').text
                pub_date = item.find('pubDate').text
                
                approx_traffic = "5K+"
                traffic_el = item.find('ht:approx_traffic', namespaces)
                if traffic_el is not None and traffic_el.text:
                    approx_traffic = traffic_el.text.strip()
                
                # Fetch related suggestions (keys) for SEO
                keys = fetch_suggestions(title)
                if not keys:
                    keys = [title]
                
                trends_list.append({
                    "title": title,
                    "source": "google_trends",
                    "traffic": approx_traffic,
                    "country": geo,
                    "pubDate": pub_date,
                    "keys": keys
                })
        except Exception as e:
            continue

    print(json.dumps(trends_list))

if __name__ == "__main__":
    fetch_worldwide_trends()
