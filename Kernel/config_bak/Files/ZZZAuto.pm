# OTRS config file (automatically generated)
# VERSION:1.1
package Kernel::Config::Files::ZZZAuto;
use strict;
use warnings;
use utf8;
sub Load {
    my ($File, $Self) = @_;
$Self->{'iPhone::API::Object'}->{'TicketObject'} =  '';
$Self->{'PostMaster::PreFilterModule::NewTicketReject::Body'} =  'Dear Customer,

Unfortunately we could not detect a valid ticket number
in your subject, so this email can\'t be processed.

Please create a new ticket via the customer panel.

Thanks for your help!

 Your Helpdesk Team';
$Self->{'PostMaster::PreFilterModule::NewTicketReject::Sender'} =  'internet@holzland.de';
$Self->{'PostmasterMaxEmails'} =  '200';
$Self->{'Frontend::ToolBarModule'}->{'9-Ticket::TicketSearchProfile'} =  {
  'Block' => 'ToolBarSearchProfile',
  'Description' => 'Search-Template',
  'MaxWidth' => '40',
  'Module' => 'Kernel::Output::HTML::ToolBarTicketSearchProfile',
  'Name' => 'Search-Template',
  'Priority' => '1990010'
};
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'State'} =  '1';
$Self->{'Ticket::ZoomTimeDisplay'} =  '1';
$Self->{'Ticket::Frontend::ZoomExpandSort'} =  'reverse';
$Self->{'Ticket::Watcher'} =  '1';
$Self->{'Ticket::Responsible'} =  '1';
$Self->{'Ticket::SubjectFormat'} =  'Right';
$Self->{'Ticket::Hook'} =  'HLZ#';
delete $Self->{'PreferencesGroups'}->{'SpellDict'};
$Self->{'NotificationSenderEmail'} =  'internet@holzland.de';
$Self->{'NotificationSenderName'} =  'HolzLand GmbH';
delete $Self->{'SendmailBcc'};
$Self->{'SendmailModule::AuthPassword'} =  'Werbung1';
$Self->{'SendmailModule::AuthUser'} =  'internet1';
$Self->{'SendmailModule::Port'} =  '25';
$Self->{'SendmailModule::Host'} =  'owa.holzland.de';
$Self->{'SendmailModule'} =  'Kernel::System::Email::MultiSMTP';
$Self->{'CheckEmailAddresses'} =  '0';
$Self->{'CheckMXRecord'} =  '0';
$Self->{'DefaultLanguage'} =  'de';
$Self->{'Organization'} =  'HolzLand GmbH';
$Self->{'AdminEmail'} =  'andre.rosowski@omigos.de';
$Self->{'FQDN'} =  'h2109435.stratoserver.net';
$Self->{'SystemID'} =  '11';
$Self->{'SecureMode'} =  '1';
}
1;
