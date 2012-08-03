package Lim::Plugin::OpenDNSSEC;

use common::sense;

use base qw(Lim::Component);

=head1 NAME

Lim::Plugin::OpenDNSSEC - OpenDNSSEC management plugin for Lim

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';

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
                    name => 'string optional',
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
                    name => 'string'
                }
            },
            out => {
                kasp => 'string optional',
                policy => {
                    name => 'string',
                    kasp => 'string'
                }
            }
        },
        DeleteEnforcerPolicyPurge => {
        },
        #
        # Calls for ods-ksmutil/ods-enforcer key *
        #
        ReadEnforcerKeyList => {
            in => {
                verbose => 'bool optional',
                zone => {
                    name => 'string'
                }
            },
            out => {
                zone => {
                    name => 'string',
                    key => {
                        '' => 'required',
                        type => 'string',
                        state => 'string',
                        next_transaction => 'string',
                        cka_id => 'string optional',
                        repository => 'string optional',
                        keytag => 'string optional'
                    }
                }
            }
        },
        ReadEnforcerKeyExport => {
            in => {
                keystate => 'string optional',
                keytype => 'string optional',
                ds => 'bool optional',
                zone => {
                    name => 'string',
                    keystate => 'string optional',
                    keytype => 'string optional',
                    ds => 'bool optional'
                }
            },
            out => {
                rr => {
                    name => 'string',
                    ttl => 'integer',
                    class => 'string',
                    type => 'string',
                    rdata => 'string'
                }
            }
        },
        CreateEnforcerKeyImport => {
            in => {
                key => {
                    '' => 'required',
                    zone => 'string',
                    cka_id => 'string',
                    repository => 'string',
                    bits => 'integer',
                    algorithm => 'integer',
                    keystate => 'string',
                    keytype => 'string',
                    time => 'string',
                    retire => 'string optional'
                }
            }
        },
        UpdateEnforcerKeyRollover => {
            in => {
                zone => {
                    name => 'string',
                    keytype => 'string optional'
                },
                policy => {
                    name => 'string',
                    keytype => 'string optional'
                }
            }
        },
        DeleteEnforcerKeyPurge => {
            in => {
                zone => {
                    name => 'string'
                },
                policy => {
                    name => 'string'
                }
            },
            out => {
                key => {
                    cka_id => 'string'
                }
            }
        },
        CreateEnforcerKeyGenerate => {
            in => {
                policy => {
                    '' => 'required',
                    name => 'string',
                    interval => 'string'
                }
            },
            out => {
                key => {
                    cka_id => 'string',
                    repository => 'string',
                    bits => 'integer',
                    algorithm => 'integer',
                    keytype => 'string'
                }
            }
        },
        UpdateEnforcerKeyKskRetire => {
            in => {
                zone => {
                    '' => 'required',
                    name => 'string',
                    cka_id => 'string optional',
                    keytag => 'string optional'
                }
            }
        },
        UpdateEnforcerKeyDsSeen => {
            in => {
                zone => {
                    '' => 'required',
                    name => 'string',
                    cka_id => 'string optional',
                    keytag => 'string optional',
                    no_retire => 'bool optional'
                }
            }
        },
        #
        # Calls for ods-ksmutil/ods-enforcer backup *
        #
        UpdateEnforcerBackupPrepare => {
            in => {
                repository => {
                    name => 'string'
                }
            }
        },
        UpdateEnforcerBackupCommit => {
            in => {
                repository => {
                    name => 'string'
                }
            }
        },
        UpdateEnforcerBackupRollback => {
            in => {
                repository => {
                    name => 'string'
                }
            }
        },
        UpdateEnforcerBackupDone => {
            in => {
                repository => {
                    name => 'string'
                }
            }
        },
        ReadEnforcerBackupList => {
            in => {
                repository => {
                    name => 'string'
                }
            },
            out => {
                repository => {
                    name => 'string',
                    backup => {
                        date => 'string'
                    },
                    unbacked_up_keys => 'bool optional',
                    prepared_keys => 'bool optional'
                }
            }
        },
        #
        # Call for ods-ksmutil/ods-enforcer rollover list
        #
        ReadEnforcerRolloverList => {
            in => {
                zone => {
                    name => 'string'
                }
            },
            out => {
                zone => {
                    name => 'string',
                    keytype => 'string',
                    rollover_expected => 'string'
                }
            }
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
            out => {
                zonelist => 'string'
            }
        },
        #
        # Calls for ods-signer *
        #
        ReadSignerZones => {
            out => {
                zone => {
                    name => 'string'
                }
            }
        },
        UpdateSignerSign => {
            in => {
                zone => {
                    name => 'string'
                }
            }
        },
        UpdateSignerClear => {
            in => {
                zone => {
                    '' => 'required',
                    name => 'string'
                }
            }
        },
        ReadSignerQueue => {
            out => {
                now => 'string optional',
                task => {
                    type => 'string',
                    date => 'string',
                    zone => 'string'
                }
            }
        },
        UpdateSignerFlush => {
        },
        UpdateSignerUpdate => {
            in => {
                zone => {
                    name => 'string'
                }
            }
        },
        ReadSignerRunning => {
            out => {
                running => 'bool'
            }
        },
        UpdateSignerReload => {
        },
        UpdateSignerVerbosity => {
            in => {
                verbosity => 'integer'
            }
        },
        #
        # Calls for ods-hsmutil *
        #
        ReadHsmList => {
            in => {
                repository => {
                    name => 'string'
                }
            },
            out => {
                key => {
                    repository => 'string',
                    id => 'string',
                    keytype => 'string',
                    keysize => 'integer'
                }
            }
        },
        CreateHsmGenerate => {
            in => {
                key => {
                    '' => 'required',
                    repository => 'string',
                    keysize => 'integer'
                }
            },
            out => {
                key => {
                    repository => 'string',
                    id => 'string',
                    keysize => 'integer',
                    keytype => 'string'
                }
            }
        },
        DeleteHsmRemove => {
            in => {
                key => {
                    '' => 'required',
                    id => 'string'
                }
            }
        },
        DeleteHsmPurge => {
            in => {
                repository => {
                    '' => 'required',
                    name => 'string'
                }
            }
        },
        CreateHsmDnskey => {
            in => {
                key => {
                    '' => 'required',
                    id => 'string',
                    name => 'string'
                }
            },
            out => {
                key => {
                    id => 'string',
                    name => 'string',
                    rr => 'string'
                }
            }
        },
        ReadHsmTest => {
            in => {
                repository => {
                    '' => 'required',
                    name => 'string'
                }
            }
        },
        ReadHsmInfo => {
            out => {
                repository => {
                    name => 'string',
                    module => 'string',
                    slot => 'integer',
                    token_label => 'string',
                    manufacturer => 'string',
                    model => 'string',
                    serial => 'string'
                }
            }
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
            list => 1,
            export => 1
        },
        key => {
            list => 1,
            export => 1,
            import => 1,
            rollover => {
                zone => 1,
                policy => 1
            },
            purge => {
                zone => 1,
                policy => 1
            },
            generate => 1,
            ksk => {
                retire => 1
            },
            ds => {
                seen => 1
            }
        },
        backup => {
            prepare => 1,
            commit => 1,
            rollback => 1,
            done => 1,
            list => 1
        },
        rollover => {
            list => 1
        },
        database => {
            backup => 1
        },
        zonelist => {
            export => 1
        },
        signer => {
            zones => 1,
            sign => 1,
            clear => 1,
            queue => 1,
            flush => 1,
            update => 1,
            running => 1,
            reload => 1,
            verbosity => 1
        },
        hsm => {
            list => 1,
            generate => 1,
            remove => 1,
            purge => 1,
            dnskey => 1,
            test => 1,
            info => 1
        }
    };
}

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim-plugin-opendnssec/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim::Plugin::OpenDNSSEC

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim-plugin-opendnssec/issues>

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
