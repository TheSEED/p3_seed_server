# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.029",
	package_date => 1534185838,
	package_date_str => "Aug 13, 2018 13:43:58",
    };
    return bless $self, $class;
}
1;
