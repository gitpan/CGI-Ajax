package CGI::Ajax;
use strict;
use base qw(Class::Accessor);
use overload '""' => 'show_javascript'; # for building web pages, so
                                        # you can just say: print $pjx
BEGIN {
    use vars qw ($VERSION @ISA);
    $VERSION     = .31;
    @ISA         = qw(Class::Accessor);
}

########################################### main pod documentation begin ##
# Below is the stub of documentation for your module. You better edit it!


=head1 NAME

CGI::Ajax - a perl-specific system for writing AJAX- or DHTML-based
web applications (formerly know as the module CGI::Perljax).

=head1 SYNOPSIS

  use CGI::Ajax;
  my $pjx = new CGI::Ajax( 'exported_func1' => \&perl_func1 );

=head1 DESCRIPTION

CGI::Ajax is an object-oriented module that provides a unique mechanism
for using perl code asynchronously from javascript-enhanced
web pages.  You would commonly use CGI::Ajax in AJAX/DHTML-based web
applications.  CGI::Ajax unburdens the user from having to write any
javascript, except for having to associate an exported method with
a document-defined event (such as onClick, onKeyUp, etc). Only in
the more advanced implementations of a exported perl method would
a user need to write any javascript.

CGI::Ajax supports methods that return single results, or multiple
results to the web page, and the after version >= 0.20, supports
returning values to multiple DIV elements on the HTML page.

Using CGI::Ajax, the URL for the HTTP GET request is automatically
generated based on HTML layout and events, and the page is then
dynamically updated.  We also have support for mapping URL's to a
CGI::Ajax function name, so you can separate your code processing
over multiple scripts.

Other than using the Class::Accessor module to generate CGI::Ajax'
accessor methods, CGI::Ajax is completely self-contained - it does
not require you to install a larger package or a full Content
Management System.

A primary goal of CGI::Ajax is to keep the module streamlined and
maximally flexible.  We are trying to keep the generated javascript
code to a minimum, and provide users with a variety of methods for
deploying CGI::Ajax in their own applications.


=head1 USAGE

Create a CGI object to send to CGI::Ajax, export the subroutines
prior to creating the CGI::Ajax object, like so:

  use strict;
  use CGI::Ajax;
  use CGI;

  # define a normal perl subroutine that you want available 

    sub evenodd_func {
    my $input = shift;
    
    # see if input is defined
    if ( not defined $input ) {
      return("input not defined or NaN");
    }

    # see if value is a number (*thanks Randall!*)
    if ( $input !~ /\A\d+\z/ ) {
      return("input is NaN");
    }

    # got a number, so mod by 2
    $input % 2 == 0 ? return("EVEN") : return("ODD");

  }

  # define a function to generate the web page - this can be done
  # million different ways, and can also be defined as an anonymous sub.
  # The only requirement is that the sub send back the html of the page.

  sub Show_HTML {
    my $html = <<EOT;

  <HTML>
  <HEAD><title>CGI::Ajax Example</title>
  </HEAD>
  <BODY>
    Enter a number:&nbsp;
    <input type="text" name="val1" id="val1" size="6"
       onkeyup="evenodd( ['val1'], 'resultdiv' );
       return true;"><br>
    <hr>
    <div id="resultdiv" style="border: 1px solid black;
          width: 440px; height: 80px; overflow: auto">
    </div>
  </BODY>
  </HTML>
  EOT

    return $html;
  }

  my $cgi = new CGI();  # create a new CGI object

  # create a CGI::Ajax object, and associate our anon code
  # In >= version 0.20 of CGI::Ajax, you can make the associated
  # code a url to another CGI script.

  my $pjx = new CGI::Ajax( 'evenodd' => \&evenodd_func );

	# print the form sending in the cgi and the HTML function
  
  # this outputs the html for the page
  print $pjx->build_html($cgi,\&Show_HTML);

=head1 METHODS

=item build_html()

    Purpose: associate cgi obj ($cgi) with pjx object, insert
		         javascript into <HEAD></HEAD> element
  Arguments: either a coderef, or a string containing html
    Returns: html or updated html (including the header)
  Called By: originating cgi script

=cut

=item show_javascript()

    Purpose: builds the text of all the javascript that needs to be
             inserted into the calling scripts html header
  Arguments: 
    Returns: javascript text
  Called By: originating web script
       Note: This method is also overridden so when you just print
             a CGI::Ajax object it will output all the javascript needed
             for the web page.

=cut

=head1 BUGS

=head1 SUPPORT

Check out the sourceforge discussion lists at:
  
  http://www.sourceforge.net/projects/pjax

=head1 AUTHORS

	Brian C. Thomas     Brent Pedersen
	CPAN ID: BCT
	bct.x42@gmail.com   bpederse@gmail.com

=head1 A NOTE ABOUT THE MODULE NAME

This module was initiated using the name "Perljax", but then
registered with CPAN under the WWW group "CGI::", and so became
"CGI::Perljax".  Upon further deliberation, we decided to change it's
name to CGI::Ajax.

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

Class::Accessor, CGI

=cut

############################################# main pod documentation end ##

######################################################
## METHODS - public                                 ##
######################################################


#=item build_html()
#
#    Purpose: associate cgi obj ($q) with pjx object, insert
#		         javascript into <HEAD></HEAD> element
#  Arguments: either a coderef, or a string containing html
#    Returns: html or updated html (including the header)
#  Called By: originating cgi script
#
#=cut

sub build_html {
  my ( $self, $q, $html_source ) = @_;
  if ( $self->DEBUG() ) {
    print STDERR "html_source is ", $html_source, "\n";
  }

  $self->cgi($q);    # associate the CGI object with this object
                     #check if "fname" was defined in the CGI object
  if ( defined $self->cgi()->param("fname") ) {

    # it was, so just return the html from the handled request
    return ( $self->handle_request() );
  } else {
    my $html = $self->cgi()->header();    # start with the minimum,
                                          # a http header line

    # check if the user sent in a coderef for generating the html,
    # or the actual html
    if ( ref($html_source) eq "CODE" ) {
      eval { $html .= &$html_source };
      if ($@) {

        # there was a problem evaluating the html-generating function
        # that was sent in, so generate an error page
        $html = $self->cgi()->header();
        $html .= qq!<html><body><h2>Problems</h2> with 
          the html-generating function sent to CGI::Ajax
          object</body></html>!;
        return $html;
      }
      $self->html($html);    # no problems, so set html
    } else {

      # user must have sent in raw html, so add it
      $self->html( $html . $html_source );
    }

    # now modify the html to insert the javascript
    $self->insert_js_in_head();
  }
  return $self->html();
}

#=item show_javascript()
#
#    Purpose: builds the text of all the javascript that needs to be
#             inserted into the calling script's html header
#  Arguments: 
#    Returns: javascript text
#  Called By: originating web script
#
#=cut

sub show_javascript {
  my ($self) = @_;
  my $rv = $self->show_common_js();    # show the common js

  # build the js for each perl function you want exported to js
  foreach my $func ( keys %{ $self->coderef_list() }, keys %{ $self->url_list() } ) {
    $rv .= $self->make_function($func);
  }
  $rv = "\n" . '//<![CDATA[' . "\n" . $rv . "\n" . '//]]>' . "\n";
  $rv = '<script type="text/javascript">' . $rv . '</script>';
  return $rv;
}

## new
sub new {
  my ($class) = shift;
  my $self = bless ({}, ref ($class) || $class);
  $self->mk_accessors( qw(url_list coderef_list cgi html DEBUG JSDEBUG) );
  $self->JSDEBUG(0);
  $self->DEBUG(0);
  $self->{coderef_list} = {}; #accessorized
  $self->{url_list} = {}; #accessorized
  $self->{html}=undef;
  $self->{cgi}= undef; #accessorized

  if ( @_ < 2 ) {
    die "incorrect usage: must have fn=>code pairs in new\n";
  }

  while ( @_ ) {
    my($function_name,$code) = splice( @_, 0, 2 );
    if ( ref( $code ) eq "CODE" ) {
      if ( $self->DEBUG() ) {
        print STDERR "name = $function_name, code = $code\n";
      }
      # add the name/code to hash
      $self->coderef_list()->{ $function_name } = $code;
    } elsif ( ref($code) ) {
      die "Unsuported code block/url\n";
    } else {
      if ( $self->DEBUG() ) {
        print STDERR "Setting function $function_name to url $code\n";
      }
			# if it's a url, it is added here 
      $self->url_list()->{ $function_name } = $code;
    }
  }
  return ($self);
} 

######################################################
## METHODS - private                                ##
######################################################

#=item show_common_js()
#
#    Purpose: create text of the javascript needed to interface with
#             the perl functions
#  Arguments: none
#    Returns: text of common javascript subroutine, 'do_http_request'
#  Called By: originating cgi script, or build_html()
#
#=cut

sub show_common_js {
  my $self = shift;
  my $rv = <<EOT;
function pjx(args,fname){
  this.dt=args[1];
  this.args=args[0]
  this.req=ghr();
  this.url = this.getURL(fname);
}

function getVal(id) {
  if(typeof id != 'string'){ return id; }
  try {
    return document.getElementById(id).value.toString();
  } catch(e) {
    try { 
      return document.getElementById(id).innerHTML.toString();
    } catch(e) {
      if (id.constructor == Function ) {
        return id;
      }
      try {
        return document.getElementById(id).innerHTML.toString();
      } catch(e) {
        var errstr = 'ERROR: cant get html element with id:' +
        id + 'check that an element with id=' + id + ' exists';
        alert(errstr);return false;
      }
    }
  }
}

function fnsplit(arg){
  var arg2;
	if(arg.indexOf('__')!=-1){
		var arg2 =  '&' + (arg.split(/__/).join('='));
	}else{
		arg2 = '&args=' + getVal(arg);
	}
	return arg2;
}

pjx.prototype.perl_do=function() {
  r = this.req;
  dt=this.dt;
  url=this.url;
  r.open("GET",url,true);
  r.onreadystatechange=handleReturn;
  r.send(null);
}

handleReturn =	function() {
	if ( r.readyState!= 4) { return; }
	var data = r.responseText.split(/__pjx__/);
	if(dt.constructor != Array){dt=[dt];}
	if(data.constructor != Array){data=[data];}
	if (typeof(dt[0])!='function') {
    for(var i=0;i<dt.length;i++){ 		
			var div = document.getElementById(dt[i]);
			if (div.type=='text') {
				div.value=data[i];
			} else {
				div.innerHTML = data[i];
			}
		}
	} else if (typeof(dt[0])=='function') {
			eval(dt[0](data));
	}
} 


pjx.prototype.getURL=function(fname){
  args = this.args;
  url= 'fname=' + fname;
  for(i=0;i<args.length;i++){
    url=url + args[i];
  }
  return url;
}

function ghr() {
  if ( typeof ActiveXObject!="undefined" ) {
    try { return new ActiveXObject("Microsoft.XMLHTTP") }
    catch(a) { }
  }
  if ( typeof XMLHttpRequest!="undefined" ) {
    return new XMLHttpRequest();
  }
  return null;
}
EOT
  return $rv;
}

#=item insert_js_in_head()
#
#    Purpose: searches the html value in the CGI::Ajax object and inserts
#             the ajax javascript code in the <script></script> section,
#             or if no such section exists, then it creates it.
#  Arguments: none
#    Returns: none
#  Called By: build_html()
#
#=cut

sub insert_js_in_head{
  my $self = shift;
	my $mhtml = $self->html();
	my $newhtml;
	my @shtml;
	my $js = $self->show_javascript();
	if($self->JSDEBUG()){
	  my $showurl=qq|<br /><div id='__pjxrequest'></div><br/>|;
		my @splith = $mhtml =~ /(.*)(<\s*\/\s*body\s*>)(.*)/is;
		$mhtml = $splith[0].$showurl.$splith[1].$splith[2];
	}
  @shtml= $mhtml =~ /(.*)(<\s*\/\s*head\s*>)(.*)/is;
	if(@shtml){
    $newhtml = $shtml[0].$js.$shtml[1].$shtml[2];
	} elsif( @shtml= $mhtml =~ /(.*)(<\s*html.*?>)(.*)/is){
    $newhtml = $shtml[0].$shtml[1].$js.$shtml[2];
	}
	$self->html($newhtml);
	return;
}

#=item handle_request()
#
#    Purpose: makes sure a fname function name was set in the CGI
#             object, and then tries to eval the function with
#             parameters sent in on args
#  Arguments: none
#    Returns: the result of the perl subroutine, as text; if multiple
#             arguments are sent back from the defined, exported perl
#             method, then join then with a connector (__pjx__).
#  Called By: build_html()
#
#=cut

sub handle_request {
  my ($self) = shift;
	
  my $rv = $self->cgi()->header();
  my $result; # $result takes the output of the function, if it's an
              # array split on __pjx__
  my @other = (); # array for catching extra parameters

  # make sure "fname" was set in the form from the web page
  return undef unless defined $self->cgi();	
  #return undef unless defined $self->cgi()->param("fname");

  # get the name of the function
  my $func_name = $self->cgi()->param("fname");

  # check if the function name was created
  if ( defined $self->coderef_list()->{$func_name} ) {
    my $code = $self->coderef_list()->{$func_name};
    
    # eval the code from the coderef, and append the output to $rv
    if ( ref($code) eq "CODE" ) {
      eval { ($result, @other) = $code->( $self->cgi()->param("args") ) };

      if( @other ) {
          $rv .= join( "__pjx__", ($result, @other) );
          if ( $self->DEBUG() ) {
            print STDERR "rv = $rv\n";
          }
      } else {
        if ( defined $result ) {
          $rv .= $result;
        } 
      }

      if ($@) {
        # see if the eval caused and error and report it
        # Should we be more severe and die?
        if ( $self->DEBUG() ) {
          print STDERR "Problem with code: $@\n";
        }
      }
    } # end if ref = CODE
  } else {
    $rv .= "$func_name is not defined!";
  }
  return $rv;
}


#=item make_function()
#
#    Purpose: creates the javascript wrapper for the underlying perl
#             subroutine
#  Arguments: CGI object from web form, and the name of the perl
#             function to export to javascript, or a url if the
#             function name refers to another cgi script
#    Returns: text of the javascript-wrapped perl subroutine
#  Called By: show_javascript; called once for each registered perl
#             subroutine
#
#=cut

sub make_function {
  my ($self, $func_name ) = @_;
  return("") if not defined $func_name;
  return("") if $func_name eq "";
  my $rv = "";
	my $outside_url = $self->url_list()->{$func_name};
	if(not defined $outside_url){$outside_url = 0;}
  my $jsdebug = $self->JSDEBUG();

  #create the javascript text
  $rv .= <<EOT;

function $func_name() {
  var args = $func_name.arguments;
  for( i=0; i<args[0].length;i++ ) {
	  args[0][i] = fnsplit(args[0][i]);
  }
  var pjx_obj = new pjx(args,"$func_name");
	var amp = '?';
	if ( \'$outside_url\' == '0') {
	  if(window.location.toString().indexOf('?')!=-1){
		  amp = '&';
		}
	  pjx_obj.url = window.location + amp + pjx_obj.url;
	} else {
	  if(window.location.toString().indexOf('?')!=-1){
		  amp = '&';
		}
	  pjx_obj.url = \'$outside_url\' + amp +  pjx_obj.url;
	}
	
  var tmp = '<a href= '+ pjx_obj.url +' target=_blank>' + pjx_obj.url + ' </a>';
  pjx_obj.perl_do();
	if ($jsdebug) {
	  document.getElementById('__pjxrequest').innerHTML = tmp;
	}
}
EOT
# make sure 'EOT' is at the left margin if you copy and paste
# this code. 

 return $rv;
}

#=item Subroutine: register()
#
#    Purpose: adds a function name and a code ref to the global coderef hash
#  Arguments: function name, code reference
#    Returns: none
#  Called By: originating web script
#
#=cut

sub register {
  my ( $self, $fn, $coderef ) = @_;
  # coderef_list() is a Class::Accessor function
  # url_list() is a Class::Accessor function
  if ( ref( $coderef ) eq "CODE" ) {
    $self->coderef_list()->{$fn} = $coderef;
  } elsif ( ref($coderef) ) {
    die "Unsupported code/url type - error\n";
  } else {
    $self->url_list()->{$fn} = $coderef;
  }
}
1;
__END__
