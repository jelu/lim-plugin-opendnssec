package Lim::Plugin::OpenDNSSEC::Server;

use common::sense;

use Fcntl qw(:seek);
use IO::File ();
use Digest::SHA ();
use AnyEvent ();
use AnyEvent::Util ();
use Scalar::Util qw(weaken);

use Lim::Plugin::OpenDNSSEC ();

use base qw(Lim::Component::Server);

=head1 NAME

...

=head1 VERSION

Version 0.1

=cut

our $VERSION = $Lim::Plugin::OpenDNSSEC::VERSION;
our %ConfigFiles = (
    'conf.xml' => [
        '/etc/opendnssec/conf.xml',
        'conf.xml'
    ],
    'kasp.xml' => [
        '/etc/opendnssec/kasp.xml',
        'kasp.xml'
    ],
    'zonelist.xml' => [
        '/etc/opendnssec/zonelist.xml',
        'zonelist.xml'
    ],
    'zonefetch.xml' => [
        '/etc/opendnssec/zonefetch.xml',
        'zonefetch.xml'
    ],
    'addns.xml' => [
        '/etc/opendnssec/addns.xml',
        'addns.xml'
    ]
);

sub OPENDNSSEC_VERSION_MIN (){ 1003000 }
sub OPENDNSSEC_VERSION_MAX (){ 1004000 }

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub Init {
    my $self = shift;
    my %args = ( @_ );

    $self->{bin} = {
        control => 0,
        enforcerd => 0,
        ksmutil => 0,
        signer => 0,
        signerd => 0
    };
    
    my ($stdout, $stderr);
    my $cv = AnyEvent::Util::run_cmd [ 'ods-control' ],
        '<', '/dev/null',
        '>', \$stdout,
        '2>', \$stderr;
    # ods-control exits with 1 when just running it
    if ($cv->recv) {
        if ($stderr =~ /usage:\s+ods-control/o) {
            $self->{bin}->{control} = 1;
        }
        else {
            $self->{logger}->warn('Unable to find "ods-control" executable, module functions limited');
        }
    }

    my $cv = AnyEvent::Util::run_cmd [ 'ods-enforcerd', '-V' ],
        '<', '/dev/null',
        '>', \$stdout,
        '2>', \$stderr;
    if ($cv->recv) {
        $self->{logger}->warn('Unable to find "ods-enforcerd" executable, module functions limited');
    }
    else {
        if ($stderr =~ /opendnssec\s+version\s+([0-9]+)\.([0-9]+)\.([0-9]+)/o) {
            my ($major,$minor,$patch) = ($1, $2, $3);
            
            if ($major > 0 and $major < 10 and $minor > -1 and $minor < 10 and $patch > -1 and $patch < 100) {
                my $version = ($major * 1000000) + ($minor * 1000) + $patch;
                
                unless ($version >= OPENDNSSEC_VERSION_MIN and $version <= OPENDNSSEC_VERSION_MAX) {
                    $self->{logger}->warn('Unsupported "ods-enforcerd" executable version, unable to continue');
                }
                else {
                    $self->{bin}->{enforcerd} = $version;
                }
            }
            else {
                $self->{logger}->warn('Invalid "ods-enforcerd" version, module functions limited');
            }
        }
        else {
            $self->{logger}->warn('Unable to get "ods-enforcerd" version, module functions limited');
        }
    }

    my $cv = AnyEvent::Util::run_cmd [ 'ods-ksmutil', '--version' ],
        '<', '/dev/null',
        '>', \$stdout,
        '2>', \$stderr;
    if ($cv->recv) {
        $self->{logger}->warn('Unable to find "ods-ksmutil" executable, module functions limited');
    }
    else {
        if ($stdout =~ /opendnssec\s+version\s+([0-9]+)\.([0-9]+)\.([0-9]+)/o) {
            my ($major,$minor,$patch) = ($1, $2, $3);
            
            if ($major > 0 and $major < 10 and $minor > -1 and $minor < 10 and $patch > -1 and $patch < 100) {
                my $version = ($major * 1000000) + ($minor * 1000) + $patch;
                
                unless ($version >= OPENDNSSEC_VERSION_MIN and $version <= OPENDNSSEC_VERSION_MAX) {
                    $self->{logger}->warn('Unsupported "ods-ksmutil" executable version, unable to continue');
                }
                else {
                    $self->{bin}->{ksmutil} = $version;
                }
            }
            else {
                $self->{logger}->warn('Invalid "ods-ksmutil" version, module functions limited');
            }
        }
        else {
            $self->{logger}->warn('Unable to get "ods-ksmutil" version, module functions limited');
        }
    }

    my $cv = AnyEvent::Util::run_cmd [ 'ods-signer', '--help' ],
        '<', '/dev/null',
        '>', \$stdout,
        '2>', \$stderr;
    # ods-signer exits with 3 on --help
    if ($cv->recv) {
        if ($stdout =~ /Version\s+([0-9]+)\.([0-9]+)\.([0-9]+)/o) {
            my ($major,$minor,$patch) = ($1, $2, $3);
            
            if ($major > 0 and $major < 10 and $minor > -1 and $minor < 10 and $patch > -1 and $patch < 100) {
                my $version = ($major * 1000000) + ($minor * 1000) + $patch;
                
                unless ($version >= OPENDNSSEC_VERSION_MIN and $version <= OPENDNSSEC_VERSION_MAX) {
                    $self->{logger}->warn('Unsupported "ods-signer" executable version, unable to continue');
                }
                else {
                    $self->{bin}->{signer} = $version;
                }
            }
            else {
                $self->{logger}->warn('Invalid "ods-signer" version, module functions limited');
            }
        }
        else {
            $self->{logger}->warn('Unable to get "ods-signer" version, module functions limited');
        }
    }

    my $cv = AnyEvent::Util::run_cmd [ 'ods-signerd', '-V' ],
        '<', '/dev/null',
        '>', \$stdout,
        '2>', \$stderr;
    if ($cv->recv) {
        $self->{logger}->warn('Unable to find "ods-signerd" executable, module functions limited');
    }
    else {
        if ($stdout =~ /opendnssec\s+version\s+([0-9]+)\.([0-9]+)\.([0-9]+)/o) {
            my ($major,$minor,$patch) = ($1, $2, $3);
            
            if ($major > 0 and $major < 10 and $minor > -1 and $minor < 10 and $patch > -1 and $patch < 100) {
                my $version = ($major * 1000000) + ($minor * 1000) + $patch;
                
                unless ($version >= OPENDNSSEC_VERSION_MIN and $version <= OPENDNSSEC_VERSION_MAX) {
                    $self->{logger}->warn('Unsupported "ods-signerd" executable version, unable to continue');
                }
                else {
                    $self->{bin}->{signerd} = $version;
                }
            }
            else {
                $self->{logger}->warn('Invalid "ods-signerd" version, module functions limited');
            }
        }
        else {
            $self->{logger}->warn('Unable to get "ods-signerd" version, module functions limited');
        }
    }
    
    my $version = 0;
    foreach my $program (keys %{$self->{bin}}) {
        if ($program eq 'control') {
            next;
        }
        if ($self->{bin}->{$program}) {
            if ($version and $version != $self->{bin}->{$program}) {
                die 'Missmatch version between Enforcer and Signer tools, disabling module';
            }
            $version = $self->{bin}->{$program};
        }
    }
    
    $self->{version} = $version;
}

=head2 function1

=cut

sub Destroy {
}

=head2 function1

=cut

sub _ScanConfig {
    my ($self) = @_;
    my %file;
    
    foreach my $config (keys %ConfigFiles) {
        
        if ($config eq 'zonefetch.xml') {
            if ($self->{version} >= 1004000) {
                # zonefetch.xml is only pre 1.4
                next;
            }
        }
        elsif ($config eq 'addns.xml') {
            if ($self->{version} <= 1004000) {
                # addns.xml is only 1.4 and up
                next;
            }
        }
        
        foreach my $file (@{$ConfigFiles{$config}}) {
            if (defined ($file = Lim::Util::FileWritable($file))) {
                if (exists $file{$file}) {
                    $file{$file}->{write} = 1;
                    next;
                }
                
                $file{$file} = {
                    name => $file,
                    write => 1,
                    read => 1
                };
            }
            elsif (defined ($file = Lim::Util::FileReadable($file))) {
                if (exists $file{$file}) {
                    next;
                }
                
                $file{$file} = {
                    name => $file,
                    write => 0,
                    read => 1
                };
            }
        }
    }
    
    return \%file;
}

=head2 function1

=cut

sub ReadConfigs {
    my ($self, $cb) = @_;
    my $files = $self->_ScanConfig;
    
    $self->Successful($cb, {
        file => [ values %$files ]
    });
}

=head2 function1

=cut

sub CreateConfig {
    my ($self, $cb) = @_;
    
    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub ReadConfig {
    my ($self, $cb, $q) = @_;
    my $files = $self->_ScanConfig;
    my $result = {};

    if (exists $q->{file}) {
        foreach my $read (ref($q->{file}) eq 'ARRAY' ? @{$q->{file}} : $q->{file}) {
            if (exists $files->{$read->{name}}) {
                my $file = $files->{$read->{name}};
                
                if ($file->{read} and defined (my $fh = IO::File->new($file->{name}))) {
                    my ($tell, $content);
                    $fh->seek(0, SEEK_END);
                    $tell = $fh->tell;
                    $fh->seek(0, SEEK_SET);
                    if ($fh->read($content, $tell) == $tell) {
                        if (exists $result->{file}) {
                            unless (ref($result->{file}) eq 'ARRAY') {
                                $result->{file} = [ $result->{file} ];
                            }
                            push(@{$result->{file}}, {
                                name => $file->{name},
                                content => $content
                            });
                        }
                        else {
                            $result->{file} = {
                                name => $file->{name},
                                content => $content
                            };
                        }
                    }
                }
            }
            else {
                $self->Error($cb, Lim::Error->new(
                    code => 500,
                    message => 'File "'.$read->{name}.'" not found in configuration files'
                ));
                return;
            }
        }
    }
    $self->Successful($cb, $result);
}

=head2 function1

=cut

sub UpdateConfig {
    my ($self, $cb, $q) = @_;
    my $files = $self->_ScanConfig;
    my $result = {};

    if (exists $q->{file}) {
        foreach my $read (ref($q->{file}) eq 'ARRAY' ? @{$q->{file}} : $q->{file}) {
            if (exists $files->{$read->{name}}) {
                my $file = $files->{$read->{name}};

                if ($file->{write} and defined (my $tmp = Lim::Util::TempFileLikeThis($file->{name}))) {
                    print $tmp $read->{content};
                    $tmp->flush;
                    $tmp->close;
                    
                    my $fh = IO::File->new;
                    if ($fh->open($tmp->filename)) {
                        my ($tell, $content);
                        $fh->seek(0, SEEK_END);
                        $tell = $fh->tell;
                        $fh->seek(0, SEEK_SET);
                        unless ($fh->read($content, $tell) == $tell) {
                            $self->Error($cb, Lim::Error->new(
                                code => 500,
                                message => 'Failed to write "'.$read->{name}.'" to temporary file'
                            ));
                            return;
                        }
                        unless (Digest::SHA::sha1_base64($read->{content}) eq Digest::SHA::sha1_base64($content)) {
                            $self->Error($cb, Lim::Error->new(
                                code => 500,
                                message => 'Checksum missmatch on "'.$read->{name}.'" after writing to temporary file'
                            ));
                            return;
                        }
                        unless (rename($tmp->filename, $file->{name}))
                        {
                            $self->Error($cb, Lim::Error->new(
                                code => 500,
                                message => 'Failed to rename "'.$read->{name}.'"'
                            ));
                            return;
                        }
                    }
                }
            }
            else {
                $self->Error($cb, Lim::Error->new(
                    code => 500,
                    message => 'File "'.$read->{name}.'" not found in configuration files'
                ));
                return;
            }
        }
    }
    $self->Successful($cb);
}

=head2 function1

=cut

sub DeleteConfig {
    my ($self, $cb) = @_;
    
    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub UpdateControlStart {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{control}) {
        $self->Error($cb, 'No "ods-control" executable found or unsupported version, unable to continue');
        return;
    }

    if (exists $q->{program}) {
        my @programs;
        foreach my $program (ref($q->{program}) eq 'ARRAY' ? @{$q->{program}} : $q->{program}) {
            if (exists $program->{name}) {
                my $name = lc($program->{name});
                if ($name eq 'enforcer' and $self->{bin}->{enforcerd}) {
                    push(@programs, $name);
                }
                elsif ($name eq 'signer' and $self->{bin}->{signerd}) {
                    push(@programs, $name);
                }
                else {
                    $self->Error($cb, Lim::Error->new(
                        code => 500,
                        message => 'Unknown program "'.$name.'" specified'
                    ));
                    return;
                }
            }
        }
        if (scalar @programs) {
            weaken($self);
            my $cmd_cb; $cmd_cb = sub {
                if (my $program = shift(@programs)) {
                    my $cv = AnyEvent::Util::run_cmd
                        [ 'ods-control', $program, 'start' ],
                        '<', '/dev/null',
                        '>', '/dev/null',
                        '2>', '/dev/null';
                    $cv->cb(sub {
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to start OpenDNSSEC '.$program);
                            return;
                        }
                        $cmd_cb->();
                    });
                }
                else {
                    $self->Successful($cb);
                }
            };
            $cmd_cb->();
            return;
        }
    }
    else {
        weaken($self);
        my $cv = AnyEvent::Util::run_cmd
            [ 'ods-control', 'start' ],
            '<', '/dev/null',
            '>', '/dev/null',
            '2>', '/dev/null';
        $cv->cb(sub {
            if (shift->recv) {
                $self->Error($cb, 'Unable to start OpenDNSSEC');
                return;
            }
            $self->Successful($cb);
        });
        return;
    }
    $self->Successful($cb);
}

=head2 function1

=cut

sub UpdateControlStop {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{control}) {
        $self->Error($cb, 'No "ods-control" executable found or unsupported version, unable to continue');
        return;
    }

    if (exists $q->{program}) {
        my @programs;
        foreach my $program (ref($q->{program}) eq 'ARRAY' ? @{$q->{program}} : $q->{program}) {
            if (exists $program->{name}) {
                my $name = lc($program->{name});
                if ($name eq 'enforcer' and $self->{bin}->{enforcerd}) {
                    push(@programs, $name);
                }
                elsif ($name eq 'signer' and $self->{bin}->{signerd}) {
                    push(@programs, $name);
                }
                else {
                    $self->Error($cb, Lim::Error->new(
                        code => 500,
                        message => 'Unknown program "'.$name.'" specified'
                    ));
                    return;
                }
            }
        }
        if (scalar @programs) {
            weaken($self);
            my $cmd_cb; $cmd_cb = sub {
                if (my $program = shift(@programs)) {
                    my $cv = AnyEvent::Util::run_cmd
                        [ 'ods-control', $program, 'stop' ],
                        '<', '/dev/null',
                        '>', '/dev/null',
                        '2>', '/dev/null';
                    $cv->cb(sub {
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to stop OpenDNSSEC '.$program);
                            return;
                        }
                        $cmd_cb->();
                    });
                }
                else {
                    $self->Successful($cb);
                }
            };
            $cmd_cb->();
            return;
        }
    }
    else {
        weaken($self);
        my $cv = AnyEvent::Util::run_cmd
            [ 'ods-control', 'stop' ],
            '<', '/dev/null',
            '>', '/dev/null',
            '2>', '/dev/null';
        $cv->cb(sub {
            if (shift->recv) {
                $self->Error($cb, 'Unable to stop OpenDNSSEC');
                return;
            }
            $self->Successful($cb);
        });
        return;
    }
    $self->Successful($cb);
}

=head2 function1

=cut

sub CreateEnforcerSetup {
    my ($self, $cb) = @_;
    
    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }
    
    # TODO confirm with user

    weaken($self);
    my ($stdout, $stderr);
    my $stdin = "Y\r";
    my $cv = AnyEvent::Util::run_cmd [ 'ods-ksmutil', 'setup' ],
        '<', \$stdin,
        '>', \$stdout,
        '2>', \$stderr;
    $cv->cb(sub {
        if (shift->recv) {
            $self->Error($cb, 'Unable to setup OpenDNSSEC');
            return;
        }
        $self->Successful($cb);
    });
}

=head2 function1

=cut

sub UpdateEnforcerUpdate {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub CreateEnforcerZone {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub ReadEnforcerZoneList {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub DeleteEnforcerZone {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub ReadEnforcerRepositoryList {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub ReadEnforcerPolicyList {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub ReadEnforcerPolicyExport {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub DeleteEnforcerPolicyPurge {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub ReadEnforcerKeyList {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub ReadEnforcerKeyExport {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub CreateEnforcerKeyImport {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub UpdateEnforcerKeyRollover {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub DeleteEnforcerKeyPurge {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub CreateEnforcerKeyGenerate {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub UpdateEnforcerKeyKskRetire {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub UpdateEnforcerKeyDsSeen {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub UpdateEnforcerBackupPrepare {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub UpdateEnforcerBackupCommit {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub UpdateEnforcerBackupRollback {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub UpdateEnforcerBackupDone {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub ReadEnforcerBackupList {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub ReadEnforcerRolloverList {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub CreateEnforcerDatabaseBackup {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub ReadEnforcerZonelistExport {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub ReadSignerZones {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub UpdateSignerSign {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub UpdateSignerClear {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub ReadSignerQueue {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub UpdateSignerFlush {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub UpdateSignerUpdate {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub ReadSignerRunning {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub UpdateSignerReload {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub UpdateSignerVerbosity {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented');
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

1; # End of Lim::Plugin::OpenDNSSEC::Server
