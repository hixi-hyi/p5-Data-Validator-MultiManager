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
    $manager->validate({ id => [1, 2] });
    ok $manager->is_success;

    is_deeply $manager->get_success, ['collection'];
    ok $manager->is_success('collection');
    is_deeply $manager->errors('collection'), [];

    ok not $manager->is_success('entry');
    cmp_deeply $manager->error('entry'), superhashof( { name => 'id', type => 'InvalidValue' } );
};

subtest 'entry' => sub {
    $manager->validate({ id => 1 });
    ok $manager->is_success;

    is_deeply $manager->get_success, ['entry'];
    ok $manager->is_success('entry');
    is_deeply $manager->errors('entry'), [];

    ok not $manager->is_success('collection');
    cmp_deeply $manager->error('collection'), superhashof( { name => 'id', type => 'InvalidValue' } );
};

subtest 'fail' => sub {
    my $param =$manager->validate({ id => 'aaa' });
    use Data::Dumper::Names; printf("[%s]\n%s \n",(caller 0)[3],Dumper($param));
    ok not $manager->is_success;

    ok not $manager->is_success('entry');
    ok not $manager->is_success('collection');

    cmp_deeply $manager->error('entry'), superhashof( { name => 'id', type => 'InvalidValue' } );
    cmp_deeply $manager->error('collection'), superhashof( { name => 'id', type => 'InvalidValue' } );
};

done_testing;
