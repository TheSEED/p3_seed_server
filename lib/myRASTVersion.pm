# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.033",
	package_date => 1538601641,
	package_date_str => "Oct 03, 2018 16:20:41",
    };
    return bless $self, $class;
}
1;
