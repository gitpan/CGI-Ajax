#! /usr/bin/perl -w

use strict;
use CGI::Ajax;
use CGI;
use vars qw( $data );

$data = {
  'A' => { '1' => "A1", '2' => "A2", '3' => "A3", '42' => "A42" },
  'B' => { 'green' => "Bgreen", 'red' => "Bred" },
  'some other thing' => { 'firefly' => "great show" },
  'final thing' => { 'email' => "chunkeylover53", 'name' => "homer",
                     'address' => "742 Evergreen Terrace" }
};

my $q = new CGI;

my %hash = ( 'SetA'         => \&set_listA,
             'SetB'         => \&set_listB,
             'ShowResult'   => \&show_result );

my $pjx = CGI::Ajax->new( %hash );

$pjx->DEBUG(1);
$pjx->JSDEBUG(1);

print $pjx->build_html( $q, \&Show_HTML );

sub Show_HTML {
  my $html = <<EOT;
<HTML>
<HEAD><title>Combo Example</title>
<SCRIPT>

// define some reset functions to properly clear out the divs
function resetdiv( ) {
  if ( arguments.length ) {
    // reset a specific div
    for(var i = 0; i < arguments.length; i++ ) {
      document.getElementById(arguments[i]).innerHTML = "";
    }
  } else {
    // just reset all the divs
    document.getElementById("listAdiv").innerHTML = "";
    document.getElementById("listBdiv").innerHTML = "";
    document.getElementById("resultdiv").innerHTML = "";
  }
}

</SCRIPT>

</HEAD>
<BODY onload="resetdiv(); SetA([],['listAdiv']); return true;" >
  <table>
  <tr>
      <td>
          Select something...
      </td>
      <td>
        <div id="listAdiv"></div>
      </td>
      <td>
        <div id="listBdiv"></div>
      </td>
      <td>
        <div id="resultdiv"></div>
      </td>
  </tr>
  </table>
</BODY>
</HTML>
EOT

  return($html);
}

sub set_listA {
  # this is the returned text... html to be displayed in the div
  # defined in the javascript call
  my $txt = qq!<select id="listA" size=3!;
  $txt .= qq! onclick="resetdiv('resultdiv'); SetB( ['listA'], ['listBdiv'] ); return true;">!;
  # get values from $data, could also be a db lookup
  foreach my $topval ( keys %$data ) {
    $txt .= '<option>' . $topval . "</option>";
  }
  $txt .= "</select>";
  print STDERR "set_listA:\n";
  print STDERR "returning $txt\n";
  return($txt);
}

sub set_listB {
  my $listA_selection = shift;
  my $txt = qq!<select id="listB" size=3!; # this is the returned text... html to be displayed in the div
                                           # defined in the javascript call
  $txt .= qq! onclick="ShowResult( ['listA','listB'], ['resultdiv'] ); return true;">!;
  # get values from $data, could also be a db lookup
  foreach my $midval ( keys %{ $data->{ $listA_selection } } ) {
    $txt .= '<option>' . $midval . "</option>";
  }
  $txt .= "</select>";
  print STDERR "set_listB:\n";
  print STDERR "returning $txt\n";
  return($txt);
}

sub show_result {
  my $listA_selection = shift;
  my $listB_selection = shift;
  return( $data->{ $listA_selection }->{ $listB_selection } );
}

