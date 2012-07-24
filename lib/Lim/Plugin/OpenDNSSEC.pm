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
        ReadVersion => {
            out => {
                version => 'string',
                program => {
                    name => 'string',
                    version => 'string'
                }
            }
        },
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
                    '' => 'required',
                    name => 'string',
                    content => 'string'
                }
            }
        },
        ReadConfig => {
            in => {
                file => {
                    '' => 'required',
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
                    '' => 'required',
                    name => 'string',
                    content => 'string'
                }
            }
        },
        DeleteConfig => {
            in => {
                file => {
                    '' => 'required',
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
        CreateEnforcerSetup => {
        },
        #
        # Call for ods-ksmutil/ods-enforcer update *
        #
        UpdateEnforcerUpdate => {
            in => {
                update => {
                    section => 'string'
                }
            }
        },
        #
        # Call for ods-ksmutil/ods-enforcer zone *
        #
        CreateEnforcerZone => {
            in => {
                zone => {
                    '' => 'required',
                    name => 'string',
                    policy => 'string',
                    signerconf => 'string',
                    input => 'string',
                    output => 'string',
                    no_xml => 'bool optional'
                }
            }
        },
        ReadEnforcerZoneList => {
            out => {
                zone => {
                    name => 'string',
                    policy => 'string'
                }
            }
        },
        DeleteEnforcerZone => {
            in => {
                zone => {
                    '' => 'required',
                    all => 'bool optional',
                    name => 'string',
                    no_xml => 'bool optional'
                },
            }
        },
        #
        # Call for ods-ksmutil/ods-enforcer repository *
        #
        ReadEnforcerRepositoryList => {
            out => {
                repository => {
                    name => 'string',
                    capacity => 'integer',
                    require_backup => 'bool'
                }
            }
        },
        #
        # Calls for ods-ksmutil/ods-enforcer policy *
        #
        ReadEnforcerPolicyList => {
            out => {
                policy => {
                    name => 'string',
                    description => 'string'
                }
            }
        },
        ReadEnforcerPolicyExport => {
            in => {
                policy => {
                    '' => 'required',
                    all => 'bool optional',
                    name => 'string optional'
                }
            },
            out => {
                policy => {
                    name => 'string',
                    content => 'string'
                }
            }
        },
        DeleteEnforcerPolicyPurge => {
        },
        #
        # Calls for ods-ksmutil/ods-enforcer key *
        #
        ReadEnforcerKeyList => {
            
        },
        ReadEnforcerKeyExport => {
            
        },
        CreateEnforcerKeyImport => {
            
        },
        UpdateEnforcerKeyRollover => {
            
        },
        DeleteEnforcerKeyPurge => {
            
        },
        CreateEnforcerKeyGenerate => {
            
        },
        UpdateEnforcerKeyKskRetire => {
            
        },
        UpdateEnforcerKeyDsSeen => {
            
        },
        #
        # Calls for ods-ksmutil/ods-enforcer backup *
        #
        UpdateEnforcerBackupPrepare => {
            
        },
        UpdateEnforcerBackupCommit => {
            
        },
        UpdateEnforcerBackupRollback => {
            
        },
        UpdateEnforcerBackupDone => {
            
        },
        ReadEnforcerBackupList => {
            
        },
        #
        # Call for ods-ksmutil/ods-enforcer rollover list
        #
        ReadEnforcerRolloverList => {
            
        },
        #
        # Call for ods-ksmutil/ods-enforcer database backup
        #
        CreateEnforcerDatabaseBackup => {
            
        },
        #
        # Call for ods-ksmutil/ods-enforcer zonelist export
        #
        ReadEnforcerZonelistExport => {
            
        },
        #
        # Calls for ods-signer *
        #
        ReadSignerZones => {
            
        },
        UpdateSignerSign => {
            
        },
        UpdateSignerClear => {
            
        },
        ReadSignerQueue => {
            
        },
        UpdateSignerFlush => {
            
        },
        UpdateSignerUpdate => {
            
        },
        ReadSignerRunning => {
            
        },
        UpdateSignerReload => {
            
        },
        UpdateSignerVerbosity => {
            
        }
    };
}

=head2 function1

=cut

sub Commands {
    {
        version => 1,
        configs => 1,
        config => {
            view => 1,
            edit => 1
        },
        start => {
            enforcer => 1,
            signer => 1
        },
        stop => {
            enforcer => 1,
            signer => 1
        },
        setup => 1,
        update => {
            all => 1,
            kasp => 1,
            zonelist => 1,
            conf => 1
        },
        zone => {
            add => 1,
            list => 1,
            delete => 1
        },
        repository => {
            list => 1
        },
        policy => {
            list => 1
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
