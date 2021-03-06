#!/usr/bin/env perl
use strict;
use warnings;
use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;
use Getopt::Long;

=head1 USAGE

Через Cache::Memcached::Fast;
или вручную:
nc localhost 11211
 
 set key_name flags expire 100\r\n
 data\r\n

 get key_name\r\n


 
=head1 DESCRIPTION

Асинхронный tcp сервер memchached на AnyEvent::Scoket;

=cut



my ($listen, $port);

GetOptions (
	"listen|l=s" => \$listen,
	"port|p=i" => \$port,
	) or die 'Err args';

$listen = "127.0.0.1" unless $listen;
$port = 11211 unless $port;

my $cv = AE::cv;

my %db;

#ToDo удаление ключа по estimated time
tcp_server $listen, $port, sub {
	my $fh = shift;
	my $h = AnyEvent::Handle->new(
		fh => $fh,
		timeout => 30,
	);

	$h->on_error(sub { $h->destroy; });
	#ToDo получение/удаление нескольких ключей
	my $lsub; $lsub = sub {
		#warn $_[1]; for debug
		if ($_[1] =~ m/^set (?<key>\w+) (?<flags>\w+) (?<expire>\w+) (?<bytes>\d+)\\r\\n/){
			my $key = $+{key};
			my $struct = {	flags => $+{flags},
							expire => $+{expire},
							bytes => $+{bytes}};
			$_[0]->unshift_read (line => sub {
				if ($_[1] =~ m/(?<data>.*)\\r\\n/) {
					$struct->{data} = $+{data};
					$db{$key} = $struct;
					$h->push_write("STORED\r\n");
				}
			});
		}
		elsif ($_[1] =~ m/^add (?<key>\w+) (?<flags>\w+) (?<expire>\w+) (?<bytes>\d+)\\r\\n/) {
			unless ($db{$+{key}}) {
				my $key = $+{key};
				my $struct = {	flags => $+{flags},
								expire => $+{expire},
								bytes => $+{bytes}};
				$_[0]->unshift_read (line => sub {
					if ($_[1] =~ m/(?<data>.*)\\r\\n/) {
						$struct->{data} = $+{data};
						$db{$key} = $struct;
						$h->push_write("STORED\r\n");
					}
				});
			}
			else {
				$h->push_write("NOT_STORED\r\n");
			}
		}
		elsif ($_[1] =~ m/^replace (?<key>\w+) (?<flags>\w+) (?<expire>\w+) (?<bytes>\d+)\\r\\n/) {
			if ($db{$+{key}}) {
				my $key = $+{key};
				my $struct = {	flags => $+{flags},
								expire => $+{expire},
								bytes => $+{bytes}};
				$_[0]->unshift_read (line => sub {
					if ($_[1] =~ m/(?<data>.*)\\r\\n/) {
						$struct->{data} = $+{data};
						$db{$key} = $struct;
						$h->push_write("STORED\r\n");
					}
				});
			}
			else {
				$h->push_write("NOT_STORED\r\n");
			}
		}
		elsif ($_[1] =~ m/^get (?<key>\w+)\\r\\n/) {
			if ($db{$+{key}}) {
				$h->push_write("VALUE ".$+{key}." ".$db{$+{key}}->{flags}." ".$db{$+{key}}->{bytes}."\r\n");
				$h->push_write($db{$+{key}}->{data}."\r\n")
			}
			$h->push_write("END\r\n");
		}
		elsif ($_[1] =~ m/^delete (?<key>\w+)\\r\\n/) {
			if ($db{$+{key}}) {
				delete $db{$+{key}};
				$h->push_write("DELETED\r\n");
			}
			else {
				$h->push_write("NOT_FOUND\r\n");
			}
		}
		$h->push_read( line => \&$lsub);
	};
	$h->push_read( line => \&$lsub);
	return;
};

print "Listening on $listen:$port\n";

$cv->recv;