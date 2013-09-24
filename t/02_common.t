#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More;
use Test::Deep;

use Data::Validator::MultiManager;

my $manager = Data::Validator::MultiManager->new;
$manager->set_common(
    category => { isa => 'Int' },
);
$manager->add(
    collection => {
        id => { isa => 'ArrayRef' },
    },
    entry => {
        id => { isa => 'Int' },
    },
);

subtest 'collection' => sub {
    my $p = $manager->validate({
        category => 1,
        id       => [1,2],
    });
    is $manager->valid, 'collection';
    ok exists $p->{collection};
    ok not exists $p->{entry};
};

subtest 'entry' => sub {
    my $p = $manager->validate({
        category => 1,
        id       => 1,
    });
    is $manager->valid, 'entry';
    ok not exists $p->{collection};
    ok exists $p->{entry};
};

subtest 'fail category (entry)' => sub {
    my $p = $manager->validate({
        category => 'candy',
        id       => 1,
    });
    ok not $manager->valid;
    cmp_deeply $manager->error('entry'), superhashof( { name => 'category', type => 'InvalidValue' } );
    ok not exists $p->{collection};
    ok not exists $p->{entry};
};

subtest 'fail category (collection)' => sub {
    my $p = $manager->validate({
        category => 'candy',
        id       => [1],
    });
    ok not $manager->valid;
    cmp_deeply $manager->error('collection'), superhashof( { name => 'category', type => 'InvalidValue' } );
    ok not exists $p->{collection};
    ok not exists $p->{entry};
};

done_testing;
