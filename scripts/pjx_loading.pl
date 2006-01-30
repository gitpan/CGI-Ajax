#! /usr/bin/perl -w

use strict;
use CGI::Ajax;
use CGI;

my $func = sub {
  my $input = shift;
  my $i=10000000;
  while($i--){
  }
  return 'done';
};


sub Show_HTML {
my  $html = <<EOT;

<html>
<head><title>CGI::Ajax Example</title>
<script type=text/javascript>
function check_ajax(){
  if(!ajax) return;
  if(ajax.length){
    document.getElementById('result').style.backgroundColor='#ccc';   
    document.getElementById('result').innerHTML = 'LOADING';
  }else{
    document.getElementById('result').style.backgroundColor='#fff';   
  }
}

setInterval('check_ajax()',400);

</script>
</head>
<body>
  Enter a number:&nbsp;
  <input type="text" name="val1" id="val1" size="6"
     onkeyup="jsfunc( ['val1'], 'result' ); return true;"><br>
    <hr>
    <div id="result" style="border: 1px solid black;
          width: 440px; height: 80px; overflow: auto">
    </div>
</body>
</html>

EOT

}

my $cgi = new CGI();  # create a new CGI object
my $pjx = new CGI::Ajax( 'jsfunc' => $func );
print $pjx->build_html($cgi,\&Show_HTML);
