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
    my $p = $manager->validate({
        human => {
            name => 'hixi',
            age  => 24,
        },
    });
    is $manager->valid, 'nest';
    ok exists $p->{nest};
    ok not exists $p->{flat};
};

subtest 'flat' => sub {
    my $p = $manager->validate({
        name => 'hixi',
        age  => 24,
    });
    is $manager->valid, 'flat';
    ok not exists $p->{nest};
    ok exists $p->{flat};
};

subtest 'fail' => sub {
    my $p = $manager->validate({ id => 'aaa' });
    ok not $manager->valid;
    ok not exists $p->{nest};
    ok not exists $p->{flat};
};

done_testing;
