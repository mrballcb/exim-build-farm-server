#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use Mail::Send;
use Data::Dumper;

die "Must pass current sysname and new sysname\n" unless scalar @ARGV == 2;

use vars qw($dbhost $dbname $dbuser $dbpass $dbport
            $user_list_format
            $default_host $mail_from
);
require "$ENV{BFConfDir}/BuildFarmWeb.pl";

die "no dbname" unless $dbname;
die "no dbuser" unless $dbuser;

my $dsn="dbi:Pg:dbname=$dbname";
$dsn .= ";host=$dbhost" if $dbhost;
$dsn .= ";port=$dbport" if $dbport;

my $db = DBI->connect($dsn,$dbuser,$dbpass);

die $DBI::errstr unless $db;

$db->do('SELECT approve(?, ?)', undef, @ARGV);

my $sth = $db->prepare(q[ 
       SELECT name, status, operating_system, os_version, sys_owner, owner_email,
              secret, compiler, compiler_version, architecture
       FROM buildsystems AS b
       ORDER BY name ASC
      ]);
$sth->execute();

sub send_welcome_email
{
  my $row = shift() or return;
  my $msg = new Mail::Send;
  my $me = `id -un`; chomp($me);
  my $host = `hostname`; chomp($host);
  $host = $default_host unless ($host =~ m/[.]/ || !defined($default_host));
  my $from_addr = $mail_from ?
                  "Exim BuildFarm <$mail_from>" :
                  "Exim BuildFarm <$me\@$host>" ;
  $from_addr =~ tr /\r\n//d;
  $msg->set('From',$from_addr);
  $msg->to($row->{owner_email});
  $msg->subject('Exim BuildFarm Application Approved');
  my $fh = $msg->open;
  print $fh "\n\nCongratulations $row->{sys_owner},\n",
            "Your application for the Exim BuildFarm has been accepted.\n\n",
            "Please set the following in your build-farm.conf:\n",
            "Animal:  $row->{name}\n",
            "Secret:  $row->{secret}\n\n",
            "BuildFarm machine details:\n",
            "Distro  : $row->{operating_system}\n",
            "+Version: $row->{os_version}\n",
            "Arch    : $row->{architecture}\n",
            "Compiler: $row->{compiler}\n",
            "+Version: $row->{compiler_version}\n\n",
            "If you update your system, either the Distro or compiler version\n",
            "you can use the update_personality.pl script to update the\n",
            "version stored in the BuildFarm database.\n\n",
            "-- The Exim BuildFarm Maintainers";
  $fh->close;
}

printf $user_list_format,
       "SysName", "Status", "Owner", "Email", "Distro", "Version";
while (my $row = $sth->fetchrow_hashref)
{
  printf $user_list_format,
                  $row->{name}, $row->{status}, $row->{sys_owner},
                  $row->{owner_email}, $row->{operating_system},
                  $row->{os_version};
  if ($row->{name} eq $ARGV[1])
  {
    &send_welcome_email($row);
  }
}
$db->disconnect();

