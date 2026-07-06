package App::Greple::xlate::llm;

our $VERSION = "1.0202";

=encoding utf-8

=head1 NAME

App::Greple::xlate::llm - common backend for llm-based translation engines

=head1 DESCRIPTION

This module provides the shared machinery for translation engines built
on the C<llm> command line tool (L<https://llm.datasette.io/>): command
construction, JSON array protocol, batching, progress display, and
failure diagnosis.  Engine modules such as
L<App::Greple::xlate::llm::gpt5> only define the model name, prompt,
and model options.

=head1 SEE ALSO

L<App::Greple::xlate>, L<App::Greple::xlate::llm::gpt5>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use v5.14;
use warnings;
use utf8;
use Data::Dumper;
{
    no warnings 'redefine';
    *Data::Dumper::qquote = sub { qq["${\(shift)}"] };
    $Data::Dumper::Useperl = 1;
}

use Command::Run;
use JSON;

use App::Greple::xlate qw(%opt &opt);
use App::Greple::xlate::Lang qw(%LANGNAME);

my $json = JSON->new->canonical->pretty;

sub _progress {
    print STDERR @_ if opt('progress');
}

##
## Assemble the system prompt: expand %s to the target language name
## and append --xlate-context entries.  Phase 2 (context-aware
## differential translation) extends this function.
##
sub build_system {
    my $param = shift;
    my $prompt = $App::Greple::xlate::prompt || opt('prompt') || $param->{prompt};
    my @vars = do {
	if ($prompt =~ /%s/) {
	    $LANGNAME{$param->{lang_to}} // die "$param->{lang_to}: unknown lang.\n";
	} else {
	    ();
	}
    };
    my $system = sprintf($prompt, @vars);
    if (my @contexts = @App::Greple::xlate::contexts) {
	$system .= "\n\nTranslation context:\n" . join("\n", map "- $_", @contexts);
    }
    $system;
}

sub llm_command {
    my($param, $system) = @_;
    my @command = ('llm', '-m' => $param->{model}, '-s' => $system);
    for my $kv (@{$param->{options} // []}) {
	push @command, '-o', @$kv;
    }
    push @command, '--no-stream', '--no-log';
    @command;
}

1;
