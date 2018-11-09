public class AppointmentTriggerHandler
{
    //this method will validate the new appointments so that there won't be any conflict in appointment timings
    public void onBeforeInsert(List<Appointment__c> lstAppointments)
    {
        onBeforeInsertEXT(lstAppointments) ;
    }
    
    private static void onBeforeInsertEXT(List<Appointment__c> lstAppointments)
    {
        Map<Date,List<Appointment__c>> mapAppDateToExistingApp = new Map<Date,List<Appointment__c>>() ;
        
        //getting all the existing appointments of current user
        for(Appointment__c objAppointment : [select Id,Name,Appointment_Date__c,Start_Time__c,End_Time__c,Contact__c from Appointment__c where OwnerId =: UserInfo.getUserId() AND Appointment_Date__c >= TODAY ORDER BY Start_Time__c ASC LIMIT 24000])
        {
            if(mapAppDateToExistingApp.containsKey(objAppointment.Appointment_Date__c))
                mapAppDateToExistingApp.get(objAppointment.Appointment_Date__c).add(objAppointment) ;
            else
                mapAppDateToExistingApp.put(objAppointment.Appointment_Date__c,new Appointment__c[] {objAppointment}) ;
        }

        Map<Date,List<Appointment__c>> mapDateToSuccessAppointments = new Map<Date,List<Appointment__c>>() ;
        if(!mapAppDateToExistingApp.isEmpty())
        {
            for(Appointment__c objAppointment : lstAppointments)
            {
                Boolean isConflict = false ;
                if(mapAppDateToExistingApp.containsKey(objAppointment.Appointment_Date__c))
                {
                    //this piece of code will check if current appointment timings does not conflict with existing appointmnet timing 
                    for(Appointment__c objExistingApp : mapAppDateToExistingApp.get(objAppointment.Appointment_Date__c))
                    {
                        if((objAppointment.Start_Time__c >= objExistingApp.Start_Time__c && objAppointment.Start_Time__c < objExistingApp.End_Time__c) || (objAppointment.End_Time__c > objExistingApp.Start_Time__c && objAppointment.End_Time__c <= objExistingApp.End_Time__c) || (objAppointment.Start_Time__c <= objExistingApp.Start_Time__c && objAppointment.End_Time__c >= objExistingApp.End_Time__c))
                        {
                            isConflict = true ;
                            objAppointment.addError('You have already booked an appointment for this time slot.Please check all your appointments for ' + String.valueOf(objAppointment.Appointment_Date__c) + ' , and select the available time slot.') ;
                        }
                    }
                }
                
                //this piece of code will check if same appointment timing has not been set for all current appointments(to prevent the conflict among all current appointments) 
                if(isConflict == false)
                {
                    if(mapDateToSuccessAppointments.containsKey(objAppointment.Appointment_Date__c))
                    {
                        for(Appointment__c objSuccessAppointment : mapDateToSuccessAppointments.get(objAppointment.Appointment_Date__c))
                        {
                            if((objAppointment.Start_Time__c >= objSuccessAppointment.Start_Time__c && objAppointment.Start_Time__c < objSuccessAppointment.End_Time__c) || (objAppointment.End_Time__c > objSuccessAppointment.Start_Time__c && objAppointment.End_Time__c <= objSuccessAppointment.End_Time__c) || (objAppointment.Start_Time__c <= objSuccessAppointment.Start_Time__c && objAppointment.End_Time__c >= objSuccessAppointment.End_Time__c))
                            {
                                objAppointment.addError('You have already booked an appointment for this time slot.Please check all your appointments for ' + String.valueOf(objAppointment.Appointment_Date__c) + ' , and select the available time slot.') ;
                            }
                        }
                    }
                    else
                        mapDateToSuccessAppointments.put(objAppointment.Appointment_Date__c,new Appointment__c[] {objAppointment}) ;
                }
            }
        }
    }
    
    //this method will send the email to Appointment's Contact Person
    public void onAfterInsert(Map<Id,Appointment__c> mapIdToAppointments)
    {
        onAfterInsertEXT(mapIdToAppointments) ;
    }
    
    private static void onAfterInsertEXT(Map<Id,Appointment__c> mapIdToAppointments)
    {
        Map<String,Schema.sObjectField> fieldMap = Schema.getGlobalDescribe().get('Appointment__c').getDescribe().fields.getMap() ;
        List<EmailTemplate> emailTemplate = new List<EmailTemplate>() ; 
        if(String.isNotBlank(Label.BookAppointmentEmailTemplate))
            emailTemplate = [select Id,Name,HTMLValue,Subject from EmailTemplate where DeveloperName =: Label.BookAppointmentEmailTemplate] ;
        
        List<Messaging.SingleEmailMessage> lstEmails = new List<Messaging.SingleEmailMessage>() ;
        if(!emailTemplate.isEmpty())
        {
            EmailTemplate objEmailTemplate = emailTemplate[0] ;
            String refTempBody = objEmailTemplate.HTMLValue ;
            String refSubject = objEmailTemplate.Subject ;
            String templateBody = refTempBody ;
            String templateSubject = refSubject ;
            String fieldsFromTemplate = 'Id,Name,Contact__r.Email,OwnerId,Owner.Name,Owner.Email,' ;
            String query = 'select ' ;
            
            //the merging and replacing of values in email template is partially dynamic.See Read me file in GIT repo for more information
            //getting all the merge field value from template subject
            while(templateSubject.contains('{!'))
            {
                String fieldApiName = templateSubject.subStringBetween('{!','}') ;
                
                if(fieldApiName.contains('.'))
                {
                    String fieldApi = fieldApiName.subString(fieldApiName.indexOf('.') + 1,fieldApiName.length()) ;
                    refSubject = refSubject.replace(fieldApiName,fieldApi) ;
                    
                    if(fieldApi == 'OwnerFirstName' || fieldApi == 'OwnerLastName' || fieldApi == 'OwnerId' || fieldApi == 'OwnerFullName')
                    {
                        if(!fieldsFromTemplate.contains('OwnerId,Owner.Name'))      
                            fieldsFromTemplate += 'OwnerId,Owner.Name' + ',' ;
                            
                        refSubject = refSubject.replace(fieldApiName,'OwnerId') ;
                    }
                    else if(fieldApi == 'CreatedBy' || fieldApi == 'LastModifiedBy')
                    {
                        if(!fieldsFromTemplate.contains(','+ fieldApi + 'Id,'))      
                            fieldsFromTemplate += fieldApi + 'Id,' ;
                            
                        refSubject = refSubject.replace(fieldApi,fieldApi + 'Id') ;
                    }
                    else if(fieldApi == 'Link')
                    {
                        refSubject = refSubject.replace('{!' + fieldApi + '}',System.URL.getSalesforceBaseUrl().toExternalForm() + '/{!Id}') ;
                    }
                    else if(fieldMap.containsKey(fieldApi.toLowerCase()))
                    {
                        DescribeFieldResult objDFR = fieldMap.get(fieldApi.toLowerCase()).getDescribe() ;
                        if(objDFR.getType() == Schema.DisplayType.REFERENCE  && objDFR.isCustom())
                            fieldApi = fieldApi.replace('__c','__r.Name') ;
                        
                        if(!fieldsFromTemplate.contains(','+fieldApi+','))                      
                            fieldsFromTemplate += fieldApi + ',' ;
                    }
                    else
                        refSubject = refSubject.replace('{!' + fieldApi + '}','') ;
                }
                
                templateSubject = templateSubject.replace('{!' + fieldApiName + '}','') ;
            }
            
            //getting all the merge field value from template body
            while(templateBody.contains('{!')) 
            {
                String fieldApiName = templateBody.subStringBetween('{!','}') ;
                   
                if(fieldApiName.contains('.'))
                {
                    String fieldApi = fieldApiName.subString(fieldApiName.indexOf('.') + 1,fieldApiName.length()) ;
                    refTempBody = refTempBody.replace(fieldApiName,fieldApi) ;
                    
                    if(fieldApi == 'OwnerFirstName' || fieldApi == 'OwnerLastName' || fieldApi == 'OwnerId' || fieldApi == 'OwnerFullName')
                    {
                        if(!fieldsFromTemplate.contains('OwnerId,Owner.Name'))      
                            fieldsFromTemplate += 'OwnerId,Owner.Name' + ',' ;
                            
                        refTempBody = refTempBody.replace(fieldApiName,'OwnerId') ;
                    }
                    else if(fieldApi == 'CreatedBy' || fieldApi == 'LastModifiedBy')
                    {
                        if(!fieldsFromTemplate.contains(','+ fieldApi + 'Id,'))      
                            fieldsFromTemplate += fieldApi + 'Id,' ;
                            
                        refTempBody = refTempBody.replace(fieldApi,fieldApi + 'Id') ;
                    }
                    else if(fieldApi == 'Link')
                    {
                        refTempBody = refTempBody.replace('{!' + fieldApi + '}',System.URL.getSalesforceBaseUrl().toExternalForm() + '/{!Id}') ;
                    }
                    else if(fieldMap.containsKey(fieldApi.toLowerCase()))
                    {
                        DescribeFieldResult objDFR = fieldMap.get(fieldApi.toLowerCase()).getDescribe() ;
                        if(objDFR.getType() == Schema.DisplayType.REFERENCE && objDFR.isCustom())
                            fieldApi += ',' + fieldApi.replace('__c','__r.Name') ;
                        
                        if(!fieldsFromTemplate.contains(',' + fieldApi + ','))
                            fieldsFromTemplate += fieldApi + ',' ;
                    }
                    else
                        refTempBody = refTempBody.replace('{!' + fieldApi + '}','') ;
                        
                }
                
                templateBody = templateBody.replace('{!' + fieldApiName + '}','') ;
            }
            
            query += fieldsFromTemplate ;
            
            if(query.endsWith(','))
                query = query.removeEnd(',') ;
            
            Set<Id> setAppIds = mapIdToAppointments.keyset() ;
            query += ' from Appointment__c where Id IN: setAppIds AND Contact__c != null LIMIT 24000' ;
            
            for(Appointment__c objAppointment: Database.query(query))
            {
                if(String.isNotBlank(objAppointment.Contact__r.Email))
                {
                    String body = refTempBody ;
                    String subject = refSubject ;
                    
                    //replacing the merge field with actual values on email subject 
                    while(subject.contains('{!'))
                    {
                        String fieldApiName = subject.subStringBetween('{!','}') ;
                        if(fieldMap.containsKey(fieldApiName))
                        {
                            DescribeFieldResult objDFR = fieldMap.get(fieldApiName).getDescribe() ;
                            if(objDFR.getType() == Schema.DisplayType.REFERENCE  && objDFR.isCustom())
                                subject = subject.replace('{!' + fieldApiName + '}',(String) objAppointment.getsObject(fieldApiName.replace('__c','__r')).get('Name')) ;
                            else 
                                subject = subject.replace('{!' + fieldApiName + '}',objAppointment.get(fieldApiName) != null ? String.valueOf(objAppointment.get(fieldApiName)) : '') ;
                            
                        }
                        
                    }
                    
                    //replacing the merge field with actual values on email body 
                    while(body.contains('{!'))  
                    {
                        String fieldApiName = body.subStringBetween('{!','}') ;
                        if(fieldMap.containsKey(fieldApiName))
                        {
                            DescribeFieldResult objDFR = fieldMap.get(fieldApiName).getDescribe() ;
                            if(objDFR.getType() == Schema.DisplayType.REFERENCE && objDFR.isCustom())
                                body = body.replace('{!' + fieldApiName + '}',(String) objAppointment.getsObject(fieldApiName.replace('__c','__r')).get('Name')) ;
                            else 
                                body = body.replace('{!' + fieldApiName + '}',objAppointment.get(fieldApiName) != null ? String.valueOf(objAppointment.get(fieldApiName)) : '') ;
                            
                        }
                    }
                    
                    if(subject.contains(objAppointment.OwnerId))
                        subject = subject.replace(objAppointment.OwnerId,objAppointment.Owner.Name != null ? objAppointment.Owner.Name : '') ;
                    
                    if(body.contains(objAppointment.OwnerId))
                        body = body.replace(objAppointment.OwnerId,objAppointment.Owner.Name != null ? objAppointment.Owner.Name : '') ;
                    
                    Messaging.SingleEmailMessage objEmail = new Messaging.SingleEmailMessage() ;
                    objEmail.setSubject(subject) ;
                    objEmail.setToAddresses(new String[] {objAppointment.Contact__r.Email}) ;
                    objEmail.setHtmlBody(body) ;
                    
                    //contains the email service address so that we can get the email response in SF.It is highly recommended that an external service address should have the email forwarding to email service address so that the external email and SF both can get the response
                    objEmail.setReplyTo('book_appointment_response@1ojaytyxko6diugup4cji3o6j4kkuq6hsreblbwyjud64nmqjq.6f-2zipmua0.ap4.apex.salesforce.com') ; 
                    
                    objEmail.setTargetObjectId(objAppointment.Contact__c) ;
                    objEmail.setSaveAsActivity(true) ;
                    lstEmails.add(objEmail) ;
                }
            }
            if(!lstEmails.isEmpty())
            {
                if(!Test.isRunningTest())
                    Messaging.sendEmail(lstEmails) ;
            }
        }
    }
}