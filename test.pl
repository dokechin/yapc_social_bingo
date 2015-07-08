use strict;
use warnings;
use Imager::Tiler qw(tile);
use Imager::DTP::Textbox::Horizontal;
use Web::Scraper;
use URI;
use Digest::MD5 qw/md5_hex/;
use List::Util qw/shuffle/;
use Furl;
$|=1;

get_recent_author_image();
tile_images();

sub tile_images {
  my $output = 'output.png';

  my $images = [ map {my $img = Imager->new(file=>$_);} grep { $_ ne $output; } glob '*.png'];

  my $count = @$images;
  
  warn($count);

  if ($count < 64){

      my $furl = Furl->new;
      my $res = $furl->get( "http://yapcasia.org/2015/assets/images/header_logo.png" );
      unless ( $res->is_success ) {
          warn "Can't download logo\n";
          die;
      }

      my $logo = Imager->new();
      $logo->read(data=>$res->content);
      $logo = $logo->scale(xpixels=>96, ypixels=>96);

      while($count < 64){
          push(@$images, $logo);
          $count++;
      }

  }

  my @shuffled = shuffle @$images;
  my ($img, @coords) = tile(
    Images => \@shuffled,
    Background => 'white',
    Center => 1,
    VEdgeMargin  => 10,
    HEdgeMargin  => 10,
    VTileMargin  => 50,
    HTileMargin  => 50,
    ImagesPerRow => 8);

    open my $fh, '>', $output or die "Can't open $output\n";
    print {$fh} $img;
    close $fh;
}

sub get_recent_author_image {
    my $talks = scraper {
        process '.talk_box', "talks[]" => scraper {
            process 'table > tr > td > a > img', icon => '@src';
            process 'table > tr > td > span.name > a', speaker => 'TEXT';
        };
    };

    my $res = $talks->scrape( URI->new('http://yapcasia.org/2015/talk/list'));

    my $furl = Furl->new;
    for my $talk (@{$res->{talks}}) {
        my $img_url = $talk->{icon}->as_string;
        my $speaker = $talk->{speaker};

        my $res = $furl->get( $img_url );
        unless ( $res->is_success ) {
            warn "Can't download $img_url\n";
            next;
        }

        my $file = md5_hex($img_url) . ".png";

        my $img = Imager->new();
        $img->read(data=> $res->content);
        $img = $img->scale(xpixels=>136, ypixels=>136);

        my $named_img = Imager->new(xsize => 152, ysize => 152);
        $named_img->box(filled => 1, color => 'white');
        $named_img->paste(left=>13, top=>0, src=>$img);
        
        # IPA Pゴシックフォントをオブジェクト化
        my $font = Imager::Font->new( file => 'ipagp.ttf' );
        # create textbox instance
        my $tb = Imager::DTP::Textbox::Horizontal->new(
            text=>$speaker,font=>$font,haligh=>'left', wrapWidth=>136, wrapHeight=>16);
        
        $tb->draw(target=>$named_img,x=>0,y=>136);

        $named_img->write(file=> $file);

    }


}

