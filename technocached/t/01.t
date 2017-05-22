use Cache::Memcached::Fast;
use DDP;

my $memd = Cache::Memcached::Fast->new({servers => ['127.0.0.1:11211']});

$memd->set('skey', 'text');