package Lim::Plugin::OpenDNSSEC::Server;

use common::sense;

use Fcntl qw(:seek :flock);
use IO::File ();
use Digest::SHA ();
use Scalar::Util qw(weaken blessed);
use XML::LibXML ();

use Lim::Plugin::OpenDNSSEC ();

use Lim::Util ();

use base qw(Lim::Component::Server);

=encoding utf8

=head1 NAME

...

=head1 VERSION

See L<Lim::Plugin::OpenDNSSEC> for version.

=over 4

=item OPENDNSSEC_VERSION_MIN

=item OPENDNSSEC_VERSION_MAX

=back

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

=head2 Init

=cut

sub Init {
    my $self = shift;
    my %args = ( @_ );

    $self->{bin} = {
        control => 0,
        enforcerd => 0,
        ksmutil => 0,
        signer => 0,
        signerd => 0,
        hsmutil => 0
    };
    $self->{bin_version} = {};
    
    my ($stdout, $stderr);
    my $cv = Lim::Util::run_cmd [ 'ods-control' ],
        '<', '/dev/null',
        '>', \$stdout,
        '2>', \$stderr;
    # ods-control exits with 1 when just running it
    if ($cv->recv) {
        if ($stderr =~ /usage:\s+ods-control/o) {
            $self->{bin}->{control} = 1;
            $self->{bin_version}->{control} = 1;
        }
        else {
            $self->{logger}->warn('Unable to find "ods-control" executable, module functions limited');
        }
    }

    my $cv = Lim::Util::run_cmd [ 'ods-enforcerd', '-V' ],
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
                    $self->{bin_version}->{enforcerd} = $major.'.'.$minor.'.'.$patch;
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

    my $cv = Lim::Util::run_cmd [ 'ods-ksmutil', '--version' ],
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
                    $self->{bin_version}->{ksmutil} = $major.'.'.$minor.'.'.$patch;
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

    my $cv = Lim::Util::run_cmd [ 'ods-signer', '--help' ],
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
                    $self->{bin_version}->{signer} = $major.'.'.$minor.'.'.$patch;
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

    my $cv = Lim::Util::run_cmd [ 'ods-signerd', '-V' ],
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
                    $self->{bin_version}->{signerd} = $major.'.'.$minor.'.'.$patch;
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
    
    my $cv = Lim::Util::run_cmd [ 'ods-hsmutil', '-V' ],
        '<', '/dev/null',
        '>', \$stdout,
        '2>', \$stderr;
    if ($cv->recv) {
        $self->{logger}->warn('Unable to find "ods-hsmutil" executable, module functions limited');
    }
    else {
        if ($stdout =~ /version\s+([0-9]+)\.([0-9]+)\.([0-9]+)/o) {
            my ($major,$minor,$patch) = ($1, $2, $3);
            
            if ($major > 0 and $major < 10 and $minor > -1 and $minor < 10 and $patch > -1 and $patch < 100) {
                my $version = ($major * 1000000) + ($minor * 1000) + $patch;
                
                unless ($version >= OPENDNSSEC_VERSION_MIN and $version <= OPENDNSSEC_VERSION_MAX) {
                    $self->{logger}->warn('Unsupported "ods-hsmutil" executable version, unable to continue');
                }
                else {
                    $self->{bin}->{hsmutil} = $version;
                    $self->{bin_version}->{hsmutil} = $major.'.'.$minor.'.'.$patch;
                }
            }
            else {
                $self->{logger}->warn('Invalid "ods-hsmutil" version, module functions limited');
            }
        }
        else {
            $self->{logger}->warn('Unable to get "ods-hsmutil" version, module functions limited');
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

=head2 Destroy

=cut

sub Destroy {
}

=head2 _ScanConfig

=cut

sub _ScanConfig {
    my ($self, $not_index_fullpath) = @_;
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
            if (defined ($_ = Lim::Util::FileWritable($file))) {
                my $name = $_;
                
                if ($not_index_fullpath) {
                    $_ = $config;
                }

                if (exists $file{$_}) {
                    $file{$_}->{write} = 1;
                    next;
                }
                
                $file{$_} = {
                    name => $name,
                    write => 1,
                    read => 1
                };
            }
            elsif (defined ($_ = Lim::Util::FileReadable($file))) {
                my $name = $_;
                
                if ($not_index_fullpath) {
                    $_ = $config;
                }

                if (exists $file{$_}) {
                    next;
                }
                
                $file{$_} = {
                    name => $name,
                    write => 0,
                    read => 1
                };
            }
        }
    }
    
    return \%file;
}

=head2 ReadVersion

=cut

sub ReadVersion {
    my ($self, $cb) = @_;
    my @program;
    
    foreach my $program (keys %{$self->{bin_version}}) {
        push(@program, { name => 'ods-'.$program, version => $self->{bin_version}->{$program} });
    }

    if (scalar @program) {
        $self->Successful($cb, { version => $VERSION, program => \@program });
    }
    else {
        $self->Successful($cb, { version => $VERSION });
    }
}

=head2 ReadConfigs

=cut

sub ReadConfigs {
    my ($self, $cb) = @_;
    my $files = $self->_ScanConfig;
    
    $self->Successful($cb, {
        file => [ values %$files ]
    });
}

=head2 CreateConfig

=cut

sub CreateConfig {
    my ($self, $cb) = @_;
    
    $self->Error($cb, 'Not Implemented');
}

=head2 ReadConfig

=cut

sub ReadConfig {
    my ($self, $cb, $q) = @_;
    my $files = $self->_ScanConfig;
    my $result = {};

    foreach my $read (ref($q->{file}) eq 'ARRAY' ? @{$q->{file}} : $q->{file}) {
        if (exists $files->{$read->{name}}) {
            my $file = $files->{$read->{name}};
            
            unless ($file->{read}) {
                $self->Error($cb, Lim::Error->new(
                    code => 500,
                    message => 'File "'.$read->{name}.'" not readable'
                ));
                return;
            }
            
            my $fh = IO::File->new($file->{name});
            unless (defined $fh) {
                $self->Error($cb, Lim::Error->new(
                    code => 500,
                    message => 'Unable to open file "'.$read->{name}.'": '.$!
                ));
                return;
            }

            unless (flock($fh, LOCK_SH|LOCK_NB)) {
                $self->Error($cb, Lim::Error->new(
                    code => 400,
                    message => 'Unable to lock file "'.$read->{name}.'": '.$!
                ));
                return;
            }
            
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
            else {
                flock($fh, LOCK_UN);
                $self->Error($cb, Lim::Error->new(
                    code => 500,
                    message => 'Unable to read all content of file "'.$read->{name}
                ));
                return;
            }
            
            unless (flock($fh, LOCK_UN)) {
                $self->Error($cb, Lim::Error->new(
                    code => 500,
                    message => 'Unable to unlock file "'.$read->{name}.'": '.$!
                ));
                return;
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
    $self->Successful($cb, $result);
}

=head2 UpdateConfig

=cut

sub UpdateConfig {
    my ($self, $cb, $q) = @_;
    my $files = $self->_ScanConfig;
    my $result = {};

    foreach my $read (ref($q->{file}) eq 'ARRAY' ? @{$q->{file}} : $q->{file}) {
        if (exists $files->{$read->{name}}) {
            my $file = $files->{$read->{name}};

            unless ($file->{write}) {
                $self->Error($cb, Lim::Error->new(
                    code => 500,
                    message => 'File "'.$read->{name}.'" not writable'
                ));
                return;
            }
            
            my $tmp = Lim::Util::TempFileLikeThis($file->{name});
            unless (defined $tmp) {
                $self->Error($cb, Lim::Error->new(
                    code => 500,
                    message => 'Unable to create temporary file: '.$!
                ));
                return;
            }
            
            my $fh = IO::File->new($file->{name});
            unless (defined $fh) {
                $self->Error($cb, Lim::Error->new(
                    code => 500,
                    message => 'Unable to open file "'.$read->{name}.'": '.$!
                ));
                return;
            }

            unless (flock($fh, LOCK_EX|LOCK_NB)) {
                $self->Error($cb, Lim::Error->new(
                    code => 400,
                    message => 'Unable to lock file "'.$read->{name}.'": '.$!
                ));
                return;
            }

            print $tmp $read->{content};
            $tmp->flush;
            $tmp->close;
            
            my $tmp_fh = IO::File->new;
            if ($tmp_fh->open($tmp->filename)) {
                my ($tell, $content);
                $tmp_fh->seek(0, SEEK_END);
                $tell = $tmp_fh->tell;
                $tmp_fh->seek(0, SEEK_SET);
                unless ($tmp_fh->read($content, $tell) == $tell) {
                    flock($fh, LOCK_UN);
                    $self->Error($cb, Lim::Error->new(
                        code => 500,
                        message => 'Failed to write "'.$read->{name}.'" to temporary file'
                    ));
                    return;
                }
                unless (Digest::SHA::sha1_base64($read->{content}) eq Digest::SHA::sha1_base64($content)) {
                    flock($fh, LOCK_UN);
                    $self->Error($cb, Lim::Error->new(
                        code => 500,
                        message => 'Checksum missmatch on "'.$read->{name}.'" after writing to temporary file'
                    ));
                    return;
                }
                unless (rename($tmp->filename, $file->{name})) {
                    flock($fh, LOCK_UN);
                    $self->Error($cb, Lim::Error->new(
                        code => 500,
                        message => 'Failed to rename "'.$read->{name}.'"'
                    ));
                    return;
                }
            }
            else {
                flock($fh, LOCK_UN);
                $self->Error($cb, Lim::Error->new(
                    code => 500,
                    message => 'Unable to open temporary file: '.$!
                ));
                return;
            }
            
            unless (flock($fh, LOCK_UN)) {
                $self->Error($cb, Lim::Error->new(
                    code => 500,
                    message => 'Unable to unlock file "'.$read->{name}.'": '.$!
                ));
                return;
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
    $self->Successful($cb);
}

=head2 DeleteConfig

=cut

sub DeleteConfig {
    my ($self, $cb) = @_;
    
    $self->Error($cb, 'Not Implemented');
}

=head2 __XMLAttr

=cut

sub __XMLAttr {
    my ($self, $node, $name) = @_;
    
    my $attributes = $node->attributes;
    unless (blessed $attributes and $attributes->isa('XML::LibXML::NamedNodeMap')) {
        die 'XML::LibXML::Node->attributes did not return a XML::LibXML::NamedNodeMap';
    }
    
    my $attr = $attributes->getNamedItem($name);
    unless (defined $attr) {
        die 'Missing attribute '.$name.' on '.$node->nodeName.' element';
    }
    unless (blessed $attr and $attr->isa('XML::LibXML::Attr')) {
        die 'XML::LibXML::NamedNodeMap->getNamedItem did not return a XML::LibXML::Attr';
    }
    unless ($attr->value) {
        die 'No value in attribute '.$name.' on '.$node->nodeName.' element';
    }
    
    return $attr->value;
}

=head2 __XMLEleAttrReq

=cut

sub __XMLEleAttrReq {
    my ($self, $node, $name, $attrName) = @_;
    
    my ($ele) = $node->findnodes($name);
    unless (defined $ele) {
        die 'Missing '.$name.' in '.$node->nodeName;
    }
    unless (blessed $ele and $ele->isa('XML::LibXML::Node')) {
        die 'Invalid class returned for '.$name.' by XML::LibXML::Node->find in '.$node->nodeName;
    }

    my $attributes = $ele->attributes;
    unless (blessed $attributes and $attributes->isa('XML::LibXML::NamedNodeMap')) {
        die 'XML::LibXML::Node->attributes did not return a XML::LibXML::NamedNodeMap';
    }
    
    my $attr = $attributes->getNamedItem($attrName);
    unless (defined $attr) {
        die 'Missing attribute '.$attrName.' on '.$node->nodeName.' element';
    }
    unless (blessed $attr and $attr->isa('XML::LibXML::Attr')) {
        die 'XML::LibXML::NamedNodeMap->getNamedItem did not return a XML::LibXML::Attr';
    }
    unless ($attr->value) {
        die 'No value in attribute '.$attrName.' on '.$node->nodeName.' element';
    }
    
    return $attr->value;
}

=head2 __XMLEleAttr

=cut

sub __XMLEleAttr {
    my ($self, $node, $name, $attrName) = @_;
    
    my ($ele) = $node->findnodes($name);
    unless (defined $ele) {
        die 'Missing '.$name.' in '.$node->nodeName;
    }
    unless (blessed $ele and $ele->isa('XML::LibXML::Node')) {
        die 'Invalid class returned for '.$name.' by XML::LibXML::Node->find in '.$node->nodeName;
    }

    my $attributes = $ele->attributes;
    unless (blessed $attributes and $attributes->isa('XML::LibXML::NamedNodeMap')) {
        die 'XML::LibXML::Node->attributes did not return a XML::LibXML::NamedNodeMap';
    }
    
    my $attr = $attributes->getNamedItem($attrName);
    unless (defined $attr) {
        return;
    }
    unless (blessed $attr and $attr->isa('XML::LibXML::Attr')) {
        die 'XML::LibXML::NamedNodeMap->getNamedItem did not return a XML::LibXML::Attr';
    }
    unless ($attr->value) {
        die 'No value in attribute '.$attrName.' on '.$node->nodeName.' element';
    }
    
    return $attr->value;
}

=head2 __XMLEleReq

=cut

sub __XMLEleReq {
    my ($self, $node, $name) = @_;
    
    my ($ele) = $node->findnodes($name);
    unless (defined $ele) {
        die 'Missing '.$name.' in '.$node->nodeName;
    }
    unless (blessed $ele and $ele->isa('XML::LibXML::Node')) {
        die 'Invalid class returned for '.$name.' by XML::LibXML::Node->find in '.$node->nodeName;
    }
    unless ($ele->textContent) {
        die 'No value for '.$name.' in '.$node->nodeName;
    }

    return $ele->textContent;
}

=head2 __XMLEle

=cut

sub __XMLEle {
    my ($self, $node, $name) = @_;
    
    my ($ele) = $node->findnodes($name);
    if (defined $ele) {
        unless (blessed $ele and $ele->isa('XML::LibXML::Node')) {
            die 'Invalid class returned for '.$name.' by XML::LibXML::Node->find in '.$node->nodeName;
        }
        unless ($ele->textContent) {
            die 'No value for '.$name.' in '.$node->nodeName;
        }
        
        return $ele->textContent;
    }
    
    return;
}

=head2 __XMLEleEmpty

=cut

sub __XMLEleEmpty {
    my ($self, $node, $name) = @_;
    
    my ($ele) = $node->findnodes($name);
    if (defined $ele) {
        unless (blessed $ele and $ele->isa('XML::LibXML::Node')) {
            die 'Invalid class returned for '.$name.' by XML::LibXML::Node->find in '.$node->nodeName;
        }
        
        return $ele->textContent;
    }
    
    return;
}

=head2 __XMLBoolEle

=cut

sub __XMLBoolEle {
    my ($self, $node, $name) = @_;
    
    my ($ele) = $node->findnodes($name);
    if (defined $ele) {
        unless (blessed $ele and $ele->isa('XML::LibXML::Node')) {
            die 'Invalid class returned for '.$name.' by XML::LibXML::Node->find in '.$node->nodeName;
        }
        
        return 1;
    }
    
    return 0;
}

=head2 _RepositoryJSON2XML

=cut

sub _RepositoryJSON2XML {
    my ($self, $repository) = @_;
    
    unless (ref($repository) eq 'HASH') {
        die 'Repository given is not a HASH';
    }
    
    my $node = XML::LibXML::Element->new('Repository');
    $node->setAttribute('name', $repository->{name});

    $node->appendTextChild('Module', $repository->{module});
    $node->appendTextChild('TokenLabel', $repository->{token_label});
    $node->appendTextChild('PIN', $repository->{pin});

    if (defined $repository->{capacity}) {
        $node->appendTextChild('Capacity', $repository->{capacity});
    }
    if (exists $repository->{require_backup}) {
        $node->appendChild(XML::LibXML::Element->new('RequireBackup'));
    }
    if (exists $repository->{skip_public_key}) {
        $node->appendChild(XML::LibXML::Element->new('SkipPublicKey'));
    }
    
    return $node;
}

=head2 _RepositoryXML2JSON

=cut

sub _RepositoryXML2JSON {
    my ($self, $node) = @_;
    
    unless (blessed $node and $node->isa('XML::LibXML::Node')) {
        die 'Node given is not an XML::LibXML::Node class';
    }

    my $name = $self->__XMLAttr($node, 'name');

    my ($module, $token_label, $pin, $capacity, $require_backup, $skip_public_key);
    eval {
        $module = $self->__XMLEleReq($node, 'Module');
        $token_label = $self->__XMLEleReq($node, 'TokenLabel');
        $pin = $self->__XMLEleReq($node, 'PIN');
        $capacity = $self->__XMLEle($node, 'Capacity');
        $require_backup = $self->__XMLBoolEle($node, 'RequireBackup');
        $skip_public_key = $self->__XMLBoolEle($node, 'SkipPublicKey');
    };
    if ($@) {
        die 'Error in Repository '.$name.': '.$@;
    }
    
    return {
        name => $name,
        module => $module,
        token_label => $token_label,
        pin => $pin,
        (defined $capacity ? (capacity => $capacity) : ()),
        ($require_backup ? (require_backup => 1) : ()),
        ($skip_public_key ? (skip_public_key => 1) : ())
    };
}

=head2 _RepositoryNameXML

=cut

sub _RepositoryNameXML {
    my ($self, $node) = @_;
    
    unless (blessed $node and $node->isa('XML::LibXML::Node')) {
        die 'Node given is not an XML::LibXML::Node class';
    }

    return $self->__XMLAttr($node, 'name');
}

=head2 ReadRepositories

=cut

sub ReadRepositories {
    my ($self, $cb) = @_;
    my $files = $self->_ScanConfig(1);

    unless (exists $files->{'conf.xml'}) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'No conf.xml configuration file exists'
        ));
        return;
    }
    
    unless ($files->{'conf.xml'}->{read}) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'The conf.xml configuration file is not readable'
        ));
        return;
    }

    my $fh = IO::File->new($files->{'conf.xml'}->{name});
    unless (defined $fh) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to open conf.xml: '.$!
        ));
        return;
    }

    unless (flock($fh, LOCK_SH|LOCK_NB)) {
        $self->Error($cb, Lim::Error->new(
            code => 400,
            message => 'Unable to lock conf.xml: '.$!
        ));
        return;
    }

    my $dom;
    eval {
        $dom = XML::LibXML->load_xml(IO => $fh);
    };
    if ($@) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to load XML file: '.$@
        ));
        return;
    }
    
    my @repositories;
    eval {
        foreach my $node ($dom->findnodes('/Configuration/RepositoryList/Repository')) {
            push(@repositories, $self->_RepositoryXML2JSON($node));
        }
    };
    if ($@) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'XML Error: '.$@
        ));
        return;
    }

    $dom = undef;
    unless (flock($fh, LOCK_UN)) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to unlock conf.xml: '.$!
        ));
        return;
    }

    if (scalar @repositories == 1) {
        $self->Successful($cb, { repository => $repositories[0] });
    }
    elsif (scalar @repositories) {
        $self->Successful($cb, { repository => \@repositories });
    }
    else {
        $self->Successful($cb);
    }
}

=head2 CreateRepository

=cut

sub CreateRepository {
    my ($self, $cb, $q) = @_;
    my $files = $self->_ScanConfig(1);

    unless (exists $files->{'conf.xml'}) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'No conf.xml configuration file exists'
        ));
        return;
    }
    
    unless ($files->{'conf.xml'}->{write}) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'The conf.xml configuration file is not writable'
        ));
        return;
    }

    my $fh = IO::File->new($files->{'conf.xml'}->{name}, 'r+');
    unless (defined $fh) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to open conf.xml: '.$!
        ));
        return;
    }

    unless (flock($fh, LOCK_EX|LOCK_NB)) {
        $self->Error($cb, Lim::Error->new(
            code => 400,
            message => 'Unable to lock conf.xml: '.$!
        ));
        return;
    }

    my $dom;
    eval {
        $dom = XML::LibXML->load_xml(IO => $fh);
    };
    if ($@) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to load XML file: '.$@
        ));
        return;
    }
    
    my %repository;
    eval {
        foreach my $node ($dom->findnodes('/Configuration/RepositoryList/Repository')) {
            $repository{$self->_RepositoryNameXML($node)} = 1;
        }
    };
    if ($@) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'XML Error: '.$@
        ));
        return;
    }

    my ($repository_list) = $dom->findnodes('/Configuration/RepositoryList');
    unless (defined $repository_list) {
        my ($configuration) = $dom->findnodes('/Configuration');
        
        unless (defined $configuration) {
            flock($fh, LOCK_UN);
            $self->Error($cb, Lim::Error->new(
                code => 500,
                message => 'Unable to find Configuration element within XML'
            ));
            return;
        }
        
        $configuration->appendChild(($repository_list = XML::LibXML::Element->new('RepositoryList')));
    }
    unless (blessed $repository_list and $repository_list->isa('XML::LibXML::Node')) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to find or create RepositoryList element within XML'
        ));
        return;
    }

    foreach my $repository (ref($q->{repository}) eq 'ARRAY' ? @{$q->{repository}} : $q->{repository}) {
        if (exists $repository{$repository->{name}}) {
            flock($fh, LOCK_UN);
            $self->Error($cb, Lim::Error->new(
                code => 500,
                message => 'Repository '.$repository->{name}.' already exists'
            ));
            return;
        }
        
        eval {
            $repository_list->addChild($self->_RepositoryJSON2XML($repository));
        };
        if ($@) {
            flock($fh, LOCK_UN);
            $self->Error($cb, Lim::Error->new(
                code => 500,
                message => 'Unable to add repository '.$repository->{name}.' to XML: '.$@
            ));
            return;
        }
    }

    my $tmp = Lim::Util::TempFile;
    unless (defined $tmp and chmod(0600, $tmp->filename)) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to create temporary file: '.$!
        ));
        return;
    }
    $fh->seek(0, SEEK_SET);
    while ($fh->sysread(my $buf, 32*1024)) {
        unless ($tmp->syswrite($buf) == length($buf)) {
            flock($fh, LOCK_UN);
            $self->Error($cb, Lim::Error->new(
                code => 500,
                message => 'Unable to create backup copy of conf.xml: '.$!
            ));
            return;
        }
    }
    $tmp->flush;

    my $fh_sha = Digest::SHA->new(512);
    $fh->seek(0, SEEK_SET);
    $fh_sha->addfile($fh);

    my $tmp_sha = Digest::SHA->new(512);
    $tmp->seek(0, SEEK_SET);
    $tmp_sha->addfile($tmp);
    
    unless ($fh_sha->b64digest eq $tmp_sha->b64digest) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Verification of backup file failed, checksums does not match!'
        ));
        return;
    }
    
    $fh->seek(0, SEEK_SET);
    unless ($dom->toFH($fh)) {
        $fh->seek(0, SEEK_SET);
        $tmp->seek(0, SEEK_SET);
        
        my $wrote = 0;
        while ((my $read = $tmp->sysread(my $buf, 32*1024))) {
            $wrote += $read;
            unless ($fh->syswrite($buf) == length($buf)) {
                flock($fh, LOCK_UN);
                $tmp->unlink_on_destroy(0);
                $self->Error($cb, Lim::Error->new(
                    code => 500,
                    message => 'Failure when writing new conf.xml and unable to restore backup conf.xml, kept backup in '.$tmp->filename.': '.$!
                ));
                return;
            }
        }
        $fh->flush;
        $fh->truncate($wrote);
        flock($fh, LOCK_UN);
        $fh->close;

        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Failure when writing new conf.xml: '.$!
        ));
        return;
    }
    $fh->flush;

    $dom = undef;
    unless (flock($fh, LOCK_UN)) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to unlock conf.xml: '.$!
        ));
        return;
    }

    $self->Successful($cb);
}

=head2 ReadRepository

=cut

sub ReadRepository {
    my ($self, $cb, $q) = @_;
    my $files = $self->_ScanConfig(1);

    unless (exists $files->{'conf.xml'}) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'No conf.xml configuration file exists'
        ));
        return;
    }
    
    unless ($files->{'conf.xml'}->{read}) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'The conf.xml configuration file is not readable'
        ));
        return;
    }
    
    my $fh = IO::File->new($files->{'conf.xml'}->{name});
    unless (defined $fh) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to open conf.xml: '.$!
        ));
        return;
    }

    unless (flock($fh, LOCK_SH|LOCK_NB)) {
        $self->Error($cb, Lim::Error->new(
            code => 400,
            message => 'Unable to lock conf.xml: '.$!
        ));
        return;
    }

    my $dom;
    eval {
        $dom = XML::LibXML->load_xml(IO => $fh);
    };
    if ($@) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to load XML file: '.$@
        ));
        return;
    }
    
    my %repository;
    eval {
        foreach my $node ($dom->findnodes('/Configuration/RepositoryList/Repository')) {
            $_ = $self->_RepositoryXML2JSON($node);
            $repository{$_->{name}} = $_;
        }
    };
    if ($@) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'XML Error: '.$@
        ));
        return;
    }

    my @repositories;
    foreach my $repository (ref($q->{repository}) eq 'ARRAY' ? @{$q->{repository}} : $q->{repository}) {
        if (exists $repository{$repository->{name}}) {
            push(@repositories, $repository{$repository->{name}});
        }
    }

    $dom = undef;
    unless (flock($fh, LOCK_UN)) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to unlock conf.xml: '.$!
        ));
        return;
    }

    if (scalar @repositories == 1) {
        $self->Successful($cb, { repository => $repositories[0] });
    }
    elsif (scalar @repositories) {
        $self->Successful($cb, { repository => \@repositories });
    }
    else {
        $self->Successful($cb);
    }
}

=head2 UpdateRepository

=cut

sub UpdateRepository {
    my ($self, $cb, $q) = @_;
    my $files = $self->_ScanConfig(1);

    unless (exists $files->{'conf.xml'}) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'No conf.xml configuration file exists'
        ));
        return;
    }
    
    unless ($files->{'conf.xml'}->{write}) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'The conf.xml configuration file is not writable'
        ));
        return;
    }

    my $fh = IO::File->new($files->{'conf.xml'}->{name}, 'r+');
    unless (defined $fh) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to open conf.xml: '.$!
        ));
        return;
    }

    unless (flock($fh, LOCK_EX|LOCK_NB)) {
        $self->Error($cb, Lim::Error->new(
            code => 400,
            message => 'Unable to lock conf.xml: '.$!
        ));
        return;
    }

    my $dom;
    eval {
        $dom = XML::LibXML->load_xml(IO => $fh);
    };
    if ($@) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to load XML file: '.$@
        ));
        return;
    }
    
    my %repository;
    eval {
        foreach my $node ($dom->findnodes('/Configuration/RepositoryList/Repository')) {
            $repository{$self->_RepositoryNameXML($node)} = $node;
        }
    };
    if ($@) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'XML Error: '.$@
        ));
        return;
    }

    my ($repository_list) = $dom->findnodes('/Configuration/RepositoryList');
    unless (defined $repository_list) {
        my ($configuration) = $dom->findnodes('/Configuration');
        
        unless (defined $configuration) {
            flock($fh, LOCK_UN);
            $self->Error($cb, Lim::Error->new(
                code => 500,
                message => 'Unable to find Configuration element within XML'
            ));
            return;
        }
        
        $configuration->appendChild(($repository_list = XML::LibXML::Element->new('RepositoryList')));
    }
    unless (blessed $repository_list and $repository_list->isa('XML::LibXML::Node')) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to find or create RepositoryList element within XML'
        ));
        return;
    }

    foreach my $repository (ref($q->{repository}) eq 'ARRAY' ? @{$q->{repository}} : $q->{repository}) {
        unless (exists $repository{$repository->{name}}) {
            flock($fh, LOCK_UN);
            $self->Error($cb, Lim::Error->new(
                code => 500,
                message => 'Repository '.$repository->{name}.' does not exists'
            ));
            return;
        }
        
        eval {
            $repository_list->removeChild($repository{$repository->{name}});
            $repository_list->addChild($self->_RepositoryJSON2XML($repository));
        };
        if ($@) {
            flock($fh, LOCK_UN);
            $self->Error($cb, Lim::Error->new(
                code => 500,
                message => 'Unable to update repository '.$repository->{name}.' to XML: '.$@
            ));
            return;
        }
    }

    my $tmp = Lim::Util::TempFile;
    unless (defined $tmp and chmod(0600, $tmp->filename)) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to create temporary file: '.$!
        ));
        return;
    }
    $fh->seek(0, SEEK_SET);
    while ($fh->sysread(my $buf, 32*1024)) {
        unless ($tmp->syswrite($buf) == length($buf)) {
            flock($fh, LOCK_UN);
            $self->Error($cb, Lim::Error->new(
                code => 500,
                message => 'Unable to create backup copy of conf.xml: '.$!
            ));
            return;
        }
    }
    $tmp->flush;

    my $fh_sha = Digest::SHA->new(512);
    $fh->seek(0, SEEK_SET);
    $fh_sha->addfile($fh);

    my $tmp_sha = Digest::SHA->new(512);
    $tmp->seek(0, SEEK_SET);
    $tmp_sha->addfile($tmp);
    
    unless ($fh_sha->b64digest eq $tmp_sha->b64digest) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Verification of backup file failed, checksums does not match!'
        ));
        return;
    }
    
    $fh->seek(0, SEEK_SET);
    unless ($dom->toFH($fh)) {
        $fh->seek(0, SEEK_SET);
        $tmp->seek(0, SEEK_SET);
        
        my $wrote = 0;
        while ((my $read = $tmp->sysread(my $buf, 32*1024))) {
            $wrote += $read;
            unless ($fh->syswrite($buf) == length($buf)) {
                flock($fh, LOCK_UN);
                $tmp->unlink_on_destroy(0);
                $self->Error($cb, Lim::Error->new(
                    code => 500,
                    message => 'Failure when writing new conf.xml and unable to restore backup conf.xml, kept backup in '.$tmp->filename.': '.$!
                ));
                return;
            }
        }
        $fh->flush;
        $fh->truncate($wrote);
        flock($fh, LOCK_UN);
        $fh->close;

        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Failure when writing new conf.xml: '.$!
        ));
        return;
    }
    $fh->flush;

    $dom = undef;
    unless (flock($fh, LOCK_UN)) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to unlock conf.xml: '.$!
        ));
        return;
    }

    $self->Successful($cb);
}

=head2 DeleteRepository

=cut

sub DeleteRepository {
    my ($self, $cb, $q) = @_;
    my $files = $self->_ScanConfig(1);

    unless (exists $files->{'conf.xml'}) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'No conf.xml configuration file exists'
        ));
        return;
    }
    
    unless ($files->{'conf.xml'}->{write}) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'The conf.xml configuration file is not writable'
        ));
        return;
    }

    my $fh = IO::File->new($files->{'conf.xml'}->{name}, 'r+');
    unless (defined $fh) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to open conf.xml: '.$!
        ));
        return;
    }

    unless (flock($fh, LOCK_EX|LOCK_NB)) {
        $self->Error($cb, Lim::Error->new(
            code => 400,
            message => 'Unable to lock conf.xml: '.$!
        ));
        return;
    }

    my $dom;
    eval {
        $dom = XML::LibXML->load_xml(IO => $fh);
    };
    if ($@) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to load XML file: '.$@
        ));
        return;
    }
    
    my %repository;
    eval {
        foreach my $node ($dom->findnodes('/Configuration/RepositoryList/Repository')) {
            $repository{$self->_RepositoryNameXML($node)} = $node;
        }
    };
    if ($@) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'XML Error: '.$@
        ));
        return;
    }

    my ($repository_list) = $dom->findnodes('/Configuration/RepositoryList');
    unless (defined $repository_list) {
        my ($configuration) = $dom->findnodes('/Configuration');
        
        unless (defined $configuration) {
            flock($fh, LOCK_UN);
            $self->Error($cb, Lim::Error->new(
                code => 500,
                message => 'Unable to find Configuration element within XML'
            ));
            return;
        }
        
        $configuration->appendChild(($repository_list = XML::LibXML::Element->new('RepositoryList')));
    }
    unless (blessed $repository_list and $repository_list->isa('XML::LibXML::Node')) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to find or create RepositoryList element within XML'
        ));
        return;
    }

    foreach my $repository (ref($q->{repository}) eq 'ARRAY' ? @{$q->{repository}} : $q->{repository}) {
        unless (exists $repository{$repository->{name}}) {
            flock($fh, LOCK_UN);
            $self->Error($cb, Lim::Error->new(
                code => 500,
                message => 'Repository '.$repository->{name}.' does not exists'
            ));
            return;
        }
        
        eval {
            $repository_list->removeChild($repository{$repository->{name}});
        };
        if ($@) {
            flock($fh, LOCK_UN);
            $self->Error($cb, Lim::Error->new(
                code => 500,
                message => 'Unable to remove repository '.$repository->{name}.' to XML: '.$@
            ));
            return;
        }
    }

    my $tmp = Lim::Util::TempFile;
    unless (defined $tmp and chmod(0600, $tmp->filename)) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to create temporary file: '.$!
        ));
        return;
    }
    $fh->seek(0, SEEK_SET);
    while ($fh->sysread(my $buf, 32*1024)) {
        unless ($tmp->syswrite($buf) == length($buf)) {
            flock($fh, LOCK_UN);
            $self->Error($cb, Lim::Error->new(
                code => 500,
                message => 'Unable to create backup copy of conf.xml: '.$!
            ));
            return;
        }
    }
    $tmp->flush;

    my $fh_sha = Digest::SHA->new(512);
    $fh->seek(0, SEEK_SET);
    $fh_sha->addfile($fh);

    my $tmp_sha = Digest::SHA->new(512);
    $tmp->seek(0, SEEK_SET);
    $tmp_sha->addfile($tmp);
    
    unless ($fh_sha->b64digest eq $tmp_sha->b64digest) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Verification of backup file failed, checksums does not match!'
        ));
        return;
    }
    
    $fh->seek(0, SEEK_SET);
    unless ($dom->toFH($fh)) {
        $fh->seek(0, SEEK_SET);
        $tmp->seek(0, SEEK_SET);
        
        my $wrote = 0;
        while ((my $read = $tmp->sysread(my $buf, 32*1024))) {
            $wrote += $read;
            unless ($fh->syswrite($buf) == length($buf)) {
                flock($fh, LOCK_UN);
                $tmp->unlink_on_destroy(0);
                $self->Error($cb, Lim::Error->new(
                    code => 500,
                    message => 'Failure when writing new conf.xml and unable to restore backup conf.xml, kept backup in '.$tmp->filename.': '.$!
                ));
                return;
            }
        }
        $fh->flush;
        $fh->truncate($wrote);
        flock($fh, LOCK_UN);
        $fh->close;

        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Failure when writing new conf.xml: '.$!
        ));
        return;
    }
    $fh->flush;

    $dom = undef;
    unless (flock($fh, LOCK_UN)) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to unlock conf.xml: '.$!
        ));
        return;
    }

    $self->Successful($cb);
}

=head2 _PolicyJSON2XML

=cut

sub _PolicyJSON2XML {
    my ($self, $policy) = @_;
    
    unless (ref($policy) eq 'HASH') {
        die 'Policy given is not a HASH';
    }
    
    my $node = XML::LibXML::Element->new('Policy');
    $node->setAttribute('name', $policy->{name});
    $node->appendTextChild('Description', $policy->{description});
    
    my $signatures = XML::LibXML::Element->new('Signatures');
    $signatures->appendTextChild('Resign', $policy->{signatures}->{resign});
    $signatures->appendTextChild('Refresh', $policy->{signatures}->{refresh});
    my $signatures_validity = XML::LibXML::Element->new('Validity');
    $signatures->appendTextChild('Default', $policy->{signatures}->{validity}->{default});
    $signatures->appendTextChild('Denial', $policy->{signatures}->{validity}->{denial});
    $signatures->appendChild($signatures_validity);
    $signatures->appendTextChild('Jitter', $policy->{signatures}->{jitter});
    $signatures->appendTextChild('InceptionOffset', $policy->{signatures}->{inception_offset});
    $node->appendChild($signatures);
    
    my $denial = XML::LibXML::Element->new('Denial');
    if (exists $policy->{nsec}) {
        $denial->appendChild(XML::LibXML::Element->new('NSEC'));
    }
    if (exists $policy->{nsec3}) {
        my $nsec3 = XML::LibXML::Element->new('NSEC3');
        if (exists $policy->{denial}->{nsec3}->{opt_out}) {
            $nsec3->appendChild(XML::LibXML::Element->new('OptOut'));
        }
        $nsec3->appendTextChild('Resalt', $policy->{denial}->{nsec3}->{resalt});
        my $hash = XML::LibXML::Element->new('Hash');
        $hash->appendTextChild('Algorithm', $policy->{denial}->{nsec3}->{hash}->{algorithm});
        $hash->appendTextChild('Iterations', $policy->{denial}->{nsec3}->{hash}->{iterations});
        my $salt = XML::LibXML::Element->new('Salt');
        $salt->setAttribute('length', $policy->{denial}->{nsec3}->{hash}->{length});
        if (exists $policy->{denial}->{nsec3}->{hash}->{value}) {
            $salt->appendText($policy->{denial}->{nsec3}->{hash}->{value});
        }
        $hash->appendChild($salt);
        $nsec3->appendChild($hash);
        $denial->appendChild($nsec3);
    }
    $node->appendChild($denial);

    my $keys = XML::LibXML::Element->new('Keys');
    $keys->appendTextChild('TTL', $policy->{keys}->{ttl});
    $keys->appendTextChild('RetireSafety', $policy->{keys}->{retire_safety});
    $keys->appendTextChild('PublishSafety', $policy->{keys}->{publish_safety});
    if (exists $policy->{keys}->{share_keys}) {
        $keys->appendChild(XML::LibXML::Element->new('ShareKeys'));
    }
    if (exists $policy->{keys}->{purge}) {
        $keys->appendTextChild('Purge', $policy->{keys}->{purge});
    }
    my $ksk = XML::LibXML::Element->new('KSK');
    my $ksk_algorithm = XML::LibXML::Element->new('Algorithm');
    if (exists $policy->{keys}->{ksk}->{algorithm}->{length}) {
        $ksk_algorithm->setAttribute('length', $policy->{keys}->{ksk}->{algorithm}->{length});
    }
    $ksk_algorithm->appendText($policy->{keys}->{ksk}->{algorithm}->{value});
    $ksk->appendChild($ksk_algorithm);
    $ksk->appendTextChild('Lifetime', $policy->{keys}->{ksk}->{lifetime});
    $ksk->appendTextChild('Repository', $policy->{keys}->{ksk}->{repository});
    if (exists $policy->{keys}->{ksk}->{standby}) {
        $ksk->appendChild(XML::LibXML::Element->new('Standby'));
    }
    if (exists $policy->{keys}->{ksk}->{manual_rollover}) {
        $ksk->appendChild(XML::LibXML::Element->new('ManualRollover'));
    }
    if (exists $policy->{keys}->{ksk}->{RFC5011}) {
        $ksk->appendChild(XML::LibXML::Element->new('RFC5011'));
    }
    $keys->appendChild($ksk);
    my $zsk = XML::LibXML::Element->new('KSK');
    my $zsk_algorithm = XML::LibXML::Element->new('Algorithm');
    if (exists $policy->{keys}->{zsk}->{algorithm}->{length}) {
        $zsk_algorithm->setAttribute('length', $policy->{keys}->{zsk}->{algorithm}->{length});
    }
    $zsk_algorithm->appendText($policy->{keys}->{zsk}->{algorithm}->{value});
    $zsk->appendChild($zsk_algorithm);
    $zsk->appendTextChild('Lifetime', $policy->{keys}->{zsk}->{lifetime});
    $zsk->appendTextChild('Repository', $policy->{keys}->{zsk}->{repository});
    if (exists $policy->{keys}->{zsk}->{standby}) {
        $zsk->appendChild(XML::LibXML::Element->new('Standby'));
    }
    if (exists $policy->{keys}->{zsk}->{manual_rollover}) {
        $zsk->appendChild(XML::LibXML::Element->new('ManualRollover'));
    }
    $keys->appendChild($zsk);
    $node->appendChild($keys);

    my $zone = XML::LibXML::Element->new('Zone');
    $zone->appendTextChild('PropagationDelay', $policy->{zone}->{propagation_delay});
    my $zone_soa = XML::LibXML::Element->new('SOA');
    $zone_soa->appendTextChild('TTL', $policy->{zone}->{soa}->{ttl});
    $zone_soa->appendTextChild('Minimum', $policy->{zone}->{soa}->{minimum});
    $zone_soa->appendTextChild('Serial', $policy->{zone}->{soa}->{serial});
    $zone->appendChild($zone_soa);
    $node->appendChild($zone);

    my $parent = XML::LibXML::Element->new('Parent');
    $parent->appendTextChild('PropagationDelay', $policy->{parent}->{propagation_delay});
    my $parent_ds = XML::LibXML::Element->new('DS');
    $parent_ds->appendTextChild('TTL', $policy->{parent}->{ds}->{ttl});
    $parent->appendChild($parent_ds);
    my $parent_soa = XML::LibXML::Element->new('SOA');
    $parent_soa->appendTextChild('TTL', $policy->{parent}->{soa}->{ttl});
    $parent_soa->appendTextChild('Minimum', $policy->{parent}->{soa}->{minimum});
    $parent->appendChild($parent_soa);
    $node->appendChild($parent);
    
    if (exists $policy->{audit} and $policy->{audit}->{active}) {
        my $audit = XML::LibXML::Element->new('Audit');
        if (exists $policy->{audit}->{partial}) {
            $audit->appendChild(XML::LibXML::Element->new('Partial'));
        }
        $node->appendChild($audit);
    }
    
    return $node;
}

=head2 _PolicyXML2JSON

=cut

sub _PolicyXML2JSON {
    my ($self, $node) = @_;
    
    unless (blessed $node and $node->isa('XML::LibXML::Node')) {
        die 'Node given is not an XML::LibXML::Node class';
    }

    my $name = $self->__XMLAttr($node, 'name');
    my $description = $self->__XMLEleReq($node, 'Description');

    my $signatures;
    {
        my ($resign, $refresh, $default, $denial, $jitter, $inception_offset);
        eval {
            $resign = $self->__XMLEleReq($node, 'Signatures/Resign');
            $refresh = $self->__XMLEleReq($node, 'Signatures/Refresh');
            $default = $self->__XMLEleReq($node, 'Signatures/Validity/Default');
            $denial = $self->__XMLEleReq($node, 'Signatures/Validity/Denial');
            $jitter = $self->__XMLEleReq($node, 'Signatures/Jitter');
            $inception_offset = $self->__XMLEleReq($node, 'Signatures/InceptionOffset');
        };
        if ($@) {
            die 'Error in Policy '.$name.' Signatures: '.$@;
        }
        $signatures = {
            resign => $resign,
            refresh => $refresh,
            validity => {
                default => $default,
                denial => $denial
            },
            jitter => $jitter,
            inception_offset => $inception_offset
        };
    }
    
    my $denial;
    {
        my ($nsec, $nsec3, $opt_out, $resalt, $algorithm, $iterations, $length, $value);
        eval {
            $nsec = $self->__XMLBoolEle($node, 'Denial/NSEC');
            $nsec3 = $self->__XMLBoolEle($node, 'Denial/NSEC3');
            
            if ($nsec3) {
                $opt_out = $self->__XMLBoolEle($node, 'Denial/NSEC3/OptOut');
                $resalt = $self->__XMLEleReq($node, 'Denial/NSEC3/Resalt');
                $algorithm = $self->__XMLEleReq($node, 'Denial/NSEC3/Hash/Algorithm');
                $iterations = $self->__XMLEleReq($node, 'Denial/NSEC3/Hash/Iterations');
                $length = $self->__XMLEleAttrReq($node, 'Denial/NSEC3/Hash/Salt', 'length');
                $value = $self->__XMLEleEmpty($node, 'Denial/NSEC3/Hash/Salt');
            }
        };
        if ($@) {
            die 'Error in Policy '.$name.' Denial: '.$@;
        }
        $denial = {
            ($nsec ? (nsec => 1) : ()),
            ($nsec3 ? (nsec3 => {
                ($opt_out ? (opt_out => 1) : ()),
                resalt => $resalt,
                hash => {
                    algorithm => $algorithm,
                    iterations => $iterations,
                    salt => {
                        length => $length,
                        ($value ? (value => $value) : ())
                    }
                }
            }) : ())
        };
    }

    my $keys;
    {
        my ($ttl, $retire_safety, $publish_safety, $share_keys, $purge,
            $klength, $kvalue, $klifetime, $krepository, $kstandby, $kmanual_rollover, $kRFC5011,
            $zlength, $zvalue, $zlifetime, $zrepository, $zstandby, $zmanual_rollover);
        eval {
            $ttl = $self->__XMLEleReq($node, 'Keys/TTL');
            $retire_safety = $self->__XMLEleReq($node, 'Keys/RetireSafety');
            $publish_safety = $self->__XMLEleReq($node, 'Keys/PublishSafety');
            $share_keys = $self->__XMLBoolEle($node, 'Keys/ShareKeys');
            $purge = $self->__XMLEle($node, 'Keys/Purge');
            
            $klength = $self->__XMLEleAttr($node, 'Keys/KSK/Algorithm', 'length');
            $kvalue = $self->__XMLEleReq($node, 'Keys/KSK/Algorithm');
            $klifetime = $self->__XMLEleReq($node, 'Keys/KSK/Lifetime');
            $krepository = $self->__XMLEleReq($node, 'Keys/KSK/Repository');
            $kstandby = $self->__XMLBoolEle($node, 'Keys/KSK/Standby');
            $kmanual_rollover = $self->__XMLBoolEle($node, 'Keys/KSK/ManualRollover');
            $kRFC5011 = $self->__XMLEle($node, 'Keys/KSK/RFC5011');

            $zlength = $self->__XMLEleAttr($node, 'Keys/ZSK/Algorithm', 'length');
            $zvalue = $self->__XMLEleReq($node, 'Keys/ZSK/Algorithm');
            $zlifetime = $self->__XMLEleReq($node, 'Keys/ZSK/Lifetime');
            $zrepository = $self->__XMLEleReq($node, 'Keys/ZSK/Repository');
            $zstandby = $self->__XMLBoolEle($node, 'Keys/ZSK/Standby');
            $zmanual_rollover = $self->__XMLBoolEle($node, 'Keys/ZSK/ManualRollover');
        };
        if ($@) {
            die 'Error in Policy '.$name.' Keys: '.$@;
        }
        $keys = {
            ttl => $ttl,
            retire_safety => $retire_safety,
            publish_safety => $publish_safety,
            ($share_keys ? (share_keys => 1) : ()),
            (defined $purge ? (purge => $purge) : ()),
            ksk => {
                algorithm => {
                    (defined $klength ? (length => $klength) : ()),
                    value => $kvalue
                },
                lifetime => $klifetime,
                repository => $krepository,
                ($kstandby ? (standby => 1) : ()),
                ($kmanual_rollover ? (manual_rollover => 1) : ()),
                ($kRFC5011 ? (RFC5011 => 1) : ())
            },
            zsk => {
                algorithm => {
                    (defined $zlength ? (length => $zlength) : ()),
                    value => $zvalue
                },
                lifetime => $zlifetime,
                repository => $zrepository,
                ($zstandby ? (standby => 1) : ()),
                ($zmanual_rollover ? (manual_rollover => 1) : ())
            }
        };
    }
    
    my $zone;
    {
        my ($propagation_delay, $ttl, $minimum, $serial);
        eval {
            $propagation_delay = $self->__XMLEleReq($node, 'Zone/PropagationDelay');
            $ttl = $self->__XMLEleReq($node, 'Zone/SOA/TTL');
            $minimum = $self->__XMLEleReq($node, 'Zone/SOA/Minimum');
            $serial = $self->__XMLBoolEle($node, 'Zone/SOA/Serial');
        };
        if ($@) {
            die 'Error in Policy '.$name.' Zone: '.$@;
        }
        $zone = {
            propagation_delay => $propagation_delay,
            soa => {
                ttl => $ttl,
                minimum => $minimum,
                serial => $serial
            }
        };
    }

    my $parent;
    {
        my ($propagation_delay, $ttl, $minimum, $ds_ttl);
        eval {
            $propagation_delay = $self->__XMLEleReq($node, 'Parent/PropagationDelay');
            $ttl = $self->__XMLEleReq($node, 'Parent/SOA/TTL');
            $minimum = $self->__XMLEleReq($node, 'Parent/SOA/Minimum');
            $ds_ttl = $self->__XMLEleReq($node, 'Parent/DS/TTL');
        };
        if ($@) {
            die 'Error in Policy '.$name.' Parent: '.$@;
        }
        $parent = {
            propagation_delay => $propagation_delay,
            ds => {
                ttl => $ds_ttl,
            },
            soa => {
                ttl => $ttl,
                minimum => $minimum
            }
        };
    }

    my $audit;
    {
        my ($partial);
        eval {
            $audit = $self->__XMLBoolEle($node, 'Audit');
            $partial = $self->__XMLBoolEle($node, 'Audit/Partial');
        };
        if ($@) {
            die 'Error in Policy '.$name.' Audit: '.$@;
        }
        $audit = {
            active => $audit ? 1 : 0,
            ($partial ? (partial => 1) : ())
        };
    }

    return {
        name => $name,
        description => $description,
        signatures => $signatures,
        denial => $denial,
        keys => $keys,
        zone => $zone,
        parent => $parent,
        audit => $audit
    };
}

=head2 _PolicyNameXML

=cut

sub _PolicyNameXML {
    my ($self, $node) = @_;
    
    unless (blessed $node and $node->isa('XML::LibXML::Node')) {
        die 'Node given is not an XML::LibXML::Node class';
    }

    return $self->__XMLAttr($node, 'name');
}

=head2 ReadPolicies

=cut

sub ReadPolicies {
    my ($self, $cb) = @_;
    my $files = $self->_ScanConfig(1);

    unless (exists $files->{'kasp.xml'}) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'No kasp.xml configuration file exists'
        ));
        return;
    }
    
    unless ($files->{'kasp.xml'}->{read}) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'The kasp.xml configuration file is not readable'
        ));
        return;
    }

    my $fh = IO::File->new($files->{'kasp.xml'}->{name});
    unless (defined $fh) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to open kasp.xml: '.$!
        ));
        return;
    }

    unless (flock($fh, LOCK_SH|LOCK_NB)) {
        $self->Error($cb, Lim::Error->new(
            code => 400,
            message => 'Unable to lock kasp.xml: '.$!
        ));
        return;
    }

    my $dom;
    eval {
        $dom = XML::LibXML->load_xml(IO => $fh);
    };
    if ($@) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to load XML file: '.$@
        ));
        return;
    }
    
    my @policies;
    eval {
        foreach my $node ($dom->findnodes('/KASP/Policy')) {
            push(@policies, $self->_PolicyXML2JSON($node));
        }
    };
    if ($@) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'XML Error: '.$@
        ));
        return;
    }

    $dom = undef;
    unless (flock($fh, LOCK_UN)) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to unlock kasp.xml: '.$!
        ));
        return;
    }

    if (scalar @policies == 1) {
        $self->Successful($cb, { policy => $policies[0] });
    }
    elsif (scalar @policies) {
        $self->Successful($cb, { policy => \@policies });
    }
    else {
        $self->Successful($cb);
    }
}

=head2 CreatePolicy

=cut

sub CreatePolicy {
    my ($self, $cb, $q) = @_;
    my $files = $self->_ScanConfig(1);

    unless (exists $files->{'kasp.xml'}) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'No kasp.xml configuration file exists'
        ));
        return;
    }
    
    unless ($files->{'kasp.xml'}->{write}) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'The kasp.xml configuration file is not writable'
        ));
        return;
    }

    my $fh = IO::File->new($files->{'kasp.xml'}->{name}, 'r+');
    unless (defined $fh) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to open kasp.xml: '.$!
        ));
        return;
    }

    unless (flock($fh, LOCK_EX|LOCK_NB)) {
        $self->Error($cb, Lim::Error->new(
            code => 400,
            message => 'Unable to lock kasp.xml: '.$!
        ));
        return;
    }

    my $dom;
    eval {
        $dom = XML::LibXML->load_xml(IO => $fh);
    };
    if ($@) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to load XML file: '.$@
        ));
        return;
    }
    
    my %policy;
    eval {
        foreach my $node ($dom->findnodes('/KASP/Policy')) {
            $policy{$self->_PolicyNameXML($node)} = 1;
        }
    };
    if ($@) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'XML Error: '.$@
        ));
        return;
    }

    my ($kasp) = $dom->findnodes('/KASP');
    unless (defined $kasp) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to find KASP element within XML'
        ));
        return;
    }
    unless (blessed $kasp and $kasp->isa('XML::LibXML::Node')) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to find KASP element within XML'
        ));
        return;
    }

    foreach my $policy (ref($q->{policy}) eq 'ARRAY' ? @{$q->{policy}} : $q->{policy}) {
        if (exists $policy{$policy->{name}}) {
            flock($fh, LOCK_UN);
            $self->Error($cb, Lim::Error->new(
                code => 500,
                message => 'Policy '.$policy->{name}.' already exists'
            ));
            return;
        }
        
        eval {
            $kasp->addChild($self->_PolicyJSON2XML($policy));
        };
        if ($@) {
            flock($fh, LOCK_UN);
            $self->Error($cb, Lim::Error->new(
                code => 500,
                message => 'Unable to add policy '.$policy->{name}.' to XML: '.$@
            ));
            return;
        }
    }

    my $tmp = Lim::Util::TempFile;
    unless (defined $tmp and chmod(0600, $tmp->filename)) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to create temporary file: '.$!
        ));
        return;
    }
    $fh->seek(0, SEEK_SET);
    while ($fh->sysread(my $buf, 32*1024)) {
        unless ($tmp->syswrite($buf) == length($buf)) {
            flock($fh, LOCK_UN);
            $self->Error($cb, Lim::Error->new(
                code => 500,
                message => 'Unable to create backup copy of kasp.xml: '.$!
            ));
            return;
        }
    }
    $tmp->flush;

    my $fh_sha = Digest::SHA->new(512);
    $fh->seek(0, SEEK_SET);
    $fh_sha->addfile($fh);

    my $tmp_sha = Digest::SHA->new(512);
    $tmp->seek(0, SEEK_SET);
    $tmp_sha->addfile($tmp);
    
    unless ($fh_sha->b64digest eq $tmp_sha->b64digest) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Verification of backup file failed, checksums does not match!'
        ));
        return;
    }
    
    $fh->seek(0, SEEK_SET);
    unless ($dom->toFH($fh)) {
        $fh->seek(0, SEEK_SET);
        $tmp->seek(0, SEEK_SET);
        
        my $wrote = 0;
        while ((my $read = $tmp->sysread(my $buf, 32*1024))) {
            $wrote += $read;
            unless ($fh->syswrite($buf) == length($buf)) {
                flock($fh, LOCK_UN);
                $tmp->unlink_on_destroy(0);
                $self->Error($cb, Lim::Error->new(
                    code => 500,
                    message => 'Failure when writing new kasp.xml and unable to restore backup kasp.xml, kept backup in '.$tmp->filename.': '.$!
                ));
                return;
            }
        }
        $fh->flush;
        $fh->truncate($wrote);
        flock($fh, LOCK_UN);
        $fh->close;

        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Failure when writing new kasp.xml: '.$!
        ));
        return;
    }
    $fh->flush;

    $dom = undef;
    unless (flock($fh, LOCK_UN)) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to unlock kasp.xml: '.$!
        ));
        return;
    }

    $self->Successful($cb);
}

=head2 ReadPolicy

=cut

sub ReadPolicy {
    my ($self, $cb, $q) = @_;
    my $files = $self->_ScanConfig(1);

    unless (exists $files->{'kasp.xml'}) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'No kasp.xml configuration file exists'
        ));
        return;
    }
    
    unless ($files->{'kasp.xml'}->{read}) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'The kasp.xml configuration file is not readable'
        ));
        return;
    }
    
    my $fh = IO::File->new($files->{'kasp.xml'}->{name});
    unless (defined $fh) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to open kasp.xml: '.$!
        ));
        return;
    }

    unless (flock($fh, LOCK_SH|LOCK_NB)) {
        $self->Error($cb, Lim::Error->new(
            code => 400,
            message => 'Unable to lock kasp.xml: '.$!
        ));
        return;
    }

    my $dom;
    eval {
        $dom = XML::LibXML->load_xml(IO => $fh);
    };
    if ($@) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to load XML file: '.$@
        ));
        return;
    }
    
    my %policy;
    eval {
        foreach my $node ($dom->findnodes('/KASP/Policy')) {
            $_ = $self->_PolicyXML2JSON($node);
            $policy{$_->{name}} = $_;
        }
    };
    if ($@) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'XML Error: '.$@
        ));
        return;
    }

    my @policies;
    foreach my $policy (ref($q->{policy}) eq 'ARRAY' ? @{$q->{policy}} : $q->{policy}) {
        if (exists $policy{$policy->{name}}) {
            push(@policies, $policy{$policy->{name}});
        }
    }

    $dom = undef;
    unless (flock($fh, LOCK_UN)) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to unlock kasp.xml: '.$!
        ));
        return;
    }

    if (scalar @policies == 1) {
        $self->Successful($cb, { policy => $policies[0] });
    }
    elsif (scalar @policies) {
        $self->Successful($cb, { policy => \@policies });
    }
    else {
        $self->Successful($cb);
    }
}

=head2 UpdatePolicy

=cut

sub UpdatePolicy {
    my ($self, $cb, $q) = @_;
    my $files = $self->_ScanConfig(1);

    unless (exists $files->{'kasp.xml'}) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'No kasp.xml configuration file exists'
        ));
        return;
    }
    
    unless ($files->{'kasp.xml'}->{write}) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'The kasp.xml configuration file is not writable'
        ));
        return;
    }

    my $fh = IO::File->new($files->{'kasp.xml'}->{name}, 'r+');
    unless (defined $fh) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to open kasp.xml: '.$!
        ));
        return;
    }

    unless (flock($fh, LOCK_EX|LOCK_NB)) {
        $self->Error($cb, Lim::Error->new(
            code => 400,
            message => 'Unable to lock kasp.xml: '.$!
        ));
        return;
    }

    my $dom;
    eval {
        $dom = XML::LibXML->load_xml(IO => $fh);
    };
    if ($@) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to load XML file: '.$@
        ));
        return;
    }
    
    my %policy;
    eval {
        foreach my $node ($dom->findnodes('/KASP/Policy')) {
            $policy{$self->_PolicyNameXML($node)} = $node;
        }
    };
    if ($@) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'XML Error: '.$@
        ));
        return;
    }

    my ($kasp) = $dom->findnodes('/KASP');
    unless (defined $kasp) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to find KASP element within XML'
        ));
        return;
    }
    unless (blessed $kasp and $kasp->isa('XML::LibXML::Node')) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to find KASP element within XML'
        ));
        return;
    }

    foreach my $policy (ref($q->{policy}) eq 'ARRAY' ? @{$q->{policy}} : $q->{policy}) {
        unless (exists $policy{$policy->{name}}) {
            flock($fh, LOCK_UN);
            $self->Error($cb, Lim::Error->new(
                code => 500,
                message => 'Policy '.$policy->{name}.' does not exists'
            ));
            return;
        }
        
        eval {
            $kasp->removeChild($policy{$policy->{name}});
            $kasp->addChild($self->_PolicyJSON2XML($policy));
        };
        if ($@) {
            flock($fh, LOCK_UN);
            $self->Error($cb, Lim::Error->new(
                code => 500,
                message => 'Unable to update policy '.$policy->{name}.' to XML: '.$@
            ));
            return;
        }
    }

    my $tmp = Lim::Util::TempFile;
    unless (defined $tmp and chmod(0600, $tmp->filename)) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to create temporary file: '.$!
        ));
        return;
    }
    $fh->seek(0, SEEK_SET);
    while ($fh->sysread(my $buf, 32*1024)) {
        unless ($tmp->syswrite($buf) == length($buf)) {
            flock($fh, LOCK_UN);
            $self->Error($cb, Lim::Error->new(
                code => 500,
                message => 'Unable to create backup copy of kasp.xml: '.$!
            ));
            return;
        }
    }
    $tmp->flush;

    my $fh_sha = Digest::SHA->new(512);
    $fh->seek(0, SEEK_SET);
    $fh_sha->addfile($fh);

    my $tmp_sha = Digest::SHA->new(512);
    $tmp->seek(0, SEEK_SET);
    $tmp_sha->addfile($tmp);
    
    unless ($fh_sha->b64digest eq $tmp_sha->b64digest) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Verification of backup file failed, checksums does not match!'
        ));
        return;
    }
    
    $fh->seek(0, SEEK_SET);
    unless ($dom->toFH($fh)) {
        $fh->seek(0, SEEK_SET);
        $tmp->seek(0, SEEK_SET);
        
        my $wrote = 0;
        while ((my $read = $tmp->sysread(my $buf, 32*1024))) {
            $wrote += $read;
            unless ($fh->syswrite($buf) == length($buf)) {
                flock($fh, LOCK_UN);
                $tmp->unlink_on_destroy(0);
                $self->Error($cb, Lim::Error->new(
                    code => 500,
                    message => 'Failure when writing new kasp.xml and unable to restore backup kasp.xml, kept backup in '.$tmp->filename.': '.$!
                ));
                return;
            }
        }
        $fh->flush;
        $fh->truncate($wrote);
        flock($fh, LOCK_UN);
        $fh->close;

        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Failure when writing new kasp.xml: '.$!
        ));
        return;
    }
    $fh->flush;

    $dom = undef;
    unless (flock($fh, LOCK_UN)) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to unlock kasp.xml: '.$!
        ));
        return;
    }

    $self->Successful($cb);
}

=head2 DeletePolicy

=cut

sub DeletePolicy {
    my ($self, $cb, $q) = @_;
    my $files = $self->_ScanConfig(1);

    unless (exists $files->{'kasp.xml'}) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'No kasp.xml configuration file exists'
        ));
        return;
    }
    
    unless ($files->{'kasp.xml'}->{write}) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'The kasp.xml configuration file is not writable'
        ));
        return;
    }

    my $fh = IO::File->new($files->{'kasp.xml'}->{name}, 'r+');
    unless (defined $fh) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to open kasp.xml: '.$!
        ));
        return;
    }

    unless (flock($fh, LOCK_EX|LOCK_NB)) {
        $self->Error($cb, Lim::Error->new(
            code => 400,
            message => 'Unable to lock kasp.xml: '.$!
        ));
        return;
    }

    my $dom;
    eval {
        $dom = XML::LibXML->load_xml(IO => $fh);
    };
    if ($@) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to load XML file: '.$@
        ));
        return;
    }
    
    my %policy;
    eval {
        foreach my $node ($dom->findnodes('/KASP/Policy')) {
            $policy{$self->_PolicyNameXML($node)} = $node;
        }
    };
    if ($@) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'XML Error: '.$@
        ));
        return;
    }

    my ($kasp) = $dom->findnodes('/KASP');
    unless (defined $kasp) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to find KASP element within XML'
        ));
        return;
    }
    unless (blessed $kasp and $kasp->isa('XML::LibXML::Node')) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to find KASP element within XML'
        ));
        return;
    }

    foreach my $policy (ref($q->{policy}) eq 'ARRAY' ? @{$q->{policy}} : $q->{policy}) {
        unless (exists $policy{$policy->{name}}) {
            flock($fh, LOCK_UN);
            $self->Error($cb, Lim::Error->new(
                code => 500,
                message => 'Policy '.$policy->{name}.' does not exists'
            ));
            return;
        }
        
        eval {
            $kasp->removeChild($policy{$policy->{name}});
        };
        if ($@) {
            flock($fh, LOCK_UN);
            $self->Error($cb, Lim::Error->new(
                code => 500,
                message => 'Unable to remove policy '.$policy->{name}.' to XML: '.$@
            ));
            return;
        }
    }

    my $tmp = Lim::Util::TempFile;
    unless (defined $tmp and chmod(0600, $tmp->filename)) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to create temporary file: '.$!
        ));
        return;
    }
    $fh->seek(0, SEEK_SET);
    while ($fh->sysread(my $buf, 32*1024)) {
        unless ($tmp->syswrite($buf) == length($buf)) {
            flock($fh, LOCK_UN);
            $self->Error($cb, Lim::Error->new(
                code => 500,
                message => 'Unable to create backup copy of kasp.xml: '.$!
            ));
            return;
        }
    }
    $tmp->flush;

    my $fh_sha = Digest::SHA->new(512);
    $fh->seek(0, SEEK_SET);
    $fh_sha->addfile($fh);

    my $tmp_sha = Digest::SHA->new(512);
    $tmp->seek(0, SEEK_SET);
    $tmp_sha->addfile($tmp);
    
    unless ($fh_sha->b64digest eq $tmp_sha->b64digest) {
        flock($fh, LOCK_UN);
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Verification of backup file failed, checksums does not match!'
        ));
        return;
    }
    
    $fh->seek(0, SEEK_SET);
    unless ($dom->toFH($fh)) {
        $fh->seek(0, SEEK_SET);
        $tmp->seek(0, SEEK_SET);
        
        my $wrote = 0;
        while ((my $read = $tmp->sysread(my $buf, 32*1024))) {
            $wrote += $read;
            unless ($fh->syswrite($buf) == length($buf)) {
                flock($fh, LOCK_UN);
                $tmp->unlink_on_destroy(0);
                $self->Error($cb, Lim::Error->new(
                    code => 500,
                    message => 'Failure when writing new kasp.xml and unable to restore backup kasp.xml, kept backup in '.$tmp->filename.': '.$!
                ));
                return;
            }
        }
        $fh->flush;
        $fh->truncate($wrote);
        flock($fh, LOCK_UN);
        $fh->close;

        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Failure when writing new kasp.xml: '.$!
        ));
        return;
    }
    $fh->flush;

    $dom = undef;
    unless (flock($fh, LOCK_UN)) {
        $self->Error($cb, Lim::Error->new(
            code => 500,
            message => 'Unable to unlock kasp.xml: '.$!
        ));
        return;
    }

    $self->Successful($cb);
}

=head2 UpdateControl

=cut

sub UpdateControl {
    my ($self, $cb) = @_;

    $self->Successful($cb);
}

=head2 UpdateControlStart

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
                unless (defined $self) {
                    undef($cmd_cb);
                    return;
                }
                if (my $program = shift(@programs)) {
                    Lim::Util::run_cmd
                        [ 'ods-control', $program, 'start' ],
                        '<', '/dev/null',
                        '>', sub {
                            if (defined $_[0]) {
                                $cb->reset_timeout;
                            }
                        },
                        '2>', '/dev/null',
                        timeout => 30,
                        cb => sub {
                            unless (defined $self) {
                                undef($cmd_cb);
                                return;
                            }
                            if (shift->recv) {
                                $self->Error($cb, 'Unable to start OpenDNSSEC '.$program);
                                undef($cmd_cb);
                                return;
                            }
                            $cmd_cb->();
                        };
                }
                else {
                    $self->Successful($cb);
                    undef($cmd_cb);
                }
            };
            $cmd_cb->();
            return;
        }
    }
    else {
        weaken($self);
        Lim::Util::run_cmd
            [ 'ods-control', 'start' ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $cb->reset_timeout;
                }
            },
            '2>', '/dev/null',
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to start OpenDNSSEC');
                    return;
                }
                $self->Successful($cb);
            };
        return;
    }
    $self->Successful($cb);
}

=head2 UpdateControlStop

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
                unless (defined $self) {
                    undef($cmd_cb);
                    return;
                }
                if (my $program = shift(@programs)) {
                    Lim::Util::run_cmd
                        [ 'ods-control', $program, 'stop' ],
                        '<', '/dev/null',
                        '>', sub {
                            if (defined $_[0]) {
                                $cb->reset_timeout;
                            }
                        },
                        '2>', '/dev/null',
                        timeout => 30,
                        cb => sub {
                            unless (defined $self) {
                                undef($cmd_cb);
                                return;
                            }
                            if (shift->recv) {
                                $self->Error($cb, 'Unable to stop OpenDNSSEC '.$program);
                                undef($cmd_cb);
                                return;
                            }
                            $cmd_cb->();
                        };
                }
                else {
                    $self->Successful($cb);
                    undef($cmd_cb);
                }
            };
            $cmd_cb->();
            return;
        }
    }
    else {
        weaken($self);
        Lim::Util::run_cmd
            [ 'ods-control', 'stop' ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $cb->reset_timeout;
                }
            },
            '2>', '/dev/null',
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to stop OpenDNSSEC');
                    return;
                }
                $self->Successful($cb);
            };
        return;
    }
    $self->Successful($cb);
}

=head2 CreateEnforcer

=cut

sub CreateEnforcer {
    my ($self, $cb) = @_;

    $self->Successful($cb);
}

=head2 ReadEnforcer

=cut

sub ReadEnforcer {
    my ($self, $cb) = @_;

    $self->Successful($cb);
}

=head2 UpdateEnforcer

=cut

sub UpdateEnforcer {
    my ($self, $cb) = @_;

    $self->Successful($cb);
}

=head2 DeleteEnforcer

=cut

sub DeleteEnforcer {
    my ($self, $cb) = @_;

    $self->Successful($cb);
}

=head2 CreateEnforcerSetup

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
    my $stdin = "Y\015";
    Lim::Util::run_cmd [ 'ods-ksmutil', 'setup' ],
        '<', \$stdin,
        '>', sub {
            if (defined $_[0]) {
                $cb->reset_timeout;
            }
        },
        '2>', \$stderr,
        timeout => 30,
        cb => sub {
            unless (defined $self) {
                return;
            }
            if (shift->recv) {
                $self->Error($cb, 'Unable to setup OpenDNSSEC');
                return;
            }
            $self->Successful($cb);
        };
}

=head2 UpdateEnforcerUpdate

=cut

sub UpdateEnforcerUpdate {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }
    
    my %section = (
        kasp => 1,
        zonelist => 1,
        conf => 1
    );
    
    if (exists $q->{update}) {
        my @sections;
        foreach my $section (ref($q->{update}) eq 'ARRAY' ? @{$q->{update}} : $q->{update}) {
            my $name = lc($section->{section});
            
            if (exists $section{$name}) {
                push(@sections, $name);
            }
            else {
                $self->Error($cb, Lim::Error->new(
                    code => 500,
                    message => 'Unknown Enforcer configuration section "'.$name.'" specified'
                ));
                return;
            }
        }
        if (scalar @sections) {
            weaken($self);
            my $cmd_cb; $cmd_cb = sub {
                unless (defined $self) {
                    undef($cmd_cb);
                    return;
                }
                if (my $section = shift(@sections)) {
                    my ($stdout, $stderr);
                    Lim::Util::run_cmd
                        [ 'ods-ksmutil', 'update', $section ],
                        '<', '/dev/null',
                        '>', sub {
                            if (defined $_[0]) {
                                $cb->reset_timeout;
                                $stdout .= $_[0];
                            }
                        },
                        '2>', \$stderr,
                        timeout => 30,
                        cb => sub {
                            unless (defined $self) {
                                undef($cmd_cb);
                                return;
                            }
                            if (shift->recv) {
                                $self->Error($cb, 'Unable to update Enforcer configuration section '.$section);
                                undef($cmd_cb);
                                return;
                            }
                            $cmd_cb->();
                        };
                }
                else {
                    $self->Successful($cb);
                    undef($cmd_cb);
                }
            };
            $cmd_cb->();
            return;
        }
    }
    else {
        my ($stdout, $stderr);
        weaken($self);
        Lim::Util::run_cmd
            [ 'ods-ksmutil', 'update', 'all' ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $cb->reset_timeout;
                    $stdout .= $_[0];
                }
            },
            '2>', \$stderr,
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to update all Enforcer configuration sections');
                    return;
                }
                $self->Successful($cb);
            };
        return;
    }
    $self->Successful($cb);
}

=head2 CreateEnforcerZone

=cut

sub CreateEnforcerZone {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }
    
    my @zones = ref($q->{zone}) eq 'ARRAY' ? @{$q->{zone}} : ($q->{zone});
    if (scalar @zones) {
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $zone = shift(@zones)) {
                my ($stdout, $stderr);
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'zone', 'add',
                        '--zone', $zone->{name},
                        '--policy', $zone->{policy},
                        '--signerconf', $zone->{signerconf},
                        '--input', $zone->{input},
                        '--output', $zone->{output},
                        (exists $zone->{no_xml} and $zone->{no_xml} ? '--no-xml' : ())
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $cb->reset_timeout;
                            $stdout .= $_[0];
                        }
                    },
                    '2>', \$stderr,
                    timeout => 10,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to create zone ', $zone->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                $self->Successful($cb);
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
        return;
    }
    $self->Successful($cb);
}

=head2 ReadEnforcerZoneList

=cut

sub ReadEnforcerZoneList {
    my ($self, $cb) = @_;
    
    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }
    
    weaken($self);
    my ($data, $stderr, @zones);
    Lim::Util::run_cmd [ 'ods-ksmutil', 'zone', 'list' ],
        '<', '/dev/null',
        '>', sub {
            if (defined $_[0]) {
                $data .= $_[0];
                
                $cb->reset_timeout;
                
                while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                    my $line = $1;
                    
                    if ($line =~ /^Found\s+Zone:\s+([^;]+);\s+on\s+policy\s+(.+)$/o) {
                        push(@zones, {
                            name => $1,
                            policy => $2
                        });
                    }
                }
            }
        },
        '2>', \$stderr,
        timeout => 30,
        cb => sub {
            unless (defined $self) {
                return;
            }
            if (shift->recv) {
                $self->Error($cb, 'Unable to get Enforcer zone list');
                return;
            }
            if (scalar @zones == 1) {
                $self->Successful($cb, { zone => $zones[0] });
            }
            elsif (scalar @zones) {
                $self->Successful($cb, { zone => \@zones });
            }
            else {
                $self->Successful($cb);
            }
        };
}

=head2 DeleteEnforcerZone

=cut

sub DeleteEnforcerZone {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }
    
    my @zones = ref($q->{zone}) eq 'ARRAY' ? @{$q->{zone}} : ($q->{zone});
    if (scalar @zones) {
        foreach (@zones) {
            if (exists $_->{all} and $_->{all}) {
                weaken($self);
                my ($stdout, $stderr);
                # TODO reset timer on stdout output
                Lim::Util::run_cmd
                    [ 'ods-ksmutil', 'zone', 'delete', '--all' ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $cb->reset_timeout;
                            $stdout .= $_[0];
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to delete all zones');
                            return;
                        }
                        $self->Successful($cb);
                    };
                return;
            }
        }
        
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $zone = shift(@zones)) {
                while (defined $zone and !exists $zone->{name}) {
                    $zone = shift(@zones);
                }
                unless (defined $zone) {
                    $self->Successful($cb);
                    undef($cmd_cb);
                    return;
                }
                my ($stdout, $stderr);
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'zone', 'delete',
                        '--zone', $zone->{name},
                        (exists $zone->{no_xml} and $zone->{no_xml} ? '--no-xml' : ())
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $cb->reset_timeout;
                            $stdout .= $_[0];
                        }
                    },
                    '2>', \$stderr,
                    timeout => 10,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to delete zone ', $zone->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                $self->Successful($cb);
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
        return;
    }
    $self->Successful($cb);
}

=head2 ReadEnforcerRepositoryList

=cut

sub ReadEnforcerRepositoryList {
    my ($self, $cb) = @_;
    
    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }
    
    weaken($self);
    my ($data, $stderr, @repositories);
    my $skip = 2;
    Lim::Util::run_cmd [ 'ods-ksmutil', 'repository', 'list' ],
        '<', '/dev/null',
        '>', sub {
            if (defined $_[0]) {
                $data .= $_[0];
                
                $cb->reset_timeout;
                
                while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                    my $line = $1;
                    
                    if ($skip) {
                        $skip--;
                        next;
                    }
                    
                    # TODO spaces in name?
                    if ($line =~ /^(\S+)\s+(\d+)\s+((?:Yes|No))$/o) {
                        push(@repositories, {
                            name => $1,
                            capacity => $2,
                            require_backup => $3 eq 'Yes' ? 1 : 0
                        });
                    }
                }
            }
        },
        '2>', \$stderr,
        timeout => 30,
        cb => sub {
            unless (defined $self) {
                return;
            }
            if (shift->recv) {
                $self->Error($cb, 'Unable to get Enforcer repository list');
                return;
            }
            if (scalar @repositories == 1) {
                $self->Successful($cb, { repository => $repositories[0] });
            }
            elsif (scalar @repositories) {
                $self->Successful($cb, { repository => \@repositories });
            }
            else {
                $self->Successful($cb);
            }
        };
}

=head2 ReadEnforcerPolicyList

=cut

sub ReadEnforcerPolicyList {
    my ($self, $cb) = @_;
    
    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }
    
    weaken($self);
    my ($data, $stderr, @policies);
    my $skip = 2;
    Lim::Util::run_cmd [ 'ods-ksmutil', 'policy', 'list' ],
        '<', '/dev/null',
        '>', sub {
            if (defined $_[0]) {
                $data .= $_[0];
                
                $cb->reset_timeout;
                
                while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                    my $line = $1;
                    
                    if ($skip) {
                        $skip--;
                        next;
                    }
                    
                    # TODO spaces in name?
                    if ($line =~ /^(\S+)\s+(.+)$/o) {
                        push(@policies, {
                            name => $1,
                            description => $2
                        });
                    }
                }
            }
        },
        '2>', \$stderr,
        timeout => 30,
        cb => sub {
            unless (defined $self) {
                return;
            }
            if (shift->recv) {
                $self->Error($cb, 'Unable to get Enforcer policy list');
                return;
            }
            if (scalar @policies == 1) {
                $self->Successful($cb, { policy => $policies[0] });
            }
            elsif (scalar @policies) {
                $self->Successful($cb, { policy => \@policies });
            }
            else {
                $self->Successful($cb);
            }
        };
}

=head2 ReadEnforcerPolicyExport

=cut

sub ReadEnforcerPolicyExport {
    my ($self, $cb, $q) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    # TODO is there a way to send the database as base64 incrementaly to avoid hogning memory?
    
    if (exists $q->{policy}) {
        my @policies = ref($q->{policy}) eq 'ARRAY' ? @{$q->{policy}} : ($q->{policy});
        my %policy;
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $policy = shift(@policies)) {
                my ($stdout, $stderr);
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'policy', 'export',
                        '--policy', $policy->{name}
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $cb->reset_timeout;
                            $stdout .= $_[0];
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to get Enforcer policy export for policy ', $policy->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $policy{$policy->{name}} = {
                            name => $policy->{name},
                            kasp => $stdout
                        };
                        $cmd_cb->();
                    };
            }
            else {
                if (scalar %policy) {
                    $self->Successful($cb, { policy => [ values %policy ] });
                }
                else {
                    $self->Successful($cb);
                }
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
    }
    else {
        weaken($self);
        my ($stdout, $stderr);
        Lim::Util::run_cmd [ 'ods-ksmutil', 'policy', 'export', '--all' ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $cb->reset_timeout;
                    $stdout .= $_[0];
                }
            },
            '2>', \$stderr,
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to export policies');
                    return;
                }
                $self->Successful($cb, { kasp => $stdout });
            };
    }
}

=head2 DeleteEnforcerPolicyPurge

=cut

sub DeleteEnforcerPolicyPurge {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented: function experimental');
}

=head2 ReadEnforcerKeyList

=cut

sub ReadEnforcerKeyList {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    if (exists $q->{zone}) {
        my @zones = ref($q->{zone}) eq 'ARRAY' ? @{$q->{zone}} : ($q->{zone});
        my %zone;
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $zone = shift(@zones)) {
                my ($data, $stderr);
                my $skip = 2;
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'key', 'list',
                        '--zone', $zone->{name},
                        (exists $q->{verbose} and $q->{verbose} ? '--verbose' : ())
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $data .= $_[0];
                            
                            $cb->reset_timeout;
                            
                            while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                                my $line = $1;
                                
                                if ($skip) {
                                    $skip--;
                                    next;
                                }
                                
                                if ($line =~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+(?:\s\S+)*)\s*(?:(\S+)\s+(\S+)\s+(\S+)){0,1}$/o) {
                                    unless (exists $zone{$1}) {
                                        $zone{$1} = {
                                            name => $1,
                                            key => []
                                        };
                                    }
                                    push(@{$zone{$1}->{key}}, {
                                        type => $2,
                                        state => $3,
                                        next_transaction => $4,
                                        (defined $5 ? (cka_id => $5) : ()),
                                        (defined $6 ? (repository => $6) : ()),
                                        (defined $7 ? (keytag => $7) : ())
                                    });
                                }
                            }
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to get Enforcer key list for zone ', $zone->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                if (scalar %zone) {
                    $self->Successful($cb, { zone => [ values %zone ] });
                }
                else {
                    $self->Successful($cb);
                }
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
    }
    else {
        weaken($self);
        my ($data, $stderr, %zone);
        my $skip = 2;
        Lim::Util::run_cmd
            [
                'ods-ksmutil', 'key', 'list',
                (exists $q->{verbose} and $q->{verbose} ? '--verbose' : ())
            ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $data .= $_[0];
                    
                    $cb->reset_timeout;
                    
                    while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                        my $line = $1;
                        
                        if ($skip) {
                            $skip--;
                            next;
                        }
                        
                        if ($line =~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+(?:\s\S+)*)\s*(?:(\S+)\s+(\S+)\s+(\S+)){0,1}$/o) {
                            unless (exists $zone{$1}) {
                                $zone{$1} = {
                                    name => $1,
                                    key => []
                                };
                            }
                            push(@{$zone{$1}->{key}}, {
                                type => $2,
                                state => $3,
                                next_transaction => $4,
                                (defined $5 ? (cka_id => $5) : ()),
                                (defined $6 ? (repository => $6) : ()),
                                (defined $7 ? (keytag => $7) : ())
                            });
                        }
                    }
                }
            },
            '2>', \$stderr,
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to get Enforcer key list');
                    return;
                }
                elsif (scalar %zone) {
                    $self->Successful($cb, { zone => [ values %zone ] });
                }
                else {
                    $self->Successful($cb);
                }
            };
    }
}

=head2 ReadEnforcerKeyExport

=cut

sub ReadEnforcerKeyExport {
    my ($self, $cb, $q) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    if (exists $q->{zone}) {
        my @zones = ref($q->{zone}) eq 'ARRAY' ? @{$q->{zone}} : ($q->{zone});
        my @rr;
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $zone = shift(@zones)) {
                my ($data, $stderr);
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'key', 'export',
                        '--zone', $zone->{name},
                        (exists $zone->{keystate} ? ('--keystate' => $zone->{keystate}) : (exists $q->{keystate} and $q->{keystate} ? ('--keystate', $q->{keystate}) : ())),
                        (exists $zone->{keytype} ? ('--keytype' => $zone->{keytype}) : (exists $q->{keytype} and $q->{keytype} ? ('--keytype', $q->{keytype}) : ())),
                        (exists $zone->{ds} ? ('--ds' => $zone->{ds}) : (exists $q->{ds} and $q->{ds} ? ('--ds') : ()))
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $data .= $_[0];
                            
                            $cb->reset_timeout;
                            
                            while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                                my $line = $1;
                                
                                $line =~ s/;.*//o;
                                
                                if ($line =~ /^(\S+)\s+(\d+)\s+(\S+)\s+(\S+)\s+(.+)$/o) {
                                    push(@rr, {
                                        name => $1,
                                        ttl => $2,
                                        class => $3,
                                        type => $4,
                                        rdata => $5
                                    });
                                }
                            }
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to get Enforcer key export for zone ', $zone->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                if (scalar @rr == 1) {
                    $self->Successful($cb, { rr => $rr[0] });
                }
                elsif (scalar @rr) {
                    $self->Successful($cb, { rr => \@rr });
                }
                else {
                    $self->Successful($cb);
                }
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
    }
    else {
        weaken($self);
        my ($data, $stderr, @rr);
        Lim::Util::run_cmd
            [
                'ods-ksmutil', 'key', 'export', '--all',
                (exists $q->{keystate} and $q->{keystate} ? ('--keystate', $q->{keystate}) : ()),
                (exists $q->{keytype} and $q->{keytype} ? ('--keytype', $q->{keytype}) : ()),
                (exists $q->{ds} and $q->{ds} ? ('--ds') : ())
            ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $data .= $_[0];
                    
                    $cb->reset_timeout;
                    
                    while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                        my $line = $1;
                        
                        $line =~ s/;.*//o;
                        
                        if ($line =~ /^(\S+)\s+(\d+)\s+(\S+)\s+(\S+)\s+(.+)$/o) {
                            push(@rr, {
                                name => $1,
                                ttl => $2,
                                class => $3,
                                type => $4,
                                rdata => $5
                            });
                        }
                    }
                }
            },
            '2>', \$stderr,
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to get Enforcer key export');
                    return;
                }
                elsif (scalar @rr == 1) {
                    $self->Successful($cb, { rr => $rr[0] });
                }
                elsif (scalar @rr) {
                    $self->Successful($cb, { rr => \@rr });
                }
                else {
                    $self->Successful($cb);
                }
            };
    }
}

=head2 CreateEnforcerKeyImport

=cut

sub CreateEnforcerKeyImport {
    my ($self, $cb, $q) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    my @keys = ref($q->{key}) eq 'ARRAY' ? @{$q->{key}} : ($q->{key});

    weaken($self);
    my $cmd_cb; $cmd_cb = sub {
        unless (defined $self) {
            undef($cmd_cb);
            return;
        }
        if (my $key = shift(@keys)) {
            my ($stdout, $stderr);
            Lim::Util::run_cmd
                [
                    'ods-ksmutil', 'key', 'import',
                    '--zone', $key->{zone},
                    '--cka_id', $key->{cka_id},
                    '--repository', $key->{repository},
                    '--bits', $key->{bits},
                    '--algorithm', $key->{algorithm},
                    '--keystate', $key->{keystate},
                    '--keytype', $key->{keytype},
                    '--time', $key->{time},
                    (exists $key->{retire} ? ('--retire', $key->{retire}) : ())
                ],
                '<', '/dev/null',
                '>', sub {
                    if (defined $_[0]) {
                        $cb->reset_timeout;
                        $stdout .= $_[0];
                    }
                },
                '2>', \$stderr,
                timeout => 30,
                cb => sub {
                    unless (defined $self) {
                        undef($cmd_cb);
                        return;
                    }
                    if (shift->recv) {
                        $self->Error($cb, 'Unable to import key cka id ', $key->{cka_id}, ' to Enforcer for zone ', $key->{zone});
                        undef($cmd_cb);
                        return;
                    }
                    $cmd_cb->();
                };
        }
        else {
            $self->Successful($cb);
            undef($cmd_cb);
        }
    };
    $cmd_cb->();
}

=head2 UpdateEnforcerKeyRollover

=cut

sub UpdateEnforcerKeyRollover {
    my ($self, $cb, $q) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    my @zones;
    if (exists $q->{zone}) {
        @zones = ref($q->{zone}) eq 'ARRAY' ? @{$q->{zone}} : ($q->{zone});
    }
    
    my @policies;
    if (exists $q->{policy}) {
        @policies = ref($q->{policy}) eq 'ARRAY' ? @{$q->{policy}} : ($q->{policy});
    }

    if (scalar @zones or scalar @policies) {
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $zone = shift(@zones)) {
                my ($stdout, $stderr);
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'key', 'rollover',
                        '--zone', $zone->{name},
                        (exists $zone->{keytype} ? ('--keytype' => $zone->{keytype}) : ())
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $cb->reset_timeout;
                            $stdout .= $_[0];
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to issue Enforcer key rollover for zone ', $zone->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            elsif (my $policy = shift(@policies)) {
                my ($stdout, $stderr, $stdin);
                $stdin = "Y\015";
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'key', 'rollover',
                        '--policy', $policy->{name},
                        (exists $policy->{keytype} ? ('--keytype' => $policy->{keytype}) : ())
                    ],
                    '<', \$stdin,
                    '>', sub {
                        if (defined $_[0]) {
                            $cb->reset_timeout;
                            $stdout .= $_[0];
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to issue Enforcer key rollover for policy ', $policy->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                $self->Successful($cb);
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
        return;
    }
    $self->Successful($cb);
}

=head2 DeleteEnforcerKeyPurge

=cut

sub DeleteEnforcerKeyPurge {
    my ($self, $cb, $q) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    my @zones;
    if (exists $q->{zone}) {
        @zones = ref($q->{zone}) eq 'ARRAY' ? @{$q->{zone}} : ($q->{zone});
    }
    
    my @policies;
    if (exists $q->{policy}) {
        @policies = ref($q->{policy}) eq 'ARRAY' ? @{$q->{policy}} : ($q->{policy});
    }

    # TODO test parsing of output

    if (scalar @zones or scalar @policies) {
        my @keys;
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $zone = shift(@zones)) {
                my ($data, $stderr);
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'key', 'purge',
                        '--zone', $zone->{name}
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $data .= $_[0];
                            
                            $cb->reset_timeout;
                            
                            while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                                my $line = $1;
                                
                                if ($line =~ /^Key\s+remove\s+successful:\s+(\S+)$/o) {
                                    push(@keys, {
                                        cka_id => $1
                                    });
                                }
                            }
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to issue Enforcer key rollover for zone ', $zone->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            elsif (my $policy = shift(@policies)) {
                my ($data, $stderr);
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'key', 'purge',
                        '--policy', $policy->{name}
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $data .= $_[0];
                            
                            $cb->reset_timeout;
                            
                            while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                                my $line = $1;
                                
                                if ($line =~ /^Key\s+remove\s+successful:\s+(\S+)$/o) {
                                    push(@keys, {
                                        cka_id => $1
                                    });
                                }
                            }
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to issue Enforcer key rollover for policy ', $policy->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                if (scalar @keys == 1) {
                    $self->Successful($cb, { key => $keys[0] });
                }
                elsif (scalar @keys) {
                    $self->Successful($cb, { key => \@keys });
                }
                else {
                    $self->Successful($cb);
                }
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
        return;
    }
    $self->Successful($cb);
}

=head2 CreateEnforcerKeyGenerate

=cut

sub CreateEnforcerKeyGenerate {
    my ($self, $cb, $q) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    my @policies = ref($q->{policy}) eq 'ARRAY' ? @{$q->{policy}} : ($q->{policy});
    my @keys;
    weaken($self);
    my $cmd_cb; $cmd_cb = sub {
        unless (defined $self) {
            undef($cmd_cb);
            return;
        }
        if (my $policy = shift(@policies)) {
            my ($data, $stderr);
            Lim::Util::run_cmd
                [
                    'ods-ksmutil', 'key', 'generate',
                    '--policy', $policy->{name},
                    '--interval', $policy->{interval},
                ],
                '<', '/dev/null',
                '>', sub {
                    if (defined $_[0]) {
                        $data .= $_[0];
                        
                        $cb->reset_timeout;
                        
                        while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                            my $line = $1;
                            
                            if ($line =~ /^Created\s+(\S+)\s+size:\s+(\d+),\s+alg:\s+(\d+)\s+with\s+id:\s+(\S+)\s+in\s+repository:\s+(.*)\s+and\s+database\.$/o) {
                                push(@keys, {
                                    keytype => $1,
                                    bits => $2,
                                    algorithm => $3,
                                    cka_id => $4,
                                    repository => $5
                                });
                            }
                        }
                    }
                },
                '2>', \$stderr,
                timeout => 30,
                cb => sub {
                    unless (defined $self) {
                        undef($cmd_cb);
                        return;
                    }
                    if (shift->recv) {
                        $self->Error($cb, 'Unable to generate keys for policy ', $policy->{name});
                        undef($cmd_cb);
                        return;
                    }
                    $cmd_cb->();
                };
        }
        else {
            if (scalar @keys == 1) {
                $self->Successful($cb, { key => $keys[0] });
            }
            elsif (scalar @keys) {
                $self->Successful($cb, { key => \@keys });
            }
            else {
                $self->Successful($cb);
            }
            undef($cmd_cb);
        }
    };
    $cmd_cb->();
}

=head2 UpdateEnforcerKeyKskRetire

=cut

sub UpdateEnforcerKeyKskRetire {
    my ($self, $cb, $q) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    my @zones = ref($q->{zone}) eq 'ARRAY' ? @{$q->{zone}} : ($q->{zone});
    weaken($self);
    my $cmd_cb; $cmd_cb = sub {
        unless (defined $self) {
            undef($cmd_cb);
            return;
        }
        if (my $zone = shift(@zones)) {
            my ($stdout, $stderr, $stdin);
            $stdin = "Y\015";
            Lim::Util::run_cmd
                [
                    'ods-ksmutil', 'key', 'ksk-retire',
                    '--zone', $zone->{name},
                    (exists $zone->{cka_id} ? ('--cka_id' => $zone->{cka_id}) : ()),
                    (exists $zone->{keytag} ? ('--keytag' => $zone->{keytag}) : ())
                ],
                '<', \$stdin,
                '>', sub {
                    if (defined $_[0]) {
                        $cb->reset_timeout;
                        $stdout .= $_[0];
                    }
                },
                '2>', \$stderr,
                timeout => 30,
                cb => sub {
                    unless (defined $self) {
                        undef($cmd_cb);
                        return;
                    }
                    if (shift->recv) {
                        my $error;
                        if ($stdout =~ /((?:Error:|No keys in)[^,]+)/o) {
                            $error = $1;
                            $error =~ s/^Error:\s+//o;
                        }
                        $self->Error($cb, 'Unable to retire KSK keys for zone ', $zone->{name},
                            (exists $zone->{cka_id} ? ' cka_id '.$zone->{cka_id} : ''),
                            (exists $zone->{keytag} ? ' keytag '.$zone->{keytag} : ''),
                            ' error: ', (defined $error ? $error : 'unknown')
                            );
                        undef($cmd_cb);
                        return;
                    }
                    $cmd_cb->();
                };
        }
        else {
            $self->Successful($cb);
            undef($cmd_cb);
        }
    };
    $cmd_cb->();
}

=head2 UpdateEnforcerKeyDsSeen

=cut

sub UpdateEnforcerKeyDsSeen {
    my ($self, $cb, $q) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    my @zones = ref($q->{zone}) eq 'ARRAY' ? @{$q->{zone}} : ($q->{zone});

    weaken($self);
    my $cmd_cb; $cmd_cb = sub {
        unless (defined $self) {
            undef($cmd_cb);
            return;
        }
        if (my $zone = shift(@zones)) {
            my ($stdout, $stderr);
            Lim::Util::run_cmd
                [
                    'ods-ksmutil', 'key', 'ds-seen',
                    '--zone', $zone->{name},
                    (exists $zone->{cka_id} ? ('--cka_id', $zone->{cka_id}) : ()),
                    (exists $zone->{keytag} ? ('--keytag',  $zone->{keytag}) : ()),
                    (exists $zone->{no_retire} and $zone->{no_retire} ? ('--no-retire') : ())
                ],
                '<', '/dev/null',
                '>', sub {
                    if (defined $_[0]) {
                        $cb->reset_timeout;
                        $stdout .= $_[0];
                    }
                },
                '2>', \$stderr,
                timeout => 30,
                cb => sub {
                    unless (defined $self) {
                        undef($cmd_cb);
                        return;
                    }
                    if (shift->recv) {
                        $self->Error($cb, 'Unable to set key as ds seen for zone ', $zone->{name},
                            (exists $zone->{cka_id} ? ' cka_id '.$zone->{cka_id} : ''),
                            (exists $zone->{keytag} ? ' keytag '.$zone->{keytag} : '')
                            );
                        undef($cmd_cb);
                        return;
                    }
                    $cmd_cb->();
                };
        }
        else {
            $self->Successful($cb);
            undef($cmd_cb);
        }
    };
    $cmd_cb->();
}

=head2 UpdateEnforcerBackupPrepare

=cut

sub UpdateEnforcerBackupPrepare {
    my ($self, $cb, $q) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    if (exists $q->{repository}) {
        my @repositories = ref($q->{repository}) eq 'ARRAY' ? @{$q->{repository}} : ($q->{repository});
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $repository = shift(@repositories)) {
                my ($stdout, $stderr);
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'backup', 'prepare',
                        '--repository', $repository->{name}
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $cb->reset_timeout;
                            $stdout .= $_[0];
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to prepare backup of repository ', $repository->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                $self->Successful($cb);
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
    }
    else {
        weaken($self);
        my ($stdout, $stderr);
        Lim::Util::run_cmd
            [
                'ods-ksmutil', 'backup', 'prepare'
            ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $cb->reset_timeout;
                    $stdout .= $_[0];
                }
            },
            '2>', \$stderr,
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to prepare backup');
                    return;
                }
                $self->Successful($cb);
            };
    }
}

=head2 UpdateEnforcerBackupCommit

=cut

sub UpdateEnforcerBackupCommit {
    my ($self, $cb, $q) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    if (exists $q->{repository}) {
        my @repositories = ref($q->{repository}) eq 'ARRAY' ? @{$q->{repository}} : ($q->{repository});
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $repository = shift(@repositories)) {
                my ($stdout, $stderr);
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'backup', 'commit',
                        '--repository', $repository->{name}
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $cb->reset_timeout;
                            $stdout .= $_[0];
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to commit backup of repository ', $repository->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                $self->Successful($cb);
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
    }
    else {
        weaken($self);
        my ($stdout, $stderr);
        Lim::Util::run_cmd
            [
                'ods-ksmutil', 'backup', 'commit'
            ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $cb->reset_timeout;
                    $stdout .= $_[0];
                }
            },
            '2>', \$stderr,
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to commit backup');
                    return;
                }
                $self->Successful($cb);
            };
    }
}

=head2 UpdateEnforcerBackupRollback

=cut

sub UpdateEnforcerBackupRollback {
    my ($self, $cb, $q) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    if (exists $q->{repository}) {
        my @repositories = ref($q->{repository}) eq 'ARRAY' ? @{$q->{repository}} : ($q->{repository});
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $repository = shift(@repositories)) {
                my ($stdout, $stderr);
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'backup', 'rollback',
                        '--repository', $repository->{name}
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $cb->reset_timeout;
                            $stdout .= $_[0];
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to rollback backup of repository ', $repository->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                $self->Successful($cb);
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
    }
    else {
        weaken($self);
        my ($stdout, $stderr);
        Lim::Util::run_cmd
            [
                'ods-ksmutil', 'backup', 'rollback'
            ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $cb->reset_timeout;
                    $stdout .= $_[0];
                }
            },
            '2>', \$stderr,
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to rollback backup');
                    return;
                }
                $self->Successful($cb);
            };
    }
}

=head2 UpdateEnforcerBackupDone

=cut

sub UpdateEnforcerBackupDone {
    my ($self, $cb, $q) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    if (exists $q->{repository}) {
        my @repositories = ref($q->{repository}) eq 'ARRAY' ? @{$q->{repository}} : ($q->{repository});
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $repository = shift(@repositories)) {
                my ($stdout, $stderr);
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'backup', 'done',
                        '--repository', $repository->{name}
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $cb->reset_timeout;
                            $stdout .= $_[0];
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to take backup of repository ', $repository->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                $self->Successful($cb);
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
    }
    else {
        weaken($self);
        my ($stdout, $stderr);
        Lim::Util::run_cmd
            [
                'ods-ksmutil', 'backup', 'done'
            ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $cb->reset_timeout;
                    $stdout .= $_[0];
                }
            },
            '2>', \$stderr,
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to take backup');
                    return;
                }
                $self->Successful($cb);
            };
    }
}

=head2 ReadEnforcerBackupList

=cut

sub ReadEnforcerBackupList {
    my ($self, $cb, $q) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    if (exists $q->{repository}) {
        my @respositories = ref($q->{repository}) eq 'ARRAY' ? @{$q->{repository}} : ($q->{repository});
        my %repository;
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $repository = shift(@respositories)) {
                my ($data, $stderr);
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'backup', 'list',
                        '--repository', $repository->{name}
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $data .= $_[0];
                            
                            $cb->reset_timeout;
                            
                            while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                                my $line = $1;
                                
                                if ($line =~ /^Repository\s+(.+)\s+has\s+unbacked\s+up\s+keys/o) {
                                    unless (exists $repository{$1}) {
                                        $repository{$1} = {
                                            name => $1
                                        };
                                    }
                                    $repository{$1}->{unbacked_up_keys} = 1;
                                }
                                elsif ($line =~ /^Repository\s+(.+)\s+has\s+keys\s+prepared/o) {
                                    unless (exists $repository{$1}) {
                                        $repository{$1} = {
                                            name => $1
                                        };
                                    }
                                    $repository{$1}->{prepared_keys} = 1;
                                }
                                elsif ($line =~ /^(\S+\s+\S+)\s+(\S+)$/o) {
                                    unless (exists $repository{$2}) {
                                        $repository{$2} = {
                                            name => $2
                                        };
                                    }
                                    push(@{$repository{$2}->{backup}}, {
                                        date => $1
                                    });
                                }
                            }
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to get Enforcer backup list for repository ', $repository->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                if (scalar %repository) {
                    $self->Successful($cb, { repository => [ values %repository ] });
                }
                else {
                    $self->Successful($cb);
                }
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
    }
    else {
        weaken($self);
        my ($data, $stderr, %repository);
        Lim::Util::run_cmd
            [
                'ods-ksmutil', 'backup', 'list'
            ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $data .= $_[0];
                    
                    $cb->reset_timeout;
                    
                    while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                        my $line = $1;
                        
                        if ($line =~ /^Repository\s+(.+)\s+has\s+unbacked\s+up\s+keys/o) {
                            unless (exists $repository{$1}) {
                                $repository{$1} = {
                                    name => $1
                                };
                            }
                            $repository{$1}->{unbacked_up_keys} = 1;
                        }
                        elsif ($line =~ /^Repository\s+(.+)\s+has\s+keys\s+prepared/o) {
                            unless (exists $repository{$1}) {
                                $repository{$1} = {
                                    name => $1
                                };
                            }
                            $repository{$1}->{prepared_keys} = 1;
                        }
                        elsif ($line =~ /^(\S+\s+\S+)\s+(\S+)$/o) {
                            unless (exists $repository{$2}) {
                                $repository{$2} = {
                                    name => $2
                                };
                            }
                            push(@{$repository{$2}->{backup}}, {
                                date => $1
                            });
                        }
                    }
                }
            },
            '2>', \$stderr,
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to get Enforcer backup list');
                    return;
                }
                elsif (scalar %repository) {
                    $self->Successful($cb, { repository => [ values %repository ] });
                }
                else {
                    $self->Successful($cb);
                }
            };
    }
}

=head2 ReadEnforcerRolloverList

=cut

sub ReadEnforcerRolloverList {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    if (exists $q->{zone}) {
        my @zones = ref($q->{zone}) eq 'ARRAY' ? @{$q->{zone}} : ($q->{zone});
        my @rollovers;
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $zone = shift(@zones)) {
                my ($data, $stderr);
                my $skip = 2;
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'rollover', 'list',
                        '--zone', $zone->{name}
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $data .= $_[0];
                            
                            $cb->reset_timeout;
                            
                            while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                                my $line = $1;
                                
                                if ($skip) {
                                    $skip--;
                                    next;
                                }
                                
                                if ($line =~ /^(\S+)\s+(\S+)\s+(\S+\s+\S+)$/o) {
                                    push(@rollovers, {
                                        name => $1,
                                        keytype => $2,
                                        rollover_expected => $3
                                    });
                                }
                            }
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to get Enforcer rollover list for zone ', $zone->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                if (scalar @rollovers == 1) {
                    $self->Successful($cb, { zone => $rollovers[0] });
                }
                elsif (scalar @rollovers) {
                    $self->Successful($cb, { zone => \@rollovers });
                }
                else {
                    $self->Successful($cb);
                }
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
    }
    else {
        weaken($self);
        my ($data, $stderr, @rollovers);
        my $skip = 2;
        Lim::Util::run_cmd
            [
                'ods-ksmutil', 'rollover', 'list'
            ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $data .= $_[0];
                    
                    $cb->reset_timeout;
                    
                    while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                        my $line = $1;
                        
                        if ($skip) {
                            $skip--;
                            next;
                        }
                        
                        if ($line =~ /^(\S+)\s+(\S+)\s+(\S+\s+\S+)$/o) {
                            push(@rollovers, {
                                name => $1,
                                keytype => $2,
                                rollover_expected => $3
                            });
                        }
                    }
                }
            },
            '2>', \$stderr,
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to get Enforcer rollover list');
                    return;
                }
                elsif (scalar @rollovers == 1) {
                    $self->Successful($cb, { zone => $rollovers[0] });
                }
                elsif (scalar @rollovers) {
                    $self->Successful($cb, { zone => \@rollovers });
                }
                else {
                    $self->Successful($cb);
                }
            };
    }
}

=head2 CreateEnforcerDatabaseBackup

=cut

sub CreateEnforcerDatabaseBackup {
    my ($self, $cb) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    # TODO is there a way to send the database as base64 incrementaly to avoid hogning memory?
    
    weaken($self);
    my ($stdout, $stderr);
    Lim::Util::run_cmd [ 'ods-ksmutil', 'database', 'backup' ],
        '<', '/dev/null',
        '>', sub {
            if (defined $_[0]) {
                $cb->reset_timeout;
                $stdout .= $_[0];
            }
        },
        '2>', \$stderr,
        timeout => 30,
        cb => sub {
            unless (defined $self) {
                return;
            }
            if (shift->recv) {
                $self->Error($cb, 'Unable to backup Enforcer database');
                return;
            }
            $self->Successful($cb);
        };
}

=head2 ReadEnforcerZonelistExport

=cut

sub ReadEnforcerZonelistExport {
    my ($self, $cb) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    # TODO is there a way to send the database as base64 incrementaly to avoid hogning memory?
    
    weaken($self);
    my ($stdout, $stderr);
    Lim::Util::run_cmd [ 'ods-ksmutil', 'zonelist', 'export' ],
        '<', '/dev/null',
        '>', sub {
            if (defined $_[0]) {
                $cb->reset_timeout;
                $stdout .= $_[0];
            }
        },
        '2>', \$stderr,
        timeout => 30,
        cb => sub {
            unless (defined $self) {
                return;
            }
            if (shift->recv) {
                $self->Error($cb, 'Unable to export zonelist');
                return;
            }
            $self->Successful($cb, { zonelist => $stdout });
        };
}

=head2 ReadSigner

=cut

sub ReadSigner {
    my ($self, $cb) = @_;

    $self->Successful($cb);
}

=head2 UpdateSigner

=cut

sub UpdateSigner {
    my ($self, $cb) = @_;

    $self->Successful($cb);
}

=head2 ReadSignerZones

=cut

sub ReadSignerZones {
    my ($self, $cb) = @_;

    unless ($self->{bin}->{signer}) {
        $self->Error($cb, 'No "ods-signer" executable found or unsupported version, unable to continue');
        return;
    }

    weaken($self);
    my ($data, $stderr, @zones);
    Lim::Util::run_cmd [ 'ods-signer', 'zones' ],
        '<', '/dev/null',
        '>', sub {
            if (defined $_[0]) {
                $data .= $_[0];
                
                $cb->reset_timeout;
                
                while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                    my $line = $1;
                    
                    if ($line =~ /^-\s+(\S+)$/o) {
                        push(@zones, {
                            name => $1
                        });
                    }
                }
            }
        },
        '2>', \$stderr,
        timeout => 30,
        cb => sub {
            unless (defined $self) {
                return;
            }
            if (shift->recv) {
                $self->Error($cb, 'Unable to get Signer zones');
                return;
            }
            elsif (scalar @zones == 1) {
                $self->Successful($cb, { zone => $zones[0] });
            }
            elsif (scalar @zones) {
                $self->Successful($cb, { zone => \@zones });
            }
            else {
                $self->Successful($cb);
            }
        };
}

=head2 UpdateSignerSign

=cut

sub UpdateSignerSign {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{signer}) {
        $self->Error($cb, 'No "ods-signer" executable found or unsupported version, unable to continue');
        return;
    }

    if (exists $q->{zone}) {
        my @zones = ref($q->{zone}) eq 'ARRAY' ? @{$q->{zone}} : ($q->{zone});
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $zone = shift(@zones)) {
                my ($stdout, $stderr);
                Lim::Util::run_cmd
                    [
                        'ods-signer', 'sign', $zone->{name}
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $cb->reset_timeout;
                            $stdout .= $_[0];
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to issue sign to Signer for zone ', $zone->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                $self->Successful($cb);
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
    }
    else {
        weaken($self);
        my ($stdout, $stderr);
        Lim::Util::run_cmd
            [
                'ods-signer', 'sign', '--all'
            ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $cb->reset_timeout;
                    $stdout .= $_[0];
                }
            },
            '2>', \$stderr,
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to issue sign to Signer for all zones');
                    return;
                }
                $self->Successful($cb);
            };
    }
}

=head2 UpdateSignerClear

=cut

sub UpdateSignerClear {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{signer}) {
        $self->Error($cb, 'No "ods-signer" executable found or unsupported version, unable to continue');
        return;
    }

    my @zones = ref($q->{zone}) eq 'ARRAY' ? @{$q->{zone}} : ($q->{zone});
    weaken($self);
    my $cmd_cb; $cmd_cb = sub {
        unless (defined $self) {
            undef($cmd_cb);
            return;
        }
        if (my $zone = shift(@zones)) {
            my ($stdout, $stderr);
            Lim::Util::run_cmd
                [
                    'ods-signer', 'clear', $zone->{name}
                ],
                '<', '/dev/null',
                '>', sub {
                    if (defined $_[0]) {
                        $cb->reset_timeout;
                        $stdout .= $_[0];
                    }
                },
                '2>', \$stderr,
                timeout => 30,
                cb => sub {
                    unless (defined $self) {
                        undef($cmd_cb);
                        return;
                    }
                    if (shift->recv) {
                        $self->Error($cb, 'Unable to issue clear to Signer for zone ', $zone->{name});
                        undef($cmd_cb);
                        return;
                    }
                    $cmd_cb->();
                };
        }
        else {
            $self->Successful($cb);
            undef($cmd_cb);
        }
    };
    $cmd_cb->();
}

=head2 ReadSignerQueue

=cut

sub ReadSignerQueue {
    my ($self, $cb) = @_;

    unless ($self->{bin}->{signer}) {
        $self->Error($cb, 'No "ods-signer" executable found or unsupported version, unable to continue');
        return;
    }

    weaken($self);
    my ($data, $stderr, @task, $now);
    Lim::Util::run_cmd [ 'ods-signer', 'queue' ],
        '<', '/dev/null',
        '>', sub {
            if (defined $_[0]) {
                $data .= $_[0];
                
                $cb->reset_timeout;
                
                while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                    my $line = $1;
                    
                    if ($line =~ /^It\s+is\s+now\s+(.+)$/o) {
                        $now = $1;
                    }
                    elsif ($line =~ /On\s+(.+)\s+I\s+will\s+\[([^\]]+)\]\s+zone\s+(.+)/o) {
                        push(@task, {
                            type => $2,
                            date => $1,
                            zone => $3
                        });
                    }
                }
            }
        },
        '2>', \$stderr,
        timeout => 30,
        cb => sub {
            unless (defined $self) {
                return;
            }
            if (shift->recv) {
                $self->Error($cb, 'Unable to get Signer queue');
                return;
            }
            elsif (scalar @task == 1) {
                $self->Successful($cb, { now => $now, task => $task[0] });
            }
            elsif (scalar @task) {
                $self->Successful($cb, { now => $now, task => \@task });
            }
            else {
                $self->Successful($cb);
            }
        };
}

=head2 UpdateSignerFlush

=cut

sub UpdateSignerFlush {
    my ($self, $cb) = @_;

    unless ($self->{bin}->{signer}) {
        $self->Error($cb, 'No "ods-signer" executable found or unsupported version, unable to continue');
        return;
    }

    weaken($self);
    my ($stdout, $stderr);
    Lim::Util::run_cmd [ 'ods-signer', 'flush' ],
        '<', '/dev/null',
        '>', sub {
            if (defined $_[0]) {
                $cb->reset_timeout;
                $stdout .= $_[0];
            }
        },
        '2>', \$stderr,
        timeout => 30,
        cb => sub {
            unless (defined $self) {
                return;
            }
            if (shift->recv) {
                $self->Error($cb, 'Unable to issue flush to Signer');
                return;
            }
            $self->Successful($cb);
        };
}

=head2 UpdateSignerUpdate

=cut

sub UpdateSignerUpdate {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{signer}) {
        $self->Error($cb, 'No "ods-signer" executable found or unsupported version, unable to continue');
        return;
    }

    if (exists $q->{zone}) {
        my @zones = ref($q->{zone}) eq 'ARRAY' ? @{$q->{zone}} : ($q->{zone});
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $zone = shift(@zones)) {
                my ($stdout, $stderr);
                Lim::Util::run_cmd
                    [
                        'ods-signer', 'update', $zone->{name}
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $cb->reset_timeout;
                            $stdout .= $_[0];
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to issue update to Signer for zone ', $zone->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                $self->Successful($cb);
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
    }
    else {
        weaken($self);
        my ($stdout, $stderr);
        Lim::Util::run_cmd
            [
                'ods-signer', 'update', '--all'
            ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $cb->reset_timeout;
                    $stdout .= $_[0];
                }
            },
            '2>', \$stderr,
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to issue update to Signer for all zones');
                    return;
                }
                $self->Successful($cb);
            };
    }
}

=head2 ReadSignerRunning

=cut

sub ReadSignerRunning {
    my ($self, $cb) = @_;

    unless ($self->{bin}->{signer}) {
        $self->Error($cb, 'No "ods-signer" executable found or unsupported version, unable to continue');
        return;
    }

    weaken($self);
    my ($stdout, $stderr);
    Lim::Util::run_cmd [ 'ods-signer', 'running' ],
        '<', '/dev/null',
        '>', sub {
            if (defined $_[0]) {
                $cb->reset_timeout;
                $stdout .= $_[0];
            }
        },
        '2>', \$stderr,
        timeout => 30,
        cb => sub {
            unless (defined $self) {
                return;
            }
            if ($stderr =~ /Engine\s+not\s+running/o) {
                $self->Successful($cb, { running => 0 });
                return;
            }
            if (shift->recv) {
                $self->Error($cb, 'Unable to issue running to Signer');
                return;
            }
            $self->Successful($cb, { running => 1 });
        };
}

=head2 UpdateSignerReload

=cut

sub UpdateSignerReload {
    my ($self, $cb) = @_;

    unless ($self->{bin}->{signer}) {
        $self->Error($cb, 'No "ods-signer" executable found or unsupported version, unable to continue');
        return;
    }

    weaken($self);
    my ($stdout, $stderr);
    Lim::Util::run_cmd [ 'ods-signer', 'reload' ],
        '<', '/dev/null',
        '>', sub {
            if (defined $_[0]) {
                $cb->reset_timeout;
                $stdout .= $_[0];
            }
        },
        '2>', \$stderr,
        timeout => 30,
        cb => sub {
            unless (defined $self) {
                return;
            }
            if (shift->recv) {
                $self->Error($cb, 'Unable to issue reload to Signer');
                return;
            }
            $self->Successful($cb);
        };
}

=head2 UpdateSignerVerbosity

=cut

sub UpdateSignerVerbosity {
    my ($self, $cb, $q) = @_;

    unless ($self->{bin}->{signer}) {
        $self->Error($cb, 'No "ods-signer" executable found or unsupported version, unable to continue');
        return;
    }

    weaken($self);
    my ($stdout, $stderr);
    Lim::Util::run_cmd [ 'ods-signer', 'verbosity', $q->{verbosity} ],
        '<', '/dev/null',
        '>', sub {
            if (defined $_[0]) {
                $cb->reset_timeout;
                $stdout .= $_[0];
            }
        },
        '2>', \$stderr,
        timeout => 30,
        cb => sub {
            unless (defined $self) {
                return;
            }
            if (shift->recv) {
                $self->Error($cb, 'Unable to issue verbosity ', $q->{verbosity}, ' to Signer');
                return;
            }
            $self->Successful($cb);
        };
}

=head2 CreateHsm

=cut

sub CreateHsm {
    my ($self, $cb) = @_;

    $self->Successful($cb);
}

=head2 ReadHsm

=cut

sub ReadHsm {
    my ($self, $cb) = @_;

    $self->Successful($cb);
}

=head2 DeleteHsm

=cut

sub DeleteHsm {
    my ($self, $cb) = @_;

    $self->Successful($cb);
}

=head2 ReadHsmList

=cut

sub ReadHsmList {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{hsmutil}) {
        $self->Error($cb, 'No "ods-hsmutil" executable found or unsupported version, unable to continue');
        return;
    }

    if (exists $q->{repository}) {
        my @repositories = ref($q->{repository}) eq 'ARRAY' ? @{$q->{repository}} : ($q->{repository});
        my @keys;
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $repository = shift(@repositories)) {
                my ($data, $stderr);
                my $skip = 5;
                Lim::Util::run_cmd
                    [
                        'ods-hsmutil', 'list', $repository->{name}
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $data .= $_[0];
                            
                            $cb->reset_timeout;
                            
                            while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                                my $line = $1;
                                
                                if ($skip) {
                                    $skip--;
                                    next;
                                }
                                
                                if ($line =~ /^(\S+)\s+(\S+)\s+(\w+)\/(\d+)\s*$/o) {
                                    push(@keys, {
                                        repository => $1,
                                        id => $2,
                                        keytype => $3,
                                        keysize => $4
                                    });
                                }
                            }
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to get hsm key list for repository ', $repository->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                if (scalar @keys == 1) {
                    $self->Successful($cb, { key => $keys[0] });
                }
                elsif (scalar @keys) {
                    $self->Successful($cb, { key => \@keys });
                }
                else {
                    $self->Successful($cb);
                }
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
    }
    else {
        weaken($self);
        my ($data, $stderr, @keys);
        my $skip = 5;
        Lim::Util::run_cmd
            [
                'ods-hsmutil', 'list'
            ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $data .= $_[0];
                    
                    $cb->reset_timeout;
                    
                    while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                        my $line = $1;
                        
                        if ($skip) {
                            $skip--;
                            next;
                        }
                        
                        if ($line =~ /^(\S+)\s+(\S+)\s+(\w+)\/(\d+)\s*$/o) {
                            push(@keys, {
                                repository => $1,
                                id => $2,
                                keytype => $3,
                                keysize => $4
                            });
                        }
                    }
                }
            },
            '2>', \$stderr,
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to get hsm key list');
                    return;
                }
                if (scalar @keys == 1) {
                    $self->Successful($cb, { key => $keys[0] });
                }
                elsif (scalar @keys) {
                    $self->Successful($cb, { key => \@keys });
                }
                else {
                    $self->Successful($cb);
                }
            };
    }
}

=head2 CreateHsmGenerate

=cut

sub CreateHsmGenerate {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{hsmutil}) {
        $self->Error($cb, 'No "ods-hsmutil" executable found or unsupported version, unable to continue');
        return;
    }

    my @keys = ref($q->{key}) eq 'ARRAY' ? @{$q->{key}} : ($q->{key});
    my @generated;
    weaken($self);
    my $cmd_cb; $cmd_cb = sub {
        unless (defined $self) {
            undef($cmd_cb);
            return;
        }
        if (my $key = shift(@keys)) {
            my ($data, $stderr, $bits, $keytype, $repository, $id);
            Lim::Util::run_cmd
                [
                    'ods-hsmutil', 'generate', $key->{repository}, 'rsa', $key->{keysize}
                ],
                '<', '/dev/null',
                '>', sub {
                    if (defined $_[0]) {
                        $data .= $_[0];
                        
                        $cb->reset_timeout;
                        
                        while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                            my $line = $1;
                            
                            if ($line =~ /^Generating\s+(\d+)\s+bit\s+(\w+)\s+key\s+in\s+repository:\s+(.+)$/o) {
                                ($bits, $keytype, $repository) = ($1, $2, $3);
                            }
                            elsif ($line =~ /^Key\s+generation\s+successful:\s+(\S+)$/o) {
                                $id = $1;
                            }
                        }
                    }
                },
                '2>', \$stderr,
                timeout => 30,
                cb => sub {
                    unless (defined $self) {
                        undef($cmd_cb);
                        return;
                    }
                    if (shift->recv) {
                        $self->Error($cb, 'Unable to generate hsm key in repository ', $key->{name});
                        undef($cmd_cb);
                        return;
                    }
                    push(@generated, {
                        repository => $repository,
                        id => $id,
                        keytype => $keytype,
                        keysize => $bits
                    });
                    $cmd_cb->();
                };
        }
        else {
            if (scalar @generated == 1) {
                $self->Successful($cb, { key => $generated[0] });
            }
            elsif (scalar @generated) {
                $self->Successful($cb, { key => \@generated });
            }
            else {
                $self->Successful($cb);
            }
            undef($cmd_cb);
        }
    };
    $cmd_cb->();
}

=head2 DeleteHsmRemove

=cut

sub DeleteHsmRemove {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{hsmutil}) {
        $self->Error($cb, 'No "ods-hsmutil" executable found or unsupported version, unable to continue');
        return;
    }

    my @keys = ref($q->{key}) eq 'ARRAY' ? @{$q->{key}} : ($q->{key});
    weaken($self);
    my $cmd_cb; $cmd_cb = sub {
        unless (defined $self) {
            undef($cmd_cb);
            return;
        }
        if (my $key = shift(@keys)) {
            my ($stdout, $stderr);
            Lim::Util::run_cmd
                [
                    'ods-hsmutil', 'remove', $key->{id}
                ],
                '<', '/dev/null',
                '>', sub {
                    if (defined $_[0]) {
                        $cb->reset_timeout;
                        $stdout .= $_[0];
                    }
                },
                '2>', \$stderr,
                timeout => 30,
                cb => sub {
                    unless (defined $self) {
                        undef($cmd_cb);
                        return;
                    }
                    if (shift->recv) {
                        $self->Error($cb, 'Unable to remove hsm key id ', $key->{id});
                        undef($cmd_cb);
                        return;
                    }
                    $cmd_cb->();
                };
        }
        else {
            $self->Successful($cb);
            undef($cmd_cb);
        }
    };
    $cmd_cb->();
}

=head2 DeleteHsmPurge

=cut

sub DeleteHsmPurge {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{hsmutil}) {
        $self->Error($cb, 'No "ods-hsmutil" executable found or unsupported version, unable to continue');
        return;
    }

    my @repositories = ref($q->{repository}) eq 'ARRAY' ? @{$q->{repository}} : ($q->{repository});
    weaken($self);
    my $cmd_cb; $cmd_cb = sub {
        unless (defined $self) {
            undef($cmd_cb);
            return;
        }
        if (my $repository = shift(@repositories)) {
            my ($stdout, $stderr, $stdin);
            $stdin = "YES\015";
            Lim::Util::run_cmd
                [
                    'ods-hsmutil', 'purge', $repository->{name}
                ],
                '<', \$stdin,
                '>', sub {
                    if (defined $_[0]) {
                        $cb->reset_timeout;
                        $stdout .= $_[0];
                    }
                },
                '2>', \$stderr,
                timeout => 30,
                cb => sub {
                    unless (defined $self) {
                        undef($cmd_cb);
                        return;
                    }
                    if (shift->recv) {
                        $self->Error($cb, 'Unable to purge hsm repository ', $repository->{name});
                        undef($cmd_cb);
                        return;
                    }
                    $cmd_cb->();
                };
        }
        else {
            $self->Successful($cb);
            undef($cmd_cb);
        }
    };
    $cmd_cb->();
}

=head2 CreateHsmDnskey

=cut

sub CreateHsmDnskey {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{hsmutil}) {
        $self->Error($cb, 'No "ods-hsmutil" executable found or unsupported version, unable to continue');
        return;
    }

    my @keys = ref($q->{key}) eq 'ARRAY' ? @{$q->{key}} : ($q->{key});
    my @dnskeys;
    weaken($self);
    my $cmd_cb; $cmd_cb = sub {
        unless (defined $self) {
            undef($cmd_cb);
            return;
        }
        if (my $key = shift(@keys)) {
            my ($stdout, $stderr);
            Lim::Util::run_cmd
                [
                    'ods-hsmutil', 'dnskey', $key->{id}, $key->{name}
                ],
                '<', '/dev/null',
                '>', sub {
                    if (defined $_[0]) {
                        $cb->reset_timeout;
                        $stdout .= $_[0];
                    }
                },
                '2>', \$stderr,
                timeout => 30,
                cb => sub {
                    unless (defined $self) {
                        undef($cmd_cb);
                        return;
                    }
                    if (shift->recv) {
                        $self->Error($cb, 'Unable to remove hsm key id ', $key->{id});
                        undef($cmd_cb);
                        return;
                    }
                    $stdout =~ s/[\r\n].*//o;
                    push(@dnskeys, {
                        id => $key->{id},
                        name => $key->{name},
                        rr => $stdout
                    });
                    $cmd_cb->();
                };
        }
        else {
            if (scalar @dnskeys == 1) {
                $self->Successful($cb, { key => $dnskeys[0] });
            }
            elsif (scalar @dnskeys) {
                $self->Successful($cb, { key => \@dnskeys });
            }
            else {
                $self->Successful($cb);
            }
            undef($cmd_cb);
        }
    };
    $cmd_cb->();
}

=head2 ReadHsmTest

=cut

sub ReadHsmTest {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{hsmutil}) {
        $self->Error($cb, 'No "ods-hsmutil" executable found or unsupported version, unable to continue');
        return;
    }

    my @repositories = ref($q->{repository}) eq 'ARRAY' ? @{$q->{repository}} : ($q->{repository});
    weaken($self);
    my $cmd_cb; $cmd_cb = sub {
        unless (defined $self) {
            undef($cmd_cb);
            return;
        }
        if (my $repository = shift(@repositories)) {
            my ($stdout, $stderr);
            Lim::Util::run_cmd
                [
                    'ods-hsmutil', 'test', $repository->{name}
                ],
                '<', '/dev/null',
                '>', sub {
                    if (defined $_[0]) {
                        $cb->reset_timeout;
                        $stdout .= $_[0];
                    }
                },
                '2>', \$stderr,
                timeout => 30,
                cb => sub {
                    unless (defined $self) {
                        undef($cmd_cb);
                        return;
                    }
                    if (shift->recv) {
                        $self->Error($cb, 'Unable to test hsm repository ', $repository->{name});
                        undef($cmd_cb);
                        return;
                    }
                    $cmd_cb->();
                };
        }
        else {
            $self->Successful($cb);
            undef($cmd_cb);
        }
    };
    $cmd_cb->();
}

=head2 ReadHsmInfo

=cut

sub ReadHsmInfo {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{hsmutil}) {
        $self->Error($cb, 'No "ods-hsmutil" executable found or unsupported version, unable to continue');
        return;
    }

    my @repositories;
    weaken($self);
    my ($data, $stderr, $repository);
    Lim::Util::run_cmd
        [
            'ods-hsmutil', 'info'
        ],
        '<', '/dev/null',
        '>', sub {
            if (defined $_[0]) {
                $data .= $_[0];
                
                $cb->reset_timeout;
                
                while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                    my $line = $1;
                    if ($line =~ /^Repository:\s+(.+)$/o) {
                        my $name = $1;
                        if (defined $repository) {
                            foreach (qw(name module slot token_label manufacturer model serial)) {
                                unless (exists $repository->{$_}) {
                                    undef($repository);
                                    last;
                                }
                            }
                            if (defined $repository) {
                                push(@repositories, $repository);
                            }
                        }
                        $repository = {
                            name => $name
                        };
                    }
                    elsif ($line =~ /Module:\s+(.+)$/o) {
                        $repository->{module} = $1;
                    }
                    elsif ($line =~ /Slot:\s+(\d+)$/o) {
                        $repository->{slot} = $1;
                    }
                    # TODO spaces in names?
                    elsif ($line =~ /Token\s+Label:\s+(\S+)/o) {
                        $repository->{token_label} = $1;
                    }
                    elsif ($line =~ /Manufacturer:\s+(\S+)/o) {
                        $repository->{manufacturer} = $1;
                    }
                    elsif ($line =~ /Model:\s+(\S+)/o) {
                        $repository->{model} = $1;
                    }
                    elsif ($line =~ /Serial:\s+(\S+)/o) {
                        $repository->{serial} = $1;
                    }
                }
            }
        },
        '2>', \$stderr,
        timeout => 30,
        cb => sub {
            unless (defined $self) {
                return;
            }
            if (shift->recv) {
                $self->Error($cb, 'Unable to get hsm repository info');
                return;
            }
            if (defined $repository) {
                foreach (qw(name module slot token_label manufacturer model serial)) {
                    unless (exists $repository->{$_}) {
                        undef($repository);
                        last;
                    }
                }
                if (defined $repository) {
                    push(@repositories, $repository);
                }
            }
            if (scalar @repositories == 1) {
                $self->Successful($cb, { repository => $repositories[0] });
            }
            elsif (scalar @repositories) {
                $self->Successful($cb, { repository => \@repositories });
            }
            else {
                $self->Successful($cb);
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

Copyright 2012-2013 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::Plugin::OpenDNSSEC::Server
