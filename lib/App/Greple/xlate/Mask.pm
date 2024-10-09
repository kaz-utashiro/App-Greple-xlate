package App::Greple::xlate::Mask;

use v5.24;
use warnings;
use Data::Dumper;

use Hash::Util qw(lock_keys);

my %default = (
    TAG       => 'm',
    INDEX     => 'id',
    NUMBER    => 0,
    PATTERN   => [],
    TABLE     => [],
    AUTORESET => 0,
);

sub new {
    my $class = shift;
    my $obj = bless { %default }, $class;
    lock_keys %{$obj};
    $obj->configure(@_);
    $obj;
}

sub reset {
    my $obj = shift;
    $obj->{NUMBER} = 0;
    $obj->{TABLE} = [];
    $obj;
}

sub configure {
    my $obj = shift;
    while (my($a, $b) = splice @_, 0, 2) {
	if ($a eq 'pattern') {
	    my @pattern = ref $b ? @$b : $b;
	    push @{$obj->{PATTERN}}, @pattern;
	}
	elsif ($a eq 'file') {
	    open my $fh, $b or die "$b: $!";
	    chomp(my @pattern = <$fh>);
	    push @{$obj->{PATTERN}}, @pattern;
	}
	else {
	    $obj->{$a} = $b;
	}
    }
}

sub mask {
    my $obj = shift;
    my $pattern = $obj->{PATTERN} // die;
    my @patterns = ref $pattern ? @$pattern : $pattern;
    my $fromto = $obj->{TABLE};
    # edit parameters in place
    for (@_) {
	for my $pat (@patterns) {
	    next if $pat =~ /^\s*(#|$)/;
	    s{$pat}{
		my $tag = sprintf("<%s %s=%d />",
				  $obj->{TAG}, $obj->{INDEX}, ++$obj->{NUMBER});
		push @$fromto, [ $tag, ${^MATCH} ];
		$tag;
	    }gpe;
	}
    }
    return $obj;
}

sub unmask {
    my $obj = shift;
    # edit parameters in place
    for (@_) {
	for my $fromto (reverse @{$obj->{TABLE}}) {
	    my($from, $to) = @$fromto;
	    s/\Q$from/$to/;
	    /\Q$from/ and die "Masking error: \"$from\" duplicated.\n";
	}
    }
    $obj->reset if $obj->{AUTORESET};
    return $obj;
}

1;
