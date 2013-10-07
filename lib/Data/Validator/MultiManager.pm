package Data::Validator::MultiManager;
use 5.008005;
use strict;
use warnings;

use Carp qw(croak);
use Clone qw(clone);

our $VERSION = "0.01";

sub new {
    my ($class, $validator) = @_;

    $validator ||= 'Data::Validator';
    _load_class($validator);

    bless {
        validator_class => $validator,
        priority        => [],
        validators      => {},
        common          => {},
        errors          => {},
        valid           => '',
    }, $class;
}

sub add {
    my ($self, @args) = @_;
    croak 'must be specified key-value pair' unless @args && scalar @args % 2 == 0;

    while (my ($tag, $rule) = splice @args, 0, 2) {
        my %merged_rule = (%{clone $self->{common}}, %$rule);
        my $validator = $self->{validator_class}->new(%merged_rule);
        $validator->with('NoThrow');

        push @{$self->{priority}}, $tag;
        $self->{validators}->{$tag} = $validator;
    }
}

sub common {
    my ($self, %rule) = @_;
    $self->{common} = \%rule;
}

sub validate {
    my ($self, $param) = @_;
    my $result = Data::Validator::MultiManager::Result->new($param, $self->{priority});

    for my $tag (@{$self->{priority}}) {
        my $validator = $self->{validators}->{$tag};
        my $args      = $validator->validate($param);

        if (my $errors = $validator->clear_errors) {
            $result->set_errors($tag, $errors);
        }
        else {
            $result->set_tag($tag);
            $result->set_value($tag, $args);
            return $result;
        }
    }
    return $result;
}

# copy from Plack::Util
sub _load_class {
    my($class, $prefix) = @_;

    if ($prefix) {
        unless ($class =~ s/^\+// || $class =~ /^$prefix/) {
            $class = "$prefix\::$class";
        }
    }

    my $file = $class;
    $file =~ s!::!/!g;
    require "$file.pm"; ## no critic

    return $class;
}

package
    Data::Validator::MultiManager::Result;

sub new {
    my ($class, $original, $priority) = @_;

    my $self = bless {
        priority => $priority,
        errors   => {},
        tag      => '',
        values   => {},
    }, $class;
    $self->set_original($original);
    return $self;
}

sub set_errors {
    my ($self, $tag, $errors) = @_;
    $self->{errors}->{$tag} = $errors;
}

sub set_value {
    my ($self, $tag, $value) = @_;
    $self->{values}->{$tag} = $value;
}

sub set_original {
    my ($self, $value) = @_;
    $self->{values}->{_original} = $value;
}

sub set_tag {
    my ($self, $tag) = @_;
    $self->{tag} = $tag;
}

sub original {
    my $self = shift;
    return $self->{values}->{_original};
}

sub valid {
    my $self = shift;
    return $self->{tag};
}

sub invalid {
    my $self = shift;
    return $self->guess_error_tag_to_match;
}

sub is_valid {
    my $self = shift;
    return ($self->{tag})? 1: 0;
}

sub tag {
    my $self = shift;
    return $self->{tag};
}

sub value {
    my $self = shift;

    my $tag = $self->tag;
    return $self->{values}->{$tag};
}

sub values {
    my $self = shift;
    return $self->{values};
}

sub error {
    my ($self, $tag) = @_;

    my $errors = $self->errors($tag);

    return undef unless $errors;
    return $errors->[0];
}

sub errors {
    my ($self, $tag) = @_;

    unless ($tag) {
        $tag = $self->guess_error_tag_to_match;
    }
    return $self->{errors}->{$tag} || [];
}

sub guess_error_tag_to_match {
    my ($self) = @_;

    my %diff;
    for my $tag (reverse @{$self->{priority}}) {
        if (my $errors = $self->{errors}->{$tag}) {
            my $error_size     = scalar @$errors;
            $diff{$error_size} = $tag;
        }
    }
    my $min = (sort keys %diff)[0];
    return $diff{$min};
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

