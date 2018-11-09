global class BookAppointmentEmailResponseHandler implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        String emailAddress = email.fromAddress ;
        String emailSubject = email.Subject ;
        String emailBody = email.htmlBody ;
        String appointmentName = '' ;
        List<Appointment__c> lstAppointment = new List<Appointment__c>() ;
        if(emailSubject.contains('-'))
        {
            appointmentName = emailSubject.subString(emailSubject.indexOf('-')+1,emailSubject.length()).trim() ;
            if(String.isNotBlank(appointmentName))
            {
                appointmentName = '%' + appointmentName + '%';
                lstAppointment = [select Id,Contact__c from Appointment__c where Name LIKE :appointmentName] ;
            }
        }
        
        String parentId = '' ;
        if(!lstAppointment.isEmpty())
            parentId = lstAppointment[0].Contact__c ;
        else
        {
            List<Contact> lstContacts = [select Id from Contact where Email =: emailAddress] ;
            if(!lstContacts.isEmpty())
                parentId = lstContacts[0].Id ;
        }
        
        if(String.isNotBlank(parentId))
        {
            EmailMessage objEmailMessage = new EmailMessage() ;
            objEmailMessage.FromAddress = email.fromAddress ;
            objEmailMessage.FromName = email.fromName ;
            objEmailMessage.ToAddress = email.toAddresses[0] ;
            objEmailMessage.Subject = email.subject ;
            objEmailMessage.TextBody = email.plainTextBody ;
            objEmailMessage.HtmlBody = email.htmlBody ;
            objEmailMessage.Incoming = true ;
            objEmailMessage.Status = '3' ;
            insert objEmailMessage ;
            
            EmailMessageRelation objEMR = new EmailMessageRelation() ;
            objEMR.EmailMessageId = objEmailMessage.Id ;
            objEMR.RelationId = parentId ;
            objEMR.RelationType = 'FromAddress' ;
            insert objEMR ;
        }
        
        return null ;
    }
}