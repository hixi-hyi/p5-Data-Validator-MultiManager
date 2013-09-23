package Data::Validator::MultiManager;
use 5.008005;
use strict;
use warnings;

use Carp qw(croak);
use Clone qw(clone);
use Data::Validator;

our $VERSION = "0.01";

sub new {
    my ($class, $validator) = @_;

    $validator ||= 'Data::Validator';

    bless {
        validator_class => $validator,
        validators      => [],
        common          => {},
        success         => [],
        errors          => {},
    }, $class;
}

sub add {
    my ($self, @args) = @_;
    croak 'must be specified key-value pair' unless @args && scalar @args % 2 == 0;
    my %pairs = @args;

    while (my ($tag, $rule) = each %pairs) {
        my %merged_rule = (%{clone $self->{common}}, %$rule);
        my $validator = $self->{validator_class}->new(%merged_rule);
        $validator->with('NoThrow');

        push @{$self->{validators}}, {
            tag       => $tag,
            validator => $validator,
        };
    }
}

sub set_common {
    my ($self, %rule) = @_;
    $self->{common} = \%rule;
}

sub validate {
    my ($self, $param) = @_;
    $self->_reset;

    my %args;
    for my $rule (@{$self->{validators}}) {
        my $tag       = $rule->{tag};
        my $validator = $rule->{validator};
        $args{$tag}   = $validator->validate($param);
        $self->_after_validate($tag, $validator->clear_errors);
    }
    return \%args;
}

sub _reset {
    my $self = shift;
    $self->{errors} = {};
    for my $rule (@{$self->{validators}}) {
        $self->{errors}->{$rule->{tag}} = [];
    }
    $self->{success} = [];
}

sub _after_validate {
    my ($self, $tag, $errors) = @_;
    if ($errors) {
        map { push @{$self->{errors}->{$tag}}, @{$_} } $errors;
        return 1;
    }
    else {
        push @{$self->{success}}, $tag;
        return 0;
    }
}

sub is_success {
    my ($self, $tag) = @_;

    if ($tag) {
        return @{ $self->{errors}->{$tag} } ? 0: 1;
    }

    return (scalar @{$self->get_success} == 0) ? 0: 1;
}

sub get_success {
    my $self = shift;
    return $self->{success};
}

sub is_xor {
    my $self = shift;
    return (scalar @{$self->get_success} == 1) ? 1: 0;
}

sub error {
    my ($self, $tag) = @_;

    my $errors = $self->errors($tag) or return {};
    return $errors->[0];
}

sub errors {
    my ($self, $tag) = @_;

    if ($tag) {
        return $self->{errors}->{$tag} || [];
    }
    else {
        return [ map { @{$_} } values $self->{errors} ] || [];
    }
}


1;
__END__

=encoding utf-8

=head1 NAME

Data::Validator::MultiManager - It's new $module

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Data::Validator::MultiManager is ...

=head1 LICENSE

Copyright (C) Hiroyoshi Houchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hiroyoshi Houchi E<lt>hixi@cpan.orgE<gt>

=cut

