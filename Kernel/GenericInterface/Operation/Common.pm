# --
# Kernel/GenericInterface/Operation/Common.pm - common operation functions
# Copyright (C) 2001-2012 OTRS AG, http://otrs.org/
# --
# $Id: Common.pm,v 1.6 2012-01-25 02:45:42 cr Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::GenericInterface::Operation::Common;

use strict;
use warnings;

use vars qw(@ISA $VERSION);
$VERSION = qw($Revision: 1.6 $) [1];

use Kernel::System::User;
use Kernel::System::Auth;
use Kernel::System::Group;
use Kernel::System::AuthSession;
use Kernel::System::CustomerUser;
use Kernel::System::CustomerAuth;
use Kernel::System::GenericInterface::Webservice;
use Kernel::System::VariableCheck qw(:all);

=head1 NAME

Kernel::GenericInterface::Operation::Common - common operation functions

=head1 SYNOPSIS

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

usually, you do not need to instantiate this object directly.
It will be passed to all Operation backends so that they can
take advantage of it.

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for my $Needed (
        qw( DebuggerObject MainObject TimeObject ConfigObject LogObject DBObject EncodeObject)
        )
    {

        if ( !$Param{$Needed} ) {
            return {
                Success      => 0,
                ErrorMessage => "Got no $Needed!"
            };
        }

        $Self->{$Needed} = $Param{$Needed};
    }

    # create additional objects
    $Self->{UserObject}    = Kernel::System::User->new( %{$Self} );
    $Self->{SessionObject} = Kernel::System::AuthSession->new( %{$Self} );
    $Self->{GroupObject}   = Kernel::System::Group->new( %{$Self} );
    $Self->{AuthObject}    = Kernel::System::Auth->new( %{$Self} );

    $Self->{CustomerUserObject} = Kernel::System::CustomerUser->new( %{$Self} );
    $Self->{CustomerAuthObject} = Kernel::System::CustomerAuth->new( %{$Self} );

    return $Self;
}

=item Auth()

performs user or customer user authorization

    my ( $UserID, $UserType ) = $CommonObject->Auth(
        Data => {
            SessionID         => 'AValidSessionIDValue'     # the ID of the user session
            UserLogin         => 'Agent',                   # if no SessionID is given UserLogin or
                                                            #   CustomerUserLogin is required
            CustomerUserLogin => 'Customer',
            Password  => 'some password',                   # user password
        },
    );

    returns

    (
        1,                                              # the UserID from login or session data
        'Agent',                                        # || 'Customer', the UserType.
    );

=cut

sub Auth {
    my ( $Self, %Param ) = @_;

    my $SessionID = $Param{Data}->{SessionID} || '';

    # check if a valid SessionID is present
    if ($SessionID) {
        my $ValidSessionID =
            $Self->{SessionObject}->CheckSessionID( SessionID => $SessionID ) if $SessionID;
        return 0 if !$ValidSessionID;

        # get session data
        my %UserData = $Self->{SessionObject}->GetSessionIDData(
            SessionID => $SessionID,
        );

        # get UserID from SessionIDData
        if ( $UserData{UserID} && $UserData{UserType} ne 'Customer' ) {
            return ( $UserData{UserID}, $UserData{UserType} );
        }
        elsif ( $UserData{UserLogin} && $UserData{UserType} eq 'Customer' ) {

            # if UserCustomerLogin
            return ( $UserData{UserLogin}, $UserData{UserType} );
        }
        return 0;
    }

    if ( defined $Param{Data}->{UserLogin} && $Param{Data}->{UserLogin} ) {

        my $UserID = $Self->_AuthUser(%Param);

        # if UserLogin
        if ($UserID) {
            return ( $UserID, 'Agent' );
        }
    }
    elsif ( defined $Param{Data}->{CustomerUserLogin} && $Param{Data}->{CustomerUserLogin} ) {

        my $CustomerUserID = $Self->_AuthCustomerUser(%Param);

        # if UserCustomerLogin
        if ($CustomerUserID) {
            return ( $CustomerUserID, 'Customer' );
        }
    }

    return 0;
}

=item GetSessionID()

performs user authentication and return a new SessionID value

    my $SessionID = $CommonObject->GetSessionID(
        Data {
            UserLogin         => 'Agent1',
            CustomerUserLogin => 'Customer1',       # optional, provide UserLogin or
                                                    #   CustomerUserLogin
            Password          => 'some password',   # plain text password
        }
    );

Returns undef on failure or

    $SessionID = 'AValidSessionIDValue';         # the new session id value

=cut

sub GetSessionID {
    my ( $Self, %Param ) = @_;

    my $User;
    my %UserData;
    my $UserType;

    # get params
    my $PostPw = $Param{Data}->{Password} || '';

    if ( defined $Param{Data}->{UserLogin} && $Param{Data}->{UserLogin} ) {

        # if UserLogin
        my $PostUser = $Param{Data}->{UserLogin} || $Param{Data}->{UserLogin} || '';

        # check submitted data
        $User = $Self->{AuthObject}->Auth(
            User => $PostUser,
            Pw   => $PostPw,
        );
        %UserData = $Self->{UserObject}->GetUserData(
            User  => $User,
            Valid => 1,
        );
        $UserType = 'Agent';
    }
    elsif ( defined $Param{Data}->{CustomerUserLogin} && $Param{Data}->{CustomerUserLogin} ) {

        # if UserCustomerLogin
        my $PostUser = $Param{Data}->{CustomerUserLogin} || $Param{Data}->{CustomerUserLogin} || '';

        # check submitted data
        $User = $Self->{CustomerAuthObject}->Auth(
            User => $PostUser,
            Pw   => $PostPw,
        );
        %UserData = $Self->{CustomerUserObject}->CustomerUserDataGet(
            User  => $PostUser,
            Valid => 1,
        );
        $UserType = 'Customer';
    }

    # login is invalid
    return if !$User;

    # create new session id
    my $NewSessionID = $Self->{SessionObject}->CreateSessionID(
        %UserData,
        UserLastRequest => $Self->{TimeObject}->SystemTime(),
        UserType        => $UserType,
    );

    return $NewSessionID if ($NewSessionID);

    return;
}

=item ReturnError()

helper function to return an error message.

    my $Return = $CommonObject->ReturnError(
        ErrorCode    => Ticket.AccessDenied,
        ErrorMessage => 'You dont have rights to access this ticket',
    );

=cut

sub ReturnError {
    my ( $Self, %Param ) = @_;

    $Self->{DebuggerObject}->Error(
        Summary => $Param{ErrorCode},
        Data    => $Param{ErrorMessage},
    );

    # return structure
    return {
        Success      => 1,
        ErrorMessage => "$Param{ErrorCode}: $Param{ErrorMessage}",
        Data         => {
            Error => {
                ErrorCode    => $Param{ErrorCode},
                ErrorMessage => $Param{ErrorMessage},
            },
        },
    };
}

=item _AuthUser()

performs user authentication

    my $UserID = $CommonObject->_AuthUser(
        UserLogin => 'Agent',
        Password  => 'some password',           # plain text password
    );

    returns

    $UserID = 1;                                # the UserID from login or session data

=cut

sub _AuthUser {
    my ( $Self, %Param ) = @_;

    my $ReturnData = 0;

    # get params
    my $PostUser = $Param{Data}->{UserLogin} || '';
    my $PostPw   = $Param{Data}->{Password}  || '';

    # check submitted data
    my $User = $Self->{AuthObject}->Auth(
        User => $PostUser,
        Pw   => $PostPw,
    );

    # login is valid
    if ($User) {

        # get UserID
        my $UserID = $Self->{UserObject}->UserLookup(
            UserLogin => $User,
        );
        $ReturnData = $UserID;
    }

    return $ReturnData;
}

=begin Internal:

=item _AuthCustomerUser()

performs customer user authentication

    my $UserID = $CommonObject->_AuthCustomerUser(
        UserLogin => 'Agent',
        Password  => 'some password',           # plain text password
    );

    returns

    $UserID = 1;                               # the UserID from login or session data

=cut

sub _AuthCustomerUser {
    my ( $Self, %Param ) = @_;

    my $ReturnData = $Param{Data}->{CustomerUserLogin} || 0;

    # get params
    my $PostUser = $Param{Data}->{CustomerUserLogin} || '';
    my $PostPw   = $Param{Data}->{Password}          || '';

    # check submitted data
    my $User = $Self->{CustomerAuthObject}->Auth(
        User => $PostUser,
        Pw   => $PostPw,
    );

    # login is invalid
    if ( !$User ) {
        $ReturnData = 0;
    }

    return $ReturnData;
}

1;

=end Internal:

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

=head1 VERSION

$Revision: 1.6 $ $Date: 2012-01-25 02:45:42 $

=cut
