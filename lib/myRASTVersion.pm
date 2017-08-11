# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.021",
	package_date => 1502470954,
	package_date_str => "Aug 11, 2017 12:02:34",
    };
    return bless $self, $class;
}
1;
