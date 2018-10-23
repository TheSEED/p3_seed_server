# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.036",
	package_date => 1540326959,
	package_date_str => "Oct 23, 2018 15:35:59",
    };
    return bless $self, $class;
}
1;
