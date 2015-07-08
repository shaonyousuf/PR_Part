#!/usr/bin/perl
#!/usr/bin/sh
##########initialization#####################
use strict;
use warnings;
use POSIX;
use Fcntl qw(:flock :seek)
  ;    #Export fileLock and seek  opened file using quote word qw
#use Switch;

#use Cwd;    # current working directory
my $path = getcwd;    # current working directory
print "current working path = $path\n";
my $pwd;
my @dirstruct;

#use Math::Complex;
use List::Util qw[min max];
use Data::Dumper qw(Dumper);
use Algorithm::Combinatorics qw(combinations);
use Algorithm::Combinatorics qw(partitions);
use Spreadsheet::WriteExcel;
#use Algorithm::Combinatorics qw(permutations);

#$Data::Dumper::Sortkeys = 1;
#$Data::Dumper::Sortkeys = sub { [sort { $a <=> $b } keys %$_ ] }; 

$Data::Dumper::Sortkeys = sub {
    no warnings 'numeric';
    [ sort { $a <=> $b } keys %{$_[0]} ]
};

#print Dumper($obj);




print "\nPartition Start:\n";
print "Please make sure your files compile without errors before running tool\n";
print "NOTE: Tool in Development Phase\n\n";
############Parse Input file######################


my $infile;
my @filelist;

#if ( !$ARGV[0] )
#{
#	print "Please enter file name:";
#	$infile = <STDIN>;
#	$infile =~ s/\s+//g;
#	chomp($infile);
#	while ( !( $infile =~ /^([-\@\w.]+)$/ ) )
#	{
#		print "Invalid File Name!\nPlease enter top file name:";
#		$infile = <STDIN>;
#		$infile =~ s/\s+//g;
#		chomp($infile);
#	}
#} else
#{
#	$infile = $ARGV[0];
#	chomp($infile);
#}
#############################################Create task list and associated CI and RR############################
push( @filelist, $infile );
my @task_list;
my %CI_of;
my %RR_of; # resource requirement, should be proportional to reconfiguration delay
my %SW_of; # SW execution time


print "TASK LIST, COMPUTATIONAL INTENSITY, AND RESOURCE REQUIREMENTS\n";

open( INFILE, "<app.c" ) or die "$infile cannot be opened! It doesn't exist!\n";
flock( INFILE, LOCK_SH );
foreach my $line (<INFILE>) {
	chomp($line);    #remove newlines
	if ( !$line ) {
		print "line is empty\n";
		next;
	}else{
		
		my $string = $line;
		$string =~ s/\s+//g;    #remove spaces	
		my @temp_string = split( ',', $string );
		push (@task_list, $temp_string[0]);
		$temp_string[1] =~ s/CI//g;
		$temp_string[2] =~ s/RR//g;
		$temp_string[3] =~ s/SW//g;
		
		$CI_of{$temp_string[0]} = $temp_string[1];
		$RR_of{$temp_string[0]} = $temp_string[2];
		$SW_of{$temp_string[0]} = $temp_string[3];
		
	}
	close (INFILE);
}

#foreach my $val (@task_list)
#{
#	print "The CI of $val is $CI_of{$val},";
#	print "The RR of $val is $RR_of{$val}\n";
#}
#print "CI\n";
#print Dumper \%CI_of;
#print "RR\n";
#print Dumper \%RR_of;


###################################Output file for debugging#######################

open( DEBUG, ">debug.txt" ) or die "DEBUG file cannot be opened\n";

open( RR, ">RR.txt" ) or die "DEBUG file cannot be opened\n";
open( RT, ">RT.txt" ) or die "DEBUG file cannot be opened\n";
open( ET, ">ET.txt" ) or die "DEBUG file cannot be opened\n";

############################Read Configurations#################################

my @configurations;
my %configuration_of;
my %no_of_transitions_in_configuration;
my %tasks_in_transition_of;

open( INFILE, "<valid.conf" ) or die "$infile cannot be opened! It doesn't exist!\n";
flock( INFILE, LOCK_SH );
foreach my $line (<INFILE>) {
	chomp($line);    #remove newlines
	if ( !$line ) {
		print "line is empty\n";
		next;
	}else{
		#print "$line\n";
		my $string = $line;
		$string =~ s/\s+//g;
		my @temp_string = split( '=', $string );
		push (@configurations, $temp_string[0]);
		$configuration_of{$temp_string[0]} = $temp_string[1];
		
		my @temp_string1 = split( '>', $temp_string[1] );
		my $config_size = @temp_string1;
		$no_of_transitions_in_configuration{$temp_string[0]} = $config_size;
		
		
		foreach my $value(@temp_string1)
		{
			push @{$tasks_in_transition_of{$temp_string[0]}}, $value;
			
		}
		
	}
	close (INFILE);
}


#foreach my $val (@configurations)
#{
#	print "\nThe Configuration of $val is $configuration_of{$val}||";
#	print "The no_of_transitions_in_configuration in $val is $no_of_transitions_in_configuration{$val}||";
#	print "The task transitions are $val is @{$tasks_in_transition_of{$val}}\n";
#
#}

print DEBUG "Configurations:\n";
print DEBUG Dumper \%configuration_of;
print DEBUG "No of transitions in configuration:\n";
print DEBUG Dumper \%no_of_transitions_in_configuration;
print DEBUG "Task transition:\n";
print DEBUG Dumper \%tasks_in_transition_of;

################Find task frequency in each configuration###############################



#***************initialize configuration tasks and frequency***************

#foreach my $val (@configurations){
#
#	$tasks_in_configuration {$val} = 
#	$task_frequency_in_configuration{$val} = 0;
#	
#}



#*************************************
my %task_frequency_in_configuration;


foreach my $config (@configurations){ 
    foreach my $tasks (@task_list){ 	  	
    	$task_frequency_in_configuration{$config}{$tasks} = 0;
    }
}

#print Dumper \%task_frequency_in_configuration;


foreach my $config (@configurations){   
      
    foreach my $task (@task_list){
       
		foreach my $val($configuration_of{$config}){
			
		#	print "##$config, $task, $val###\n";
			$val =~ s/,/>/g;
		#	print "##$config, $task, $val###\n";
			
			my @temp = split ( '>', $val);
		#	print "@temp\n";
			
			
		#	@{$task_list_in_configuration{$config}} = @temp; 
			
			foreach my $compare (@temp){
			   
			   
				   if($compare eq $task){ 
		
		    			$task_frequency_in_configuration{$config}{$task}++;
 	
			   }
			}		 
		}
    #	$task_frequency_in_configuration {$config}{$tasks}++;
    } 
}
print DEBUG "Task frequency:\n";
print DEBUG Dumper \%task_frequency_in_configuration;
	
#}

######################### Initialize partition, one task per PRR ########################

my %partition_list;
my %partition_PRR_max_resource;
my $partition_no=0;
#print @task_list;

my @temp_array_test = qw(t0 t1 t2);

#my @temp_array_test = @task_list;


my $size = @temp_array_test;		



#my $partition = 0;
my %total_resource_requirements_for_partition;

#print DEBUG Dumper \%partition_PRR_max_resource;

#my $total_reconfiguration_time = 0;
my %reconfiguration_time_of_configuration;
my %execution_time_of_configuration;
my %reconfiguration_transition_times;



insert_partition(); # hw only

#print DEBUG Dumper \%partition_PRR_max_resource;

#calculate_max_resource_requiment_per_PRR();

#find_total_resource_requirements();
#find_total_reconfig_time_and_execution_time();




#	insert_partition_SW(); # SW and HW
	
	
	print DEBUG "########################SW###########################################\n";


#	calculate_max_resource_requiment_per_PRR();
#	find_total_resource_requirements();
#find_total_reconfig_time_and_execution_time();


#calculate_max_resource_requiment_per_PRR();
#find_total_resource_requirements();
#find_total_reconfig_time_and_execution_time();

#find_total_execution_time();

#sub execution_time{
#	
#	
#	
#};

##################################Insert HW/SW Partitions Subroutine########################################


sub insert_partition_SW{

	#my $SW_PRR_partition_no = 1;
#	my $continued_partition = $partition_no;
#	$continued_partition++;
#	my @temp_array_test = qw(t0 t1 t2 t3);    
    $size = @temp_array_test;
#    
    my %partition_list_test = %partition_list;
    my %partition_list_test_temp;
    
   my $i=0;
   #print $size;
for (my $i=0; $i<1; $i++){
	foreach my $partition (sort keys %partition_list_test){
		
		
			
			print "i= $i\n";
				$partition_list_test{$partition}{"SW"} = delete $partition_list_test{$partition}{$i};
				
	}
	
	
	#my %partition_list_test_temp = %partition_list_test;
	
	#%partition_list_test = %partition_list;
	
	print DEBUG "SW partition\n";
	print DEBUG Dumper \%partition_list;
}
	
	
	
	
#	print DEBUG "SW partition\n";
#	print DEBUG Dumper \%partition_list_test;


}


###################################Insert HW/SW Partition Subroutine########################################




###################################Insert Partition Subroutine########################################

sub insert_partition{


##############################################Insert other partitions ###########################################
	
	

	



	@temp_array_test = qw (t0 t1 t2);
	print "@temp_array_test\n";
	
	my $loop_PRR = 0;
	my @all_partitions = partitions(\@temp_array_test);
	
	#print "@all_partitions\n";
	
	for my $ref (@all_partitions)
	
	{
	
		
	print "\nreference = $ref\n";	
	
		for my $value (@$ref){
		
		#	print "value =  @$value\n";
			
			
			my $scal = join(",", @$value);
			
		
			print "scalar =  $scal\n";
			
			$partition_list{$partition_no}{$loop_PRR} = $scal;
			$loop_PRR++;
		}
		$loop_PRR = 0;
		$partition_no++;
	}
	
	
	

 	print DEBUG" XXXXXXXXXXXXXXX\n";
	print DEBUG Dumper \%partition_list;
	
	
#	print Dumper \%all_partitions;
	
	#my $iter = partitions(\@temp_array_test);
	#print $iter;
# 	while (my $p = $iter->next) {
#     # ...
#     
#    #my $ref = $p;
#  #  print "$ref\n";
#    # print "@$p\n";
#     for my $ref (@$p) {
#     	
#     #	print "\n ref=  @$ref\n";
#     	#   print "$temp_array_test[$ref]\n";
#     	
#     }
#   #  
#     
#     #print "$temp_array_test[$ref]\n";
#     
#   #  my $value = @$p;
#     
#   #  print "
#     
#     #my $string = "@$p";
#     #print "$string\n";
#     
##     $string =~ s/\s+/,/g;
##     
##     $partition_list{$partition_no}{$loop_PRR} = $string;
##     
##     $partition_no++;
##     
#     
# 	}
 	
	
	
 	
#    while ($size > 0){
#    	
#     
#		my $iter = combinations(\@temp_array_test, $size);
#	
#		while (my $p = $iter->next) {
#	     # ...
#	     #print "@$p\n";
#	     
#	     my $string = "@$p";
#	     
#	     $string =~ s/\s+/,/g;
#	     
#	     $partition_list{$partition_no}{$loop_PRR} = $string;  
#	     $partition_PRR_max_resource{$partition_no}{$loop_PRR} = 0; 
#	     
#	     
#	     my $temp_loop = $loop_PRR;
#	     my @temp_array;
#	     foreach my $task(@temp_array_test){
#	     	
#	     	
#	     	if ($string !~ /$task/){
#	     		
#	     	#	print "task left/$string = $task / $string\n";
#	     		
#	     		push (@temp_array, $task);
#	     		$temp_loop++;
#	     		$partition_list{$partition_no}{$temp_loop} = $task;
#	     		$partition_PRR_max_resource{$partition_no}{$temp_loop} = 0; 
#	     		
#	     		my $size_temp = @temp_array;
#	     		
#	     		#print "size_temp = $size_temp\n";
#	     		
#	     		while ($size_temp >= 1){
#	     			
#	     			my $iter_2 = combinations(\@temp_array, $size_temp);
#	     			
#	     			
#	     				while (my $x = $iter_2->next) {
#					     # ...
#					     #print "@$p\n";
#					     
#					     my $string = "@$x";
#					     
#					     $string =~ s/\s+/,/g;
#					  #   print "s = $string\n";
#							
#	     				}
#	     			
#	     			
#	     			if ($size_temp == 1){
#	     				
#	     				     
#					     $partition_list{$partition_no}{$temp_loop} = $task;	
#	     				 $partition_PRR_max_resource{$partition_no}{$temp_loop} = 0;
#	     			}
##	     			
##	     			else{
##	                     $partition_no++;
##	                     
##	                     my $loop_x = 0;
##	                     while ($loop_x < $temp_loop){
##	                     	$partition_list{$partition_no}{$loop_x} = $partition_list{$partition_no-1}{$loop_x} = $task;
##	                     	$loop_x++;
##	                     }
##	     				# $partition_list{$partition_no}{$temp_loop} = $task;
##	     				
##	     			} 
#	     			#$partition_no++;
#	     			
#	     			
#	     			#$partition_list{$partition_no}{$temp_loop} = $task;
#	     			$size_temp--;
#	     		} 
#	     		
#	     	}
#	     	
#	     }
#	     
#
#	     
#	     $partition_no++;
#	    
#	 	}
#	 	
#	 #	$partition_no = 0;
#	 	#$loop_PRR++;
#	 	$size--;
#    }
 	

 	
 	
	
#	%partition_list = %partition_list;

	
	
#	my $fact_size = fac($size);
	#print $fact_size;
	
	#my $loop_size = 2**$size;
#	my $loop_size = 2;
#	#print $loop_size;
#	my $i=0;
#	my $ii=0;
#	
#	foreach my $task (@task_list){
#		
#		for(my $i=2; $i<$size; $i++){
#		
#			$partition_list{$i}{$ii} = $task;
#		
#		}
#	}
	
#	for(my $i=2; $i<$size; $i++){
#		
#		for(my $ii=0; $ii<$size; $ii++){
#	
#			$partition_list{$i}{$ii} = $task_list[$ii];
#		}
#	}
		#$partition_list{$i}{"SW"};
		#print "test";
#	}
#	
#	foreach my $val (@task_list)
#	{
#		
#		$partition_list{$starting_partition_no}{$PRR} = $val;
#	#	$partition_list{$partition}{0} = "t0,t1,t2,t3,t4,t5"; ## worst case reconfiguration time aka least resource requirement
#	#	$partition_list{$partition}{1} = "t6,t7"; ## worst case reconfiguration time aka least resource requirement
#	#	$partition_list{1}{0} = "t5,t3"; ## worst case reconfiguration time aka least resource requirement
#	#	$partition_list{1}{1} = "t4,t6"; ## worst case reconfiguration time aka least resource requirement
#	#	
#		
#		$partition_PRR_max_resource{$one_task_per_PRR_partition_no}{$PRR} = 0;
#	#	$partition_PRR_max_resource{1}{$PRR} = 0;
#	#	
#		$PRR++;
#		#$partition_list{$partition}{$PRR} = $val;
#	}
#	
#	
	
	
	
	
	#######sum total frequency of tasks####################;
	
#	my %task_frequency_in_configuration;
################################################################



	####################################################
	#print DEBUG Dumper \%task_frequency_in_configuration;
	
	
	
	
	##############################################Insert other partitions ###########################################
	
	
	
	#print DEBUG "Partition_list\n";
	#print DEBUG Dumper \%partition_list;
	
}



###################################Insert Partition Subroutine end########################################




######################### calculate_max_resource_requiment_per_PRR subroutine ########################

sub calculate_max_resource_requiment_per_PRR{
	
	

	
		foreach my $partition (sort keys %partition_list){
		#	print DEBUG "partition = $partition\n";
		    my $PRR_lp=0;    
		    
	
			foreach my $PRR (sort keys %{$partition_list{$partition}})
			{
				
				#print "PRR = $PRR\n";
				my $tasks_in_PRR = $partition_list{$partition}{$PRR};
			#	print "tasks in PRR = $tasks_in_PRR\n";
				
				if($PRR ne "SW"){
					
				foreach my $cmp(@task_list){
					
					#print "cmp = $cmp\n";
					if ($tasks_in_PRR =~ /$cmp/){
					
					#	print "#########$cmp = $tasks_in_PRR\n";
						
						my $RR = $RR_of{$cmp};
					#	print "RR = $RR\n";
						my $max_RR = $partition_PRR_max_resource{$partition}{$PRR};
					#	print "max_RR = $max_RR\n";
						
						if ($partition_PRR_max_resource{$partition}{$PRR} < $RR){
							$partition_PRR_max_resource{$partition}{$PRR} = $RR;
							
						} ;
						
						
					}
					
				}	
			}			
			}
			
		}
		
	
	
		
	print DEBUG "MAX resource required in each PRR for partition\n";
	print DEBUG Dumper \%partition_PRR_max_resource;
	
}


######################### calculate_max_resource_requiment_per_PRR subroutine end ########################



##########################################Find resource requirements subroutine#############################

sub find_total_resource_requirements{
	
	

	foreach my $val (sort keys %partition_list){
			my $sum = 0;
		#print "partition = $val\n";
		
		foreach my $PRR(sort keys %{$partition_PRR_max_resource{$val}}){
			
			my $PRR_RR = $partition_PRR_max_resource{$val}{$PRR};
			#print "resources in partition = $PRR_RR\n";
			if ($PRR_RR != 0 ){
				$sum += $PRR_RR;
			}
			
		}
	
	$total_resource_requirements_for_partition{$val} = $sum;
		
	}
#	print DEBUG "Total_resource_requirements_for_partition\n";
	
	print DEBUG Dumper \%total_resource_requirements_for_partition;
	print RR Dumper \%total_resource_requirements_for_partition;
	
#	
	my $XL = Spreadsheet::WriteExcel->new('output_file_RR.xls');
    my $WS = $XL->add_worksheet('RR data');

    my ($ROW, $COL) = (0, 0);
for my $colname (sort keys %total_resource_requirements_for_partition) {
    # Add column header
    #$WS->write_string($ROW, $COL, $colname);
	 #add partion value
	 $WS->write_string($ROW, $COL, $total_resource_requirements_for_partition{$colname});
    # Add column
    #$WS->write_col($ROW+1, $COL, $total_resource_requirements_for_partition{$colname});

    # Move on to next column
    ++$ROW;
}
	


	
} 


##########################################Find resource requirements subroutine end#############################









##########################################Find total reconfiguration time subroutine#############################
#	my $transition = 0;



my %reconfiguration_time_between_transitions;
sub find_total_reconfig_time_and_execution_time{

	
	foreach my $configuration (sort keys %tasks_in_transition_of){
	#  print DEBUG "######################Configuration = $configuration########################\n";
	  
	  #	my $loop_flag = 0;
	  #########create reconfiguration steps#####################
	  	
	  		
	  		foreach my $partition (sort keys %partition_list){
	  			# 	print DEBUG "partition = $partition\n";
	  			 	my $loop = 0;
	  				my $total_reconfiguration_time = 0;
	  				my $total_execution_time = 0;
	  				my %reconfig_steps= ();
	  				my $size = @task_list;
	  				my @occupied_PRRs = (0) x $size; #size of task_list
	  
	  			
	  			foreach my $PRR (sort keys %{$partition_list{$partition}}){
	  				
	  			#	print DEBUG "PRR = $PRR\n";
	  				
	  				#if ($PRR eq "SW"){
	  					
	  				#	next;
	  			#	}
	  				my $tasks_in_PRR = $partition_list{$partition}{$PRR};
	  				
	  		#		print DEBUG "$tasks_in_transition and $tasks_in_PRR\n";
	  				
	  				my @temp_array_PRR = split (',', $tasks_in_PRR);
	  				
	  				foreach my $tasks_in_transition (@{$tasks_in_transition_of{$configuration}}){
	  		
	  				#print DEBUG "tasks_in_transition = $tasks_in_transition\n";
	  				my @temp_array_transition = split (',', $tasks_in_transition);
	  				
	  				
	  				#if ($loop_flag == 0){
	  					#calculate intial reconfiguration time
	  					foreach my $loaded_task(@temp_array_transition){
	  						
	  						foreach my $assigned_task(@temp_array_PRR){
	  							
	  							#print "loaded_task $loaded_task, assigned_task = $assigned_task\n";
	  							if ($loaded_task eq $assigned_task)
	  							{
	  								#print "inside if: loaded_task $loaded_task, assigned_task = $assigned_task\n";
	  								
	  								$reconfig_steps{$loop}{$PRR} = $loaded_task;
	  								
#	  							    print DEBUG "reconfiguration steps\n";
#	  								print DEBUG Dumper \%reconfig_steps;
	  								
	  								#$initial_reconfiguration_time = $initial_reconfiguration_time + $CI_of{$loaded_task};
	  								#print "CI_of $loaded_task = $CI_of{$loaded_task},  initial_recongfiuration_time = $initial_reconfiguration_time\n";
	  								$loop++;
	  								last;
	  							}	
	  						}		
	  					}
	  					#print "occupied PRRs = @occupied_PRRs\n";
	  				}
	  			}
	  		
	  		#	print DEBUG Dumper \%reconfig_steps;
	  			
	  			
	  			
	  	###############calculate reconfiguration time foreach reconfiguration#####################
	
	#my %task_loaded_in_PRR;
	
	#	print DEBUG "########partition $partition configuration $configuration reconfiguration steps#############\n";
#	print DEBUG "###########configuration = $configuration###############################\n";
#	print DEBUG "####################reconfiguration steps for configuration = $configuration##########################\n";
#	print DEBUG Dumper \%reconfig_steps;
#	print DEBUG "occupied_PRRs\n";
#	print DEBUG Dumper \@occupied_PRRs;
	
	foreach my $step (sort keys %reconfig_steps){
		
	#	print DEBUG "step = $step\n";
		
		foreach my $PRR (sort keys %{$reconfig_steps{$step}}){
			
			#print DEBUG "PRR = $PRR\n";
			
			my $task_to_reconfigure;
			my $task_currently_in_PRR;
			
			if ($PRR ne "SW"){
				
				$task_to_reconfigure = $reconfig_steps{$step}{$PRR};
				$task_currently_in_PRR = $occupied_PRRs[$PRR];
				
				
				if ($occupied_PRRs[$PRR] eq 0){
					$occupied_PRRs[$PRR] = $task_to_reconfigure;
					
				#	print DEBUG"Reconfiguration step $step\n";
				#	print DEBUG"PRR_to_reconfigure = $task_to_reconfigure\n";
				#	print DEBUG Dumper \@occupied_PRRs;
					$total_reconfiguration_time += $RR_of{$task_to_reconfigure};
					$total_execution_time += $CI_of{$task_to_reconfigure};
				#	print DEBUG "total_reconfiguration_time = $total_reconfiguration_time\n";
					next;
					
				}
					else{
					
					#print "task_to_reconfigure = $task_to_reconfigure\n";
				#	print DEBUG "Before reconfiguration\n";
				#	print DEBUG Dumper \@occupied_PRRs;
					
					
					if ($occupied_PRRs[$PRR] eq $task_to_reconfigure){
						
					###same task no need to reconfigure#########	
					
					#print "same task $task_to_reconfigure no need to reconfigure\n";
					#print DEBUG "after reconfiguration\n";
				#	print DEBUG Dumper \@occupied_PRRs;
					
					next;
						
					}
					else{
						
						#########different PRR so update occupied PRRs########
						
						$occupied_PRRs[$PRR] = $task_to_reconfigure;
						#print "Reconfiguration step $step Occupied PRRs\n ";
						
						##add reconfiguration time############
						
					#	print DEBUG "after reconfiguration\n";
						#print DEBUG Dumper \@occupied_PRRs;
						
						$total_reconfiguration_time += $RR_of{$task_to_reconfigure};
						$total_execution_time += $CI_of{$task_to_reconfigure};
					#	print DEBUG "total_reconfiguration_time = $total_reconfiguration_time\n";
					
						
					}
					
					#$occupied_PRRs[$PRR] = 1;
				}
					
			}else{
			#	$total_reconfiguration_time += $RR_of{$task_to_reconfigure};
				$task_to_reconfigure = $reconfig_steps{$step}{$PRR};
				$total_execution_time += $SW_of{$task_to_reconfigure};
				
			}
			
			
			
		#	print DEBUG "task_to_reconfigure = $task_to_reconfigure\n";
		#	print DEBUG "task_currently_in_PRR = $task_currently_in_PRR\n";
			
			
		

			#$total_reconfiguration_time += $CI_of{$PRR};
		}
		# $reconfiguration_time_of_configuration {$configuration}{$partition} = $total_reconfiguration_time;
		
	}
	 $reconfiguration_time_of_configuration {$configuration}{$partition} = $total_reconfiguration_time;
	 $execution_time_of_configuration {$configuration}{$partition} = $total_execution_time;
	###############end calculate reconfiguration time#####################
	  			
	  		}  	
	
	 
	}

#	print DEBUG "Reconfiguration times\n";
#	print DEBUG Dumper \%reconfiguration_time_of_configuration;
#	print DEBUG "execution times\n";
#	print DEBUG Dumper \%execution_time_of_configuration;
	
	
	
	my $XL_RT = Spreadsheet::WriteExcel->new('output_file_RT.xls');
    my $WS_RT = $XL_RT->add_worksheet('RT data');
   

    my ($ROW, $COL) = (0, 0);
for my $configuration (sort keys %reconfiguration_time_of_configuration) {
    # Add column header
    $WS_RT->write_string($ROW, $COL, $configuration);
	 #add partion value
	 
	 my $loop = 1;
	 for my $partition (sort keys %{$reconfiguration_time_of_configuration{$configuration}}) {
	# my $value = $reconfiguration_time_of_configuration{$configuration};
	 
	 
	 $WS_RT->write_string($ROW+$loop, $COL, $reconfiguration_time_of_configuration{$configuration}{$partition});
	 $loop++;
	 print $partition;
	 
	 }
	 $loop = 1;
	# print $value;
#	$WS_RT->write_string($ROW+1, $COL, $value);
    # Add column
    #$WS->write_col($ROW+1, $COL, $total_resource_requirements_for_partition{$colname});
    # Move on to next column
    ++$COL;
}
	
	 my $XL_ET = Spreadsheet::WriteExcel->new('output_file_ET.xls');
    my $WS_ET = $XL_ET->add_worksheet('ET data');
    
	
	my ($ROW1, $COL1) = (0, 0);
for my $configuration (sort keys %execution_time_of_configuration) {
    # Add column header
    $WS_ET->write_string($ROW1, $COL1, $configuration);
	 #add partion value
	 
	 my $loop1 = 1;
	 for my $partition (sort keys %{$execution_time_of_configuration{$configuration}}) {
	# my $value = $reconfiguration_time_of_configuration{$configuration};
	 
	 
	 $WS_ET->write_string($ROW1+$loop1, $COL1, $execution_time_of_configuration{$configuration}{$partition});
	 $loop1++;
	 print $partition;
	 
	 }
	 $loop1 = 1;
	# print $value;
#	$WS_RT->write_string($ROW+1, $COL, $value);
    # Add column
    #$WS->write_col($ROW+1, $COL, $total_resource_requirements_for_partition{$colname});
    # Move on to next column
    ++$COL1;
}
	
	
	
	
	
	
	print RT Dumper \%reconfiguration_time_of_configuration;

	print ET Dumper \%execution_time_of_configuration;
	
}


##########################################Find total exectuion time subroutine end#############################



























































