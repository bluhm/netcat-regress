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

CLEANFILES =		${NC} {client,server}.{out,err,port}

NC =			./netcat-regress
REGRESS_SETUP =		netcat-regress
netcat-regress: /usr/bin/nc kill
	rm -f $@
	cp /usr/bin/nc $@
	chmod 755 $@

REGRESS_CLEANUP =	kill
kill:
	pkill ${NC:T} || true

REGRESS_TARGETS +=	run-tcp
run-tcp:
	echo greeting | \
	    ${NC} -n -v -l 127.0.0.1 0 \
	    2>&1 >server.out | tee server.err &
	let timeout=`date +%s`+5; \
	    while ! grep -q 'Listening on ' server.err; \
		do [[ `date +%s` -lt $$timeout ]] || exit 1; done
	sed -n 's/Listening on .* //p' server.err >server.port
	echo command | \
	    ${NC} -n -v 127.0.0.1 `cat server.port` \
	    2>&1 >client.out | tee client.err &
	let timeout=`date +%s`+5; \
	    while ! grep -q 'greeting' client.out && \
		! grep -q 'command' server.out; \
		do [[ `date +%s` -lt $$timeout ]] || exit 1; done
	grep 'greeting' client.out
	grep 'command' server.out
	grep 'Listening on 127.0.0.1 ' server.err
	grep 'Connection received on 127.0.0.1 ' server.err
	grep 'Connection to 127.0.0.1 .* succeeded!' client.err

.include <bsd.regress.mk>
