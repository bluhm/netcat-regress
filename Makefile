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
	-pkill ${NC:T}

REGRESS_TARGETS =

SERVER_NC = echo greeting | ${NC}
CLIENT_NC = echo command | ${NC}
SERVER_BG = 2>&1 >server.out | tee server.err &
CLIENT_BG = 2>&1 >client.out | tee client.err &

PORT_GET = \
	sed -n 's/Listening on .* //p' server.err >server.port
PORT	 = `cat server.port`

LISTEN_WAIT = \
	let timeout=`date +%s`+5; \
	until grep -q 'Listening on ' server.err; \
	do [[ `date +%s` -lt $$timeout ]] || exit 1; done

TRANSFER_WAIT = \
	let timeout=`date +%s`+5; \
	until grep -q 'greeting' client.out && grep -q 'command' server.out; \
	do [[ `date +%s` -lt $$timeout ]] || exit 1; done

REGRESS_TARGETS +=	run-tcp
run-tcp:
	@echo '======== $@ ========'
	${SERVER_NC} -n -v -l 127.0.0.1 0 ${SERVER_BG}
	${LISTEN_WAIT}
	${PORT_GET}
	${CLIENT_NC} -n -v 127.0.0.1 ${PORT} ${CLIENT_BG}
	${TRANSFER_WAIT}
	grep 'greeting' client.out
	grep 'command' server.out
	grep 'Listening on 127.0.0.1 ' server.err
	grep 'Connection received on 127.0.0.1 ' server.err
	grep 'Connection to 127.0.0.1 .* succeeded!' client.err

.PHONY: ${REGRESS_SETUP} ${REGRESS_CLEANUP} ${REGRESS_TARGETS}

.include <bsd.regress.mk>
