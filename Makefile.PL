use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Lim::Plugin::OpenDNSSEC',
    AUTHOR              => q{Jerry Lundström <lundstrom.jerry@gmail.com>},
    VERSION_FROM        => 'lib/Lim/Plugin/OpenDNSSEC.pm',
    ABSTRACT_FROM       => 'lib/Lim/Plugin/OpenDNSSEC.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PREREQ_PM => {
        'Test::More' => 0,
        'common::sense' => 3,
        'Digest::SHA' => 5,
        'Getopt::Long' => 2,
        'Pod::Usage' => 1,
        'Lim' => 0.1,
        'Scalar::Util' => 1
    },
    (! eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () :
        (META_ADD => {
            resources => {
                homepage   => 'http://github.com/jelu/lim/wiki',
                repository => 'http://github.com/jelu/lim',
                bugtracker => 'http://github.com/jelu/lim/issues',
            },
        })
    ),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Lim-Plugin-OpenDNSSEC-*' },
);
