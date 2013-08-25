#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More;
use Test::Deep;

use Data::Validator;
use Data::Validator::MultiManager;

my $manager = Data::Validator::MultiManager->new;
$manager->set_common(
    Data::Validator->new(
        category => { isa => 'Int' },
    ),
);
$manager->add(
    collection => Data::Validator->new(
        id => { isa => 'ArrayRef' },
    ),
    entry => Data::Validator->new(
        id => { isa => 'Int' },
    ),
);

subtest 'collection' => sub {
    $manager->validate({
        category => 1,
        id       => [1,2],
    });
    ok $manager->has_success;

    is_deeply $manager->get_success, ['collection'];
    ok $manager->has_success('collection');
    is_deeply $manager->errors('collection'), [];

    ok not $manager->has_success('entry');
    cmp_deeply $manager->error('entry'), superhashof( { name => 'id', type => 'InvalidValue' } );
};

subtest 'entry' => sub {
    $manager->validate({
        category => 1,
        id       => 1,
    });
    ok $manager->has_success;

    is_deeply $manager->get_success, ['entry'];
    ok $manager->has_success('entry');
    is_deeply $manager->errors('entry'), [];

    ok not $manager->has_success('collection');
    cmp_deeply $manager->error('collection'), superhashof( { name => 'id', type => 'InvalidValue' } );
};

subtest 'fail category' => sub {
    $manager->validate({
        category => 'candy',
        id       => 1,
    });
    ok not $manager->has_success;
    ok not $manager->has_success('entry');
    ok not $manager->has_success('collection');

    cmp_deeply $manager->error('common'), superhashof( { name => 'category', type => 'InvalidValue' } );
    cmp_deeply $manager->error('entry'), superhashof( { name => 'category', type => 'InvalidValue' } );
    cmp_deeply $manager->error('collection'), superhashof( { name => 'category', type => 'InvalidValue' } );
};

done_testing;
