#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More;
use Test::Deep;

use Data::Validator::MultiManager;


subtest 'deplicate' => sub {
    my $manager = Data::Validator::MultiManager->new;
    $manager->add(
        collection => {
            id => { isa => 'ArrayRef' },
        },
        collection2 => {
            id => { isa => 'ArrayRef' },
        },
    );
    $manager->validate({ id => [1, 2] });

    ok not $manager->is_xor;
    is scalar @{$manager->get_success}, 2;
};

subtest 'independent' => sub {
    my $manager = Data::Validator::MultiManager->new;
    $manager->add(
        collection => {
            id => { isa => 'ArrayRef' },
        },
        entry => {
            id => { isa => 'Int' },
        },
    );
    $manager->validate({ id => [1, 2] });

    ok $manager->is_xor;
    is scalar @{$manager->get_success}, 1;
};

done_testing;
