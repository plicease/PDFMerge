package PDFMerge;

use Mojo::Base qw( Mojolicious );
use PDFMerge::Data;

# ABSTRACT: Web interface for merging PDF documents.
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

  $self->helper(pdf => sub {
    state $data;
    $data //= PDFMerge::Data->new;
  });

  return;
}

1;
