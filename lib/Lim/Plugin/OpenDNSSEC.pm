package Lim::Plugin::OpenDNSSEC;

use common::sense;

use base qw(Lim::Component);

=head1 NAME

...

=head1 VERSION

Version 0.1

=cut

our $VERSION = '0.1';

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub Module {
    'OpenDNSSEC';
}

=head2 function1

=cut

sub Calls {
    {
        #
        # Calls for config files: conf.xml kasp.xml zonelist.xml zonefetch.xml addns.xml
        #
        ReadConfigs => {
            out => {
                file => {
                    name => 'string',
                    write => 'integer',
                    read => 'integer'
                }
            }
        },
        CreateConfig => {
            in => {
                file => {
                    name => 'string',
                    content => 'string'
                }
            }
        },
        ReadConfig => {
            in => {
                file => {
                    name => 'string'
                }
            },
            out => {
                file => {
                    name => 'string',
                    content => 'string'
                }
            }
        },
        UpdateConfig => {
            in => {
                file => {
                    name => 'string',
                    content => 'string'
                }
            }
        },
        DeleteConfig => {
            in => {
                file => {
                    name => 'string'
                }
            }
        },
        #
        # Calls for ods-control
        #
        UpdateControlStart => {
            in => {
                program => {
                    name => 'string'
                }
            }
        },
        UpdateControlStop => {
            in => {
                program => {
                    name => 'string'
                }
            }
        },
        #
        # Call for ods-ksmutil/ods-enforcer setup
        #
        CreateSetup => {
        }
    };
}

=head2 function1

=cut

sub Commands {
    {
        configs => 1,
        config => {
            view => 1,
            edit => 1
        }
    };
}

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lim at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lim>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lim>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lim>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lim>

=item * Search CPAN

L<http://search.cpan.org/dist/Lim/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::Plugin::OpenDNSSEC
