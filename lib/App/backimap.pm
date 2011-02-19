package App::backimap;
# ABSTRACT: backups imap mail

use strict;
use warnings;

use URI;
use App::backimap::Utils qw( imap_uri_split );
use Data::Dump           qw( dump );
use IO::Prompt           qw( prompt );
use Mail::IMAPClient;

=method new

Creates a new program instance with command line arguments.

=cut

sub new {
    my ( $class, @argv ) = @_;

    my %opt;
    $opt{'args'} = \@argv;

    return bless \%opt, $class;
}

=method run

Parses command line arguments and starts the program.

=cut

sub run {
    my ($self) = @_;

    my ($str) = @{ $self->{'args'} };

    my $uri = URI->new($str);
    my $imap_cfg = imap_uri_split($uri);
    dump $imap_cfg;

    $imap_cfg->{'password'} = prompt('Password: ', -te => '*' )
        unless defined $imap_cfg->{'password'};

    my $imap = Mail::IMAPClient->new(
        Server   => $imap_cfg->{'host'},
        Port     => $imap_cfg->{'port'},
        Ssl      => $imap_cfg->{'secure'},
        User     => $imap_cfg->{'user'},
        Password => $imap_cfg->{'password'},

        # enable imap uid per folder
        Uid => 1,
    );

    my $path = $imap_cfg->{'path'};
    $path =~ s#^/+##;

    my @folders = $path ne '' ? $path : $imap->folders;

    my %count_for;
    for my $f (@folders) {
        my $count  = $imap->message_count($f);
        next unless defined $count;

        my $unseen = $imap->unseen_count($f);
        $count_for{$f}{'count'}  = $count;
        $count_for{$f}{'unseen'} = $unseen;
    }
    dump \%count_for;

    $imap->logout;
}

1;
