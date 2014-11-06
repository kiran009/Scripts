#!/usr/bin/perl
use Cwd;
use File::Path;
use File::Find;
use File::Basename;

#/************ Setting Environment Variables *******************/
$ENV{'CCM_HOME'}="/opt/ccm71";
$ENV{'PATH'}="$ENV{'CCM_HOME'}/bin:$ENV{'PATH'}";

@platformList740=("JAVA5");
$LINAS5_HOST=pedlinux5;
$Scripts_Dir="/data/ccmbm/final_script/kiran_test";
my @PatchFiles,@files,$patchnumber;
my $patch_number;
my @CRS,@crs,@tasks;
$PatchReleaseVersion;
$mailto='kiran.daadhi@evolving.com';
#$mailto='kiran.daadhi@evolving.com Shreraam.Gurumoorthy@evolving.com Viswanath.Banakar@evolving.com Kumar.SK@evolving.com Sekhar.Sahu@evolving.com Anand.Gubbi@evolving.com';
#/* Global Environment Variables ******* /
main();
sub main()
{
	fetch_readme();
	read_readme();
	fetch_crs();
	reconfigure_dev_proj_and_compile();
	reconfigure_del_project();
	find_binaries_tar();
	send_email();
	#move_cr_status();
	ccm_stop();
	exit;
}

sub start_ccm()
{
	open(ccm_addr,"$ENV{'CCM_HOME'}/bin/ccm start -d /data/ccmdb/dsa -m -q -r build_mgr -h ccmuk1 -nogui |");
	$ENV{'CCM_ADDR'}=<ccm_addr>;
	close(ccm_addr);
	$CCM="$ENV{'CCM_HOME'}/bin/ccm";
}
sub find_binaries_tar()
{
	chdir $Scripts_Dir;
	@PatchFiles=`sed -n '/AFFECTS/,/TO/ p' $patch_number\_README.txt  | sed '\$ d' | grep -v 'AFFECTS' | sed '/^\$/d'`;
	@files;
	chomp(@PatchFiles);
	$PatchReleaseVersion="4.0.0";
	$FUR_LINAS5_DIR="/data/ccmbm/dsa/DSA_FUR_Delivery-patch_linAS5_".$PatchReleaseVersion;
	$dir=$FUR_LINAS5_DIR;
	#$dir="/data/ccmbm/FURident/DSA_FUR_Delivery-patch_linAS5_7.4.0";
	my $ftpdir="/u/prathish/Jenkins/Patch_$patch_number";
	my %hash;
	foreach (@PatchFiles)
	{
        	push(@files,basename($_));
	        push(@dirs,dirname($_));
        	$sourcedir=$destdir=$_;
	        $sourcedir=~ s/\$FURHOME/$dir\/DSA_FUR_Delivery/g;
        	$destdir=~s/\$FURHOME/$ftpdir/g;
	        print "*************** $sourcedir and $destdir ***************\n";
	        $hash{$sourcedir}=$destdir;
	}
	#Search the binaries in the delivery project
	foreach $dir(@dirs)
	{
	        $dir=~s/\$FURHOME/$ftpdir/g;
        	push(@newdir,$dir);
	        `mkdir -p $dir`;
	}

	while(($key,$value)=each %hash) {
        	`cp -f $key $value`;
	}
	print "\$ftpdir is: $ftpdir \n";
	#chdir $ftpdir;
	chomp($patch_number);
	`cd $ftpdir; rm -f Patch\_$patch_number\*;tar cvf Patch_$patch_number.tar bin; gzip -f \*\.tar`;		
}

sub fetch_crs()
{
	chdir $Scripts_Dir;
	@CRS=`sed -n '/FIXES/,/AFFECTS/ p' $patch_number\_README.txt  | sed '\$ d' | grep -v 'FIXES' | sed '/^\$/d'`;
	chomp(@CRS);
	$PatchReleaseVersion="4.0.0";
	$FUR_LINAS5_DIR="DSA_FUR_Delivery-patch_linAS5_".$PatchReleaseVersion;
	$dir=$FUR_LINAS5_DIR;
	#$dir="/data/ccmbm/FURident/DSA_FUR_Delivery-patch_linAS5_7.4.0";
	my $ftpdir="/u/prathish/Jenkins/Patch_$patch_number";
	my %hash;
	foreach (@CRS)
	{
			my($cr,@temp)=split(/\s+/,$_);
        	push(@crs,$cr);	               
	}
	print "\@crs are: @crs\n";	 
}
sub create_patch()
{
	


}
sub send_email()
{
$body='Patch is created and available at: /u/prathish/Jenkins/Patch_8749/';
system("/usr/bin/mutt -s 'FUR 4.0.0 PATCH BUILD COMPLETED and available at: /u/prathish/Jenkins/Patch_8749/' $mailto < /dev/null ");
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
			$TaskFullNumber=~ s/^\s+|\s+$//g; 
			@tasks=split(/,/,$TaskFullNumber);
			foreach (@tasks)
			{
				my($temp,$task)=split(/_/,$_);
				push(@tasknumbers,$task);
				#($temp,$TaskNumber)=split(/_/,$TaskFullNumber);
			}
			print "***************\@tasknumbers are: @tasknumbers *************** \n";
				#$TaskNumber=~ s/^\s+|\s+$//g;
				#($PatchNumber)=split(/,/,$TaskNumber);
				$PatchNumber=2345;
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
	$PatchReleaseVersion="4.0.0";
	$FUR_LINAS5_DIR="DSA_FUR_Dev-patch_linAS5_".$PatchReleaseVersion;
	$projectName=$FUR_LINAS5_DIR;
	
	# Set the CCM workarea 
	$ccmworkarea=`$CCM wa -show -recurse $projectName`;
	($temp,$workarea)=split(/'/,$ccmworkarea);
	print "***************CCM WorkArea is: $workarea\n***************";

	# Reconfigure the project
	# DSA_FUR_Dev-patch_linAS5_7.4.0 9996
	#$SYSTEM_FOLDER_NO_740=1252;
	#`$CCM folder -modify -add_task $TaskNumber $SYSTEM_FOLDER_NO_740`;
	`$CCM folder -modify -add_task @tasks 2>&1 1>/dev/null`;
	`$CCM reconfigure -rs -r -p $projectName 2>&1 1>/tmp/reconfigure_devproject.log`;

	# Go to pedlinux5 and gmake clean all
	#`OST "cd $ccmworkarea; /usr/bin/gmake clean all;"`;
	chdir "$workarea/DSA_FUR_Dev";
	`/usr/bin/gmake clean all 2>&1 1>/tmp/gmake.log`;
}
sub reconfigure_del_project()
{
	# Go to Delivery project and reconcile and build the tar file
	$PatchReleaseVersion="4.0.0";
	$FUR_LINAS5_DIR="DSA_FUR_Delivery-patch_linAS5_".$PatchReleaseVersion;
	$projectName=$FUR_LINAS5_DIR;
	print "*************** Delivery projectName is: $projectName  ***************\n";
	$ccmworkarea=`$CCM wa -show -recurse $projectName`;
	($temp,$workarea)=split(/'/,$ccmworkarea);
	print "***************CCM WorkArea of Delivery Project is: $workarea***************\n";
	#`$CCM reconcile -missing_wa_file -update_wa $workarea 2>&1 1>/tmp/reconcile.log`;
	`$CCM reconfigure -rs -r -p $projectName 2>&1 1>/tmp/reconfigure_delproject.log`;
}
