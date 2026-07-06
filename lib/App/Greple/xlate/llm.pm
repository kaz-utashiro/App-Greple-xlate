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
    my $prompt = opt('prompt') || $param->{prompt};
    my @vars = do {
        if ($prompt =~ /%s/) {
            $LANGNAME{$param->{lang_to}} // die "$param->{lang_to}: unknown lang.\n";
        } else {
            ();
        }
    };
    my $system = sprintf($prompt, @vars);
    if (my @contexts = @{$opt{contexts}}) {
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

sub _llm_in_path {
    grep { -x "$_/llm" } split /:/, $ENV{PATH} // '';
}

sub _not_found {
    "llm: command not found.\n" .
    "Install llm <https://llm.datasette.io/> with " .
    "\"pip install llm\" or \"pipx install llm\".\n";
}

sub run_llm {
    state $run = Command::Run->new;
    my($param, $text) = @_;
    ##
    ## Check PATH before forking: Command::Run's forked child has no
    ## exit guard after a failed exec, so reaching that path would let
    ## the child escape into the caller's code.
    ##
    _llm_in_path() or die _not_found();
    my @command = llm_command($param, build_system($param));
    warn Dumper \@command if opt('debug');
    my $result = $run->command(@command)
                     ->run(stdin => $text, stderr => 'capture');
    if ($result->{result} != 0) {
        die diagnose($param, $result);
    }
    print STDERR $result->{error} if $result->{error};
    $result->{data};
}

##
## Called when the llm command fails: figure out why and return a
## message useful to the user.
##
sub diagnose {
    my($param, $result) = @_;
    my $stderr = $result->{error} // '';
    if (! _llm_in_path()) {
        return _not_found();
    }
    my $model = $param->{model};
    my $models = Command::Run->new->command('llm', 'models')
        ->run(stderr => 'capture')->{data} // '';
    if ($models !~ /\Q$model\E/) {
        return "llm does not know model \"$model\".\n" .
               "Upgrade llm (\"pip install -U llm\") or register the model " .
               "in extra-openai-models.yaml.\n" .
               ($stderr ? "\n$stderr" : "");
    }
    return "llm failed:\n$stderr";
}

sub xlate_each {
    my $param = shift;
    my @count = map { int tr/\n/\n/ } @_;
    _progress("From:\n", map s/^/\t< /mgr, @_);
    my @in = map { m/.*\n/mg } @_;
    my $out = run_llm($param, $json->encode(\@in));
    my $obj = eval { $json->decode($out) };
    ref $obj eq 'ARRAY'
        or die "Invalid JSON response:\n\n$out\n";
    my @out = map { s/(?<!\n)\z/\n/r } @$obj;
    _progress("To:\n", map s/^/\t> /mgr, @out);
    if (@out < @in) {
        my $to = join '', @out;
        die sprintf("Unexpected response (%d < %d):\n\n%s\n",
                    int(@out), int(@in), $to);
    }
    map { join '', splice @out, 0, $_ } @count;
}

##
## Public entry point for engine modules: batch the blocks up to the
## maxlen/maxline limits and translate each batch in one llm call.
##
sub xlate_with {
    my $param = shift;
    my @from = map { /\n\z/ ? $_ : "$_\n" } @_;
    my @to;
    my $max = $App::Greple::xlate::max_length || $param->{max} // die;
    my $maxline = $App::Greple::xlate::max_line;
    if (my @len = grep { $_ > $max } map length, @from) {
        die "Contain lines longer than max length (@len > $max).\n";
    }
    while (@from) {
        my @tmp;
        my $len = 0;
        while (@from) {
            my $next = length $from[0];
            last if $len + $next > $max;
            $len += $next;
            push @tmp, shift @from;
            last if $maxline > 0 and @tmp >= $maxline;
        }
        @tmp > 0 or die "Probably text is longer than max length ($max).\n";
        push @to, xlate_each($param, @tmp);
    }
    @to;
}

1;
