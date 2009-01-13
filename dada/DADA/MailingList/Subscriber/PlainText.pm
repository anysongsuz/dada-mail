package DADA::MailingList::Subscriber::PlainText; 

use lib qw (../../../ ../../../DADA/perllib); 
use strict;
use Carp qw(carp croak);
use DADA::App::Guts; 


sub add { 	

 	my $class = shift;
	
    my ($args) = @_;
	my $lh = DADA::MailingList::Subscribers->new({-list => $args->{-list}});

    if ( !exists $args->{ -type } ) {
        $args->{ -type } = 'list';
    }
    if ( !exists $args->{ -email } ) {
        croak("You MUST supply an email address in the -email paramater!");
    }
    if ( length( DADA::App::Guts::strip( $args->{ -email } ) ) <= 0 ) {
        croak("You MUST supply an email address in the -email paramater!");
    }

    if ( !exists $args->{ -fields } ) {
        $args->{ -fields } = {};
    }
	        
     $lh->add_to_email_list(
     
        -Email_Ref => [($args->{-email})], 
	    -Type      => $args->{-type}, 
     
     );

	my $added  =  DADA::MailingList::Subscriber->new(
		{
			-list  => $args->{-list}, 
			-email => $args->{-email}, 
			-type  => $args->{-type},
		}
	); 


    if ( $DADA::Config::LOG{subscriptions} == 1 ) {
        $added->{'log'}->mj_log(
            $added->{list},
            'Subscribed to ' . $added->{list} . '.' . $added->type,
            $added->email
        );
    }
	return $added;
	
}




sub get { 

    my $self = shift; 
    my ($args) = @_;
    
    if(! exists $args->{-dotted}){ 
        $args->{-dotted} = 0;
    }    
    
    my ($n, $d) = split('@', $self->email, 2);
        
    if($args->{-dotted} == 1){     
        return {'subscriber.email' => $self->email, 'subscriber.email_name' => $n, 'subscriber.email_domain' => $d}; 
    } else { 
        return {email => $self->email, email_name => $n, email_domain => $d}; 
    
    }
}




sub move { 
    
    my $self   = shift; 
    
    my ($args) = @_;
    
    if(! exists $args->{-to}){ 
        croak "You must pass a value in the -to paramater!"; 
    }
    
    if($self->{lh}->allowed_list_types->{$args->{-to}} != 1){ 
        croak "list_type passed in, -to is not valid"; 
    }

   
    
    my $moved_from_checks_out = 0; 
    if(! exists($args->{-moved_from_check})){ 
        $args->{-moved_from_check} = 1; 
    }
    
	#?
    if($self->{lh}->check_for_double_email(-Email => $self->email, -Type => $self->type) == 0){ 
        
        if($args->{-moved_from_check} == 1){ 
            croak "email, " . $self->email . " is not subscribed to " . $self->{list} . '.'  . $self->type;     
        }
        else { 
            $moved_from_checks_out = 0; 
        }
    }
    else { 
        $moved_from_checks_out = 1; 
    }


	if(!exists($args->{-mode})){ 
		$args->{-mode} = 'writeover_check'; 
	}
		
	if($args->{-mode} eq 'writeover'){ 
		if($self->{lh}->check_for_double_email(-Email => $self->email, -Type => $args->{-to}) == 1){ 
			DADA::MailingList::Subscriber->new(
				{
					-list  => $self->{list}, 
					-email => $self->email,
	                -type  => $args->{ -to },
				}
			)->remove;
		}
	}
	else { 
	    if($self->{lh}->check_for_double_email(-Email => $args->{-email}, -Type => $args->{-to}) == 1){ 
	        croak "email passed in, -email ( $args->{-email}) is already subscribed to list passed in, '-to' ($args->{-to})"; 
	    }
	}

   
   
   if($moved_from_checks_out){ 
       $self->remove;
    }

    my $new_self = DADA::MailingList::Subscriber->add(
        { 
			-list  => $self->{list}, 
            -email => $self->email, 
            -type  => $args->{-to}, 
        }
    ); 


    
    if ($DADA::Config::LOG{subscriptions}) { 
        $self->{'log'}->mj_log(
            $self->{list}, 
            'Moved from:  ' . $self->{list} . '.' . $self->type . ' to: ' . $new_self->{list} . '.' . $new_self->type, 
            $new_self->email, 
        );
    }

	$self = $new_self; 
	return 1; 

}




1;