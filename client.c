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

void __dead usage(void);
int connect_socket(const char *, const char *);
void print_sockname(int);
void receive_line(int, const char *);
void send_line(int, const char *);

void __dead
usage(void)
{
	fprintf(stderr, "client [-r rcvmsg] [-s sndmsg] host port\n"
	"    -r rcvmsg  receive from server and check message\n"
	"    -s sndmsg  send message to server\n");
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

	s = connect_socket(host, port);
	print_sockname(s);
	if (rcvmsg != NULL)
		receive_line(s, rcvmsg);
	if (sndmsg != NULL)
		send_line(s, sndmsg);

	if (close(s) == -1)
		err(1, "close");

	return 0;
}

int
connect_socket(const char *host, const char *port)
{
	struct addrinfo hints, *res, *res0;
	int error;
	int save_errno;
	int s;
	const char *cause = NULL;

	memset(&hints, 0, sizeof(hints));
	hints.ai_family = AF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;
	error = getaddrinfo(host, port, &hints, &res0);
	if (error)
		errx(1, "%s", gai_strerror(error));
	s = -1;
	for (res = res0; res; res = res->ai_next) {
		s = socket(res->ai_family, res->ai_socktype,
		res->ai_protocol);
		if (s == -1) {
			cause = "socket";
			continue;
		}
		if (connect(s, res->ai_addr, res->ai_addrlen) == -1) {
			cause = "connect";
			save_errno = errno;
			close(s);
			errno = save_errno;
			s = -1;
			continue;
		}
		break;  /* okay we got one */
	}
	if (s == -1)
		err(1, "%s", cause);
	freeaddrinfo(res0);

	return s;
}

void
print_sockname(int s)
{
	struct sockaddr_storage ss;
	socklen_t slen;
	char host[NI_MAXHOST], port[NI_MAXSERV];

	slen = sizeof(ss);
	if (getsockname(s, (struct sockaddr *)&ss, &slen) == -1)
		err(1, "getsockname");
	if (getnameinfo((struct sockaddr *)&ss, ss.ss_len, host,
	    sizeof(host), port, sizeof(port), NI_NUMERICHOST | NI_NUMERICSERV))
		errx(1, "getnameinfo");
	fprintf(stderr, "sock: %s %s\n", host, port);
}

void
receive_line(int s, const char *msg)
{
	char buf[100];
	size_t off, len;
	ssize_t n;

	len = 0;
	while (len < sizeof(buf)) {
		off = len;
		n = recv(s, buf + off, sizeof(buf) - off, 0);
		if (n == -1)
			err(1, "recv");
		if (n == 0) {
			fprintf(stderr, "<<< EOF\n");
			break;
		}
		len += n;
		buf[len] = '\0';
		if (buf[len - 1] == '\n')
			fprintf(stderr, "<<< %s", buf + off);
		else
			fprintf(stderr, "<<< %s\n", buf + off);
		if (strchr(buf + off, '\n') != NULL)
			break;
	}
	if (len == 0)
		errx(1, "empty receive buffer");
	if (buf[len - 1] != '\n')
		errx(1, "new line missing in receive buffer");
	buf[len--] = '\0';
	if (strcmp(msg, buf) != 0)
		errx(1, "receive expected '%s', got '%s'", msg, buf);
}

void
send_line(int s, const char *msg)
{
	char buf[100];
	size_t off, len;
	ssize_t n;

	len = strlcpy(buf, msg, sizeof(buf));
	if (len >= sizeof(buf))
		errx(1, "message too long for send buffer");
	if (buf[len] != '\n') {
		buf[len++] = '\n';
		if (len >= sizeof(buf))
			errx(1, "new line too long for send buffer");
		buf[len] = 0;
	}

	off = 0;
	while (off < len) {
		fprintf(stderr, ">>> %s", buf + off);
		n = send(s, buf + off, len - off, 0);
		if (n == -1)
			err(1, "send");
		off += n;
	}
}
