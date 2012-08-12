package PDFMerge::Data;

# ABSTRACT: model for PDFMerge
# VERSION

use Mojo::Base -base;
use PDF::API2;
use POSIX qw( strftime );
use File::HomeDir;
use Path::Class::Dir ();
use File::Temp qw( tempdir );

has pdf_directory => sub { Path::Class::Dir->new( File::HomeDir->my_home, 'PDF' ) };
has tmp_directory => sub { Path::Class::Dir->new( tempdir( CLEANUP => 1 ) ) };

sub pdf_list
{
  my($self) = @_;

  my $id = 0;
  my @pdfs = map { my $name = $_->basename; $name =~ s/\.pdf$//; { name => $name, id => $id++, page_count => PDF::API2->open($_)->pages } }
             grep { (not $_->is_dir) and ($_->basename =~ /\.pdf$/) }
             $self->pdf_directory->children( no_hidden => 1 );
  \@pdfs;
}

sub pdf_download
{
  my($self, $filename) = @_;

  my $path = $self->pdf_directory->file($filename . '.pdf');
  return unless -r $path;
  $path;
}

sub pdf_merge
{
  my($self, @source_pdf_list) = @_;

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

  $temp_file->filename;
}

sub links
{
  [ { href => 'https://github.com/plicease/PDFMerge', text => '@github' } ];
}

sub version
{
  $PDFMerge::VERSION // 'dev';
}

sub footer
{
  my($self) = @_;
  'PDFMerge version ' . $self->version . ' copyright &copy; 2012 Graham Ollis';
}

1;
