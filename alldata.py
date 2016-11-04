import http.client
import json
import ast

conn = http.client.HTTPSConnection("obd2cloud.apps.exosite.io")
conn.request("GET", "/development/device/moredata?device=als7061&limit=120")
r1 = conn.getresponse()
data1 = r1.read()

dataString = data1.decode(encoding='UTF-8')
jsonObj = json.loads(dataString)

import csv
with open('cardata.csv', 'w', newline='') as csvfile:
    dataWriter = csv.writer(csvfile, delimiter=',')
	
    dataHeader = []
    for i in range(8):
        dataHeader.append(jsonObj['timeseries']['results'][0]['series'][i]['name'])
    dataWriter.writerow(dataHeader)
    
    for i in range(120):
        rowData = []
        for j in range(8):
            #print(type(float(jsonObj['timeseries']['results'][0]['series'][j]['values'][i][1])))
            rowData.append(jsonObj['timeseries']['results'][0]['series'][j]['values'][i][1])
        dataWriter.writerow(rowData)
