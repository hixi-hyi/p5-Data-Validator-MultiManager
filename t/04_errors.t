#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More;
use Test::Deep;

use Data::Validator;
use Data::Validator::MultiManager;

my $manager = Data::Validator::MultiManager->new;
$manager->add(
    id => {
        id => { isa => 'Int' },
    },
    name => {
        name    => { isa => 'Str' },
        compony => { isa => 'Str' },
    },
);

subtest 'diff ( id:1 vs name:3 )' => sub {
    my $p = $manager->validate({ id => 'invalid' });
    cmp_deeply $manager->errors, bag(
        superhashof( { name => 'id', type => 'InvalidValue' } ),
    );
};

subtest 'diff ( id:2 vs name:2 ) using order by' => sub {
    my $p = $manager->validate({ name => ['invalid'] });
    cmp_deeply $manager->errors, bag(
        superhashof( { name => 'id',   type => 'MissingParameter' } ),
        superhashof( { name => 'name', type => 'UnknownParameter' } ),
    );
};

subtest 'diff ( id:3 vs name:2 )' => sub {
    my $p = $manager->validate({ name => ['invalid'], compony => ['invalid'] });
    cmp_deeply $manager->errors, bag(
        superhashof( { name => 'name',    type => 'InvalidValue' } ),
        superhashof( { name => 'compony', type => 'InvalidValue' } ),
    );
};

subtest 'diff ( id:1 vs name:2 )' => sub {
    my $p = $manager->validate({});
    cmp_deeply $manager->errors, bag(
        superhashof( { name => 'id', type => 'MissingParameter' } )
    );
};
done_testing;
__END__


