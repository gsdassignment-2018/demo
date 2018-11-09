public class BookAppointmentApexController
{
    //this method will get all the appointments of current user and display it on Calendar(Lightning Component)
    @AuraEnabled
    public static List<WrapperClass> getAppointments(String contactId)
    {
        if(String.isBlank(contactId))
            return null ;
        
        List<WrapperClass> lstWrapper = new List<WrapperClass>() ; 
        for(Appointment__c objAppointment : [select Id,Name,Subject__c,Appointment_Date__c,Start_Time__c,End_Time__c from Appointment__c where OwnerId =: UserInfo.getUserId() ORDER BY Start_Time__c ASC LIMIT 50000])
        {
            lstWrapper.add(new WrapperClass(objAppointment)) ;
        }
        
        if(!lstWrapper.isEmpty())
            return lstWrapper ;
        else
            return null ;
    } 
    
    public class WrapperClass
    {
        @AuraEnabled
            public Appointment__c objAppointment ;
        @AuraEnabled
            public DateTime StartDateTime ;
        @AuraEnabled
            public DateTime EndDateTime ;
        
        public WrapperClass(Appointment__c objAppointment)
        {
            this.objAppointment = objAppointment ;
            StartDateTime = DateTime.newInstance(objAppointment.Appointment_Date__c,objAppointment.Start_Time__c) ;
            EndDateTime = DateTime.newInstance(objAppointment.Appointment_Date__c,objAppointment.End_Time__c) ;
        }
    }   
    
    //this method will save the new Appointment record 
    @AuraEnabled
    public static String saveAppointment(String appointment,String contactId)
    {
        String message = 'SUCCESS' ;
        
        //parsing JSON data 
        BookAppointmentJSONParser objParser = new BookAppointmentJSONParser() ;
        objParser = BookAppointmentJSONParser.parse(appointment) ;
        Appointment__c objAppointment = new Appointment__c() ;
        
        if(String.isNotBlank(contactId))
            objAppointment.Contact__c = contactId ;
        
        if(String.isNotBlank(objParser.Subject))
            objAppointment.Subject__c = objParser.Subject ;
        
        String year ;
        String month ;
        String day ;
        String appointmentDate ;
        
        //converting string date into SF acceptable date type and format
        if(String.isNotBlank(objParser.AppointmentDate))
        {
            if(objParser.AppointmentDate.contains('-'))
            {
                year = objParser.AppointmentDate.subString(0,objParser.AppointmentDate.indexOf('-')) ;
                month = objParser.AppointmentDate.subString(objParser.AppointmentDate.indexOf('-')+1,objParser.AppointmentDate.lastIndexOf('-')) ;
                day = objParser.AppointmentDate.subString(objParser.AppointmentDate.lastIndexOf('-')+1,objParser.AppointmentDate.length()) ;
                appointmentDate = month + '/' + day + '/' + year ;
            }
            else
                appointmentDate = objParser.AppointmentDate ;
        }
        if(String.isNotBlank(appointmentDate))    
            objAppointment.Appointment_Date__c = Date.parse(appointmentDate) ;
        
        if(String.isNotBlank(objParser.StartTime))
            objAppointment.Start_Time__c = Time.newInstance(0,0,0,0).addMilliseconds(Integer.valueOf(objParser.StartTime)) ;
        
        if(String.isNotBlank(objParser.EndTime))
            objAppointment.End_Time__c = Time.newInstance(0,0,0,0).addMilliseconds(Integer.valueOf(objParser.EndTime)) ;
        
        try
        {
            insert objAppointment ;
        }
        catch (Exception e) {
            return e.getMessage() ;
        }   
        
        return message ;
    }
}