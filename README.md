# NAME

Data::Validator::MultiManager - It's new $module

# SYNOPSIS

    #!/usr/bin/env perl
    use strict;
    use warnings;

    use Data::Validator::MultiManager;

    my $manager = Data::Validator::MultiManager->new;
    # my $manager = Data::Validator::MultiManager->new('Data::Validator::Recursive');
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

    my $param = {
        category => 1,
        id       => [1,2],
    };

    $manager->validate($param);

    if ($manager->is_success) {
        print "success\n";
    }
    if ($manager->is_xor) {
        print "independent validation\n";
    }

    if ($manager->is_success('collection')) {
        print "collection process\n";
    }
    if ($manager->is_success('entry')) {
        print "entry process\n";
    }

# DESCRIPTION

Data::Validator::MultiManager is ...

# LICENSE

Copyright (C) Hiroyoshi Houchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Hiroyoshi Houchi <hixi@cpan.org>
