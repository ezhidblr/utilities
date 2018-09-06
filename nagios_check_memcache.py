# python3.6 ./nagios_check_memcache.py -p [PORT] -s [SERVER] -v; echo $?
import argparse
import logging
import socket
import sys
import uuid

MEMCACHE_KEY = 'memcache_nagios_check'

class MemcacheException(Exception):
    pass


class Memcache:
    EXPIRE = 900

    def __init__(self, host, port):
        self.host = host
        self.port = port

        self.sock = socket.socket()
        try:
            self.sock.connect((host, port))
        except Exception as e:
            raise MemcacheException(e)

        logging.info("connected to %s:%s", self.host, self.port)

    def set(self, key, value, expire=EXPIRE):
        message = 'set {} 0 {} {} \r\n{}\r\n'.format(
                    key, expire, len(value), value)

        self.sock.send(message.encode('utf-8'))
        logging.info("Sent: %s", message)

        data = self._socket_recv()
        if data != 'STORED':
            raise MemcacheException('Did not get "STORED" response')

        return data

    def get(self, key):
        message = "get {}\r\n".format(key)
        self.sock.send(message.encode('utf-8'))
        logging.info("Sent: %s", message)

        lines = self._socket_recv().splitlines()

        if not lines:
            raise MemcacheException('No data returned from memcache')
        elif lines[-1] != 'END':
            raise MemcacheException('END not sent from memcache')
        elif len(lines) == 1:
            return ''
        else:
            return "\n".join(lines[1:-1])

    def _socket_recv(self):
        data = self.sock.recv(1024).decode().strip()
        logging.info("Received: %s", data)
        return data


def parser():
    p = argparse.ArgumentParser(description='Monitor Memcache')
    p.add_argument('-s', '--server', dest='server', default='127.0.0.1',
                   help='Memcache server to connect to')
    p.add_argument('-p', '--port', dest='port', default=6379, type=int,
                   help='Port on server to connect to')
    p.add_argument('-v', '--verbose', action='store_const', dest='verbose',
                   const=logging.INFO, help='Enable verbose logging')
    return p


def main():
    args = parser().parse_args()
    logging.basicConfig(level=args.verbose)

    message = 'Write test OK'
    warn = crit = False
    value = uuid.uuid4().hex

    try:
        client = Memcache(args.server, args.port)
        client.set(MEMCACHE_KEY, value)
        data = client.get(MEMCACHE_KEY)
    except MemcacheException as e:
        message = "CRITICAL: {}".format(e)
        crit = True
    else:
        if data != value:
            message = 'CRITICAL: Failed write test (value different)'
            crit = True

    print(message)
    return 2 if crit else int(warn)


if __name__ == '__main__':
    sys.exit(main())
