# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.027",
	package_date => 1522350236,
	package_date_str => "Mar 29, 2018 14:03:56",
    };
    return bless $self, $class;
}
1;
