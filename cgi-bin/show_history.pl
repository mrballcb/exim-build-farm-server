#!/usr/bin/perl

use strict;
use DBI;
use Template;
use CGI;

use vars qw($dbhost $dbname $dbuser $dbpass $dbport);


require "$ENV{BFConfDir}/BuildFarmWeb.pl";
#require "BuildFarmWeb.pl";

die "no dbname" unless $dbname;
die "no dbuser" unless $dbuser;

my $dsn="dbi:Pg:dbname=$dbname";
$dsn .= ";host=$dbhost" if $dbhost;
$dsn .= ";port=$dbport" if $dbport;

my $db = DBI->connect($dsn,$dbuser,$dbpass);

die $DBI::errstr unless $db;

my $query = new CGI;
my $member = $query->param('nm'); $member =~ s/[^a-zA-Z0-9_ -]//g;
my $branch = $query->param('br'); $branch =~ s/[^a-zA-Z0-9_ -]//g;
my $hm = $query->param('hm');  $hm =~ s/[^a-zA-Z0-9_ -]//g;
$hm = '240' unless $hm =~ /^\d+$/;

# we don't really need to do this join, since we only want
# one row from buildsystems. but it means we only have to run one
# query. If it gets heavy we'll split it up and run two

my $statement = <<EOS;

  select (now() at time zone 'GMT')::timestamp(0) - snapshot as when_ago,
      sysname, snapshot, b.status, stage,
      operating_system, os_version, compiler, compiler_version, architecture,
      owner_email
  from buildsystems s, 
       build_status b 
  where name = ?
        and branch = ?
        and s.status = 'approved'
        and name = sysname
  order by snapshot desc
  limit $hm

EOS
;

my $statrows=[];
my $sth=$db->prepare($statement);
$sth->execute($member,$branch);
while (my $row = $sth->fetchrow_hashref)
{
    $row->{owner_email} =~ s/\@/ [ a t ] /;
	push(@$statrows,$row);
}
$sth->finish;

$db->disconnect;

my $template = new Template({EVAL_PERL => 1});

print "Content-Type: text/html\n\n";

$template->process(\*DATA,
		   {statrows=>$statrows, 
		    branch=>$branch, 
		    member => $member,
		    hm => $hm
		    });

exit;

__DATA__
[%- BLOCK cl %] class="[% SWITCH bgfor -%]
  [%- CASE 'OK' %]pass[% CASE 'ContribCheck' %]warn[% CASE [ 'Check' 'InstallCheck' ] %]warnx[% CASE %]fail[% END %]"
[%- END -%]
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
	<meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <title>PostgreSQL BuildFarm History</title>
	<link rel="icon" type="image/png" href="/elephant-icon.png" />
    <link rel="stylesheet" rev="stylesheet" href="/inc/pgbf.css" charset="utf-8" />
	<style type="text/css"><!--
	li#status a { color:rgb(17,45,137); background: url(/inc/b/r.png) no-repeat 100% -20px; } 
	li#status { background: url(/inc/b/l.png) no-repeat 0% -20px; }
	--></style>
</head>
<body class="history">
<div id="wrapper">
<div id="banner">
<a href="/index.html"><img src="/inc/pgbuildfarm-banner.png" alt="PostgreSQL BuildFarm" width="800" height="73" /></a>
<div id="nav">
<ul>
    <li id="home"><a href="/index.html" title="PostgreSQL BuildFarm Home">Home</a></li>
    <li id="status"><a href="/cgi-bin/show_status.pl" title="Current results">Status</a></li>
    <li id="members"><a href="/cgi-bin/show_members.pl" title="Platforms tested">Members</a></li>
    <li id="register"><a href="/register.html" title="Join PostgreSQL BuildFarm">Register</a></li>
    <li id="pgfoundry"><a href="http://pgfoundry.org/projects/pgbuildfarm/">PGFoundry</a></li>
</ul>
</div><!-- nav -->
</div><!-- banner -->
<div id="main">
<h1>PostgreSQL BuildFarm Status History</h1>
<table cellspacing="0">
    <tr><th class="head" colspan="3">System Detail</th></tr>
    <tr class="member"><th>Farm member</th><td>[% member %]</td></tr>
    <tr><th>OS</th><td>[% statrows.0.operating_system %] [% statrows.0.os_version %]</td></tr>
<!--    <tr><th>OS Version</th><td>[% statrows.0.os_version %]</td></tr> -->
    <tr><th>Compiler</th><td>[% statrows.0.compiler %] [% statrows.0.compiler_version %]</td></tr>
<!--    <tr><th>Compiler Version</th><td>[% statrows.0.compiler_version %]</td></tr> -->
    <tr><th>Architecture</th><td>[% statrows.0.architecture %]</td></tr>
    <tr><th>Owner</th><td>[% statrows.0.owner_email %]</td></tr>
    </table>
    <h3>Branch: [% branch %][% IF statrows.size >= hm %] (last [% hm %] entries shown)[% END %]</h3>
[% BLOCK stdet %]
<tr [% PROCESS cl bgfor=row.stage %]>
    <td>[%- row.when_ago | replace('\s','&nbsp;') %]&nbsp;ago&nbsp;</td>
    <td class="status">[% row.stage -%]</td>
    <td class="status"><a href="show_log.pl?nm=
               [%- row.sysname %]&amp;dt=
               [%- row.snapshot | uri %]">
                [%- IF row.stage != 'OK' %]Details[% ELSE %]Config[% END -%]</a></td>

</tr>
[% END %]
<table border="0"> <tr>
[% FOREACH offset IN [0,1,2] %][% low = offset * statrows.size / 3 ; high = -1 + (offset + 1) * statrows.size / 3 %] 
[% TRY %][% PERL %] 
  use POSIX qw(floor); 
  $stash->set(low => floor($stash->get('low'))); 
  $stash->set(high => floor($stash->get('high'))); 
[% END %][% CATCH %]<!-- [% error.info %] --> [% END %]
    <td><table cellspacing="0">
<!--      <tr><th colspan=3>low = [% low %], high = [% high %]</th></tr> -->
        [% FOREACH xrow IN statrows.slice(low,high) %][% PROCESS stdet row=xrow %][% END %]
    </table></td>
[% END %]
</table>
    </div><!-- main -->
<hr />
<p style="text-align: center;">
Hosting for the PostgreSQL Buildfarm is generously 
provided by: 
<a href="http://www.commandprompt.com">CommandPrompt, 
The PostgreSQL Company</a>
</p>
    </div><!-- wrapper -->
  </body>
</html>