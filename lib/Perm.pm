package FilePermissions;

use Moose;
use Data::Dumper;
use File::chmod;

has 'filename' => (
	is => 'rw',
	required => 1,
	predicate => 'has_filename'
);

has 'octals' => (
	is => 'rw',
	isa => 'Str'
	);

has 'executable' => (
	is => 'rw',
	isa => 'Bool',
	predicate => 'is_executable'
);

sub BUILD {
	my $self = shift;

	$self->set_octals;
	$self->set_executable;
}

sub set_octals {
	my $self = shift;
	my $mode = (stat($self->filename))[2];

	my $octals = sprintf ("%04o", $mode & 07777);

	$self->octals($octals);
}

sub set_executable {
	my $self = shift;

	my $octal = substr($self->octals, 3, 1);
	my @exec = ("1", "5", "7");

	my @ret = grep ( /$octal/, @exec );

	@ret and
		$self->executable(1) or
			$self->executable(0);
}

1
