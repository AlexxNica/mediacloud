package MediaWords::GearmanFunction::ExtractAndVector;

#
# Extract and vector a download
#
# Start this worker script by running:
#
# ./script/run_with_carton.sh local/bin/gjs_worker.pl lib/MediaWords/GearmanFunction/ExtractAndVector.pm
#

use strict;
use warnings;

use Moose;
with 'MediaWords::GearmanFunction';

BEGIN
{
    use FindBin;

    # "lib/" relative to "local/bin/gjs_worker.pl":
    use lib "$FindBin::Bin/../../lib";
}

use Modern::Perl "2013";
use MediaWords::CommonLibs;

use MediaWords::DB;
use MediaWords::DBI::Downloads;

# extract + vector the download; die() and / or return false on error
sub run($$)
{
    my ( $self, $args ) = @_;

    my $downloads_id = $args->{ downloads_id };
    unless ( defined $downloads_id )
    {
        die "'downloads_id' is undefined.";
    }

    my $db = MediaWords::DB::connect_to_db();

    my $download = $db->find_by_id( 'downloads', $downloads_id );
    unless ( $download->{ downloads_id } )
    {
        die "Download with ID $downloads_id was not found.";
    }

    eval {

        my $process_id = 'gearman:' . $$;
        MediaWords::DBI::Downloads::extract_and_vector( $db, $download, $process_id );

    };
    if ( $@ )
    {

        # Probably the download was not found
        die "Extractor died: $@\n";

    }

    return 1;
}

no Moose;    # gets rid of scaffolding

# Return package name instead of 1 or otherwise worker.pl won't know the name of the package it's loading
__PACKAGE__;
