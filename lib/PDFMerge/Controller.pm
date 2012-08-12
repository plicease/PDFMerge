package PDFMerge::Controller;

use Mojo::Base 'Mojolicious::Controller';

# ABSTRACT: controller for PDFMerge
# VERSION

sub index
{
  shift->redirect_to('pdf_list');
}

sub pdf_list
{
  my($self) = @_;

  $self->render(pdfs  => $self->pdf->pdf_list);
}

sub pdf_download
{
  my($self) = @_;
  my $filename = $self->pdf->pdf_download($self->param('filename'));
  defined $filename ? $self->render_file(filepath => $filename) : $self->render_not_found;
}

sub pdf_merge_form
{
  my($self) = @_;

  my @names = map { $self->param($_ . "_name") } grep /^pdf_\d+$/, $self->param;
  if(@names > 0)
  {
    $self->redirect_to('pdf_merge', pdf_list => join('/', @names) );
  }
  else
  {
    $self->flash(error => 'No PDFs specified for merge');
    $self->redirect_to('pdf_list');
  }
}

sub pdf_merge
{
  my($self) = @_;
  my $filename = $self->pdf->pdf_merge(split '/', $self->param('pdf_list'));
  defined $filename ? $self->render_file(filepath => $filename) : $self->render_not_found;
}

1;
