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
        validators      => [],
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

    for my $rule (@{$self->{validators}}) {
        my ($tag, $validator) = ($rule->{tag}, $rule->{validator});
        my $args              = $validator->validate($param);

        if (my $errors = $validator->clear_errors) {
            $self->{errors}->{$tag} = $errors;
        }
        else {
            $self->_reset;
            $self->{valid} = $tag;
            return {
                $tag      => $args,
                _original => $param,
            };
        }
    }
    return { _original => $param };
}

sub valid {
    my $self = shift;
    return $self->{valid};
}

sub _reset {
    my $self = shift;
    $self->clear_errors;
    $self->{valid} = '';
}

sub clear_errors {
    my $self = shift;
    $self->{errors} = {};
    for my $rule (@{$self->{validators}}) {
        $self->{errors}->{$rule->{tag}} = [];
    }
}

sub error {
    my ($self, $tag) = @_;

    my $errors = $self->errors($tag);

    return undef unless $errors;
    return $errors->[0];
}

sub errors {
    my ($self, $tag) = @_;

    if ($tag) {
        return $self->{errors}->{$tag} || [];
    }
    else {
        return $self->guess_error_to_match || [];
    }
}

sub guess_error_to_match {
    my ($self) = @_;

    my %diff;
    for my $rule (reverse @{$self->{validators}}) {
        my $tag  = $rule->{tag};

        if (my $errors = $self->{errors}->{$tag}) {
            my $error_size     = scalar @$errors;
            $diff{$error_size} = $tag;
        }
    }
    my $min = (sort keys %diff)[0];
    return $self->{errors}->{$diff{$min}};
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

