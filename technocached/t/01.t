use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;

my ($listen, $port) = ("127.0.0.1", 11211);

tcp_connect $listen, $port, sub {
	if (my $fh = shift) {
		my $h = AnyEvent::Handle->new(
			fh => $fh,
		);
		$h->on_error(sub { $h->destroy; });
		$h->push_write("set key flags 100 100\r\n");
		$h->push_write("datadatadata\r\n");
		$h->push_read (line => sub {
			warn $_[1];
			});
	}
	else {
		warn "Connect failed: $!";
	}

}, sub { my ($fh) = @_; 3};

AE::cv->recv;