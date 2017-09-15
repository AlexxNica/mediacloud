#!/usr/bin/env perl

# see MediaWords::DB::Schema for definition of which functions to add

use strict;
use warnings;

use MediaWords::DB;
use Modern::Perl "2015";
use MediaWords::CommonLibs;

use MediaWords::DB::Schema;

use Term::Prompt;
use Data::Dumper;

#why isn't this module on CPAN
sub string_starts_with
{
    my ( $string, $sub_string ) = @_;

    my $index_result = index( $string, $sub_string );

    return $index_result == 0;
}

sub main
{
    my $warning_message = "Warning this script will take a very long time. Are you sure you wish to continue?";

    my $continue_and_reset_db = &prompt( "y", $warning_message, "", "n" );

    exit if !$continue_and_reset_db;

    my $db = MediaWords::DB::connect_to_db;

    my $index_hashes = $db->query(
"select p.relname from pg_class p, pg_stat_user_indexes pg where pg.indexrelname = p.relname order by p.relpages desc;  "
    )->hashes;

    my @indexes = map { $_->{ relname } } @$index_hashes;

    TRACE Dumper( [ @indexes ] );

    my $non_reindexed_prefixes = [ qw ( downloads_ stories_ ) ];

    foreach my $non_reindexed_prefix ( @$non_reindexed_prefixes )
    {
        @indexes = grep { !string_starts_with( $_, $non_reindexed_prefix ) } @indexes;
    }

    TRACE Dumper( [ @indexes ] );

    foreach my $index ( @indexes )
    {
        ### [<now>] REINDEXing ;
        ### $index
        $db->query( "REINDEX INDEX $index" );
    }
}

main();
