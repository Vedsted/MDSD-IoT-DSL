import serial
import time
import socket
import select
import _thread


# Initializer

# You need to declare and implement:  log 
import externals






server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
print('Socket created')				

# Bind socket to local host and port
try:
    server.bind(('192.168.0.16', 8000))
    
except socket.error as msg:
    print('Bind failed. Error Code : ' + msg + ' Message ' + str(msg))
    sys.exit()

server.listen(10)
input = [server, ]  # a list of all connections we want to check for data
# each time we call select.select()

def run_server():
    inputready, outputready, exceptready = select.select(input, [], [])

    for s in inputready:  # check each socket that select() said has available data

        if s == server:  # if select returns our server socket, there is a new
                        # remote socket trying to connect
            client, address = server.accept()
            # add it to the socket list so we can check it now
            input.append(client)
            print('new client added%s' % str(address))

        else:
            # select has indicated that these sockets have data available to recv
            data = s.recv(1024)
            if data:
                value = str(data) # read data
                value = value[2:-1] # remove b'...'
                
                externals.log(value)
                 
def th_func_socket(action):
	while True:
		action()

_thread.start_new_thread(th_func_socket, (run_server,))

# Do nothing forever, because the thread(s) started above would exit if this (main) thread exits.
while True:
	time.sleep(100)
