#!/usr/bin/perl
use Cwd;
$wd=cwd();
#/************ Setting Environment Variables *******************/
$ENV{'CCM_HOME'}="/opt/ccm71";
$ENV{'PATH'}="$ENV{'CCM_HOME'}/bin:$ENV{'PATH'}";
open(ccm_addr,"$ENV{'CCM_HOME'}/bin/ccm start -m -q -d /data/ccmdb/dsa -h ccmuk1 -nogui |");
$ENV{'CCM_ADDR'}=<ccm_addr>;
close(ccm_addr);
$CCM="$ENV{'CCM_HOME'}/bin/ccm";
unlink "$wd/*.html";
open (FILE,"$wd/productname");
while (<FILE>)
{
        chomp($_);
        push @{$crs{$_}},`$CCM query \"product_name=\'$_\' and \(crstatus=\'entered\' or crstatus=\'resolved\'\)\" -u -f \"%problem_number\"`;
}
close FILE;

open (MAIL,"$wd/mailinglist");
while (<MAIL>)
{
	($prodname,$list)=split(':',$_);
	$mailhash{$prodname}=$list;
}
close MAIL;

foreach $i (keys %crs)
{
	chomp($i);
	print "$i: \n";
	$num=@{$crs{$i}};
	if($num != 0)
	{
	foreach $j (keys %mailhash)
	{
		chomp($j);
		if ($i =~ $j)
		{
			$list=$mailhash{$j};
		}
	}
	foreach $val (@{$crs{$i}})
	{
		chomp($val);
		$severity=`$CCM query \"problem_number=\'$val\'\" -u -f \"%severity\"`;
		push @{$hash{$severity}},$val;
	}
#	foreach (keys %hash)
#	{
#		print $_;
#		foreach $i (@{$hash{$_}})
#			{
#			print $i,"\n";
#		}
#	}
	open(HTML,">$wd/$i.html");
	print HTML "Content-Type: text/html\n\n";
	print HTML "<html><head></head><body>";
	print HTML "<h2>Defect List</h2>";
	print HTML "<table border=1>";
	print HTML "<thead><tr><td>Problem Number </td><td>Synopsis</td><td>Product Name</td><td>Product Version</td><td>Product Subsystem</td><td>Status</td><td>Severity</td><td>Create Time</td></tr></thead>";
	print HTML "<tbody><tr>";
	foreach (keys %hash)
	{
	foreach $val (@{$hash{$_}})
	{
		chomp($val);
		print HTML "</tr></tr>";
		print HTML "<td>$val</td>";
		$synop=`$CCM query \"problem_number=\'$val\'\" -u -f \"%problem_synopsis\"`;
		$prodname=`$CCM query \"problem_number=\'$val\'\" -u -f \"%product_name\"`;
		$prodver=`$CCM query \"problem_number=\'$val\'\" -u -f \"%product_version\"`;
		$status=`$CCM query \"problem_number=\'$val\'\" -u -f \"%crstatus\"`;
		$severity=`$CCM query \"problem_number=\'$val\'\" -u -f \"%severity\"`;
		$subsys=`$CCM query \"problem_number=\'$val\'\" -u -f \"%product_subsys\"`;
		$crtime=`$CCM query \"problem_number=\'$val\'\" -u -f \"%create_time\"`;
		print HTML "<td>$synop</td>";
		print HTML "<td>$prodname</td>";
		print HTML "<td>$prodver</td>";
		print HTML "<td>$subsys</td>";
		print HTML "<td>$status</td>";
		print HTML "<td>$severity</td>";
		print HTML "<td>$crtime</td>";
		print HTML"</tr>";
	}
	}
	print HTML "</tbody>";
	print HTML "</body></html>";
	close HTML;
	#system("/usr/local/bin/mutt -s 'Defect List for $i' '$list' -a '$wd/$i.html' < /dev/null");
	}
	else
	{
		next;
	}
}

open(ccm_addr,"$ENV{'CCM_HOME'}/bin/ccm stop |");
close(ccm_addr);
