use strict;
use warnings;
use Imager::Tiler qw(tile);
use Web::Scraper;
use URI;
use Furl;

#get_recent_author_image();
tile_images();

sub tile_images {
  my $output = 'output.png';

  my ($img, @coords) = tile(
    Images => [ map {my $img = Imager->new(file=>$_);$img->scale(xpixels=>96, ypixels=>96);} grep { $_ ne $output; } glob '*.png'],
    Background => 'lgray',
    Center => 1,
    VEdgeMargin  => 10,
    HEdgeMargin  => 10,
    VTileMargin  => 5,
    HTileMargin  => 5,
    ImagesPerRow => 8);

    open my $fh, '>', $output or die "Can't open $output\n";
    print {$fh} $img;
    close $fh;
}

sub get_recent_author_image {
    my $recents = scraper {
        process '.speaker', "speakers[]" => scraper {
            process 'a > img', image => '@src';
        };
    };

    my $res = $recents->scrape( URI->new('http://yapcasia.org/2015/talk/list'));

    my $index = 1;
    my $furl = Furl->new;
    for my $speaker (@{$res->{speakers}}) {
        my $img_url = $speaker->{image}->as_string;
        my $res = $furl->get( $img_url );
        unless ( $res->is_success ) {
            warn "Can't download $img_url\n";
            next;
        }

        my $file = $index++ . ".png";
        open my $fh, '>', $file  or die "Can't open $file";
        print {$fh} $res->content;
        close $fh;
    }
}

