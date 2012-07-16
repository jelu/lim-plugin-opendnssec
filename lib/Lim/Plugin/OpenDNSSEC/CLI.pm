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

sub configs {
    my ($self) = @_;
    my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
    
    weaken($self);
    $opendnssec->ReadConfigs(sub {
        my ($call, $response) = @_;
        
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

    if (!scalar @$args) {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->UpdateControlStart(sub {
            my ($call, $response) = @_;
            
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

    if (!scalar @$args) {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->UpdateControlStop(sub {
            my ($call, $response) = @_;
            
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
