use experimental qw[builtin class signatures];

class PPC;

use builtin 'trim';

use Pandoc;

field $author  :param = '';
field $id      :param;
field $slug    :param;
field $sponsor :param = '';
field $status  :param;
field $title   :param;

method author  { return $author }
method id      { return $id }
method slug    { return $slug }
method sponsor { return $sponsor }
method status  { return $status }
method title  { return $title }

method in_path {
  return "$slug.md";
}

method out_path {
  return "$slug/index.html";
}

method as_data {
  return {
    id      => $id,
    status  => $status,
    author  => $author,
    sponsor => $sponsor,
    slug    => $slug,
    title   => $title,
  };
}

# Very hacky parser

sub new_from_file($class, $ppc_file) {

  open my $ppc_fh, '<', $ppc_file
    or warn "Cannot open PPC [$_]: $!\n" and return;

  my (%ppc, $is_preamble);

  $ppc{slug} = $ppc_file;
  $ppc{slug} =~ s|^ppcs/||;
  $ppc{slug} =~ s|\.md$||;

  while (<$ppc_fh>) {
    !$ppc{title} and m|^#\s+(.*)| and $ppc{title} = md2text($_);

    $is_preamble and /## abstract/i and last;

    $_ = trim($_);

    if ($is_preamble and $_) {

      my ($key, $value) = split(/\s*:\s*/, $_, 2);

      $ppc{lc $key} = $value;
    }

    # 'pre.+mble' because Paul likes to use 'Preämble'
    /## pre.+mble/i and $is_preamble = 1;
  }

  if (exists $ppc{authors}) {
    $ppc{author} = delete $ppc{authors}
  }

  $ppc{$_} =~ s|\@.+?>|\@XXXX>|g for (qw[author sponsor]);

  return $class->new(%ppc);
}

sub md2text($md_string) {
  return pandoc->convert( markdown => 'plain', $md_string);
}

1;
