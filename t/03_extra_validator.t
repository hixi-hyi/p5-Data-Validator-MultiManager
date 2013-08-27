#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More;
use Test::Deep;

use Data::Validator::MultiManager;

my $manager = Data::Validator::MultiManager->new('Data::Validator::Recursive');
$manager->add(
    nest => {
        human => {
            rule => [
                name => { isa => 'Str' },
                age  => { isa => 'Int' },
            ]
        },
    },
    flat => {
        name => { isa => 'Str' },
        age  => { isa => 'Int' },
    },
);

subtest 'nest' => sub {
    $manager->validate({
        human => {
            name => 'hixi',
            age  => 24,
        },
    });
    ok $manager->is_success;
    ok $manager->is_success('nest');
    is_deeply $manager->get_success, ['nest'];

    ok not $manager->is_success('flat');
};

subtest 'flat' => sub {
    $manager->validate({
        name => 'hixi',
        age  => 24,
    });
    ok $manager->is_success;
    ok $manager->is_success('flat');
    is_deeply $manager->get_success, ['flat'];


    ok not $manager->is_success('nest');
};

subtest 'fail' => sub {
    $manager->validate({ id => 'aaa' });
    ok not $manager->is_success;
    ok not $manager->is_success('nest');
    ok not $manager->is_success('flat');

};

done_testing;
