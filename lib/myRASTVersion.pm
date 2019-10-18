# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.039",
	package_date => 1571431892,
	package_date_str => "Oct 18, 2019 15:51:32",
    };
    return bless $self, $class;
}
1;
