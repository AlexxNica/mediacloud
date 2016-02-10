package MediaWords::Util::HTML;

use strict;
use warnings;

use Modern::Perl "2013";
use MediaWords::CommonLibs;

# various functions for manipulating html

require Exporter;

our @ISA    = qw(Exporter);
our @EXPORT = qw(html_strip);

# various functions for editing feed and medium tags

use HTML::StripPP;
use HTML::Entities qw( decode_entities  );
use Devel::Peek qw(Dump);
use Encode;
use List::Util qw(min);
use Memoize;
use Tie::Cache;
use Text::Trim;

# Cache output of html_strip() because it is likely that it is going to be called multiple times from extractor
my %_html_strip_cache;
tie %_html_strip_cache, 'Tie::Cache', {
    MaxCount => 1024,          # 1024 entries
    MaxBytes => 1024 * 1024    # 1 MB of space
};

memoize 'html_strip', SCALAR_CACHE => [ HASH => \%_html_strip_cache ];

# provide a procedural interface to HTML::Strip
# use HTML::StripPP instead of HTML::Strip b/c HTML::Strip mucks up the encoding
sub html_strip($)
{
    my ( $html ) = @_;

    return defined( $html ) ? HTML::StripPP::strip( $html ) : '';
}

# parse the content for tags that might indicate the story's title
sub html_title($$;$)
{
    my ( $html, $fallback, $trim_to_length ) = @_;

    unless ( defined $html )
    {
        die "HTML is undefined.";
    }

    my $title;

    if ( $html =~ m~<meta property=\"og:title\" content=\"([^\"]+)\"~si )
    {
        $title = $1;
    }
    elsif ( $html =~ m~<meta property=\"og:title\" content=\'([^\']+)\'~si )
    {
        $title = $1;
    }
    elsif ( $html =~ m~<title>(.*?)</title>~si )
    {
        $title = $1;
    }
    else
    {
        $title = $fallback;
    }

    if ( $title )
    {

        $title = html_strip( $title );
        $title = trim( $title );
        $title =~ s/\s+/ /g;

        # Moved from _get_medium_title_from_response()
        $title =~ s/^\W*home\W*//i;

        if ( defined $trim_to_length )
        {
            if ( length( $title ) > $trim_to_length )
            {
                $title = substr( $title, 0, $trim_to_length );
            }
        }
    }

    return $title;
}

1;
