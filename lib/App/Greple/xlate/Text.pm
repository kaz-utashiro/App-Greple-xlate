package App::Greple::xlate::Text;

=encoding utf-8

=head1 NAME

App::Greple::xlate::Text - text normalization interface

=head1 SYNOPSIS

    my $obj = App::Greple::xlate::Text->new($text);
    my $normalized = $obj->normalized;

    $result = process($normalized);

    $obj->unstrip($result);

=head1 DESCRIPTION

This is an interface used within L<App::Greple::xlate> to normalize
text.

To get the normalized text, use the C<normalized> method.

Before normalization, any whitespace before and after the text is
removed.  Therefore, the result of processing the normalized text does
not preserve the whitespace in the original string; the C<unstrip>
method can be used to restore the removed whitespace.

=head1 METHODS

=over 7

=item new

Creates an object.  The first parameter is the original string; the
second and subsequent parameters are pairs of attribute name and values.

=over 4

=item paragraph

Specifies whether or not the text should be treated as a paragraph.

If true, multiple lines are concatenated into a single line.  Leading
and trailing whitespace is stripped from each line.

If false, multiple strings are processed as is.  Only leading and
trailing whitespace is stripped from the entire string.

=back

=item normalized

Returns a normalized string.

=item unstrip

Recover removed white spaces.

=back

=cut

use v5.14;
use warnings;
use utf8;

use Data::Dumper;
use Unicode::EastAsianWidth;
use Hash::Util qw(lock_keys);

sub new {
    my $class = shift;
    my $obj = bless {
	ATTR => {},
	TEXT => undef,
	STRIPPED => undef,
	NORMALIZED => undef,
	UNSTRIP => undef,
    }, $class;
    lock_keys %{$obj};
    $obj->{TEXT} = shift;
    %{$obj->{ATTR}} = (%{$obj->{ATTR}}, @_);
    $obj->strip->normalize;
    $obj;
}

sub attr :lvalue {
    my $obj = shift;
    my $key = shift;
    $obj->{ATTR}->{$key};
}

sub normalize {
    my $obj = shift;
    my $paragraph = $obj->{ATTR}->{paragraph};
    $obj->{NORMALIZED} = do {
	local $_ = $obj->{TEXT};
	if (not $paragraph) {
	    s{^.+}{
		${^MATCH}
		    =~ s/\A\s+|\s+\z//gr
		}pmger;
	}
	else {
	    s{^.+(?:\n.+)*}{
		${^MATCH}
		    # remove leading/trailing spaces
		    =~ s/\A\s+|\s+\z//gr
		    # remove newline after Japanese Punct char
		    =~ s/(?<=\p{InFullwidth})(?<=\pP)\n//gr
		    # join Japanese lines without space
		    =~ s/(?<=\p{InFullwidth})\n(?=\p{InFullwidth})//gr
		    # join ASCII lines with single space
		    =~ s/\s+/ /gr
		}pmger;
	}
    };
    $obj
}

sub normalized {
    my $obj = shift;
    $obj->{NORMALIZED};
}

sub strip {
    my $obj = shift;
    my $text = $obj->{TEXT};
    if ($obj->attr('paragraph')) {
	return $obj->paragraph_strip;
    }
    my @text = $text =~ /.*\n|.+\z/g;
    my @space = map {
	[ s/\A(\s+)// ? $1 : '', s/(\h+)$// ? $1 : '' ]
    } @text;
    $obj->{STRIPPED} = join '', @text;
    $obj->{UNSTRIP} = sub {
	for (@_) {
	    my @text = /.*\n|.+\z/g;
	    if (@space == @text + 1) {
		push @text, '';
	    }
	    die "UNMATCH:\n".Dumper(\@text, \@space) if @text != @space;
	    for my $i (keys @text) {
		my($head, $tail) = @{$space[$i]};
		$text[$i] =~ s/\A/$head/ if length $head > 0;
		$text[$i] =~ s/\Z/$tail/ if length $tail > 0;
	    }
	    $_ = join '', @text;
	}
    };
    $obj;
}

sub paragraph_strip {
    my $obj = shift;
    local *_ = \($obj->{STRIPPED} = $obj->{TEXT});
    my $head = s/\A(\s+)// ? $1 : '' ;
    my $tail = s/(\h+)$//  ? $1 : '' ;
    $obj->{UNSTRIP} = sub {
	for (@_) {
	    s/\A/$head/ if length $head;
	    s/\Z/$tail/ if length $tail;
	}
    };
    $obj;
}

sub unstrip {
    my $obj = shift;
    if (my $unstrip = $obj->{UNSTRIP}->(@_)) {
	$unstrip->(@_);
    }
    $obj;
}

1;
