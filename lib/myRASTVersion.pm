# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.035",
	package_date => 1539968953,
	package_date_str => "Oct 19, 2018 12:09:13",
    };
    return bless $self, $class;
}
1;
