#!/usr/bin/env perl

# set the given medium to have full_text_rss == true.  reprocess all of the
# stories for the given medium to use the story->{ description } for the
# story sentences

# note that this script does not reprocess any of the aggregation --
# that has to be done separately.

use strict;

use utf8;

use Modern::Perl "2015";
use MediaWords::CommonLibs;

use MediaWords::DB;
use MediaWords::StoryVectors;

sub main
{
    my ( $medium_id ) = @ARGV;

    die( "usage: $0 < medium id >" ) if ( !$medium_id );

    my $db = MediaWords::DB::connect_to_db;

    $db->begin();

    my $medium = $db->find_by_id( 'media', $medium_id ) || die( "Unable to find medium: $medium_id" );

    $medium->{ full_text_rss } = 1;
    $db->update_by_id( 'media', $medium_id, { full_text_rss => 't' } );

    my $stories = $db->query( "select * from stories where media_id = $medium_id and full_text_rss = 'f'" )->hashes;

    my $i = 0;
    for my $story ( @{ $stories } )
    {
        $story->{ full_text_rss } = 1;
        $db->update_by_id( 'stories', $story->{ stories_id }, { full_text_rss => 't' } );

        MediaWords::StoryVectors::update_story_sentences_and_language( $db, $story );

        INFO ++$i . " / " . scalar( @{ $stories } );

        $db->commit if ( !( $i % 100 ) );
    }

    $db->commit;
}

main();
