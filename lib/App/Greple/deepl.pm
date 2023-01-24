package App::Greple::deepl;

our $VERSION = "0.01";

=encoding utf-8

=head1 NAME

App::Greple::deepl - deepl module for greple

=head1 SYNOPSIS

    greple -Mdeepl --xlate target-file

=head1 DESCRIPTION

B<Greple> B<deepl> module find text blocks and replace them by the
translated text produced by the B<deepl> command.

If you want to translate normal text block in L<pod> style document,
use B<greple> command with C<deepl> and C<perl> module like this:

    greple -Mdeepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Pattern C<^(\w.*\n)+> means consecutive lines starting with
alpha-numeric character.  This command will find and replace them by
the B<deepl> command output.

Option B<--all> is used to produce entire text.

By default, original and translated text is printed in the conflict
marker format compatible with L<git(1)>.  Using C<ifdef> format, you
can get desired part by L<unifdef(1)> command easily.  Format can be
specified by B<--deepl-format> option.

If you want to translate entire text, use B<--deepl-match-entire>
option.  This is a short-cut to specify the pattern matches entire
text C<(?s).*>.

=head1 OPTIONS

=over 7

=item B<--xlate>

Invoke the translation process for each matched area.

Without this option, B<greple> behaves as a normal search command.  So
you can check which part of the file will be subject of the
translation before invoking actual work.

Command result goes to standard out, so redirect to file if necessary,
or consider to use L<App::Greple::update> module.

=item B<--deepl-format>

Specify the output format for original and translated text.

=over 4

=item B<conflict> (DEFAULT)

Print original and translated text in L<git(1)> conflict marker format.

    <<<<<<< ORIGINAL
    original text
    =======
    translated Japanese text
    >>>>>>> JA

You can recover the original file by next L<sed(1)> command.

    sed -e '/^<<<<<<< /d' -e '/^=======/,/^>>>>>>> /d'

=item B<ifdef>

Print original and translated text in L<cpp(1)> C<#ifdef> format.

    #ifdef ORIGINAL
    original text
    #endif
    #ifdef JA
    translated Japanese text
    #endif

You can retrieve only Japanese text by the B<unifdef> command:

    unifdef -UORIGINAL -DJA foo.ja.pm

=item B<space>

Print original and translated text separated by single blank line.

=item B<none>

If the format is C<none> or unkown, only translated text is printed.

=back

=item B<--xlate-to> (DEFAULT: C<JA>)

Specify the target language.  You can get available languages by
C<deepl languages> command.

=item B<-->[B<no->]B<deepl-progress> (DEFAULT: True)

See the tranlsation result in real time in the STDERR output.

=item B<-->[B<no->]B<deepl-join> (DEFAULT: True)

By default, continuous non-space lines are connected together to make
a single line paragraph.  If you don't need this operation, use
B<--no-deepl-join> option.

=item B<--deepl-fold>

=item B<--deepl-fold-width>=I<n> (DEFAULT: 76)

Fold translated text by the specified width.  Default width is 76 and
can be set by B<--deepl-fold-width> option.  Four columns are reserved
for run-in operation, so each line could hold 80 characters at most.

=item B<--deepl-match-entire>

Set the whole text of the file as a target area.

=back

=head1 ENVIRONMENT

=over 7

=item DEEPL_AUTH_KEY

Set your authentication key for DeepL service.

=back

=head1 SEE ALSO

=over 7

=item L<https://github.com/DeepLcom/deepl-python>

DeepL Python library and CLI command.

=item L<App::Greple>

See the B<greple> manual for the detail about target text pattern.
Use B<--inside>, B<--outside>, B<--include>, B<--exclude> options to
limit the matching area.

=item L<App::Greple::update>

You can use C<-Mupdate> module to modify files by the result of
B<greple> command.

=back

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright ©︎ 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use v5.14;
use warnings;

use Exporter 'import';
use Data::Dumper;

our @EXPORT = qw(deepl);

use Text::ANSI::Fold ':constants';
use App::cdif::Command;

our $show_progress = 1;
our $output_format = 'conflict';
our $join_paragraph = 1;
our $cleanup_trailing_newlines = 1;
our $lang_from = 'ORIGINAL';
our $lang_to = 'JA';
our $fold_line = 0;
our $fold_width = 76;
our $auth_key;
our $cache_data
    //= $ENV{GREPLE_DEEPL_USECACHE};
our $cache_file
    //= ($ENV{GREPLE_DEEPL_CACHEFILE} || '__GREPLE_DEEPL_CACHE__.json');

our %LABELS = (
    none => undef,
    conflict => [
	"<<<<<<< $lang_from\n",
	"=======\n",
	">>>>>>> $lang_to\n" ],
    ifdef => [
	"#ifdef $lang_from\n",
	"#endif\n#ifdef $lang_to\n",
	"#endif\n" ],
    space => [ '', "\n", '' ],
    );

my $xlate_old_cache = {};
my $xlate_new_cache = {};
my $xlate_cache_update;

sub get_label {
    $LABELS{$_[0]};
}

sub _translate {
    state $command = [ 'deepl', 'text',
		       '--to' => $lang_to,
		       $auth_key ? ('--auth-key' => $auth_key) : () ];
    (state $deepl = App::cdif::Command->new)
	->command([@$command, $_[0]])->update->data;
}

sub translate {
    goto _translate unless $cache_data;
    my $text = shift;
    $xlate_new_cache->{$text} //= $xlate_old_cache->{$text} // do {
	$xlate_cache_update++;
	_translate $text;
    };
}

sub deepl {
    my %args = @_;
    my $orig = $_;
    $orig .= "\n" unless $orig =~ /\n\z/;

    print STDERR "From:\n", $orig =~ s/^/\t< /mgr
	if $show_progress;

    my $source = $orig;
    $source =~ s/.\K\n(?=.)/ /g if $join_paragraph;

    $_ = translate($source);

    s/\n\K\n+\z// if $cleanup_trailing_newlines;
    $_ = fold_lines($_) if $fold_line;

    print STDERR "To:\n", s/^/\t> /mgr, "\n\n"
	if $show_progress;

    if (state $label = get_label($output_format)) {
	my($start, $mid, $end) = @$label;
	return join '', $start, $orig, $mid, $_, $end;
    } else {
	return $_;
    }
}

sub fold_lines {
    state $fold = Text::ANSI::Fold->new(
	width     => $fold_width,
	boundary  => 'word',
	linebreak => LINEBREAK_ALL,
	runin     => 4,
	runout    => 4,
	);
    join "\n", $fold->text($_[0])->chops;
}

use JSON;

sub read_cache {
    if (open my $fh, $cache_file) {
	my $json = do { local $/; <$fh> };
	my $hash = decode_json $json;
	%$xlate_old_cache = %$hash;
	warn "read cache from $cache_file\n";
    }
}

sub write_cache {
    if (open my $fh, ">$cache_file") {
	my $json = encode_json $xlate_new_cache;
	print $fh $json;
	warn "write cache to $cache_file\n";
    }
}

sub prologue {
    if ($cache_data) {
	if (lc $cache_data eq 'accumulate') {
	    $xlate_new_cache = $xlate_old_cache;
	}
	read_cache if $cache_data;
    }
}

sub epilogue {
    write_cache if $cache_data and $xlate_cache_update;
}

1;

__DATA__

builtin deepl-progress!    $show_progress
builtin deepl-format=s     $output_format
builtin deepl-join!        $join_paragraph
builtin deepl-auth-key=s   $auth_key
builtin deepl-fold!        $fold_line
builtin deepl-fold-width=i $fold_width
builtin xlate-from=s       $lang_from
builtin xlate-to=s         $lang_to
builtin deepl_cache        $cache_data

option default \
	--face +E --ci=A \
	--prologue __PACKAGE__::prologue \
	--epilogue __PACKAGE__::epilogue

option --deepl-target --ci=A --face=+E

option --xlate --cm &deepl

option --deepl-match-entire    --re '\A(?s).+\z'
option --deepl-match-paragraph --re '^(.+\n)+'
option --deepl-match-podtext   -Mperl --pod --re '^(\w.*\n)+'

#  LocalWords:  deepl ifdef unifdef Greple greple perl
