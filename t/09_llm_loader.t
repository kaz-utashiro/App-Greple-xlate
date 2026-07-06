use v5.14;
use warnings;

use Test::More;
use Command::Run;

my $probe = <<'END';
use App::Greple::xlate;
my($engine, $backend) = @ARGV;
App::Greple::xlate::opt('backend') = $backend if defined $backend;
$App::Greple::xlate::xlate_engine = $engine;
App::Greple::xlate::setup();
print "$_\n" for sort grep m{App/Greple/xlate/}, keys %INC;
END

sub probe {
    Command::Run->new->command($^X, '-Ilib', '-e', $probe, @_)
        ->run(stderr => 'capture');
}

my $r = probe('gpt5');
is($r->{result}, 0, 'gpt5 loads successfully');
like($r->{data}, qr{^App/Greple/xlate/llm/gpt5\.pm$}m,
     'gpt5 resolves to the llm backend');

$r = probe('gpt4o');
like($r->{data}, qr{^App/Greple/xlate/gpty/gpt4o\.pm$}m,
     'gpt4o still resolves to the gpty backend');

$r = probe('gpt5', 'gpty');
like($r->{data}, qr{^App/Greple/xlate/gpty/gpt5\.pm$}m,
     'backend=gpty forces gpty::gpt5');
unlike($r->{data}, qr{^App/Greple/xlate/llm/gpt5\.pm$}m,
       'llm::gpt5 is not loaded when gpty is forced');

$r = probe('null');
like($r->{data}, qr{^App/Greple/xlate/null\.pm$}m,
     'null resolves to the bare name');

$r = probe('nonexistent');
isnt($r->{result}, 0, 'unknown engine fails');
like($r->{error}, qr/not available/, 'clear error message');

done_testing;
