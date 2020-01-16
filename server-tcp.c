/*	$OpenBSD$	*/

/*
 * Copyright (c) 2020 Alexander Bluhm <bluhm@openbsd.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <sys/types.h>
#include <sys/socket.h>

#include <err.h>
#include <errno.h>
#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "util.h"

void __dead usage(void);

void __dead
usage(void)
{
	fprintf(stderr, "seerver-tcp [-r rcvmsg] [-s sndmsg] host port\n"
	"    -r rcvmsg  receive from client and check message\n"
	"    -s sndmsg  send message to client\n");
	exit(2);
}

int
main(int argc, char *argv[])
{
	const char *host, *port;
	const char *rcvmsg = NULL, *sndmsg = NULL;
	int ch, s;

	while ((ch = getopt(argc, argv, "r:s:")) != -1) {
		switch (ch) {
		case 'r':
			rcvmsg = optarg;
			break;
		case 's':
			sndmsg = optarg;
			break;
		default:
			usage();
		}
	}
	argc -= optind;
	argv += optind;

	if (argc == 2) {
		host = argv[0];
		port = argv[1];
	} else {
		usage();
	}

	alarm_timeout();
	s = -1;
	print_sockname(s);
	if (rcvmsg != NULL)
		receive_line(s, rcvmsg);
	if (sndmsg != NULL)
		send_line(s, sndmsg);

	if (close(s) == -1)
		err(1, "close");

	return 0;
}
