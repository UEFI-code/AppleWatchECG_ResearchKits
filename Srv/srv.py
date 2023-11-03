from flask import Flask, request
import socket

app = Flask(__name__)

@app.route('/data', methods=['POST'])
def receive_data():
    data = request.get_json()
    print(data)
    # Do something with the data
    return 'Data received'

if __name__ == '__main__':
    # get our ipv4 address in the local network
    hostname = socket.gethostbyname(socket.gethostname())
    ip = socket.gethostbyname(hostname)
    print('Server IP: ', ip)
    print('Server Port: 5000')
    app.run(host=ip, port=5000, debug=True)