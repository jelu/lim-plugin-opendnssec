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
        ksmutil => 0,
        signer => 0
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
                    $self->{bin}->{ksmutil} = $version;
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
    
    if ($self->{bin}->{ksmutil} and $self->{bin}->{signer}) {
        unless ($self->{bin}->{ksmutil} == $self->{bin}->{signer}) {
            die 'Missmatch version between Enforcer and Signer tools, disabling module';
        }
    }
    
    $self->{version} = $self->{bin}->{ksmutil};
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
    
    if (exists $q->{program}) {
        my @programs;
        foreach my $program (ref($q->{program}) eq 'ARRAY' ? @{$q->{program}} : $q->{program}) {
            $program = lc($program);
            if ($program eq 'enforcer') {
                push(@programs, $program);
            }
            elsif ($program eq 'signer') {
                push(@programs, $program);
            }
            else {
                $self->Error($cb, Lim::Error->new(
                    code => 500,
                    message => 'Unknown program "'.$program.'" specified'
                ));
                return;
            }
        }
        if (scalar @programs) {
            weaken($self);
            my $cmd_cb; $cmd_cb = sub {
                if (my $program = shift(@programs)) {
                    my ($stdout, $stderr);
                    my $cv = AnyEvent::Util::run_cmd
                        [ 'ods-control', $program, 'start' ],
                        '<', '/dev/null',
                        '>', \$stdout,
                        '2>', \$stderr;
                    $cv->cb (sub {
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
        my ($stdout, $stderr);
        weaken($self);
        my $cv = AnyEvent::Util::run_cmd
            [ 'ods-control', 'start' ],
            '<', '/dev/null',
            '>', \$stdout,
            '2>', \$stderr;
        $cv->cb (sub {
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
    
    if (exists $q->{program}) {
        my @programs;
        foreach my $program (ref($q->{program}) eq 'ARRAY' ? @{$q->{program}} : $q->{program}) {
            $program = lc($program);
            if ($program eq 'enforcer') {
                push(@programs, $program);
            }
            elsif ($program eq 'signer') {
                push(@programs, $program);
            }
            else {
                $self->Error($cb, Lim::Error->new(
                    code => 500,
                    message => 'Unknown program "'.$program.'" specified'
                ));
                return;
            }
        }
        if (scalar @programs) {
            weaken($self);
            my $cmd_cb; $cmd_cb = sub {
                if (my $program = shift(@programs)) {
                    my ($stdout, $stderr);
                    my $cv = AnyEvent::Util::run_cmd
                        [ 'ods-control', $program, 'stop' ],
                        '<', '/dev/null',
                        '>', \$stdout,
                        '2>', \$stderr;
                    $cv->cb (sub {
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
        my ($stdout, $stderr);
        weaken($self);
        my $cv = AnyEvent::Util::run_cmd
            [ 'ods-control', 'stop' ],
            '<', '/dev/null',
            '>', \$stdout,
            '2>', \$stderr;
        $cv->cb (sub {
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

sub CreateSetup {
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
