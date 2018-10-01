# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.032",
	package_date => 1538409341,
	package_date_str => "Oct 01, 2018 10:55:41",
    };
    return bless $self, $class;
}
1;
