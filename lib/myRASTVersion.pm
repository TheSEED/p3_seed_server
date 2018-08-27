# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.031",
	package_date => 1535410840,
	package_date_str => "Aug 27, 2018 18:00:40",
    };
    return bless $self, $class;
}
1;
