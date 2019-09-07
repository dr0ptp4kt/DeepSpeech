import sys
import re
import json
terms = sys.argv[1]
with open("docs.json", 'r') as f:
	data = json.loads(f.readlines()[0])
	for d in data['query']['pages']:
		if 'extract' in data['query']['pages'][d].keys():
			t = data['query']['pages'][d]['title'].encode('ascii', 'replace').decode('utf-8')
			e = data['query']['pages'][d]['extract'].encode('ascii', 'replace').decode('utf-8')
			if re.match(terms, t, re.I):
				print(e)
				exit()
			elif re.search(terms, e, re.I):
				print(e)
				exit()
	print("Sorry I have a small file. Maybe we should add fuzzy matching and talk to Kiwix about this later.")
