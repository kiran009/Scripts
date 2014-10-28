#!/usr/bin/perl
use Cwd;
use File::Path;
use File::Find;
use File::Basename;

#/************ Setting Environment Variables *******************/
$ENV{'CCM_HOME'}="/opt/ccm71";
$ENV{'PATH'}="$ENV{'CCM_HOME'}/bin:$ENV{'PATH'}";
open(ccm_addr,"$ENV{'CCM_HOME'}/bin/ccm start -d /data/ccmdb/dsa -m -q -r build_mgr -h ccmuk1 -nogui |");
$ENV{'CCM_ADDR'}=<ccm_addr>;
close(ccm_addr);
$CCM="$ENV{'CCM_HOME'}/bin/ccm";
@platformList740=("JAVA5");
$LINAS5_HOST=pedlinux5;
$Scripts_Dir="/data/ccmbm/final_script/kiran_test";
my @PatchFiles,@files,$patchnumber;
my $patch_number;
$PatchReleaseVersion;
$mailto='kiran.daadhi@evolving.com';
#$mailto='kiran.daadhi@evolving.com Shreraam.Gurumoorthy@evolving.com Viswanath.Banakar@evolving.com Kumar.SK@evolving.com Sekhar.Sahu@evolving.com Anand.Gubbi@evolving.com';
#/* Global Environment Variables ******* /
main();
sub main()
{
	fetch_readme();
	read_readme();
	#reconfigure_dev_proj_and_compile();
	reconfigure_del_project();
	find_binaries_tar();
	send_email();
	#move_cr_status();
	ccm_stop();
	exit;
}

sub find_binaries_tar()
{
	chdir $Scripts_Dir;
	@PatchFiles=`sed -n '/AFFECTS/,/TO/ p' $patch_number\_README.txt  | sed '\$ d' | grep -v 'AFFECTS' | sed '/^\$/d'`;
	@files;
	chomp(@PatchFiles);
	$PatchReleaseVersion="4.0.0";
	$PROV_LINAS5_DIR="DSA_FUR_Delivery-patch_linAS5_".$PatchReleaseVersion;
	$dir=$PROV_LINAS5_DIR;
	#$dir="/data/ccmbm/provident/DSA_FUR_Delivery-patch_linAS5_7.4.0";
	my $ftpdir="/u/kkdaadhi/Patch_$patch_number";
	my %hash;
	foreach (@PatchFiles)
	{
        	push(@files,basename($_));
	        push(@dirs,dirname($_));
        	$sourcedir=$destdir=$_;
	        $sourcedir=~ s/\$FURHOME/$dir\/DSA_FUR_Delivery/g;
        	$destdir=~s/\$FURHOME/$ftpdir/g;
	        print "$sourcedir and $destdir ";
	        $hash{$sourcedir}=$destdir;
	}
	#Search the binaries in the delivery project
	print "\@dirs is: @dirs and \@files is: @files and \@sourcedirs is: @sourcedirs \n";
	foreach $dir(@dirs)
	{
	        $dir=~s/\$FURHOME/$ftpdir/g;
        	push(@newdir,$dir);
	        `mkdir -p $dir`;
	}

	while(($key,$value)=each %hash) {
        	`cp -f $key $value`;
	}
	chdir $ftpdir;
	`tar cvf Patch.tar \*`;
}


sub send_email()
{
$body="Patch is created and available at: /u/prathish/Patch_9996/Patch.tar";
system("/usr/bin/mutt -a /tmp/gmake.log -a /tmp/reconfigure.log -s 'Build Notification' $mailto < $body ");
}

sub move_cr_status()
{

}
sub ccm_stop()
{
	open(ccm_addr,"$ENV{'CCM_HOME'}/bin/ccm stop |");
	close(ccm_addr);
}
sub fetch_readme()
{
	chdir $Scripts_Dir;
	$ccm_request_type=`$CCM query "cvtype=\'problem\' and crstatus=\'Closed\' and problem_number=\'3405\'"`;
	$patch_number=`$CCM query -u -f %patch_number`;
	$patch_readme=`$CCM query -u -f %patch_readme`;
	$patch_number=~ s/^\s+|\s+$//g;
	open OP,"+> $patch_number\_README.txt";
	print OP $patch_readme;
	close OP;
	`dos2unix $patch_number\_README.txt 2>&1 1>/dev/null`;
}
sub read_readme()
{
	# Read the README file for Task information
	open OP, "< $patch_number\_README.txt";
	my @op=<OP>;
	close OP;
	foreach $op(@op)
	{	
		if($op =~ /TASK/)
		{
			($temp,$TaskFullNumber)=split(/:/,$op);
            $TaskFullNumber=~ s/^\s+|\s+$//g; 
			($temp,$TaskNumber)=split(/_/,$TaskFullNumber);
			$TaskNumber=~ s/^\s+|\s+$//g;
			($PatchNumber)=split(/,/,$TaskNumber);
		}
		if($op =~ /AFFECTS/)
		{
			($temp,$productFullName)=split(/:/,$op);
			$productFullName=~ s/^\s+|\s+$//g;
			($temp,$productVersion)=split(/\s+/,$productFullName);
			$productVersion=~ s/^\s+|\s+$//g;
		}
		if($op =~ /FIXES/)
		{
			($temp,$patchIssueNumbers)=split(/:/,$op);
		}
	}
}
sub reconfigure_dev_proj_and_compile()
{
	# Reconfigure the project
	#open OP, "<config.properties";
	#	my @op=<OP>;
	#	close OP	;
	#	
	#	foreach $op(@op)
	#	{
	#		if($op =~ /BUILD_PLTFORMS_740/)
	#		{
	#			my ($temp,$test)=split(/'/,$op);
	#			($temp,$test1)=split(/'/,$test);
	#	        @ary=split(/\s+/,$temp);
	#			push(@ary,@platformList740);
	#		}
	#	}
	$PatchReleaseVersion="4.0.0";
	$PROV_LINAS5_DIR="DSA_FUR_Dev-patch_linAS5_".$PatchReleaseVersion;
	$projectName=$PROV_LINAS5_DIR;
	
	# Set the CCM workarea 
	$ccmworkarea=`$CCM wa -show -recurse $projectName`;
	($temp,$workarea)=split(/'/,$ccmworkarea);
	print "CCM WorkArea is: $workarea";

	# Reconfigure the project
	# DSA_FUR_Dev-patch_linAS5_7.4.0 9996
	#$SYSTEM_FOLDER_NO_740=1252;
	#`$CCM folder -modify -add_task $TaskNumber $SYSTEM_FOLDER_NO_740`;
	`$CCM folder -modify -add_task $TaskNumber`;
	`$CCM reconfigure -rs -r -p $projectName`;

	# Go to pedlinux5 and gmake clean all
	#`OST "cd $ccmworkarea; /usr/bin/gmake clean all;"`;
	chdir "$workarea/DSA_FUR_Dev";
	`/usr/bin/gmake clean all 2>&1 1>/tmp/gmake.log`;
}
sub reconfigure_del_project()
{
	# Go to Delivery project and reconcile and build the tar file
	$PatchReleaseVersion="4.0.0";
	$PROV_LINAS5_DIR="DSA_FUR_Delivery-patch_linAS5_".$PatchReleaseVersion;
	$projectName=$PROV_LINAS5_DIR;
	$ccmworkarea=`$CCM wa -show -recurse $projectName`;
	($temp,$workarea)=split(/'/,$ccmworkarea);
	#`$CCM reconcile -missing_wa_file -update_wa $workarea 2>&1 1>/tmp/reconcile.log`;
	`$CCM reconfigure -rs -r -p $projectName 2>&1 1>/tmp/reconfigure.log`;

	#foreach (@PatchFiles)
	#{
	#        print "\$PatchFiles is: $_";
        #	push(@files,basename($_));
	#}
	#print "Value of \@files is: @files and Value of \@PatchFiles is : @PatchFiles\n";
}
