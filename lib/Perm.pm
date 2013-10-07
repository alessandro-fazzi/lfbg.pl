package FilePermissions;

use Moose;
use Data::Dumper;
use File::stat;

has 'filename' => (
	is => 'rw',
	required => 1,
	predicate => 'has_filename'
);

has 'mode' => (
	is => 'rw',
	isa => 'Item'
	);

has 'octal' => (
	is => 'rw'
	);

has 'executable' => (
	is => 'rw',
	isa => 'Bool',
);

sub BUILD {
	my $self = shift;

	$self->set_mode;
	$self->set_octal;
	$self->check_if_executable;
}

sub set_mode {
	my $self = shift;
	my $info = stat($self->filename);
	my $mode = $info->mode;

	$self->mode($mode);
}

sub set_octal {
	my $self = shift;
	my $octal = sprintf "%o",$self->mode;

	$self->octal($octal);
}

sub check_if_executable {
	my $self = shift;
	( $self->mode & 0111 ) and
		$self->executable(1) or
			$self->executable(0);
}

1
