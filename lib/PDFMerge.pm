package PDFMerge;

use strict;
use warnings;
use v5.10;
use Mojo::Base qw( Mojolicious );

# VERSION

sub startup
{
  my($self) = @_;

  $self->plugin('TtRenderer');
  $self->plugin('RenderFile');

  $self->secret(rand);

  my $r = $self->routes;

  $r->get('/')->name('index')->to('controller#index');

  $r->get('/pdf')->name('pdf_list')->to('controller#pdf_list');

  $r->get('/pdf/#filename.pdf')->name('pdf_download')->to('controller#pdf_download');

  $r->post('/pdf/merge')->name('pdf_merge_form')->to('controller#pdf_merge_form');

  $r->get('/pdf/merge/*pdf_list')->name('pdf_merge')->to('controller#pdf_merge');

  return;
}

1;
