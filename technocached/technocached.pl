use strict;
use warnings;
use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;

my ($listen, $port) = ("0.0.0.0", 11211);

my $cv = AE::cv;

my %db;


tcp_server $listen, $port, sub {
	my $fh = shift;
	my $h = AnyEvent::Handle->new(
		fh => $fh,
	);

	$h->on_error(sub { $h->destroy; });
	$h->push_read( line => sub {
		if ($_[1] =~ m/^set (?<key>)/){

		}
		elsif ($_[1] =~ m/^get /) {

		}
		elsif ($_[1] =~ m/^add /) {

		}
		elsif ($_[1] =~ m/^replace /) {

		}
		$h->push_write($_[1]."\n");
	});
	return;
};

print "Listening on $listen:$port\n";

$cv->recv;