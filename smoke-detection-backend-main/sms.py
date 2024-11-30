import http.client

conn = http.client.HTTPSConnection("sms77io.p.rapidapi.com")

payload = "-----011000010111000001101001\r\nContent-Disposition: form-data; name=\"msg_id\"\r\n\r\n123456789\r\n-----011000010111000001101001\r\nContent-Disposition: form-data; name=\"to\"\r\n\r\n+201023380723\r\n-----011000010111000001101001--\r\n\r\n"

headers = {
    'x-rapidapi-key': "6a7db481dcmsh86f4431b836c6a6p147c1bjsn848db42d7841",
    'x-rapidapi-host': "sms77io.p.rapidapi.com",
    'Content-Type': "multipart/form-data; boundary=---011000010111000001101001"
}

conn.request("POST", "/rcs/events", payload, headers)

res = conn.getresponse()
data = res.read()

print(data.decode("utf-8"))