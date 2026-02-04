package nodo;
use strict;
use warnings;

sub new{
    my ($class, $valor)=@_;
    my $self = {
        valor =>  $valor,
        siguiente => undef,
        anterior => undef,
    };
    return bless $self, $class;
}
# getters / setters 
sub value { $_[0]->{valor} } 
sub set_value { $_[0]->{valor} = $_[1] } 
sub prev { $_[0]->{anterior} } 
sub set_prev { $_[0]->{anterior} = $_[1] } 
sub next { $_[0]->{siguiente} } 
sub set_next { $_[0]->{siguiente} = $_[1] } 
1;