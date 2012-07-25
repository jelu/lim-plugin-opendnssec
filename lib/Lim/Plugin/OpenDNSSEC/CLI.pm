package Lim::Plugin::OpenDNSSEC::CLI;

use common::sense;

use Getopt::Long ();
use Scalar::Util qw(weaken);

use Lim::Plugin::OpenDNSSEC ();

use base qw(Lim::Component::CLI);

=head1 NAME

...

=head1 VERSION

Version 0.1

=cut

our $VERSION = $Lim::Plugin::OpenDNSSEC::VERSION;

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub version {
    my ($self) = @_;
    my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
    
    weaken($self);
    $opendnssec->ReadVersion(sub {
        my ($call, $response) = @_;
        
        unless (defined $self) {
            undef($opendnssec);
            return;
        }
        
        if ($call->Successful) {
            $self->cli->println('OpenDNSSEC plugin version ', $response->{version});
            if (exists $response->{program}) {
                $self->cli->println('OpenDNSSEC programs:');
                foreach my $program (ref($response->{program}) eq 'ARRAY' ? @{$response->{program}} : $response->{program}) {
                    $self->cli->println('    ', $program->{name}, ' version ', $program->{version});
                }
            }
            $self->Successful;
        }
        else {
            $self->Error($call->Error);
        }
        undef($opendnssec);
    });
}

=head2 function1

=cut

sub configs {
    my ($self) = @_;
    my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
    
    weaken($self);
    $opendnssec->ReadConfigs(sub {
        my ($call, $response) = @_;
        
        unless (defined $self) {
            undef($opendnssec);
            return;
        }
        
        if ($call->Successful) {
            $self->cli->println('OpenDNSSEC config files found:');
            if (exists $response->{file}) {
                foreach my $file (ref($response->{file}) eq 'ARRAY' ? @{$response->{file}} : $response->{file}) {
                    $self->cli->println($file->{name},
                        ' (readable: ', ($file->{read} ? 'yes' : 'no'),
                        ' writable: ', ($file->{read} ? 'yes' : 'no'),
                        ')'
                        );
                }
            }
            $self->Successful;
        }
        else {
            $self->Error($call->Error);
        }
        undef($opendnssec);
    });
}

=head2 function1

=cut

sub config {
    my ($self, $cmd) = @_;
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd);
    
    unless ($getopt and scalar @$args) {
        $self->Error;
        return;
    }

    if ($args->[0] eq 'view') {
        if (defined $args->[1]) {
            my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
            weaken($self);
            $opendnssec->ReadConfig({
                file => {
                    name => $args->[1]
                }
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    if (exists $response->{file}) {
                        foreach my $file (ref($response->{file}) eq 'ARRAY' ? @{$response->{file}} : $response->{file}) {
                            if (ref($response->{file}) eq 'ARRAY') {
                                $file->{content} =~ s/^/$file->{name}: /gm;
                                $self->cli->println($file->{content});
                            }
                            else {
                                $self->cli->println($file->{content});
                            }
                        }
                    }
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
    }
    elsif ($args->[0] eq 'edit') {
        if (defined $args->[1]) {
            my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
            weaken($self);
            $opendnssec->ReadConfig({
                file => {
                    name => $args->[1]
                }
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    my $w; $w = AnyEvent->timer(
                        after => 0,
                        cb => sub {
                            if (defined (my $content = $self->cli->Editor($response->{file}->{content}))) {
                                my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
                                $opendnssec->UpdateConfig({
                                    file => {
                                        name => $args->[1],
                                        content => $content
                                    }
                                }, sub {
                                    my ($call, $response) = @_;
                                    
                                    unless (defined $self) {
                                        undef($opendnssec);
                                        return;
                                    }
                                    
                                    if ($call->Successful) {
                                        $self->cli->println('Config updated');
                                        $self->Successful;
                                    }
                                    else {
                                        $self->Error($call->Error);
                                    }
                                    undef($opendnssec);
                                });
                            }
                            else {
                                $self->cli->println('Config not update, no change');
                                $self->Successful;
                            }
                            undef($w);
                        });
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
    }
    $self->Error;
}

=head2 function1

=cut

sub start {
    my ($self, $cmd) = @_;
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd);

    unless ($getopt) {
        $self->Error;
        return;
    }

    if (!scalar @$args) {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->UpdateControlStart(sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('OpenDNSSEC started');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'enforcer') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->UpdateControlStart({
            program => {
                name => 'enforcer'
            }
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('OpenDNSSEC Enforcer started');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'signer') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->UpdateControlStart({
            program => {
                name => 'signer'
            }
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('OpenDNSSEC Signer started');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    $self->Error;
}

=head2 function1

=cut

sub stop {
    my ($self, $cmd) = @_;
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd);

    unless ($getopt) {
        $self->Error;
        return;
    }

    if (!scalar @$args) {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->UpdateControlStop(sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('OpenDNSSEC stopped');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'enforcer') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->UpdateControlStop({
            program => {
                name => 'enforcer'
            }
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('OpenDNSSEC Enforcer stopped');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'signer') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->UpdateControlStop({
            program => {
                name => 'signer'
            }
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('OpenDNSSEC Signer stopped');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    $self->Error;
}

=head2 function1

=cut

sub setup {
    my ($self) = @_;
    my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
    
    weaken($self);
    $opendnssec->CreateEnforcerSetup(sub {
        my ($call, $response) = @_;
        
        unless (defined $self) {
            undef($opendnssec);
            return;
        }
        
        if ($call->Successful) {
            $self->cli->println('OpenDNSSEC setup successful');
            $self->Successful;
        }
        else {
            $self->Error($call->Error);
        }
        undef($opendnssec);
    });
}

=head2 function1

=cut

sub update {
    my ($self, $cmd) = @_;
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd);

    unless ($getopt) {
        $self->Error;
        return;
    }

    if (!scalar @$args or $args->[0] eq 'all') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->UpdateEnforcerUpdate(sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('OpenDNSSEC Enforcer configuration updated');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    else {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->UpdateEnforcerUpdate({
            update => {
                section => $args->[0]
            }
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('OpenDNSSEC Enforcer configuration "', $args->[0], '" updated');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    $self->Error;
}

=head2 function1

=cut

sub zone {
    my ($self, $cmd) = @_;
    my $xml = 1;
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd,
        'xml!' => \$xml
    );

    unless ($getopt and scalar @$args) {
        $self->Error;
        return;
    }

    if ($args->[0] eq 'add' and scalar @$args == 6) {
        my (undef, $zone, $policy, $signerconf, $input, $output) = @$args;
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->CreateEnforcerZone({
            zone => {
                name => $zone,
                policy => $policy,
                signerconf => $signerconf,
                input => $input,
                output => $output,
                no_xml => $xml ? 0 : 1
            }
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('Zone ', $zone, ' added');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'list') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->ReadEnforcerZoneList(sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                if (exists $response->{zone}) {
                    $self->cli->println('OpenDNSSEC Enforcer Zone List:');
                    foreach my $zone (ref($response->{zone}) eq 'ARRAY' ? @{$response->{zone}} : $response->{zone}) {
                        $self->cli->println($zone->{name}, ' (policy ', $zone->{policy}, ')');
                    }
                }
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'delete' and scalar @$args == 2) {
        my (undef, $zone) = @$args;
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->DeleteEnforcerZone({
            zone => {
                name => $zone,
                no_xml => $xml ? 0 : 1
            }
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('Zone ', $zone, ' deleted');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    $self->Error;
}

=head2 function1

=cut

sub repository {
    my ($self, $cmd) = @_;
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd);

    unless ($getopt) {
        $self->Error;
        return;
    }

    if ($args->[0] eq 'list') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->ReadEnforcerRepositoryList(sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                if (exists $response->{repository}) {
                    $self->cli->println(join("\t", 'Name', 'Capacity', 'Require Backup'));
                    foreach my $repository (ref($response->{repository}) eq 'ARRAY' ? @{$response->{repository}} : $response->{repository}) {
                        $self->cli->println(join("\t",
                            $repository->{name},
                            $repository->{capacity},
                            $repository->{require_backup} ? 'Yes' : 'No'
                        ));
                    }
                }
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    $self->Error;
}

=head2 function1

=cut

sub policy {
    my ($self, $cmd) = @_;
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd);

    unless ($getopt) {
        $self->Error;
        return;
    }

    if ($args->[0] eq 'list') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->ReadEnforcerPolicyList(sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                if (exists $response->{policy}) {
                    $self->cli->println(join("\t", 'Name', 'Description'));
                    foreach my $policy (ref($response->{policy}) eq 'ARRAY' ? @{$response->{policy}} : $response->{policy}) {
                        $self->cli->println(join("\t",
                            $policy->{name},
                            $policy->{description}
                        ));
                    }
                }
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    $self->Error;
}

=head2 function1

=cut

sub key {
    my ($self, $cmd) = @_;
    my $verbose = 0;
    my $keystate;
    my $keytype;
    my $ds = 0;
    my $cka_id;
    my $keytag;
    my $retire = 1;
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd,
        'verbose' => \$verbose,
        'keystate:s' => \$keystate,
        'keytype:s' => \$keytype,
        'ds' => \$ds,
        'cka_id:s' => \$cka_id,
        'keytag:s' => \$keytag,
        'retire!' => \$retire
    );

    unless ($getopt and scalar @$args >= 1) {
        $self->Error;
        return;
    }

    if ($args->[0] eq 'list') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        if (scalar @$args > 1) {
            my @zones;
            my $skip = 1;
            
            foreach (@$args) {
                if ($skip) {
                    $skip--;
                    next;
                }
                
                push(@zones, { name => $_ });
            }
            
            weaken($self);
            $opendnssec->ReadEnforcerKeyList({
                verbose => $verbose ? 1 : 0,
                zone => \@zones
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    if (exists $response->{zone}) {
                        $self->cli->println(join("\t", 'Zone', 'Keytype', 'State', 'Next Transaction', ($verbose ? ('CKA_ID', 'Repository', 'Keytag') : ())));
                        foreach my $zone (ref($response->{zone}) eq 'ARRAY' ? @{$response->{zone}} : $response->{zone}) {
                            foreach my $key (ref($zone->{key}) eq 'ARRAY' ? @{$zone->{key}} : $zone->{key}) {
                                $self->cli->println(join("\t",
                                    $zone->{name},
                                    $key->{type},
                                    $key->{state},
                                    $key->{next_transaction},
                                    ($verbose ? (
                                        $key->{cka_id},
                                        $key->{repository},
                                        $key->{keytag}
                                    ) : ())
                                ));
                            }
                        }
                    }
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
        else {
            weaken($self);
            $opendnssec->ReadEnforcerKeyList({
                verbose => $verbose ? 1 : 0
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    if (exists $response->{zone}) {
                        $self->cli->println(join("\t", 'Zone', 'Keytype', 'State', 'Next Transaction', ($verbose ? ('CKA_ID', 'Repository', 'Keytag') : ())));
                        foreach my $zone (ref($response->{zone}) eq 'ARRAY' ? @{$response->{zone}} : $response->{zone}) {
                            foreach my $key (ref($zone->{key}) eq 'ARRAY' ? @{$zone->{key}} : $zone->{key}) {
                                $self->cli->println(join("\t",
                                    $zone->{name},
                                    $key->{type},
                                    $key->{state},
                                    $key->{next_transaction},
                                    ($verbose ? (
                                        $key->{cka_id},
                                        $key->{repository},
                                        $key->{keytag}
                                    ) : ())
                                ));
                            }
                        }
                    }
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
    }
    elsif ($args->[0] eq 'export') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        if (scalar @$args > 1) {
            my @zones;
            my $skip = 1;
            
            foreach (@$args) {
                if ($skip) {
                    $skip--;
                    next;
                }
                
                push(@zones, { name => $_ });
            }
            
            weaken($self);
            $opendnssec->ReadEnforcerKeyExport({
                zone => \@zones,
                (defined $keystate ? (keystate => $keystate) : ()),
                (defined $keytype ? (keytype => $keytype) : ()),
                (defined $ds and $ds ? (ds => 1) : ()),
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    if (exists $response->{rr}) {
                        $self->cli->println(join("\t", 'Name', 'TTL', 'Class', 'Type', 'RDATA'));
                        foreach my $rr (ref($response->{rr}) eq 'ARRAY' ? @{$response->{rr}} : $response->{rr}) {
                            $self->cli->println(join("\t",
                                $rr->{name},
                                $rr->{ttl},
                                $rr->{class},
                                $rr->{type},
                                $rr->{rdata}
                                ));
                        }
                    }
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
        else {
            weaken($self);
            $opendnssec->ReadEnforcerKeyExport({
                (defined $keystate ? (keystate => $keystate) : ()),
                (defined $keytype ? (keytype => $keytype) : ()),
                (defined $ds and $ds ? (ds => 1) : ()),
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    if (exists $response->{rr}) {
                        $self->cli->println(join("\t", 'Name', 'TTL', 'Class', 'Type', 'RDATA'));
                        foreach my $rr (ref($response->{rr}) eq 'ARRAY' ? @{$response->{rr}} : $response->{rr}) {
                            $self->cli->println(join("\t",
                                $rr->{name},
                                $rr->{ttl},
                                $rr->{class},
                                $rr->{type},
                                $rr->{rdata}
                                ));
                        }
                    }
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
    }
    elsif ($args->[0] eq 'rollover' and scalar @$args >= 2 and ($args->[1] eq 'zone' or $args->[1] eq 'policy')) {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        if (scalar @$args > 2) {
            my @names;
            my $skip = 2;
            
            foreach (@$args) {
                if ($skip) {
                    $skip--;
                    next;
                }
                
                push(@names, {
                    name => $_,
                    (defined $keytype ? (keytype => $keytype) : ()),
                });
            }

            weaken($self);
            $opendnssec->UpdateEnforcerKeyRollover({
                $args->[1] eq 'zone' ? (zone => \@names) : (policy => \@names)
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    $self->cli->println('Rollover issued');
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
    }
    elsif ($args->[0] eq 'purge' and scalar @$args >= 2 and ($args->[1] eq 'zone' or $args->[1] eq 'policy')) {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        if (scalar @$args > 2) {
            my @names;
            my $skip = 2;
            
            foreach (@$args) {
                if ($skip) {
                    $skip--;
                    next;
                }
                
                push(@names, {
                    name => $_,
                    (defined $keytype ? (keytype => $keytype) : ()),
                });
            }

            weaken($self);
            $opendnssec->DeleteEnforcerKeyPurge({
                $args->[1] eq 'zone' ? (zone => \@names) : (policy => \@names)
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    if (exists $response->{key}) {
                        $self->cli->println('Keys (CKA_ID) purged:');
                        foreach my $key (ref($response->{key}) eq 'ARRAY' ? @{$response->{key}} : $response->{key}) {
                            $self->cli->println($key->{cka_id});
                        }
                    }
                    else {
                        $self->cli->println('No keys purged');
                    }
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
    }
    elsif ($args->[0] eq 'generate' and scalar @$args == 3) {
        my (undef, $policy, $interval) = @$args;
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->CreateEnforcerKeyGenerate({
            policy => {
                name => $policy,
                interval => $interval
            }
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                if (exists $response->{key}) {
                    $self->cli->println(join("\t", 'Keytype', 'Bits', 'Algorithm', 'CKA_ID', 'Repository'));
                    foreach my $key (ref($response->{key}) eq 'ARRAY' ? @{$response->{key}} : $response->{key}) {
                        $self->cli->println(join("\t",
                            $key->{keytype},
                            $key->{bits},
                            $key->{algorithm},
                            $key->{cka_id},
                            $key->{repository}
                            ));
                    }
                }
                else {
                    $self->cli->println('No keys generated');
                }
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'ksk' and scalar @$args == 3 and $args->[1] eq 'retire') {
        my (undef, undef, $zone) = @$args;
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->UpdateEnforcerKeyKskRetire({
            zone => {
                name => $zone,
                (defined $cka_id ? (cka_id => $cka_id) : ()),
                (defined $keytag ? (keytag => $keytag) : ())
            }
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('KSK retired');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'ds' and scalar @$args == 3 and $args->[1] eq 'seen') {
        my (undef, undef, $zone) = @$args;
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->UpdateEnforcerKeyDsSeen({
            zone => {
                name => $zone,
                (defined $cka_id ? (cka_id => $cka_id) : ()),
                (defined $keytag ? (keytag => $keytag) : ()),
                ($retire == 0 ? (no_retire => 1) : ())
            }
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('DS marked as seen');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    
    $self->Error;
}

=head2 function1

=cut

sub backup {
    my ($self, $cmd) = @_;
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd);
    
    unless ($getopt and scalar @$args >= 1) {
        $self->Error;
        return;
    }

    if ($args->[0] eq 'prepare') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        if (scalar @$args > 1) {
            my @repositories;
            my $skip = 1;
            
            foreach (@$args) {
                if ($skip) {
                    $skip--;
                    next;
                }
                
                push(@repositories, { name => $_ });
            }
            
            weaken($self);
            $opendnssec->UpdateEnforcerBackupPrepare({
                repository => \@repositories
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    $self->cli->println('Backup prepared');
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
        else {
            weaken($self);
            $opendnssec->UpdateEnforcerBackupPrepare(sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    $self->cli->println('Backup prepared');
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
    }
    elsif ($args->[0] eq 'commit') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        if (scalar @$args > 1) {
            my @repositories;
            my $skip = 1;
            
            foreach (@$args) {
                if ($skip) {
                    $skip--;
                    next;
                }
                
                push(@repositories, { name => $_ });
            }
            
            weaken($self);
            $opendnssec->UpdateEnforcerBackupCommit({
                repository => \@repositories
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    $self->cli->println('Backup committed');
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
        else {
            weaken($self);
            $opendnssec->UpdateEnforcerBackupCommit(sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    $self->cli->println('Backup committed');
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
    }
    elsif ($args->[0] eq 'rollback') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        if (scalar @$args > 1) {
            my @repositories;
            my $skip = 1;
            
            foreach (@$args) {
                if ($skip) {
                    $skip--;
                    next;
                }
                
                push(@repositories, { name => $_ });
            }
            
            weaken($self);
            $opendnssec->UpdateEnforcerBackupRollback({
                repository => \@repositories
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    $self->cli->println('Backup rollbacked');
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
        else {
            weaken($self);
            $opendnssec->UpdateEnforcerBackupRollback(sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    $self->cli->println('Backup rollbacked');
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
    }
    elsif ($args->[0] eq 'done') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        if (scalar @$args > 1) {
            my @repositories;
            my $skip = 1;
            
            foreach (@$args) {
                if ($skip) {
                    $skip--;
                    next;
                }
                
                push(@repositories, { name => $_ });
            }
            
            weaken($self);
            $opendnssec->UpdateEnforcerBackupDone({
                repository => \@repositories
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    $self->cli->println('Backup done');
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
        else {
            weaken($self);
            $opendnssec->UpdateEnforcerBackupDone(sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    $self->cli->println('Backup done');
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
    }
    elsif ($args->[0] eq 'list') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        if (scalar @$args > 1) {
            my @repositories;
            my $skip = 1;
            
            foreach (@$args) {
                if ($skip) {
                    $skip--;
                    next;
                }
                
                push(@repositories, { name => $_ });
            }
            
            weaken($self);
            $opendnssec->ReadEnforcerBackupList({
                repository => \@repositories
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    if (exists $response->{repository}) {
                        $self->cli->println(join("\t", 'Repository', 'Last Backup', 'Unbacked Up Keys', 'Prepared Keys'));
                        foreach my $repository (ref($response->{repository}) eq 'ARRAY' ? @{$response->{repository}} : $response->{repository}) {
                            my $backup = 'NONE';
                            
                            if (exists $repository->{backup}) {
                                if (ref($repository->{backup}) eq 'ARRAY') {
                                    foreach (sort {$b->{date} cmp $a->{date}} @{$repository->{backup}}) {
                                        $backup = $_;
                                        last;
                                    }
                                }
                                else {
                                    $backup = $repository->{backup};
                                }
                            }
                            
                            $self->cli->println(join("\t",
                                $repository->{name},
                                $backup,
                                exists $repository->{unbacked_up_keys} and $repository->{unbacked_up_keys} ? 'Yes' : 'No',
                                exists $repository->{prepared_keys} and $repository->{prepared_keys} ? 'Yes' : 'No'
                                ));
                        }
                    }
                    else {
                        $self->cli->println('There are no backups');
                    }
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
        else {
            weaken($self);
            $opendnssec->ReadEnforcerBackupList(sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    if (exists $response->{repository}) {
                        $self->cli->println(join("\t", 'Repository', 'Last Backup', 'Unbacked Up Keys', 'Prepared Keys'));
                        foreach my $repository (ref($response->{repository}) eq 'ARRAY' ? @{$response->{repository}} : $response->{repository}) {
                            my $backup = 'NONE';
                            
                            if (exists $repository->{backup}) {
                                if (ref($repository->{backup}) eq 'ARRAY') {
                                    foreach (sort {$b->{date} cmp $a->{date}} @{$repository->{backup}}) {
                                        $backup = $_->{date};
                                        last;
                                    }
                                }
                                else {
                                    $backup = $repository->{backup}->{date};
                                }
                            }
                            
                            $self->cli->println(join("\t",
                                $repository->{name},
                                $backup,
                                ((exists $repository->{unbacked_up_keys} and $repository->{unbacked_up_keys}) ? 'Yes' : 'No'),
                                ((exists $repository->{prepared_keys} and $repository->{prepared_keys}) ? 'Yes' : 'No')
                                ));
                        }
                    }
                    else {
                        $self->cli->println('There are no backups');
                    }
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
    }
}

=head2 function1

=cut

sub rollover {
    my ($self, $cmd) = @_;
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd);
    
    unless ($getopt and scalar @$args >= 1) {
        $self->Error;
        return;
    }

    if ($args->[0] eq 'list') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        if (scalar @$args > 1) {
            my @zones;
            my $skip = 1;
            
            foreach (@$args) {
                if ($skip) {
                    $skip--;
                    next;
                }
                
                push(@zones, { name => $_ });
            }
            
            weaken($self);
            $opendnssec->ReadEnforcerRolloverList({
                zone => \@zones
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    if (exists $response->{zone}) {
                        $self->cli->println(join("\t", 'Zone', 'Keytype', 'Rollover Expected'));
                        foreach my $zone (ref($response->{zone}) eq 'ARRAY' ? @{$response->{zone}} : $response->{zone}) {
                            $self->cli->println(join("\t",
                                $zone->{name},
                                $zone->{keytype},
                                $zone->{rollover_expected}
                                ));
                        }
                    }
                    else {
                        $self->cli->println('There are no rollovers expected');
                    }
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
        else {
            weaken($self);
            $opendnssec->ReadEnforcerRolloverList(sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    if (exists $response->{zone}) {
                        $self->cli->println(join("\t", 'Zone', 'Keytype', 'Rollover Expected'));
                        foreach my $zone (ref($response->{zone}) eq 'ARRAY' ? @{$response->{zone}} : $response->{zone}) {
                            $self->cli->println(join("\t",
                                $zone->{name},
                                $zone->{keytype},
                                $zone->{rollover_expected}
                                ));
                        }
                    }
                    else {
                        $self->cli->println('There are no rollovers expected');
                    }
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
    }
}

=head2 function1

=cut

sub database {
    my ($self, $cmd) = @_;
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd);
    
    unless ($getopt and scalar @$args == 1) {
        $self->Error;
        return;
    }

    if ($args->[0] eq 'backup') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->CreateEnforcerDatabaseBackup(sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('Database backed up');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
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

1; # End of Lim::Plugin::OpenDNSSEC::CLI
