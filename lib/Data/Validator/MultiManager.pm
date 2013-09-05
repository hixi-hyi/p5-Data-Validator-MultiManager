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
        validators      => {},
        common          => {},
        success         => [],
        errors          => {},
    }, $class;
}

sub add {
    my ($self, @args) = @_;
    croak 'must be specified key-value pair' unless @args && scalar @args % 2 == 0;
    my %pairs = @args;

    while (my ($name, $rule) = each %pairs) {
        my %merged_rule = (%{clone $self->{common}}, %$rule);
        my $validator = $self->{validator_class}->new(%merged_rule);
        $validator->with('NoThrow');
        $self->{validators}->{$name} = $validator;
    }
}

sub set_common {
    my ($self, %rule) = @_;
    $self->{common} = \%rule;
}

sub validate {
    my ($self, $param) = @_;

    my $object = Data::Validator::MultiManager::Object->new;

    my %args;
    for my $name (keys %{$self->{validators}}) {
        my $validator = $self->{validators}->{$name};
        $args{$name} = $validator->validate($param);
        $self->_after_validate($name, $validator->clear_errors);
    }
    return \%args;
}

sub validate_by {
    my ($self, $name, $param) = @_;
    $self->_reset;

    my $validator = $self->{validators}->{$name};
    my $args = $validator->validate($param);
    $self->_after_validate($name, $validator->clear_errors);
    return $args;
}

sub _after_validate {
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

sub is_success {
    my ($self, $name) = @_;

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

sub is_xor {
    my $self = shift;
    return (scalar @{$self->get_success} == 1)? 1: 0;
}

sub get_success {
    my $self = shift;
    return $self->{success};
}

sub error {
    my ($self, $name) = @_;

    my $errors = $self->errors($name) or return {};
    return $errors->[0];
}

sub errors {
    my ($self, $name) = @_;
    if ($name) {
        return $self->{errors}->{$name} || [];
    }
    else {
        return [ map { @{$_} } values $self->{errors} ] || [];
    }
}

package
    Data::Validator::MultiManager::Object;

sub new {
    my $class = shift;

    bless {
        success => [],
        errors  => {},
        result  => {},
    }, $class;
}

sub set {
    my ($self, $tag, $result, $errors) = @_;

    $self->set_result($tag, $result);

    if ($errors) {
        $self->set_error($tag, $errors);
    }
    else {
        $self->set_success($tag);
    }
}

sub set_result {
    my ($self, $tag, $result) = @_;
    $self->{result}->{$tag} = $result;
}

sub set_error {
    my ($self, $tag, $errors) = @_;
    $self->{errors}->{$tag} = $errors;
}

sub set_success {
    my ($self, $tag) = @_;
    push $self->{success}, $tag;
}

sub is_success {
    my ($self, $tag) = @_;

    if ($tag) {
        if (exists $self->{errors}->{$tag}) {
            return 0;
        }
        return 1;
    }

    if (0 < scalar @{$self->{success}}) {
        return 1;
    }
    return 0;
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

