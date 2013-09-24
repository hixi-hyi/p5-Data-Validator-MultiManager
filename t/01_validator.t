#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More;
use Test::Deep;

use Data::Validator;
use Data::Validator::MultiManager;

my $manager = Data::Validator::MultiManager->new;
$manager->add(
    collection => {
        id => { isa => 'ArrayRef' },
    },
    entry => {
        id => { isa => 'Int' },
    },
);

subtest 'collection' => sub {
    my $p = $manager->validate({ id => [1, 2] });

    is $manager->valid, 'collection';
    ok not exists $p->{entry};
    ok exists $p->{collection};
};

subtest 'entry' => sub {
    my $p = $manager->validate({ id => 1 });

    is $manager->valid, 'entry';
    ok not exists $p->{collection};
    ok exists $p->{entry};
};

subtest 'fail' => sub {
    my $p =$manager->validate({ id => 'aaa' });

    ok not $manager->valid;
    cmp_deeply $manager->error('entry'), superhashof( { name => 'id', type => 'InvalidValue' } );
    cmp_deeply $manager->error('collection'), superhashof( { name => 'id', type => 'InvalidValue' } );
    ok not exists $p->{collection};
    ok not exists $p->{entry};
};

done_testing;
