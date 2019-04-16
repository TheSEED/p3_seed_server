# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.038",
	package_date => 1555440494,
	package_date_str => "Apr 16, 2019 13:48:14",
    };
    return bless $self, $class;
}
1;
