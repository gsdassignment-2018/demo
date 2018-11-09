@isTest
public class BookAppointmentApexControllerTest {
	@isTest
    public static void testClass(){
        contact con = new contact(LastName ='Test Rec');
        insert con;
        list<Appointment__c> apps = new list<Appointment__c>();
        for(integer i=0;i<5;i++){
            apps.add(new Appointment__c(Appointment_Date__c = Date.today(), Subject__c = 'test sub', Contact__c = con.id, Start_Time__c = DateTime.now().time(), End_Time__c = DateTime.Now().addMinutes(60).time()));
        }
        insert apps;
        
        BookAppointmentApexController.getAppointments(con.id);
        
        String AppointmentStr = '{"Subject":"New Test", "AppointmentDate":"2018-11-16", "StartTime":"1541760874", "EndTime":"1541761374"}';
        BookAppointmentApexController.saveAppointment(AppointmentStr, con.id);
    }
}