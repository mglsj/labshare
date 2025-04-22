import socket


# Create a TCP/IP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# Connect the socket to the server (replace with actual server address and port)
server_address = ("127.0.0.1", 4040)
sock.connect(server_address)

try:
    # Send some binary data
    getCode = 69
    code_bytes = getCode.to_bytes(1, byteorder="big", signed=False)

    chunk = 10
    chunk_bytes = chunk.to_bytes(4, byteorder="big", signed=False)
    print(f"Chunk as uint32 big endian: {chunk_bytes!r}")

    message = code_bytes + chunk_bytes  # code_bytes is 1 byte, chunk_bytes is 4 bytes
    print(f"Sending: {message!r}")
    sock.sendall(message)

    # Receive response
    data = sock.recv(1001)
    print(f"Received: {data!r}")
finally:
    sock.close()
