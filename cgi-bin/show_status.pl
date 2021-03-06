#!/usr/bin/perl

=comment

Copyright (c) 2003-2010, Andrew Dunstan

See accompanying License file for license details

=cut 

use strict;
use DBI;
use Template;
use CGI;

use vars qw($dbhost $dbname $dbuser $dbpass $dbport $template_dir);


require "$ENV{BFConfDir}/BuildFarmWeb.pl";

my $query = new CGI;
my @members = $query->param('member');
map { s/[^a-zA-Z0-9_ -]//g; } @members;

my $dsn="dbi:Pg:dbname=$dbname";
$dsn .= ";host=$dbhost" if $dbhost;
$dsn .= ";port=$dbport" if $dbport;


my $sort_clause = "";
my $sortby = $query->param('sortby') || 'nosort';
if ($sortby eq 'name')
{
	$sort_clause = 'lower(sysname),';
}
elsif ($sortby eq 'os')
{
	$sort_clause = 'lower(operating_system), os_version desc,'; 
}
elsif ($sortby eq 'compiler')
{
	$sort_clause = "lower(compiler), compiler_version,";
}

my $db = DBI->connect($dsn,$dbuser,$dbpass,{pg_expand_array => 0}) 
    or die("$dsn,$dbuser,$dbpass,$!");

my $statement =<<EOS;


  select timezone('GMT'::text, now())::timestamp(0) without time zone - b.snapshot AS when_ago, b.*
  from dashboard_mat b
  order by branch = 'master' desc,
        branch desc, $sort_clause 
        snapshot desc

EOS
;

my $statrows=[];
my $sth=$db->prepare($statement);
$sth->execute;
while (my $row = $sth->fetchrow_hashref)
{
    next if (@members && ! grep {$_ eq $row->{sysname} } @members);
    $row->{build_flags}  =~ s/^\{(.*)\}$/$1/;
    $row->{build_flags}  =~ s/,/ /g;
    $row->{build_flags}  =~ s/_PC\b//g;
    $row->{build_flags} = lc($row->{build_flags});
    push(@$statrows,$row);
}
$sth->finish;


$db->disconnect;


my $template_opts = { INCLUDE_PATH => $template_dir };
my $template = new Template($template_opts);

print "Content-Type: text/html\n\n";

$template->process('status.tt',
		{statrows=>$statrows});

exit;

