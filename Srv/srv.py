from flask import Flask, request
import socket
import sys
import os
import json

app = Flask(__name__)

@app.route('/data', methods=['POST'])
def data():
    data = request.get_data()
    try:
        json_data = json.loads(data)
        print(json_data)
    except:
        print('Invalid JSON')
        return 'Invalid JSON', 400
    return 'OK', 200

if __name__ == '__main__':
    # get our ipv4 address in the local network
    hostname = socket.gethostbyname(socket.gethostname())
    ip = socket.gethostbyname(hostname)
    print('Server IP: ', ip)
    print('Server Port: 5000')
    # run the server
    app.run(host=ip, port=5000, debug=True)