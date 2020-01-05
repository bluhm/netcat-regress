#	$OpenBSD$

# Copyright (c) 2020 Alexander Bluhm <bluhm@openbsd.org>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

NC =			./netcat-regress

CLEANFILES =		${NC:T} {client,server}.{out,err,port}

REGRESS_SETUP =		setup
setup:
	@echo '======== $@ ========'
	pkill ${NC:T} || true
	rm -f ${NC:T}
	cp /usr/bin/nc ${NC:T}
	chmod 755 ${NC:T}

REGRESS_CLEANUP =	cleanup
cleanup:
	@echo '======== $@ ========'
	-pkill ${NC:T} || true

REGRESS_TARGETS =

SERVER_NC = echo greeting | ${NC}
CLIENT_NC = echo command | ${NC}
SERVER_BG = 2>&1 >server.out | tee server.err &
CLIENT_BG = 2>&1 >client.out | tee client.err &
SERVER_LOG = >server.out 2>server.err
CLIENT_LOG = >client.out 2>client.err

PORT_GET = \
	sed -E -n 's/(Listening|Bound) on .* //p' server.err >server.port
PORT = `cat server.port`

LISTEN_WAIT = \
	let timeout=`date +%s`+5; \
	until grep -q 'Listening on ' server.err; \
	do [[ `date +%s` -lt $$timeout ]] || exit 1; done

BIND_WAIT = \
	let timeout=`date +%s`+5; \
	until grep -q 'Bound on ' server.err; \
	do [[ `date +%s` -lt $$timeout ]] || exit 1; done

TRANSFER_WAIT = \
	let timeout=`date +%s`+5; \
	until grep -q 'greeting' client.out && grep -q 'command' server.out; \
	do [[ `date +%s` -lt $$timeout ]] || exit 1; done

### TCP ####

REGRESS_TARGETS +=	run-tcp
run-tcp:
	@echo '======== $@ ========'
	${SERVER_NC} -n -v -l 127.0.0.1 0 ${SERVER_BG}
	${LISTEN_WAIT}
	${PORT_GET}
	${CLIENT_NC} -n -v 127.0.0.1 ${PORT} ${CLIENT_BG}
	${TRANSFER_WAIT}
	grep '^greeting$$' client.out
	grep '^command$$' server.out
	grep 'Listening on 127.0.0.1 ' server.err
	grep 'Connection received on 127.0.0.1 ' server.err
	grep 'Connection to 127.0.0.1 .* succeeded!' client.err

REGRESS_TARGETS +=	run-tcp6
run-tcp6:
	@echo '======== $@ ========'
	${SERVER_NC} -n -v -l ::1 0 ${SERVER_BG}
	${LISTEN_WAIT}
	${PORT_GET}
	${CLIENT_NC} -n -v ::1 ${PORT} ${CLIENT_BG}
	${TRANSFER_WAIT}
	grep '^greeting$$' client.out
	grep '^command$$' server.out
	grep 'Listening on ::1 ' server.err
	grep 'Connection received on ::1 ' server.err
	grep 'Connection to ::1 .* succeeded!' client.err

REGRESS_TARGETS +=	run-tcp-localhost-server
run-tcp-localhost-server:
	@echo '======== $@ ========'
	${SERVER_NC} -4 -v -l localhost 0 ${SERVER_BG}
	${LISTEN_WAIT}
	${PORT_GET}
	${CLIENT_NC} -n -v 127.0.0.1 ${PORT} ${CLIENT_BG}
	${TRANSFER_WAIT}
	grep '^greeting$$' client.out
	grep '^command$$' server.out
	grep 'Listening on localhost ' server.err
	grep 'Connection received on localhost ' server.err
	grep 'Connection to 127.0.0.1 .* succeeded!' client.err

REGRESS_TARGETS +=	run-tcp6-localhost-server
run-tcp6-localhost-server:
	@echo '======== $@ ========'
	${SERVER_NC} -6 -v -l localhost 0 ${SERVER_BG}
	${LISTEN_WAIT}
	${PORT_GET}
	${CLIENT_NC} -n -v ::1 ${PORT} ${CLIENT_BG}
	${TRANSFER_WAIT}
	grep '^greeting$$' client.out
	grep '^command$$' server.out
	grep 'Listening on localhost ' server.err
	grep 'Connection received on localhost ' server.err
	grep 'Connection to ::1 .* succeeded!' client.err

REGRESS_TARGETS +=	run-tcp-localhost-client
run-tcp-localhost-client:
	@echo '======== $@ ========'
	${SERVER_NC} -n -v -l 127.0.0.1 0 ${SERVER_BG}
	${LISTEN_WAIT}
	${PORT_GET}
	${CLIENT_NC} -4 -v localhost ${PORT} ${CLIENT_BG}
	${TRANSFER_WAIT}
	grep '^greeting$$' client.out
	grep '^command$$' server.out
	grep 'Listening on 127.0.0.1 ' server.err
	grep 'Connection received on 127.0.0.1 ' server.err
	grep 'Connection to localhost .* succeeded!' client.err

REGRESS_TARGETS +=	run-tcp6-localhost-client
run-tcp6-localhost-client:
	@echo '======== $@ ========'
	${SERVER_NC} -n -v -l ::1 0 ${SERVER_BG}
	${LISTEN_WAIT}
	${PORT_GET}
	${CLIENT_NC} -6 -v localhost ${PORT} ${CLIENT_BG}
	${TRANSFER_WAIT}
	grep '^greeting$$' client.out
	grep '^command$$' server.out
	grep 'Listening on ::1 ' server.err
	grep 'Connection received on ::1 ' server.err
	grep 'Connection to localhost .* succeeded!' client.err

REGRESS_TARGETS +=	run-tcp-bad-localhost-server
run-tcp-bad-localhost-server:
	@echo '======== $@ ========'
	! ${NC} -4 -v -l ::1 0 ${SERVER_LOG}
	grep 'no address associated with name' server.err

REGRESS_TARGETS +=	run-tcp6-bad-localhost-server
run-tcp6-bad-localhost-server:
	@echo '======== $@ ========'
	! ${NC} -6 -v -l 127.0.0.0 0 ${SERVER_LOG}
	grep 'no address associated with name' server.err

REGRESS_TARGETS +=	run-tcp-bad-localhost-client
run-tcp-bad-localhost-client:
	@echo '======== $@ ========'
	${SERVER_NC} -n -v -l 127.0.0.1 0 ${SERVER_BG}
	${LISTEN_WAIT}
	${PORT_GET}
	! ${NC} -4 -v ::1 ${PORT} ${CLIENT_LOG}
	grep 'no address associated with name' client.err

REGRESS_TARGETS +=	run-tcp6-bad-localhost-client
run-tcp6-bad-localhost-client:
	@echo '======== $@ ========'
	${SERVER_NC} -n -v -l 127.0.0.1 0 ${SERVER_BG}
	${LISTEN_WAIT}
	${PORT_GET}
	! ${NC} -6 -v 127.0.0.1 ${PORT} ${CLIENT_LOG}
	grep 'no address associated with name' client.err

### UDP ####

REGRESS_TARGETS +=	run-udp
run-udp:
	@echo '======== $@ ========'
	${SERVER_NC} -u -n -v -l 127.0.0.1 0 ${SERVER_BG}
	${BIND_WAIT}
	${PORT_GET}
	# the -v option would cause udptest() to write additional X
	${CLIENT_NC} -u -n 127.0.0.1 ${PORT} ${CLIENT_BG}
	${TRANSFER_WAIT}
	grep '^greeting$$' client.out
	grep '^command$$' server.out
	grep 'Bound on 127.0.0.1 ' server.err
	grep 'Connection received on 127.0.0.1 ' server.err

REGRESS_TARGETS +=	run-udp6
run-udp6:
	@echo '======== $@ ========'
	${SERVER_NC} -u -n -v -l ::1 0 ${SERVER_BG}
	${BIND_WAIT}
	${PORT_GET}
	# the -v option would cause udptest() to write additional X
	${CLIENT_NC} -u -n ::1 ${PORT} ${CLIENT_BG}
	${TRANSFER_WAIT}
	grep '^greeting$$' client.out
	grep '^command$$' server.out
	grep 'Bound on ::1 ' server.err
	grep 'Connection received on ::1 ' server.err

REGRESS_TARGETS +=	run-udp-localhost
run-udp-localhost:
	@echo '======== $@ ========'
	${SERVER_NC} -u -4 -v -l localhost 0 ${SERVER_BG}
	${BIND_WAIT}
	${PORT_GET}
	# the -v option would cause udptest() to write additional X
	${CLIENT_NC} -u -4 localhost ${PORT} ${CLIENT_BG}
	${TRANSFER_WAIT}
	grep '^greeting$$' client.out
	grep '^command$$' server.out
	grep 'Bound on localhost ' server.err
	grep 'Connection received on localhost ' server.err

REGRESS_TARGETS +=	run-udp6-localhost
run-udp6-localhost:
	@echo '======== $@ ========'
	${SERVER_NC} -u -6 -v -l localhost 0 ${SERVER_BG}
	${BIND_WAIT}
	${PORT_GET}
	# the -v option would cause udptest() to write additional X
	${CLIENT_NC} -u -6 localhost ${PORT} ${CLIENT_BG}
	${TRANSFER_WAIT}
	grep '^greeting$$' client.out
	grep '^command$$' server.out
	grep 'Bound on localhost ' server.err
	grep 'Connection received on localhost ' server.err

.PHONY: ${REGRESS_SETUP} ${REGRESS_CLEANUP} ${REGRESS_TARGETS}

.include <bsd.regress.mk>
