package Data::Validator::MultiManager;
use 5.008005;
use strict;
use warnings;

use Carp qw(croak);

our $VERSION = "0.01";

sub new {
    my $class = shift;

    bless {
        validators => {},
        common     => undef,
        success    => [],
        errors     => {},
    }, $class;
}

sub add {
    my ($self, @args) = @_;
    croak 'must be specified key-value pair' unless @args && scalar @args % 2 == 0;
    my %pairs = @args;

    while (my ($name, $validator) = each %pairs) {
        $validator->with('NoThrow', 'AllowExtra');
        $self->{validators}->{$name} = $validator;
    }
}

sub set_common {
    my ($self, $validator) = @_;
    $validator->with('NoThrow', 'AllowExtra');
    $self->{common} = $validator;
}

sub validate {
    my ($self, $param) = @_;
    $self->_init;

    if ($self->{common}) {
        $self->{common}->validate($param);
        if (my $errors = $self->{common}->clear_errors) {
            map { push @{$self->{errors}->{common}}, @{$_} } $errors;
            for my $name (keys %{$self->{validators}}) {
                map { push @{$self->{errors}->{$name}}, @{$_} } $errors;
            }
        }
    }

    for my $name (keys %{$self->{validators}}) {
        my $validator = $self->{validators}->{$name};
        $validator->validate($param);
        $self->_after($name, $validator->clear_errors);
    }
}

sub validate_with {
    my ($self, $name, $param) = @_;
    $self->_init;
    my $validator = $self->{validators}->{$name};
    $validator->validate($param);
    $self->_after($name, $validator->clear_errors);
}

sub _init {
    my $self = shift;
    $self->{errors} = {};
    $self->{errors}->{common} = [];
    for my $name (keys $self->{validators}) {
        $self->{errors}->{$name} = [];
    }
    $self->{success} = [];
}

sub _after {
    my ($self, $name, $errors) = @_;
    if ($errors) {
        map { push @{$self->{errors}->{$name}}, @{$_} } $errors;
        return 1;
    }
    else {
        push @{$self->{success}}, $name;
        return 0;
    }
}

sub has_success {
    my ($self, $name) = @_;

    return 0 if @{$self->{errors}->{common}};

    if ($name) {
        if ($self->{validators}->{$name} && not @{$self->{errors}->{$name}}) {
            return 1;
        }
        return 0;
    }

    for my $name (keys $self->{validators}) {
        return 1 unless (@{$self->{errors}->{$name}});
    }
    return 0;
}

sub get_success {
    my $self = shift;
    return $self->{success};
}

sub error {
    my ($self, $name) = @_;

    my $errors = $self->errors($name) or return;
    return $errors->[0];
}

sub errors {
    my ($self, $name) = @_;
    if ($name) {
        return $self->{errors}->{$name} || undef;
    }
    else {
        return [ map { @{$_} } values $self->{errors} ] || undef;
    }
}


1;
__END__

=encoding utf-8

=head1 NAME

Data::Validator::MultiManager - It's new $module

=head1 SYNOPSIS

    use Data::Validator::MultiManager;

=head1 DESCRIPTION

Data::Validator::MultiManager is ...

=head1 LICENSE

Copyright (C) Hiroyoshi Houchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hiroyoshi Houchi E<lt>git@hixi-hyi.comE<gt>

=cut

