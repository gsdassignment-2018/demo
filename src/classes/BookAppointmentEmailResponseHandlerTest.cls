@isTest
public class BookAppointmentEmailResponseHandlerTest {
	
    @isTest
    public static void testClass(){
        
        contact con = new contact(LastName ='Test Rec', Email = 'user@name.com');
        insert con;
        list<Appointment__c> apps = new list<Appointment__c>();
        for(integer i=0;i<5;i++){
            apps.add(new Appointment__c(Appointment_Date__c = Date.today().addDays(5), Subject__c = 'test sub', Contact__c = con.id, Start_Time__c = DateTime.now().time(), End_Time__c = DateTime.Now().addMinutes(60).time(), OwnerId = Userinfo.getUserId()));
        }
        User u = new User(
            ProfileId = userinfo.getProfileId(),
            LastName = 'last',
            Email = 'puser000@amamama.com',
            Username = 'puser@mama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        System.runAs(u){
            
        }
        insert apps;
        
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();

        email.subject = 'Test Email - test sub';
        email.fromName = 'Test User';
        email.toAddresses = new String[]{'test@user.com'};
        email.plainTextBody = 'Hello, this a test email body.';
        email.fromAddress = 'user@name.com';
        envelope.fromAddress = 'user@name.com';


        // setup controller object
        BookAppointmentEmailResponseHandler handler = new BookAppointmentEmailResponseHandler();
        handler.handleInboundEmail(email, envelope);
    }
}