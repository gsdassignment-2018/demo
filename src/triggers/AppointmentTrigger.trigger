trigger AppointmentTrigger on Appointment__c(before insert,after insert)
{
    if(trigger.isBefore && trigger.isInsert)
        new AppointmentTriggerHandler().onBeforeInsert(trigger.new) ;
    if(trigger.isAfter && trigger.isInsert)
        new AppointmentTriggerHandler().onAfterInsert(trigger.newMap) ;
}