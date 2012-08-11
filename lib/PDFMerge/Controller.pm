package PDFMerge::Controller;

use strict;
use warnings;
use v5.10;
use Mojo::Base 'Mojolicious::Controller';

# ABSTRACT: controller for PDFMerge
# VERSION

use File::HomeDir;
use PDF::API2;
use Path::Class::Dir ();
use File::Temp qw( tempdir );
use POSIX qw( strftime );

has pdf_directory => sub { Path::Class::Dir->new( File::HomeDir->my_home, 'PDF' ) };
has tmp_directory => sub { Path::Class::Dir->new( tempdir( CLEANUP => 1 ) ) };

sub index
{
  shift->redirect_to('pdf_list');
}

sub pdf_list
{
  my($self) = @_;

  my $id = 0;
  my @pdfs = map { my $name = $_->basename; $name =~ s/\.pdf$//; { name => $name, id => $id++, page_count => PDF::API2->open($_)->pages } }
             grep { (not $_->is_dir) and ($_->basename =~ /\.pdf$/) }
             $self->pdf_directory->children( no_hidden => 1 );

  $self->render( pdfs => \@pdfs );
}

sub pdf_download
{
  my($self) = @_;

  my $filename = $self->pdf_directory->file($self->param('filename') . '.pdf');
  if(-f $filename && -r $filename)
  {
    $self->render_file(filepath => $filename);
  }
  else
  {
    $self->render_not_found;
  }
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

  my @source_pdf_list = split '/', $self->param('pdf_list');

  my $dest_pdf = PDF::API2->new;

  foreach my $source_pdf_filename (map { $self->pdf_directory->file("$_.pdf") } grep !/^\./, @source_pdf_list)
  {
    my $source_pdf = PDF::API2->open($source_pdf_filename);
    foreach my $page (1..$source_pdf->pages)
    {
      $dest_pdf->importpage($source_pdf, $page, $dest_pdf->page);
    }
  }

  my $timestamp = strftime "%Y%m%d%H%M", localtime time;

  # TODO, these temp files get cleaned up when the script exits
  # (if it does so nicely), but it would be better to cleanup the
  # file after the transaction instead.
  my $temp_file = File::Temp->new(TEMPLATE => "pdf_merge_${timestamp}_XXXX", SUFFIX => '.pdf', DIR => $self->tmp_directory, UNLINK => 0 );
  binmode $temp_file;
  print $temp_file $dest_pdf->stringify;
  close $temp_file;

  $self->render_file(filepath => $temp_file->filename);
}

1;
