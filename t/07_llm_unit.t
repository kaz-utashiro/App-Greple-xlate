use v5.14;
use warnings;
use utf8;

use Test::More;

use App::Greple::xlate qw(%opt);
use App::Greple::xlate::llm;

# quiet progress output during tests
$App::Greple::xlate::show_progress = 0;

my %param = (
    model     => 'test-model',
    max       => 1000,
    options   => [ [ alpha => 'one' ], [ beta => 'two' ] ],
    prompt    => "Translate the following JSON array into %s.\n",
    lang_from => 'ORIGINAL',
    lang_to   => 'JA',
);

subtest 'build_system' => sub {
    my $system = App::Greple::xlate::llm::build_system(\%param);
    like($system, qr/\ATranslate the following JSON array into Japanese\./,
	 '%s expands to language name');

    {
	my @saved = @{$opt{contexts}};
	@{$opt{contexts}} = ('background info');
	my $system = App::Greple::xlate::llm::build_system(\%param);
	like($system, qr/Translation context:\n- background info/,
	     '--xlate-context is appended');
	@{$opt{contexts}} = @saved;
    }
    {
	my $saved = ${$opt{prompt}};
	${$opt{prompt}} = "Custom prompt.";
	my $system = App::Greple::xlate::llm::build_system(\%param);
	is($system, "Custom prompt.", '--xlate-prompt replaces the default');
	${$opt{prompt}} = $saved;
    }
    {
	my %p = (%param, lang_to => 'XX');
	ok(!eval { App::Greple::xlate::llm::build_system(\%p); 1 },
	   'unknown language dies');
	like($@, qr/XX: unknown lang/, 'die message names the language');
    }
};

subtest 'llm_command' => sub {
    my @cmd = App::Greple::xlate::llm::llm_command(\%param, 'SYSTEM PROMPT');
    is_deeply(\@cmd,
	      [ 'llm', '-m', 'test-model', '-s', 'SYSTEM PROMPT',
		'-o', 'alpha', 'one', '-o', 'beta', 'two',
		'--no-stream', '--no-log' ],
	      'command line assembled in order');
};

done_testing;
